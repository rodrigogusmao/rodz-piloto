-- =======================================================================================
-- CLIENT/MAIN.LUA
-- Funções principais do lado client (Interação com NPC, Menus, Compras)
-- =======================================================================================

-- =======================================================================================
-- MENU PRINCIPAL DO INSTRUTOR DE VOO
-- =======================================================================================
function OpenInstructorMenu()
    local hasLicense = lib.callback.await('rodz-piloto:server:hasLicense', false)
    local hasMission = lib.callback.await('rodz-piloto:server:getMissionState', false)
    local hasPlane   = exports['rodz-piloto']:GetCurrentPlane() ~= nil

    local options = {}

    -- Comprar Brevê (se não tiver)
    if not hasLicense then
        table.insert(options, {
            title = locale('buy_license'),
            description = 'Autoriza pilotagem de aeronaves',
            icon = 'id-card',
            onSelect = function()
                BuyLicense()
            end
        })
    end

    -- Comprar Paraquedas
    table.insert(options, {
        title = locale('buy_parachute'),
        description = 'Paraquedas para saltos de emergência',
        icon = 'parachute-box',
        onSelect = function()
            BuyParachute()
        end
    })

    -- Cancelar missão ativa (qualquer jogador, com ou sem brevê)
    if hasMission and hasMission.phase ~= "completed" then
        table.insert(options, {
            title = 'Cancelar Missão Atual',
            description = string.format('Caixas entregues: %s/%s', hasMission.boxesDelivered, hasMission.boxesRequired),
            icon = 'xmark-circle',
            iconColor = 'red',
            onSelect = function()
                OpenCancelConfirmMenu()
            end
        })
    end

    -- Opções com brevê (sem missão ativa ou missão completa)
    if hasLicense then
        if hasPlane or (hasMission and hasMission.phase == "completed") then
            table.insert(options, {
                title = locale('return_plane'),
                description = 'Devolver o avião ao aeroporto',
                icon = 'plane-slash',
                iconColor = 'red',
                onSelect = function()
                    ReturnPlane()
                end
            })
            table.insert(options, {
                title = locale('continue_routes'),
                description = 'Iniciar nova rota com o mesmo avião',
                icon = 'plane-departure',
                iconColor = 'green',
                onSelect = function()
                    ContinueWithSamePlane()
                end
            })
        elseif not hasMission then
            table.insert(options, {
                title = locale('start_route'),
                description = 'Iniciar entrega aérea de caixas',
                icon = 'plane-departure',
                onSelect = function()
                    TriggerEvent('rodz-piloto:client:startRoute')
                end
            })
            table.insert(options, {
                title = locale('special_mission'),
                description = 'Buscar encomenda em local específico',
                icon = 'box',
                onSelect = function()
                    TriggerServerEvent('rodz-piloto:server:startSpecialMission')
                end
            })
        end
    end

    -- Rota Clandestina (sem brevê — disponível quando não há missão ativa)
    if not hasMission then
        table.insert(options, {
            title = locale('start_clandestine_route'),
            description = 'Entrega sem brevê — sem proteção legal',
            icon = 'skull',
            iconColor = 'orange',
            onSelect = function()
                TriggerServerEvent('rodz-piloto:server:generateClandestineRoute')
            end
        })
    end

    -- Cancelar
    table.insert(options, {
        title = locale('cancel'),
        icon = 'xmark',
    })
    
    -- Registrar e mostrar menu
    lib.registerContext({
        id = 'rodz-piloto_instructor_menu',
        title = locale('npc_menu_title'),
        options = options
    })
    
    lib.showContext('rodz-piloto_instructor_menu')
end

-- Evento para abrir menu
RegisterNetEvent('rodz-piloto:client:openInstructorMenu', function()
    OpenInstructorMenu()
end)

-- =======================================================================================
-- COMPRAR BREVÊ DE PILOTO
-- =======================================================================================
function BuyLicense()
    if lib.progressCircle({
        duration = 3000,
        label = 'Comprando Brevê de Piloto...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        },
    }) then
        TriggerServerEvent('rodz-piloto:server:buyLicense')
    end
end

-- =======================================================================================
-- COMPRAR PARAQUEDAS
-- =======================================================================================
function BuyParachute()
    if lib.progressCircle({
        duration = 2000,
        label = 'Comprando Paraquedas...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        },
    }) then
        TriggerServerEvent('rodz-piloto:server:buyParachute')
    end
end

