-- =======================================================================================
-- SERVER/MAIN.LUA
-- Lógica principal server-side (Compras, Callbacks, Validações)
-- Compatível com: Qbox (qbx_core) | QBCore (qb-core) | MRI
-- =======================================================================================

local _QBX    = GetResourceState('qbx_core') ~= 'missing' and exports.qbx_core or nil
local _QBCore = (not _QBX and GetResourceState('qb-core') ~= 'missing') and exports['qb-core']:GetCoreObject() or nil

local function GetPlayer(src)
    if _QBX    then return _QBX:GetPlayer(src) end
    if _QBCore then return _QBCore.Functions.GetPlayer(src) end
    return nil
end

-- Tabela para armazenar pilotos com brevê
local pilotsWithLicense = {}

-- =======================================================================================
-- CALLBACK: VERIFICAR SE TEM BREVÊ
-- =======================================================================================
lib.callback.register('rodz-piloto:server:hasLicense', function(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    local citizenid = player.PlayerData.citizenid
    
    -- Verificar se tem o item
    local hasItem = exports.ox_inventory:Search(source, 'count', 'breve')
    
    -- Atualizar cache
    if hasItem > 0 then
        pilotsWithLicense[citizenid] = true
        return true
    end
    
    return pilotsWithLicense[citizenid] or false
end)

-- =======================================================================================
-- EVENTO: COMPRAR BREVÊ DE PILOTO
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:buyLicense', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- Verificar se já possui o brevê
    local hasLicense = exports.ox_inventory:Search(src, 'count', 'breve')
    if hasLicense > 0 then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('license_already_owned'),
            type = 'error'
        })
        return
    end
    
    -- Verificar se tem dinheiro
    local money = player.PlayerData.money.cash or 0
    
    if money < Config.LicensePrice then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('no_money', Config.LicensePrice),
            type = 'error'
        })
        return
    end
    
    -- Remover dinheiro
    player.Functions.RemoveMoney('cash', Config.LicensePrice, 'pilot-license-purchase')
    
    -- Adicionar brevê ao inventário
    local success = exports.ox_inventory:AddItem(src, 'breve', 1)
    
    if success then
        -- Atualizar cache
        pilotsWithLicense[player.PlayerData.citizenid] = true
        
        -- Notificar jogador
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('license_purchased'),
            type = 'success'
        })
        
        -- Log
        print(string.format("^3[RODZ-PILOTO]^7 Player %s purchased pilot license (R$ %s)", src, Config.LicensePrice))
    else
        -- Devolver dinheiro se falhar
        player.Functions.AddMoney('cash', Config.LicensePrice, 'pilot-license-refund')
        
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('inventory_full'),
            type = 'error'
        })
    end
end)

-- =======================================================================================
-- EVENTO: COMPRAR PARAQUEDAS
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:buyParachute', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- Verificar se tem dinheiro
    local money = player.PlayerData.money.cash or 0
    
    if money < Config.ParachutePrice then
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('no_money', Config.ParachutePrice),
            type = 'error'
        })
        return
    end
    
    -- Remover dinheiro
    player.Functions.RemoveMoney('cash', Config.ParachutePrice, 'parachute-purchase')
    
    -- Adicionar paraquedas ao inventário
    local success = exports.ox_inventory:AddItem(src, 'parachute', 1)
    
    if success then
        -- Notificar jogador
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('parachute_purchased'),
            type = 'success'
        })
        
        -- Log
        print(string.format("^3[RODZ-PILOTO]^7 Player %s purchased parachute (R$ %s)", src, Config.ParachutePrice))
    else
        -- Devolver dinheiro se falhar
        player.Functions.AddMoney('cash', Config.ParachutePrice, 'parachute-refund')
        
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('inventory_full'),
            type = 'error'
        })
    end
end)

-- =======================================================================================
-- EVENTO: DAR CAIXA ALEATÓRIA AO JOGADOR
-- =======================================================================================
RegisterNetEvent('rodz-piloto:server:giveRandomBox', function()
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    -- Selecionar caixa aleatória
    local randomBox = Config.AvailableBoxes[math.random(#Config.AvailableBoxes)]
    
    -- Adicionar caixa ao inventário
    local success = exports.ox_inventory:AddItem(src, randomBox, 1)
    
    if success then
        -- Notificar jogador
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('box_picked', randomBox),
            type = 'success'
        })
        
        -- Log
        print(string.format("^3[RODZ-PILOTO]^7 Player %s picked up box: %s", src, randomBox))
        
        -- =======================================================================================
        -- SISTEMA EXTERNO: Armazenar caixa no baú do avião por placa
        -- =======================================================================================
        -- AQUI: Chamar sistema de baú por placa do servidor
        -- Exemplo (pseudocódigo):
        -- local vehicle = GetPlayerVehicle(src)
        -- local plate = GetVehiclePlate(vehicle)
        -- exports['sistema_bau']:OpenStashByPlate(src, plate)
        -- 
        -- Jogador deve guardar a caixa manualmente no baú do avião
        -- =======================================================================================
        
        print("^3[RODZ-PILOTO]^7 SISTEMA EXTERNO: Jogador deve guardar caixa no baú do avião por placa")
    else
        TriggerClientEvent('rodz-piloto:client:notify', src, {
            title = 'Aeroporto',
            description = locale('inventory_full'),
            type = 'error'
        })
    end
end)

-- Chave e remoção do avião são gerenciadas por server/delivery.lua

print("^2[RODZ-PILOTO]^7 Server main initialized successfully")
