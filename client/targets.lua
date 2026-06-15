-- =======================================================================================
-- CLIENT/TARGETS.LUA
-- Sistema de NPCs e Targets (ox_target)
-- =======================================================================================

-- Variável global para armazenar referência do NPC
local instructorNPC = nil

-- =======================================================================================
-- COMANDO DE DEBUG - TELEPORTE PARA O AEROPORTO
-- =======================================================================================
RegisterCommand('pilot_debug', function()
    local ped = PlayerPedId()
    
    print("^3[RODZ-PILOTO]^7 ==========================================")
    print("^3[RODZ-PILOTO]^7 Coordenadas do Config:")
    print("^3[RODZ-PILOTO]^7 NPC Instrutor:", Config.InstructorNPC.coords)
    print("^3[RODZ-PILOTO]^7 Coleta de Caixas:", Config.BoxPickupZone.coords)
    print("^3[RODZ-PILOTO]^7 ==========================================")
    
    SetEntityCoords(ped, Config.InstructorNPC.coords.x, Config.InstructorNPC.coords.y, Config.InstructorNPC.coords.z)
    lib.notify({
        title = 'Debug',
        description = 'Teleportado para o Aeroporto',
        type = 'info'
    })
end)

-- =======================================================================================
-- NPC INSTRUTOR DE VOO
-- =======================================================================================
CreateThread(function()
    Wait(1000)
    
    print("^3[RODZ-PILOTO]^7 Criando NPC Instrutor de Voo...")
    
    -- Solicitar modelo do NPC
    lib.requestModel(Config.InstructorNPC.model, 5000)
    
    -- Criar NPC
    instructorNPC = CreatePed(
        4, 
        GetHashKey(Config.InstructorNPC.model), 
        Config.InstructorNPC.coords.x, 
        Config.InstructorNPC.coords.y, 
        Config.InstructorNPC.coords.z - 1.0, 
        Config.InstructorNPC.heading, 
        false, 
        true
    )
    
    -- Configurar NPC
    SetEntityInvincible(instructorNPC, true)
    FreezeEntityPosition(instructorNPC, true)
    SetBlockingOfNonTemporaryEvents(instructorNPC, true)
    
    -- Adicionar target ao NPC
        exports.ox_target:addLocalEntity(instructorNPC, {
        {
            name = 'rodz-piloto_instructor_npc',
            icon = 'fa-solid fa-plane',
            label = locale('npc_label'),
            distance = 2.5,
            canInteract = function()
                return true
            end,
            onSelect = function()
                TriggerEvent('rodz-piloto:client:openTablet')
            end
        }
    })
    
    print("^2[RODZ-PILOTO]^7 ✅ NPC Instrutor de Voo criado!")
    print("^3[RODZ-PILOTO]^7 NPC spawned at:", Config.InstructorNPC.coords)
end)

-- =======================================================================================
-- BLIP DO INSTRUTOR DE VOO
-- =======================================================================================
CreateThread(function()
    local blip = AddBlipForCoord(Config.InstructorNPC.coords.x, Config.InstructorNPC.coords.y, Config.InstructorNPC.coords.z)
    SetBlipSprite(blip, Config.Blips.instructor.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blips.instructor.scale)
    SetBlipColour(blip, Config.Blips.instructor.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.instructor.label)
    EndTextCommandSetBlipName(blip)
end)

-- =======================================================================================
-- ÁREA DE COLETA DE CAIXAS
-- =======================================================================================
CreateThread(function()
    Wait(1500)
    
    print("^3[RODZ-PILOTO]^7 Criando zona de coleta de caixas...")
    
    -- Adicionar BoxZone para coleta de caixas
    exports.ox_target:addBoxZone({
        coords = Config.BoxPickupZone.coords,
        size = vec3(3, 3, 2),
        rotation = Config.BoxPickupZone.heading,
        debug = Config.Debug,
        options = {
            {
                    name = 'rodz-piloto_pickup_box',
                icon = 'fa-solid fa-box',
                label = locale('pickup_box_label'),
                distance = 2.5,
                    canInteract = function()
                        local hasPlane = lib.callback.await('rodz-piloto:server:hasPlaneRegistered', false)
                    if not hasPlane then
                        return false
                    end
                    
                    if exports['rodz-piloto']:IsCarryingBox() then
                        return false
                    end
                    
                    -- CRÍTICO: Verificar se quota de caixas foi atingida
                    -- Se tem avião mas não conseguiu obter estado, bloquear por segurança
                    if hasPlane then
                        local mission = lib.callback.await('rodz-piloto:server:getMissionState', false)
                        
                        if not mission then
                            -- Não conseguiu obter estado da missão - bloquear por segurança
                            return false
                        end
                        
                        local boxesLoaded = tonumber(mission.boxesLoaded) or 0
                        local boxesRequired = tonumber(mission.boxesRequired) or 0
                        
                        if boxesRequired > 0 and boxesLoaded >= boxesRequired then
                            return false
                        end
                    end
                    
                    return true
                end,
                    onSelect = function()
                        TriggerEvent('rodz-piloto:client:pickupBox')
                    end
            }
        }
    })
    
    print("^2[RODZ-PILOTO]^7 ✅ Zona de coleta de caixas criada!")
end)

-- Blip da área de coleta é criado dinamicamente em delivery.lua quando a missão começa

-- =======================================================================================
-- EXPORT PARA ACESSAR NPC DE OUTROS ARQUIVOS
-- =======================================================================================
exports('GetInstructorNPC', function()
    return instructorNPC
end)

    print("^2[RODZ-PILOTO]^7 Targets system initialized successfully")
