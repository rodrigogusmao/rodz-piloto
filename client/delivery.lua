-- =======================================================================================
-- CLIENT/DELIVERY.LUA
-- Sistema de Rotas e Entregas - Nova Lógica com Props e Múltiplos Pontos
-- =======================================================================================

local currentMission = nil
local destinationBlip = nil
local pickupZoneBlip  = nil
local deliveryBlips = {}
local deliveryTargets = {}
local planePickupTargetId = nil
local planeDepositTargetId = nil

-- =======================================================================================
-- INICIAR ROTA DE ENTREGA
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:startRoute', function()
    if currentMission then
        lib.notify({
            title = 'Aeroporto',
            description = locale('route_active'),
            type = 'error'
        })
        return
    end
    
    local hasLicense = lib.callback.await('rodz-piloto:server:hasLicense', false)
    if not hasLicense then
        lib.notify({
            title = 'Aeroporto',
            description = locale('no_license'),
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('rodz-piloto:server:generateRoute')
end)

-- =======================================================================================
-- RECEBER ROTA DO SERVIDOR
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:receiveRoute', function(routeData)
    currentMission = {
        destination = routeData.destination,
        boxesRequired = routeData.boxesRequired,
        boxesCollected = 0,
        boxesLoaded = 0,
        boxesDelivered = 0,
        deliveryPoints = routeData.deliveryPoints  -- Usar pontos gerados pelo servidor
    }
    
    -- Verificar se já tem avião (para continuar com mesmo avião)
    local hasPlane = exports['rodz-piloto']:GetCurrentPlane() ~= nil
    
    if not hasPlane then
        -- Spawnar novo avião
        SpawnWorkPlane()
        
        -- Aguardar avião spawnar e criar target de depósito
        Wait(1000)
    end
    
    -- Criar ou recriar target de depósito (independente se é avião novo ou não)
    CreatePlaneDepositTarget()

    -- Mostrar blip da zona de coleta (só aparece com missão ativa)
    if pickupZoneBlip then RemoveBlip(pickupZoneBlip) end
    pickupZoneBlip = AddBlipForCoord(Config.BoxPickupZone.coords.x, Config.BoxPickupZone.coords.y, Config.BoxPickupZone.coords.z)
    SetBlipSprite(pickupZoneBlip,  Config.Blips.boxpickup.sprite)
    SetBlipDisplay(pickupZoneBlip, 4)
    SetBlipScale(pickupZoneBlip,   Config.Blips.boxpickup.scale)
    SetBlipColour(pickupZoneBlip,  Config.Blips.boxpickup.color)
    SetBlipAsShortRange(pickupZoneBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.boxpickup.label)
    EndTextCommandSetBlipName(pickupZoneBlip)

    CreateDestinationBlip(routeData.destination)
    
    lib.notify({
        title = 'Aeroporto',
        description = locale('route_started', routeData.destination.name),
        type = 'success'
    })
    
    lib.notify({
        title = 'Missão',
        description = string.format('Colete %s caixas e leve até %s', routeData.boxesRequired, routeData.destination.name),
        type = 'info',
        duration = 8000
    })
    
    MonitorArrival()
end)

