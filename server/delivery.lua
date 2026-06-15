-- =======================================================================================
-- SERVER/DELIVERY.LUA
-- Sistema de Rotas e Entregas (Server-side) - Estado Autoritativo
-- Compatível com: Qbox (qbx_core) | QBCore (qb-core) | MRI
-- =======================================================================================

local _QBX    = GetResourceState('qbx_core') ~= 'missing' and exports.qbx_core or nil
local _QBCore = (not _QBX and GetResourceState('qb-core') ~= 'missing') and exports['qb-core']:GetCoreObject() or nil

local function GetPlayer(src)
    if _QBX    then return _QBX:GetPlayer(src) end
    if _QBCore then return _QBCore.Functions.GetPlayer(src) end
    return nil
end

-- =======================================================================================
-- HELPER: REMOVER CHAVE DO VEÍCULO (temp + item físico)
-- =======================================================================================
local function RemoveVehicleKey(src, plate)
    if not Config.KeySystem.enabled or not plate then return end
    local res = Config.KeySystem.resourceName
    pcall(function() exports[res]:RemoveTempKeys(src, plate) end)
    pcall(function() exports[res]:RemoveKeyItem(src, plate)  end)
end

-- =======================================================================================
-- ESTRUTURA DE ESTADO DAS MISSÕES
-- =======================================================================================
local activeMissions = {}

--[[
    Estrutura de uma missão:
    {
        citizenid = string,
        source = number,
        destination = table,
        planeNetId = number,
        plate = string,
        boxesRequired = number,
        boxesCollected = number,
        boxesLoaded = number,
        boxesDelivered = number,
        startTime = number,
        deliveryPointsUsed = {},
        deliveryPoints = table,  -- Lista de pontos de entrega gerados pelo servidor
        phase = string ("collecting", "loading", "traveling", "delivering", "completed")
    }
]]

-- =======================================================================================
-- FUNÇÕES AUXILIARES: GERAÇÃO DETERMINÍSTICA SEM CONTAMINAR RNG GLOBAL
-- =======================================================================================
local function GetDeterministicValue(seed, min, max)
    -- Gerador Linear Congruencial (LCG) - Gera números pseudo-aleatórios sem afetar math.random()
    -- Parâmetros: a = 1103515245, c = 12345, m = 2^31 (mesmos usados em algumas implementações C)
    local a = 1103515245
    local c = 12345
    local m = 2147483648  -- 2^31
    
    -- Gerar valor pseudo-aleatório determinístico
    local value = (a * seed + c) % m
    
    -- Escalar para o intervalo [min, max]
    local range = max - min + 1
    return min + (value % range)
end

local function GetDeterministicOffset(seed, index, min, max)
    -- Combinar seed com index para gerar valor único mas determinístico
    -- Usar número primo (7919) para melhor distribuição
    local combinedSeed = seed + (index * 7919)
    return GetDeterministicValue(combinedSeed, min, max)
end

