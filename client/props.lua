-- =======================================================================================
-- CLIENT/PROPS.LUA
-- Sistema de Props (Caixas na mão do jogador)
-- =======================================================================================

local currentProp = nil
local isCarryingBox = false
local animationThread = nil

-- =======================================================================================
-- THREAD: MANTER ANIMAÇÃO ATIVA (previne perda ao colidir)
-- =======================================================================================
local function KeepAnimationActive()
    if animationThread then return end
    
    animationThread = CreateThread(function()
        local ped = PlayerPedId()
        
        -- Carregar animação
        lib.requestAnimDict(Config.Animations.carryBox.dict)
        
        while isCarryingBox do
            Wait(1000)

            if not isCarryingBox then break end

            ped = PlayerPedId()

            if not IsEntityPlayingAnim(ped, Config.Animations.carryBox.dict, Config.Animations.carryBox.anim, 3) then
                TaskPlayAnim(
                    ped,
                    Config.Animations.carryBox.dict,
                    Config.Animations.carryBox.anim,
                    8.0, 8.0, -1,
                    Config.Animations.carryBox.flag,
                    0, false, false, false
                )
            end
        end
        
        animationThread = nil
    end)
end

-- =======================================================================================
-- ANEXAR PROP DE CAIXA AO JOGADOR
-- =======================================================================================
function AttachBoxProp()
    -- Verificar se já está carregando
    if isCarryingBox then
        return false
    end
    
    local ped = PlayerPedId()
    
    -- Carregar modelo do prop
    lib.requestModel(Config.BoxProp.model, 5000)
    
    -- Criar prop
    currentProp = CreateObject(
        GetHashKey(Config.BoxProp.model),
        0.0, 0.0, 0.0,
        true, true, false
    )
    
    -- Anexar ao jogador
    AttachEntityToEntity(
        currentProp,
        ped,
        GetPedBoneIndex(ped, Config.BoxProp.bone),
        Config.BoxProp.offset.x,
        Config.BoxProp.offset.y,
        Config.BoxProp.offset.z,
        Config.BoxProp.rotation.x,
        Config.BoxProp.rotation.y,
        Config.BoxProp.rotation.z,
        true, true, false, true, 2, true
    )
    
    isCarryingBox = true
    
    -- Iniciar thread de manutenção de animação
    KeepAnimationActive()
    
    print("^2[RODZ-PILOTO]^7 Box prop attached to player")
    return true
end

-- =======================================================================================
-- REMOVER PROP DE CAIXA
-- =======================================================================================
function DetachBoxProp()
    -- Parar a thread de animação
    isCarryingBox = false
    Wait(100)  -- Aguardar thread parar
    
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
        currentProp = nil
        print("^2[RODZ-PILOTO]^7 Box prop detached from player")
        
        -- Limpar animação
        ClearPedTasks(PlayerPedId())
        return true
    end
    
    currentProp = nil
    return false
end

-- =======================================================================================
-- VERIFICAR SE ESTÁ CARREGANDO CAIXA
-- =======================================================================================
function IsCarryingBox()
    return isCarryingBox
end

-- =======================================================================================
-- FORÇAR LIMPEZA DE PROPS (em caso de bugs)
-- =======================================================================================
function ForceCleanupProps()
    if currentProp and DoesEntityExist(currentProp) then
        DeleteEntity(currentProp)
    end
    currentProp = nil
    isCarryingBox = false
    ClearPedTasks(PlayerPedId())
end

-- =======================================================================================
-- EVENTO: LIMPAR PROPS AO SAIR DO SERVIDOR
-- =======================================================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    ForceCleanupProps()
end)

-- =======================================================================================
-- EXPORTS
-- =======================================================================================
exports('AttachBoxProp', AttachBoxProp)
exports('DetachBoxProp', DetachBoxProp)
exports('IsCarryingBox', IsCarryingBox)
exports('ForceCleanupProps', ForceCleanupProps)

print("^2[RODZ-PILOTO]^7 Props system initialized successfully")