-- =======================================================================================
-- MENU DE CONFIRMAÇÃO DE CANCELAMENTO
-- =======================================================================================
function OpenCancelConfirmMenu()
    lib.registerContext({
        id = 'rodz-piloto_cancel_confirm',
        title = 'Cancelar Missão?',
        options = {
            {
                title = 'Sim, cancelar missão',
                description = 'Você perderá todo o progresso atual',
                icon = 'check',
                iconColor = 'red',
                onSelect = function()
                    TriggerServerEvent('rodz-piloto:server:cancelMission')
                end
            },
            {
                title = 'Não, voltar',
                icon = 'arrow-left',
                onSelect = function()
                    OpenInstructorMenu()
                end
            }
        }
    })
    
    lib.showContext('rodz-piloto_cancel_confirm')
end

-- =======================================================================================
-- PEGAR CAIXA NA ZONA DE COLETA
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:pickupBox', function()
    if exports['rodz-piloto']:IsCarryingBox() then
        lib.notify({
            title = 'Aeroporto',
            description = 'Você já está carregando uma caixa',
            type = 'error'
        })
        return
    end
    
    -- VERIFICAÇÃO DEFENSIVA: Checar se quota de caixas foi atingida
    -- Verificar se tem avião primeiro
    local hasPlane = lib.callback.await('rodz-piloto:server:hasPlaneRegistered', false)
    
    if hasPlane then
        -- Se tem avião, DEVE ter estado de missão. Se não tiver, bloquear por segurança.
        local mission = lib.callback.await('rodz-piloto:server:getMissionState', false)
        
        if not mission then
            lib.notify({
                title = 'Aeroporto',
                description = 'Erro ao verificar estado da missão. Tente novamente.',
                type = 'error'
            })
            return
        end
        
        local boxesLoaded = tonumber(mission.boxesLoaded) or 0
        local boxesRequired = tonumber(mission.boxesRequired) or 0
        
        if boxesRequired > 0 and boxesLoaded >= boxesRequired then
            lib.notify({
                title = 'Aeroporto',
                description = 'Todas as caixas já foram carregadas no avião',
                type = 'error'
            })
            return
        end
    end
    
    if lib.progressCircle({
        duration = 3000,
        label = 'Pegando caixa...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = Config.Animations.pickupBox
    }) then
        exports['rodz-piloto']:AttachBoxProp()
        
        lib.requestAnimDict(Config.Animations.carryBox.dict)
        TaskPlayAnim(PlayerPedId(), Config.Animations.carryBox.dict, Config.Animations.carryBox.anim, 8.0, 8.0, -1, Config.Animations.carryBox.flag, 0, false, false, false)
        
        TriggerServerEvent('rodz-piloto:server:collectBox')
    end
end)

-- =======================================================================================
-- EVENTO: CAIXA COLETADA
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:boxCollected', function(data)
    lib.notify({
        title = 'Caixa Coletada',
        description = string.format('Caixas coletadas: %s/%s', data.boxesCollected, data.boxesRequired),
        type = 'success'
    })
end)

-- =======================================================================================
-- DEVOLVER AVIÃO
-- =======================================================================================
function ReturnPlane()
    if lib.progressCircle({
        duration = 3000,
        label = 'Devolvendo avião...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        },
    }) then
        -- Notificar servidor para remover chave e limpar missão
        TriggerServerEvent('rodz-piloto:server:returnPlane')
        
        -- Deletar avião localmente
        exports['rodz-piloto']:DeleteWorkPlane()
        
        lib.notify({
            title = 'Aeroporto',
            description = locale('plane_returned'),
            type = 'success'
        })
    end
end

-- =======================================================================================
-- CONTINUAR COM O MESMO AVIÃO (NOVA ROTA)
-- =======================================================================================
function ContinueWithSamePlane()
    if lib.progressCircle({
        duration = 2000,
        label = 'Iniciando nova rota...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        },
    }) then
        -- Usar evento específico para continuar com mesmo avião (NÃO spawna novo)
        TriggerServerEvent('rodz-piloto:server:continueWithSamePlane')
        
        lib.notify({
            title = 'Aeroporto',
            description = locale('new_route_started'),
            type = 'success'
        })
    end
end

-- =======================================================================================
-- SISTEMA DE NOTIFICAÇÕES
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:notify', function(data)
    lib.notify(data)
end)

print("^2[RODZ-PILOTO]^7 Client main initialized successfully")