-- =======================================================================================
-- FUNÇÃO: GERAR PONTOS DE ENTREGA DINÂMICOS (DETERMINÍSTICO)
-- =======================================================================================
function GenerateDeliveryPoints(basePoints, requiredAmount, seed)
    local generatedPoints = {}
    
    -- Adicionar pontos base configurados
    for i, point in ipairs(basePoints) do
        table.insert(generatedPoints, vec3(point.x, point.y, point.z))
    end
    
    -- Se precisar de mais pontos, gerar extras próximos aos pontos base
    local pointsNeeded = requiredAmount - #basePoints
    if pointsNeeded > 0 then
        local baseIndex = 1
        for i = 1, pointsNeeded do
            -- Usar ponto base como referência (rotação circular)
            local basePoint = basePoints[baseIndex]
            
            -- Gerar offsets determinísticos (-15 a 15 metros de distância)
            -- Usa função determinística que NÃO contamina math.random() global
            local offsetX = GetDeterministicOffset(seed, i * 2, -15, 15)
            local offsetY = GetDeterministicOffset(seed, i * 2 + 1, -15, 15)
            
            -- Criar novo ponto próximo ao ponto base usando vec3
            local newPoint = vec3(
                basePoint.x + offsetX,
                basePoint.y + offsetY,
                basePoint.z
            )
            
            table.insert(generatedPoints, newPoint)
            
            -- Próximo ponto base para distribuir melhor
            baseIndex = (baseIndex % #basePoints) + 1
        end
    end
    
    return generatedPoints
end

-- =======================================================================================
-- FUNÇÃO INTERNA: CRIAR E ENVIAR ROTA (reutilizada por generateRoute e generateClandestineRoute)
-- =======================================================================================
-- Seleciona o destino respeitando o nível do jogador.
-- Se um índice for pedido e estiver liberado, usa-o; senão sorteia entre os liberados.
local function PickDestination(level, requestedIndex)
    if requestedIndex then
        local dest = Config.DestinationAirports[requestedIndex]
        if dest and level >= (dest.minLevel or 1) then
            return dest
        end
    end
    local allowed = {}
    for _, dest in ipairs(Config.DestinationAirports) do
        if level >= (dest.minLevel or 1) then allowed[#allowed + 1] = dest end
    end
    if #allowed == 0 then return Config.DestinationAirports[1] end
    return allowed[math.random(#allowed)]
end

-- Valida o modelo de avião pelo nível; faz fallback para o melhor liberado.
local function PickPlaneModel(level, requestedModel)
    if requestedModel then
        for _, p in ipairs(Config.Planes) do
            if p.model == requestedModel and level >= (p.minLevel or 1) then
                return p.model
            end
        end
    end
    local best = Config.Planes[1].model
    for _, p in ipairs(Config.Planes) do
        if level >= (p.minLevel or 1) then best = p.model end
    end
    return best
end

local function CreateAndSendRoute(src, player, opts)
    opts = opts or {}
    local citizenid = player.PlayerData.citizenid

    local existing = activeMissions[citizenid]
    -- Bloqueia só se já houver uma missão EM ANDAMENTO (concluída pode reiniciar)
    if existing and existing.phase ~= "completed" then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('route_active'),
            type = 'error'
        })
        return
    end

    -- Reutiliza o avião da missão concluída (não spawna outro)
    local reusePlaneNetId = existing and existing.planeNetId or nil
    local reusePlate      = existing and existing.plate or nil

    local prog          = PilotoGetData(citizenid)
    local level         = GetPlayerLevel(prog.xp)
    local destination   = PickDestination(level, opts.destinationIndex)
    local planeModel    = (existing and existing.planeModel) or PickPlaneModel(level, opts.planeModel)
    local boxesRequired = math.random(Config.BoxesPerMission.min, Config.BoxesPerMission.max)
    local seed          = os.time() + src
    local deliveryPoints = GenerateDeliveryPoints(destination.deliveryPoints, boxesRequired, seed)

    activeMissions[citizenid] = {
        citizenid          = citizenid,
        source             = src,
        destination        = destination,
        planeModel         = planeModel,
        clandestine        = opts.clandestine == true,
        planeNetId         = reusePlaneNetId,
        plate              = reusePlate,
        boxesRequired      = boxesRequired,
        boxesCollected     = 0,
        boxesLoaded        = 0,
        boxesDelivered     = 0,
        totalPaid          = 0,
        totalXP            = 0,
        startTime          = os.time(),
        deliveryPointsUsed = {},
        deliveryPoints     = deliveryPoints,
        phase              = "collecting"
    }

    TriggerClientEvent('rodz-piloto:client:receiveRoute', src, {
        destination    = destination,
        boxesRequired  = boxesRequired,
        deliveryPoints = deliveryPoints,
        planeModel     = planeModel,
        clandestine    = opts.clandestine == true
    })

    print(string.format("^3[RODZ-PILOTO]^7 Player %s started %s route to %s (%s boxes, plane %s)",
        src, opts.clandestine and "clandestine" or "official", destination.name, boxesRequired, planeModel))
end

-- =======================================================================================
-- EVENTO: INICIAR ROTA COM BREVÊ
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:generateRoute', function(opts)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    local hasLicense = exports.ox_inventory:Search(src, 'count', 'breve')
    if hasLicense == 0 then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('no_license'),
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to start route without license", src))
        return
    end

    opts = type(opts) == 'table' and opts or {}
    opts.clandestine = false
    CreateAndSendRoute(src, player, opts)
end)

-- =======================================================================================
-- EVENTO: INICIAR ROTA CLANDESTINA (sem brevê)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:generateClandestineRoute', function(opts)
    local src    = source
    local player = GetPlayer(src)
    if not player then return end

    opts = type(opts) == 'table' and opts or {}
    opts.clandestine = true
    print(string.format("^3[RODZ-PILOTO]^7 Player %s started clandestine route (no license)", src))
    CreateAndSendRoute(src, player, opts)
end)

