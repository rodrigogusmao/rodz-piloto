-- =======================================================================================
-- CLIENT/NUI.LUA
-- Ponte entre a NUI (tablet) e o jogo. Substitui o antigo menu ox_lib do instrutor.
-- =======================================================================================

local tabletOpen = false

-- Monta o payload completo (perfil do server + missão + se já tem avião) e envia à NUI
local function BuildProfile()
    local profile = lib.callback.await('rodz-piloto:server:getProfile', false)
    if not profile then return nil end
    profile.mission  = lib.callback.await('rodz-piloto:server:getMissionState', false)
    profile.hasPlane = exports['rodz-piloto']:GetCurrentPlane() ~= nil
    return profile
end

-- Abre o tablet
function OpenPilotTablet()
    print("^3[RODZ-PILOTO][DEBUG]^7 OpenPilotTablet chamado, buscando perfil...")
    local profile = BuildProfile()
    if profile and profile.__error then
        print("^1[RODZ-PILOTO][DEBUG]^7 ERRO no server getProfile -> " .. tostring(profile.__error))
        lib.notify({ title = 'Aeroporto', description = 'Erro no servidor (veja F8)', type = 'error' })
        return
    end
    if not profile then
        print("^1[RODZ-PILOTO][DEBUG]^7 getProfile retornou NIL (callback do server falhou ou nao registrado)")
        -- Auto-diagnóstico: testa um callback trivial para saber se o progression.lua carregou
        local pong = lib.callback.await('rodz-piloto:server:ping', false)
        if pong == true then
            print("^3[RODZ-PILOTO][DEBUG]^7 PING OK -> progression.lua CARREGADO. O erro esta no getProfile (veja o console do SERVIDOR a linha 'ERRO em getProfile').")
        else
            print("^1[RODZ-PILOTO][DEBUG]^7 PING FALHOU -> progression.lua NAO carregou (erro de boot). Veja o console do SERVIDOR no momento do restart.")
        end
        lib.notify({ title = 'Aeroporto', description = 'Erro ao carregar seu perfil.', type = 'error' })
        return
    end
    print(("^2[RODZ-PILOTO][DEBUG]^7 perfil OK (nivel=%s, xp=%s). Abrindo NUI..."):format(tostring(profile.level), tostring(profile.xp)))
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', profile = profile })
end

-- Atualiza o tablet (se estiver aberto) após uma ação
function RefreshPilotTablet()
    if not tabletOpen then return end
    local profile = BuildProfile()
    if profile then
        SendNUIMessage({ action = 'updateProfile', profile = profile })
    end
end

-- Evento para abrir (chamado pelo target do NPC)
RegisterNetEvent('rodz-piloto:client:openTablet', function()
    OpenPilotTablet()
end)

-- =======================================================================================
-- CALLBACKS DA NUI
-- =======================================================================================
RegisterNUICallback('closeTablet', function(_, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyLicense', function(_, cb)
    TriggerServerEvent('rodz-piloto:server:buyLicense')
    SetTimeout(400, RefreshPilotTablet)
    cb('ok')
end)

RegisterNUICallback('buyParachute', function(_, cb)
    TriggerServerEvent('rodz-piloto:server:buyParachute')
    SetTimeout(400, RefreshPilotTablet)
    cb('ok')
end)

RegisterNUICallback('startRoute', function(data, cb)
    TriggerServerEvent('rodz-piloto:server:generateRoute', {
        destinationIndex = data and data.destinationIndex or nil,
        planeModel       = data and data.planeModel or nil,
    })
    cb('ok')
end)

RegisterNUICallback('startClandestine', function(data, cb)
    TriggerServerEvent('rodz-piloto:server:generateClandestineRoute', {
        planeModel = data and data.planeModel or nil,
    })
    cb('ok')
end)

RegisterNUICallback('startSpecial', function(_, cb)
    TriggerServerEvent('rodz-piloto:server:startSpecialMission')
    cb('ok')
end)

RegisterNUICallback('returnPlane', function(_, cb)
    TriggerServerEvent('rodz-piloto:server:returnPlane')
    DeleteWorkPlane()
    lib.notify({ title = 'Aeroporto', description = locale('plane_returned'), type = 'success' })
    SetTimeout(400, RefreshPilotTablet)
    cb('ok')
end)

RegisterNUICallback('cancelMission', function(_, cb)
    TriggerServerEvent('rodz-piloto:server:cancelMission')
    SetTimeout(400, RefreshPilotTablet)
    cb('ok')
end)

-- =======================================================================================
-- LEVEL UP (aviso vindo do server)
-- =======================================================================================
RegisterNetEvent('rodz-piloto:client:levelUp', function(data)
    lib.notify({
        title = 'Subiu de Nível!',
        description = ('Agora você é %s (Nível %d) · multiplicador x%.2f'):format(data.label, data.level, data.multiplier),
        type = 'success',
        duration = 8000
    })
    RefreshPilotTablet()
end)

-- Fecha a NUI ao parar o recurso (libera o foco)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)

print("^2[RODZ-PILOTO]^7 NUI bridge initialized successfully")