-- =======================================================================================
-- CRIAR BLIP DO DESTINO
-- =======================================================================================
function CreateDestinationBlip(destination)
    if destinationBlip then
        RemoveBlip(destinationBlip)
    end
    
    destinationBlip = AddBlipForCoord(destination.planeCoords.x, destination.planeCoords.y, destination.planeCoords.z)
    SetBlipSprite(destinationBlip, 307)
    SetBlipColour(destinationBlip, destination.blipColor or 5)
    SetBlipScale(destinationBlip, 1.0)
    SetBlipRoute(destinationBlip, true)
    SetBlipRouteColour(destinationBlip, destination.blipColor or 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Destino: " .. destination.name)
    EndTextCommandSetBlipName(destinationBlip)
end

-- =======================================================================================
-- MONITORAR CHEGADA AO DESTINO
-- =======================================================================================
function MonitorArrival()
    CreateThread(function()
        while currentMission do
            Wait(2000)
            
            local mission = currentMission
            if not mission or not mission.destination then break end
            
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dest = mission.destination.planeCoords
            local distance = #(coords - dest)
            
            if distance < 300 then
                CreateDeliveryPoints()
                break
            end
        end
    end)
end

-- =======================================================================================
-- CRIAR PONTOS DE ENTREGA
-- =======================================================================================
function CreateDeliveryPoints()
    if not currentMission then return end

    local deliveryPoints = currentMission.deliveryPoints

    if not deliveryPoints or #deliveryPoints == 0 then
        print("^1[RODZ-PILOTO]^7 ERROR: No delivery points received from server")
        return
    end

    -- Remove a rota GPS do destino (jogador já chegou, não precisa mais da linha)
    if destinationBlip then
        SetBlipRoute(destinationBlip, false)
        RemoveBlip(destinationBlip)
        destinationBlip = nil
    end

    -- Remover blip da zona de coleta (caixas já estão no avião)
    if pickupZoneBlip then
        RemoveBlip(pickupZoneBlip)
        pickupZoneBlip = nil
    end

    for i, point in ipairs(deliveryPoints) do
        local blip = AddBlipForCoord(point.x, point.y, point.z)
        SetBlipSprite(blip, 38)       -- círculo pequeno em vez de caixa
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.55)      -- menor que antes
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(string.format("Entrega %s", i))
        EndTextCommandSetBlipName(blip)

        table.insert(deliveryBlips, blip)
        
        local targetId = exports.ox_target:addSphereZone({
            coords = vec3(point.x, point.y, point.z),
            radius = 2.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'rodz-piloto_deliver_box_' .. i,
                    icon = 'fa-solid fa-box-open',
                    label = 'Entregar Caixa',
                    distance = 2.5,
                    canInteract = function()
                        return exports['rodz-piloto']:IsCarryingBox()
                    end,
                    onSelect = function()
                        DeliverBox(i)
                    end
                }
            }
        })
        
        table.insert(deliveryTargets, targetId)
    end
    
    CreatePlanePickupTarget()
    
    lib.notify({
        title = 'Destino Alcançado',
        description = string.format('Saia do avião e pegue as caixas para entregar (%s pontos)', #deliveryPoints),
        type = 'info',
        duration = 7000
    })
end

-- =======================================================================================
-- CRIAR TARGET NO AVIÃO PARA DEPOSITAR CAIXAS (Zona de Coleta)
-- =======================================================================================
function CreatePlaneDepositTarget()
    local plane = exports['rodz-piloto']:GetCurrentPlane()
    if not plane or not DoesEntityExist(plane) then return end
    
    if planeDepositTargetId then
        exports.ox_target:removeLocalEntity(plane, planeDepositTargetId)
    end
    
    planeDepositTargetId = exports.ox_target:addLocalEntity(plane, {
        {
            name = 'rodz-piloto_deposit_in_plane',
            icon = 'fa-solid fa-box-open',
            label = 'Colocar Caixa no Avião',
            distance = 3.0,
            canInteract = function()
                local state = lib.callback.await('rodz-piloto:server:getMissionState', false)
                if not state then return false end
                
                -- Só pode depositar se estiver carregando e ainda precisa de mais caixas
                return exports['rodz-piloto']:IsCarryingBox() and state.boxesLoaded < state.boxesRequired
            end,
            onSelect = function()
                DepositBoxInPlane()
            end
        }
    })
    
    print("^2[RODZ-PILOTO]^7 Plane deposit target created")
end

-- =======================================================================================
-- DEPOSITAR CAIXA NO AVIÃO
-- =======================================================================================
function DepositBoxInPlane()
    if not exports['rodz-piloto']:IsCarryingBox() then
        lib.notify({
            title = 'Aeroporto',
            description = 'Você precisa estar carregando uma caixa',
            type = 'error'
        })
        return
    end
    
    if lib.progressCircle({
        duration = 2000,
        label = 'Depositando caixa no avião...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = Config.Animations.dropBox
    }) then
        -- Limpar animação do progressCircle imediatamente
        ClearPedTasks(PlayerPedId())
        Wait(50)
        
        exports['rodz-piloto']:DetachBoxProp()
        TriggerServerEvent('rodz-piloto:server:depositBox')
    end
end

-- =======================================================================================
-- CRIAR TARGET NO AVIÃO PARA PEGAR CAIXAS (Destino)
-- =======================================================================================
function CreatePlanePickupTarget()
    local plane = exports['rodz-piloto']:GetCurrentPlane()
    if not plane or not DoesEntityExist(plane) then return end
    
    -- Remover target de depósito (não precisa mais)
    if planeDepositTargetId then
        exports.ox_target:removeLocalEntity(plane, planeDepositTargetId)
        planeDepositTargetId = nil
    end
    
    if planePickupTargetId then
        exports.ox_target:removeLocalEntity(plane, planePickupTargetId)
    end
    
    planePickupTargetId = exports.ox_target:addLocalEntity(plane, {
        {
            name = 'rodz-piloto_pickup_from_plane',
            icon = 'fa-solid fa-box',
            label = 'Retirar Caixa do Avião',
            distance = 3.0,
            canInteract = function()
                local state = lib.callback.await('rodz-piloto:server:getMissionState', false)
                if not state then return false end
                
                -- Só pode pegar se não estiver carregando e ainda tiver caixas no avião
                return not exports['rodz-piloto']:IsCarryingBox() and state.boxesLoaded > 0
            end,
            onSelect = function()
                PickupBoxFromPlane()
            end
        }
    })
    
    print("^2[RODZ-PILOTO]^7 Plane pickup target created")
end

-- =======================================================================================
-- PEGAR CAIXA DO AVIÃO
-- =======================================================================================
function PickupBoxFromPlane()
    if exports['rodz-piloto']:IsCarryingBox() then
        lib.notify({
            title = 'Aeroporto',
            description = 'Você já está carregando uma caixa',
            type = 'error'
        })
        return
    end
    
    if lib.progressCircle({
        duration = 2000,
        label = 'Pegando caixa do avião...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = Config.Animations.pickupBox
    }) then
        TriggerServerEvent('rodz-piloto:server:pickupBoxFromPlane')
    end
end

-- =======================================================================================
-- ENTREGAR CAIXA
-- =======================================================================================
function DeliverBox(pointIndex)
    if not exports['rodz-piloto']:IsCarryingBox() then
        lib.notify({
            title = 'Aeroporto',
            description = 'Você precisa estar carregando uma caixa',
            type = 'error'
        })
        return
    end
    
    if lib.progressCircle({
        duration = 3000,
        label = 'Entregando caixa...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
        },
        anim = Config.Animations.dropBox
    }) then
        -- Limpar animação do progressCircle imediatamente
        ClearPedTasks(PlayerPedId())
        Wait(50)
        
        exports['rodz-piloto']:DetachBoxProp()
        TriggerServerEvent('rodz-piloto:server:deliverBox', pointIndex)
    end