-- =======================================================================================
-- EVENTO: REGISTRAR AVIÃO SPAWNADO (CHAMADO PELO CLIENT APÓS SPAWN)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:registerPlane', function(netId, plate)
    local src = source
    local player = GetPlayer(src)
    if not player then
        print("^1[RODZ-PILOTO]^7 registerPlane: GetPlayer retornou nil para src=" .. tostring(src))
        return
    end

    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]

    if not mission then
        print("^1[RODZ-PILOTO]^7 registerPlane: missão não encontrada para citizenid=" .. tostring(citizenid))
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'DEBUG Chave',
            description = 'Sem missão ativa no servidor (citizenid=' .. tostring(citizenid) .. ')',
            type = 'error'
        })
        return
    end

    mission.planeNetId = netId
    mission.plate = plate

    if Config.KeySystem.enabled then
        local res  = Config.KeySystem.resourceName
        local func = Config.KeySystem.exportName
        local ok, err = pcall(function()
            exports[res][func](exports[res], src, plate)
        end)
        if ok then
            TriggerClientEvent('rodz-piloto:client:notify', src, {
                title = 'Chave recebida',
                description = 'Placa: ' .. plate,
                type = 'success'
            })
            print(string.format("^2[RODZ-PILOTO]^7 Chave dada ao jogador %s (Placa: %s)", src, plate))
        else
            TriggerClientEvent('rodz-piloto:client:notify', src, {
                title = 'DEBUG Chave',
                description = 'Erro: ' .. tostring(err),
                type = 'error'
            })
            print(string.format("^1[RODZ-PILOTO]^7 ERRO ao dar chave [%s][%s]: %s", res, func, tostring(err)))
        end
    end

    print(string.format("^3[RODZ-PILOTO]^7 Avião registrado: NetID %s, Placa %s", netId, plate))
end)

-- =======================================================================================
-- EVENTO: COLETAR CAIXA (NA ZONA DE PICKUP)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:collectBox', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem uma missão ativa',
            type = 'error'
        })
        return
    end
    
    -- Verificar se já coletou todas as caixas necessárias
    if mission.boxesCollected >= mission.boxesRequired then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você já coletou todas as caixas necessárias',
            type = 'info'
        })
        return
    end
    
    -- Incrementar contador de caixas coletadas (ainda não foi depositada no avião)
    mission.boxesCollected = mission.boxesCollected + 1
    
    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:boxCollected', src, {
        boxesCollected = mission.boxesCollected,
        boxesRequired = mission.boxesRequired
    })
    
    print(string.format("^3[RODZ-PILOTO]^7 Player %s collected box (%s/%s) - need to deposit in plane", src, mission.boxesCollected, mission.boxesRequired))
end)

-- =======================================================================================
-- EVENTO: DEPOSITAR CAIXA NO AVIÃO
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:depositBox', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem uma missão ativa',
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to deposit without mission", src))
        return
    end
    
    -- ANTI-EXPLOIT: Verificar se tem caixa coletada pendente para depositar
    if mission.boxesCollected <= mission.boxesLoaded then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem caixa para depositar',
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to deposit without collected box (collected:%s, loaded:%s)", src, mission.boxesCollected, mission.boxesLoaded))
        return
    end
    
    -- Verificar se já carregou todas as caixas necessárias
    if mission.boxesLoaded >= mission.boxesRequired then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'O avião já está cheio',
            type = 'info'
        })
        return
    end
    
    -- Incrementar caixas carregadas no avião
    mission.boxesLoaded = mission.boxesLoaded + 1

    -- Atualizar estado/HUD do cliente
    TriggerClientEvent('rodz-piloto:client:boxDeposited', src, {
        boxesLoaded = mission.boxesLoaded,
        boxesRequired = mission.boxesRequired
    })

    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:notify', src, {
        title = 'Aeroporto',
        description = string.format('Caixa depositada no avião (%s/%s)', mission.boxesLoaded, mission.boxesRequired),
        type = 'success'
    })
    
    print(string.format("^2[RODZ-PILOTO]^7 Player %s deposited box in plane (%s/%s)", src, mission.boxesLoaded, mission.boxesRequired))
end)

