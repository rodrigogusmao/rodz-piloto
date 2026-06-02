-- =======================================================================================
-- CLIENT/VEHICLE.LUA
-- Sistema de Spawn de Aviões
-- =======================================================================================

local currentPlane = nil
local currentPlaneBlip = nil

-- =======================================================================================
-- SPAWN DE AVIÃO ALEATÓRIO
-- =======================================================================================
function SpawnWorkPlane()
    -- Selecionar avião aleatório da lista
    local randomPlane = Config.AvailablePlanes[math.random(#Config.AvailablePlanes)]
    
    print("^3[RODZ-PILOTO]^7 Spawning plane:", randomPlane)
    
    -- Solicitar modelo
    lib.requestModel(randomPlane, 10000)
    
    -- Criar veículo
    local plane = CreateVehicle(
        GetHashKey(randomPlane),
        Config.PlaneSpawn.coords.x,
        Config.PlaneSpawn.coords.y,
        Config.PlaneSpawn.coords.z,
        Config.PlaneSpawn.heading,
        true,
        false
    )
    
    -- Configurar veículo
    SetVehicleOnGroundProperly(plane)
    SetVehicleEngineOn(plane, false, false, false)
    SetVehicleDoorsLocked(plane, 1) -- Destrancado
    
    -- Obter placa do veículo
    local plate = GetVehicleNumberPlateText(plane)
    local netId = NetworkGetNetworkIdFromEntity(plane)
    
    -- Registrar avião no servidor (isso dará a chave temporária automaticamente)
    TriggerServerEvent('rodz-piloto:server:registerPlane', netId, plate)
    
    -- Armazenar referência
    currentPlane = plane
    
    print(string.format("^2[RODZ-PILOTO]^7 Plane registered: Plate %s, NetID %s", plate, netId))
    
    -- Criar blip para o avião
    CreatePlaneBlip(plane)
    
    -- Notificar jogador
    lib.notify({
        title = 'Aeroporto',
        description = locale('plane_spawned'),
        type = 'success'
    })
    
    return plane
end

-- Evento para spawnar avião
RegisterNetEvent('rodz-piloto:client:spawnPlane', function()
    SpawnWorkPlane()
end)

-- =======================================================================================
-- CRIAR BLIP PARA O AVIÃO
-- =======================================================================================
function CreatePlaneBlip(vehicle)
    -- Remover blip anterior se existir
    if currentPlaneBlip then
        RemoveBlip(currentPlaneBlip)
    end
    
    -- Criar novo blip
    currentPlaneBlip = AddBlipForEntity(vehicle)
    SetBlipSprite(currentPlaneBlip, 423)
    SetBlipColour(currentPlaneBlip, 5)
    SetBlipScale(currentPlaneBlip, 0.6)
    SetBlipAsShortRange(currentPlaneBlip, true) -- só aparece no radar quando próximo
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Avião de Trabalho")
    EndTextCommandSetBlipName(currentPlaneBlip)
end

-- =======================================================================================
-- DELETAR AVIÃO DE TRABALHO
-- =======================================================================================
function DeleteWorkPlane()
    if currentPlane and DoesEntityExist(currentPlane) then
        -- Obter placa antes de deletar
        local plate = GetVehicleNumberPlateText(currentPlane)
        
        -- Remover blip
        if currentPlaneBlip then
            RemoveBlip(currentPlaneBlip)
            currentPlaneBlip = nil
        end
        
        -- ✅ Notificar servidor para remover chave
        TriggerServerEvent('rodz-piloto:server:removePlane', plate)
        
        -- Deletar veículo
        DeleteEntity(currentPlane)
        currentPlane = nil
        
        print("^3[RODZ-PILOTO]^7 Work plane deleted")
    end
end

-- Evento para deletar avião
RegisterNetEvent('rodz-piloto:client:deletePlane', function()
    DeleteWorkPlane()
end)

-- =======================================================================================
-- VERIFICAR SE ESTÁ NO AVIÃO DE TRABALHO
-- =======================================================================================
function IsInWorkPlane()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        return false
    end
    
    return vehicle == currentPlane
end

-- =======================================================================================
-- EXPORT PARA OUTROS ARQUIVOS
-- =======================================================================================
exports('GetCurrentPlane', function()
    return currentPlane
end)

exports('IsInWorkPlane', function()
    return IsInWorkPlane()
end)

-- =======================================================================================
-- MONITORAR DESTRUIÇÃO DO AVIÃO
-- =======================================================================================
CreateThread(function()
    while true do
        Wait(1000)
        
        if currentPlane and DoesEntityExist(currentPlane) then
            -- Verificar se o avião foi destruído
            if GetEntityHealth(currentPlane) <= 0 or IsEntityDead(currentPlane) then
                lib.notify({
                    title = 'Aeroporto',
                    description = locale('plane_destroyed'),
                    type = 'error'
                })
                
                -- Cancelar rota
                TriggerEvent('rodz-piloto:client:cancelRoute')
                
                -- Limpar avião
                DeleteWorkPlane()
            end
        end
    end
end)

-- =======================================================================================
-- LIMPAR AVIÃO AO REINICIAR O SCRIPT
-- =======================================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if currentPlane and DoesEntityExist(currentPlane) then
        DeleteEntity(currentPlane)
        currentPlane = nil
    end
    if currentPlaneBlip then
        RemoveBlip(currentPlaneBlip)
        currentPlaneBlip = nil
    end
end)

print("^2[RODZ-PILOTO]^7 Vehicle system initialized successfully")