end

-- =======================================================================================
-- EVENTO: CAIXA PEGA DO AVIÃO
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:boxPickedFromPlane', function(data)
    exports['rodz-piloto']:AttachBoxProp()
    
    lib.requestAnimDict(Config.Animations.carryBox.dict)
    TaskPlayAnim(PlayerPedId(), Config.Animations.carryBox.dict, Config.Animations.carryBox.anim, 8.0, 8.0, -1, Config.Animations.carryBox.flag, 0, false, false, false)
    
    if currentMission then
        currentMission.boxesLoaded = data.boxesLoaded
    end
end)

-- =======================================================================================
-- EVENTO: CAIXA ENTREGUE
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:boxDelivered', function(data)
    if currentMission then
        currentMission.boxesDelivered = data.boxesDelivered
    end
    
    -- Remover blip do ponto usado
    if data.pointIndex and deliveryBlips[data.pointIndex] then
        RemoveBlip(deliveryBlips[data.pointIndex])
        deliveryBlips[data.pointIndex] = nil
    end
    
    -- Remover target do ponto usado
    if data.pointIndex and deliveryTargets[data.pointIndex] then
        exports.ox_target:removeZone(deliveryTargets[data.pointIndex])
        deliveryTargets[data.pointIndex] = nil
    end
    
    lib.notify({
        title = 'Entrega',
        description = string.format('Caixa entregue! (%s/%s) +R$ %s', data.boxesDelivered, data.boxesRequired, data.payment),
        type = 'success'
    })
