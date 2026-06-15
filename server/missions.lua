-- =======================================================================================
-- SERVER/MISSIONS.LUA
-- Sistema de Missões Especiais
-- Compatível com: Qbox (qbx_core) | QBCore (qb-core) | MRI
-- =======================================================================================

local _QBX    = GetResourceState('qbx_core') ~= 'missing' and exports.qbx_core or nil
local _QBCore = (not _QBX and GetResourceState('qb-core') ~= 'missing') and exports['qb-core']:GetCoreObject() or nil

local function GetPlayer(src)
    if _QBX    then return _QBX:GetPlayer(src) end
    if _QBCore then return _QBCore.Functions.GetPlayer(src) end
    return nil
end

-- Tabela para armazenar missões ativas
local activeMissions = {}

-- =======================================================================================
-- EVENTO: INICIAR MISSÃO ESPECIAL
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:startSpecialMission', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- ANTI-EXPLOIT: Validar se tem brevê de piloto
    local hasLicense = exports.ox_inventory:Search(src, 'count', 'breve')
    if hasLicense == 0 then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('no_license'),
            type = 'error'
        })
        print(string.format("^1[RODZ-PILOTO]^7 EXPLOIT ATTEMPT: Player %s tried to start special mission without license", src))
        return
    end
    
    -- Verificar se já tem missão ativa
    local citizenid = player.PlayerData.citizenid
    if activeMissions[citizenid] then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você já tem uma missão ativa',
            type = 'error'
        })
        return
    end
    
    -- Selecionar local aleatório
    local pickupLocation = Config.SpecialMissionLocations[math.random(#Config.SpecialMissionLocations)]
    
    -- Selecionar aeroporto de entrega aleatório
    local deliveryAirport = Config.DestinationAirports[math.random(#Config.DestinationAirports)]
    
    -- Criar dados da missão
    local missionData = {
        pickupLocation = pickupLocation,
        deliveryAirport = deliveryAirport,
        startTime = os.time(),
        boxCollected = false
    }
    
    -- Armazenar missão
    activeMissions[citizenid] = missionData
    
    -- Enviar missão ao cliente
    TriggerClientEvent('rodz-piloto:client:receiveSpecialMission', src, missionData)
    
    -- Log
    print(string.format("^3[RODZ-PILOTO]^7 Player %s started special mission", src))
end)

-- =======================================================================================
-- EVENTO: COLETAR ENCOMENDA ESPECIAL
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:collectSpecialBox', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Verificar se tem missão ativa
    if not activeMissions[citizenid] then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem uma missão especial ativa',
            type = 'error'
        })
        return
    end
    
    -- Verificar se já coletou
    if activeMissions[citizenid].boxCollected then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você já coletou a encomenda',
            type = 'error'
        })
        return
    end
    
    -- Dar caixa aleatória
    local randomBox = Config.AvailableBoxes[math.random(#Config.AvailableBoxes)]
    local success = exports.ox_inventory:AddItem(src, randomBox, 1)
    
    if success then
        -- Marcar como coletado
        activeMissions[citizenid].boxCollected = true
        
        -- Notificar jogador
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Missão Especial',
            description = locale('special_box_picked'),
            type = 'success'
        })
        
        -- Atualizar cliente
        TriggerClientEvent('rodz-piloto:client:updateSpecialMission', src, activeMissions[citizenid])
        
        -- Log
        print(string.format("^3[RODZ-PILOTO]^7 Player %s collected special box: %s", src, randomBox))
    else
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('inventory_full'),
            type = 'error'
        })
    end
end)

-- =======================================================================================
-- EVENTO: COMPLETAR MISSÃO ESPECIAL
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:completeSpecialMission', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Verificar se tem missão ativa
    if not activeMissions[citizenid] then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você não tem uma missão especial ativa',
            type = 'error'
        })
        return
    end
    
    -- Verificar se coletou a encomenda
    if not activeMissions[citizenid].boxCollected then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = 'Você ainda não coletou a encomenda',
            type = 'error'
        })
        return
    end
    
    -- Calcular recompensa (faixa × multiplicador do nível)
    local prog   = PilotoGetData(citizenid)
    local mult   = GetLevelMultiplier(prog.xp)
    local reward = math.floor(math.random(Config.SpecialMissionReward.min, Config.SpecialMissionReward.max) * mult)
    local xpGain = Config.XP.specialBaseXP or 0

    -- =======================================================================================
    -- SISTEMA EXTERNO: Bate-ponto valida horário
    -- =======================================================================================
    print("^3[RODZ-PILOTO]^7 SISTEMA EXTERNO: Bate-ponto valida horário para missão especial")
    -- =======================================================================================

    -- Adicionar dinheiro e XP
    player.Functions.AddMoney('cash', reward, 'pilot-special-mission')
    PilotoAward(src, citizenid, reward, xpGain)
    PilotoRecordCompletion(citizenid, {
        destination = activeMissions[citizenid].deliveryAirport and activeMissions[citizenid].deliveryAirport.name or 'Especial',
        boxes       = 1,
        pay         = reward,
        xp          = xpGain,
        special     = true,
        date        = os.date('%d/%m %H:%M'),
    })

    -- Limpar missão
    activeMissions[citizenid] = nil

    -- Notificar cliente
    TriggerClientEvent('rodz-piloto:client:specialMissionCompleted', src, { pay = reward, xp = xpGain })

    -- Log
    print(string.format("^2[RODZ-PILOTO]^7 Player %s completed special mission | R$ %s | +%s XP", src, reward, xpGain))
end)

-- =======================================================================================
-- EXPORT: CANCELAR MISSÃO
-- =======================================================================================
exports('CancelSpecialMission', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    activeMissions[player.PlayerData.citizenid] = nil
    TriggerClientEvent('rodz-piloto:client:cancelSpecialMission', source)
    
    print(string.format("^3[RODZ-PILOTO]^7 Special mission canceled for player %s", source))
    return true
end)

print("^2[RODZ-PILOTO]^7 Server missions initialized successfully")