-- =======================================================================================
-- EVENTO: PEGAR CAIXA DO AVIÃO (NO DESTINO)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:pickupBoxFromPlane', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem uma missão ativa',
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to pickup without mission", src))
        return
    end
    
    -- ANTI-EXPLOIT: Verificar se há caixas no avião
    if mission.boxesLoaded <= 0 then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Não há caixas no avião',
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to pickup without boxes in plane (loaded:%s)", src, mission.boxesLoaded))
        return
    end
    
    -- Decrementar caixas carregadas
    mission.boxesLoaded = mission.boxesLoaded - 1
    
    -- Notificar cliente para anexar prop
    TriggerClientEvent('rodz-piloto:client:boxPickedFromPlane', src, {
        boxesLoaded = mission.boxesLoaded,
        boxesRequired = mission.boxesRequired
    })
    
    print(string.format("^2[RODZ-PILOTO]^7 Player %s picked box from plane (%s remaining)", src, mission.boxesLoaded))
end)

-- =======================================================================================
-- EVENTO: ENTREGAR CAIXA (NO PONTO DE ENTREGA)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:deliverBox', function(pointIndex)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then return end
    
    -- ANTI-EXPLOIT: Validar se o índice do ponto é válido
    if not pointIndex or pointIndex < 1 or pointIndex > #mission.deliveryPoints then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Ponto de entrega inválido',
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to deliver to invalid point index %s (max: %s)", src, pointIndex or "nil", #mission.deliveryPoints))
        return
    end
    
    -- Verificar se o ponto já foi usado
    for _, usedPoint in ipairs(mission.deliveryPointsUsed) do
        if usedPoint == pointIndex then
            TriggerClientEvent('rodz-piloto:client:notify', src, {
                title = 'Aeroporto',
                description = 'Você já entregou uma caixa neste ponto',
                type = 'error'
            })
            return
        end
    end
    
    -- Incrementar caixas entregues
    mission.boxesDelivered = mission.boxesDelivered + 1
    table.insert(mission.deliveryPointsUsed, pointIndex)

    -- Calcular pagamento por caixa: faixa do destino × multiplicador do nível
    local prog = PilotoGetData(citizenid)
    local mult = GetLevelMultiplier(prog.xp)
    local dest = mission.destination
    local payMin = dest.payMin or Config.DeliveryReward.min
    local payMax = dest.payMax or Config.DeliveryReward.max
    local base   = math.random(payMin, payMax)
    if mission.clandestine then base = math.floor(base * Config.XP.clandestinePayMult) end
    local payment = math.floor(base * mult)

    -- XP da caixa (rota clandestina dá menos XP)
    local xpGain = dest.baseXP or 0
    if mission.clandestine then xpGain = math.floor(xpGain * Config.XP.clandestineXPMult) end

    -- Acumular totais da missão
    mission.totalPaid = (mission.totalPaid or 0) + payment
    mission.totalXP   = (mission.totalXP or 0) + xpGain

    -- Dar dinheiro e XP
    player.Functions.AddMoney('cash', payment, 'pilot-box-delivery')
    PilotoAward(src, citizenid, payment, xpGain)

    -- Verificar se completou todas as entregas
    if mission.boxesDelivered >= mission.boxesRequired then
        -- Missão completa
        CompleteMission(citizenid, src)
    else
        -- Notificar progresso
        TriggerClientEvent('rodz-piloto:client:boxDelivered', src, {
            boxesDelivered = mission.boxesDelivered,
            boxesRequired = mission.boxesRequired,
            payment = payment,
            xp = xpGain,
            pointIndex = pointIndex
        })
    end

    print(string.format("^3[RODZ-PILOTO]^7 Player %s delivered box (%s/%s) - R$ %s (+%s XP)", src, mission.boxesDelivered, mission.boxesRequired, payment, xpGain))
end)

-- =======================================================================================
-- FUNÇÃO: COMPLETAR MISSÃO
-- =======================================================================================
function CompleteMission(citizenid, src)
    local mission = activeMissions[citizenid]
    if not mission then return end

    local totalPayment = mission.totalPaid or 0

    -- Bônus de XP por concluir toda a missão
    local bonusXP = Config.XP.completionBonus or 0
    if mission.clandestine then bonusXP = math.floor(bonusXP * Config.XP.clandestineXPMult) end
    PilotoAward(src, citizenid, 0, bonusXP)
    local totalXP = (mission.totalXP or 0) + bonusXP

    -- Registrar estatística + histórico (e salvar no banco)
    PilotoRecordCompletion(citizenid, {
        destination = mission.destination.name,
        boxes       = mission.boxesDelivered,
        pay         = totalPayment,
        xp          = totalXP,
        clandestine = mission.clandestine == true,
        date        = os.date('%d/%m %H:%M'),
    })

    -- Marcar missão como completa (mas manter dados para permitir nova rota com mesmo avião)
    mission.phase = "completed"
    mission.completedTime = os.time()

    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:missionCompleted', src, {
        pay = totalPayment,
        xp  = totalXP,
    })

    print(string.format("^2[RODZ-PILOTO]^7 Player %s completed mission: %s boxes | R$ %s | +%s XP", src, mission.boxesDelivered, totalPayment, totalXP))