end)

-- =======================================================================================
-- EVENTO: MISSÃO COMPLETA
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:missionCompleted', function(payment)
    CancelMission()
    -- NÃO deletar avião - player precisa voltar ao aeroporto
    
    lib.notify({
        title = 'Missão Completa!',
        description = string.format('Todas as caixas entregues! Você recebeu R$ %s', payment),
        type = 'success',
        duration = 8000
    })
    
    -- Notificar para voltar ao aeroporto
    Wait(2000)
    lib.notify({
        title = 'Retornar ao Aeroporto',
        description = 'Volte ao aeroporto para devolver o avião ou pegar mais rotas',
        type = 'info',
        duration = 10000
    })
end)

-- =======================================================================================
-- EVENTO: MISSÃO CANCELADA
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:missionCancelled', function()
    CancelMission()
    DeleteWorkPlane()
    
    lib.notify({
        title = 'Aeroporto',
        description = locale('route_canceled'),
        type = 'info'
    })
end)

-- =======================================================================================
-- CANCELAR MISSÃO (LIMPEZA COMPLETA DE TODOS BLIPS E TARGETS)
-- =======================================================================================
function CancelMission()
    -- Limpar blip da zona de coleta
    if pickupZoneBlip then
        RemoveBlip(pickupZoneBlip)
        pickupZoneBlip = nil
    end

    -- Limpar blip de destino
    if destinationBlip then
        RemoveBlip(destinationBlip)
        destinationBlip = nil
    end
    
    -- Limpar TODOS os blips de entrega (mesmo que alguns sejam nil)
    for i = 1, #deliveryBlips do
        if deliveryBlips[i] then
            RemoveBlip(deliveryBlips[i])
            deliveryBlips[i] = nil
        end
    end
    deliveryBlips = {}
    
    -- Limpar TODOS os targets de entrega (mesmo que alguns sejam nil)
    for i = 1, #deliveryTargets do
        if deliveryTargets[i] then
            pcall(function()
                exports.ox_target:removeZone(deliveryTargets[i])
            end)
            deliveryTargets[i] = nil
        end
    end
    deliveryTargets = {}
    
    -- Limpar targets do avião (pickup e deposit)
    local plane = exports['rodz-piloto']:GetCurrentPlane()
    if plane and DoesEntityExist(plane) then
        if planePickupTargetId then
            pcall(function()
                exports.ox_target:removeLocalEntity(plane, planePickupTargetId)
            end)
            planePickupTargetId = nil
        end
        
        if planeDepositTargetId then
            pcall(function()
                exports.ox_target:removeLocalEntity(plane, planeDepositTargetId)
            end)
            planeDepositTargetId = nil
        end
    end
    
    -- Limpar props e tarefas do jogador
    exports['rodz-piloto']:ForceCleanupProps()
    ClearPedTasks(PlayerPedId())
    
    -- Limpar estado da missão
    currentMission = nil
    
    -- Esconder UI
    lib.hideTextUI()
    
    print("^2[RODZ-PILOTO]^7 Mission cleanup completed (all blips and targets removed)")
end

-- =======================================================================================
-- EXPORT: OBTER MISSÃO ATUAL
-- =======================================================================================
exports('GetCurrentMission', function()
    return currentMission
end)

print("^2[RODZ-PILOTO]^7 Delivery system initialized successfully")
