-- =======================================================================================
-- CLIENT/MINIGAME.LUA
-- Minigames Opcionais (Decolagem e Pouso)
-- =======================================================================================

-- =======================================================================================
-- MINIGAME DE DECOLAGEM (Sequência de Teclas)
-- =======================================================================================
function TakeoffMinigame()
    if not Config.EnableMinigames then
        return true
    end
    
    lib.notify({
        title = 'Decolagem',
        description = locale('takeoff_minigame_title'),
        type = 'info'
    })
    
    -- Usar lib.skillCheck do ox_lib
    local success = lib.skillCheck({'easy', 'easy', 'medium'}, {'w', 'a', 'd'})
    
    if success then
        lib.notify({
            title = 'Decolagem',
            description = locale('takeoff_success'),
            type = 'success'
        })
        return true
    else
        lib.notify({
            title = 'Decolagem',
            description = locale('takeoff_failed'),
            type = 'error'
        })
        
        -- Delay de 2 segundos se falhar
        Wait(Config.TakeoffMinigame.delay)
        return false
    end
end

-- =======================================================================================
-- MINIGAME DE POUSO (Estabilização)
-- =======================================================================================
function LandingMinigame()
    if not Config.EnableMinigames then
        return true
    end
    
    lib.notify({
        title = 'Pouso',
        description = locale('landing_minigame_title'),
        type = 'info'
    })
    
    -- Usar lib.skillCheck do ox_lib
    local success = lib.skillCheck({'medium', 'medium'}, {'a', 'd'})
    
    if success then
        lib.notify({
            title = 'Pouso',
            description = locale('landing_success'),
            type = 'success'
        })
        return true
    else
        lib.notify({
            title = 'Pouso',
            description = locale('landing_failed'),
            type = 'warning'
        })
        return false
    end
end

-- =======================================================================================
-- MONITORAR DECOLAGEM E POUSO
-- =======================================================================================
local hasDecolagemStarted = false
local hasLandingStarted = false

CreateThread(function()
    while true do
        Wait(1000)
        
        -- Verificar se está em avião de trabalho
        if exports['rodz-piloto']:IsInWorkPlane() then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 then
                local speed = GetEntitySpeed(vehicle) * 3.6 -- Converter para km/h
                local height = GetEntityHeightAboveGround(vehicle)
                
                -- Detectar decolagem (velocidade > 80 km/h e altura > 5m)
                if speed > 80 and height > 5 and not hasDecolagemStarted then
                    hasDecolagemStarted = true
                    TakeoffMinigame()
                end
                
                -- Detectar pouso (altura < 10m após estar no ar)
                if height < 10 and hasDecolagemStarted and not hasLandingStarted then
                    if speed < 150 then -- Só se estiver em velocidade razoável
                        hasLandingStarted = true
                        LandingMinigame()
                    end
                end
                
                -- Reset quando parar no chão
                if height < 2 and speed < 5 then
                    hasDecolagemStarted = false
                    hasLandingStarted = false
                end
            end
        else
            -- Reset se sair do avião
            hasDecolagemStarted = false
            hasLandingStarted = false
        end
    end
end)

-- =======================================================================================
-- EXPORTS
-- =======================================================================================
exports('TakeoffMinigame', TakeoffMinigame)
exports('LandingMinigame', LandingMinigame)

                print("^2[RODZ-PILOTO]^7 Minigame system initialized successfully")