end

-- =======================================================================================
-- EVENTO: CANCELAR MISSÃO
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:cancelMission', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then return end
    
    RemoveVehicleKey(src, mission.plate)

    -- Limpar missão
    activeMissions[citizenid] = nil
    
    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:missionCancelled', src)
    
    print(string.format("^3[RODZ-PILOTO]^7 Player %s cancelled mission", src))
end)

-- =======================================================================================
-- EVENTO: REMOVER AVIÃO (chamado por DeleteWorkPlane no client)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:removePlane', function(plate)
    local src = source
    RemoveVehicleKey(src, plate)
    print(string.format("^3[RODZ-PILOTO]^7 Chave removida do jogador %s (Placa: %s)", src, plate))
end)

-- =======================================================================================
-- EVENTO: DEVOLVER AVIÃO
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:returnPlane', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then return end
    
    RemoveVehicleKey(src, mission.plate)

    -- Limpar missão completamente
    activeMissions[citizenid] = nil
    
    print(string.format("^2[RODZ-PILOTO]^7 Player %s returned plane (Plate: %s)", src, mission.plate or "unknown"))
end)

-- =======================================================================================
-- EVENTO: CONTINUAR COM MESMO AVIÃO (NOVA ROTA)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:continueWithSamePlane', function()
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    local oldMission = activeMissions[citizenid]
    
    if not oldMission or oldMission.phase ~= "completed" then 
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você precisa completar uma missão primeiro',
            type = 'error'
        })
        return 
    end
    
    -- Manter dados do avião (planeNetId, plate) mas resetar contadores
    local planeNetId = oldMission.planeNetId
    local plate = oldMission.plate
    
    -- Selecionar novo destino aleatório
    local destination = Config.DestinationAirports[math.random(#Config.DestinationAirports)]
    
    -- Gerar nova quantidade de caixas
    local boxesRequired = math.random(Config.BoxesPerMission.min, Config.BoxesPerMission.max)
    
    -- Gerar seed determinística para os pontos de entrega
    local seed = os.time() + src
    
    -- Gerar pontos de entrega no servidor (autoritativo)
    local deliveryPoints = GenerateDeliveryPoints(destination.deliveryPoints, boxesRequired, seed)
    
    -- Criar nova missão com mesmo avião
    local mission = {
        citizenid = citizenid,
        source = src,
        destination = destination,
        planeNetId = planeNetId,  -- Reutilizar avião existente
        plate = plate,             -- Manter placa
        boxesRequired = boxesRequired,
        boxesCollected = 0,
        boxesLoaded = 0,
        boxesDelivered = 0,
        startTime = os.time(),
        deliveryPointsUsed = {},
        deliveryPoints = deliveryPoints,  -- Armazenar pontos gerados pelo servidor
        phase = "collecting"
    }
    
    -- Substituir missão antiga
    activeMissions[citizenid] = mission
    
    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:receiveRoute', src, {
        destination = destination,
        boxesRequired = boxesRequired,
        deliveryPoints = deliveryPoints  -- Enviar pontos para o cliente
    })
    
    print(string.format("^3[RODZ-PILOTO]^7 Player %s continued with same plane (Plate: %s) to %s", src, plate, destination.name))
end)

-- =======================================================================================
-- EVENTO ANTIGO: COMPLETAR ENTREGA (MANTER POR COMPATIBILIDADE)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:completeDelivery', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Verificar se tem rota ativa
    if not activeRoutes[citizenid] then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem uma rota ativa',
            type = 'error'
        })
        return
    end
    
    -- =======================================================================================
    -- SISTEMA EXTERNO: Contar caixas entregues do baú do avião
    -- =======================================================================================
    -- AQUI: Sistema de baú por placa deve ser consultado
    -- Exemplo (pseudocódigo):
    -- local vehicle = GetPlayerVehicle(src)
    -- local plate = GetVehiclePlate(vehicle)
    -- local boxes = exports['sistema_bau']:GetItemsFromStashByPlate(plate, Config.AvailableBoxes)
    -- local boxCount = #boxes
    -- 
    -- Por enquanto, simular com número aleatório de caixas (1-5)
    -- =======================================================================================
    
    local boxCount = math.random(1, 5) -- SIMULAÇÃO: Substituir por contagem real do baú
    
    print("^3[RODZ-PILOTO]^7 SISTEMA EXTERNO: Contar caixas do baú do avião por placa")
    print(string.format("^3[RODZ-PILOTO]^7 Simulando %s caixas entregues", boxCount))
    
    -- Calcular pagamento (R$ 350 a R$ 1.200 por caixa)
    local paymentPerBox = math.random(Config.DeliveryReward.min, Config.DeliveryReward.max)
    local totalPayment = paymentPerBox * boxCount
    
    -- =======================================================================================
    -- SISTEMA EXTERNO: Bate-ponto valida horário e autoriza pagamento
    -- =======================================================================================
    -- AQUI: Sistema de bate-ponto deve validar se o jogador está em horário de trabalho
    -- Exemplo (pseudocódigo):
    -- local isOnDuty = exports['sistema_bateponto']:IsPlayerOnDuty(src)
    -- if not isOnDuty then
    --     totalPayment = 0
    --     TriggerClientEvent('rodz-piloto:client:notify', src, {
    --         title = 'Aeroporto',
    --         description = 'Você não está em horário de trabalho!',
    --         type = 'error'
    --     })
    --     return
    -- end
    -- =======================================================================================
    
    print("^3[RODZ-PILOTO]^7 SISTEMA EXTERNO: Bate-ponto valida horário e autoriza pagamento")
    
    -- Adicionar dinheiro ao jogador
    player.Functions.AddMoney('cash', totalPayment, 'pilot-delivery-payment')
    
    -- Limpar rota
    activeRoutes[citizenid] = nil
    
    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:deliveryCompleted', src, totalPayment)
    
    -- Log
    print(string.format("^2[RODZ-PILOTO]^7 Player %s completed delivery: %s boxes | R$ %s", src, boxCount, totalPayment))
    
    -- =======================================================================================
    -- SISTEMA EXTERNO: Limpar baú do avião após entrega
    -- =======================================================================================
    -- AQUI: Remover caixas do baú do avião após contagem
    -- Exemplo (pseudocódigo):
    -- exports['sistema_bau']:ClearStashByPlate(plate)
    -- =======================================================================================
    
    print("^3[RODZ-PILOTO]^7 SISTEMA EXTERNO: Limpar caixas do baú do avião após entrega")
end)

-- =======================================================================================
-- CALLBACK: OBTER ESTADO DA MISSÃO
-- =======================================================================================
lib.callback.register('rodz-piloto:server:getMissionState', function(source)
    local player = GetPlayer(source)
    if not player then return nil end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then return nil end
    
    -- Normalizar campos numéricos com valores padrão para prevenir erros no cliente
    return {
        destination = mission.destination,
        boxesRequired = mission.boxesRequired or 0,
        boxesCollected = mission.boxesCollected or 0,
        boxesLoaded = mission.boxesLoaded or 0,
        boxesDelivered = mission.boxesDelivered or 0,
        phase = mission.phase or "unknown",
        planeNetId = mission.planeNetId
    }
end)

-- =======================================================================================
-- CALLBACK: VERIFICAR SE AVIÃO ESTÁ REGISTRADO
-- =======================================================================================
lib.callback.register('rodz-piloto:server:hasPlaneRegistered', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    return mission and mission.planeNetId ~= nil
end)

-- =======================================================================================
-- EXPORT: VERIFICAR SE TEM MISSÃO ATIVA
-- =======================================================================================
exports('HasActiveMission', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    return activeMissions[player.PlayerData.citizenid] ~= nil
end)

-- =======================================================================================
-- EXPORT: VERIFICAR SE TEM ROTA ATIVA (COMPATIBILIDADE)
-- =======================================================================================
exports('HasActiveRoute', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    return activeMissions[player.PlayerData.citizenid] ~= nil
end)

-- =======================================================================================
-- EXPORT: CANCELAR ROTA
-- =======================================================================================
exports('CancelRoute', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    local citizenid = player.PlayerData.citizenid
    local mission = activeMissions[citizenid]
    
    if not mission then return false end
    
    RemoveVehicleKey(source, mission.plate)
    
    activeMissions[citizenid] = nil
    TriggerClientEvent('rodz-piloto:client:missionCancelled', source)
    
    print(string.format("^3[RODZ-PILOTO]^7 Mission canceled for player %s", source))
    return true
end)

print("^2[RODZ-PILOTO]^7 Server delivery initialized successfully")
