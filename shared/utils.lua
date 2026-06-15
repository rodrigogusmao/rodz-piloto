-- =======================================================================================
-- SHARED/UTILS.LUA
-- Funções de progressão (nível/XP) compartilhadas entre client e server
-- =======================================================================================

-- Nível do jogador a partir do XP acumulado
function GetPlayerLevel(xp)
    xp = xp or 0
    local level = 1
    for l = #Config.Levels, 1, -1 do
        if xp >= Config.Levels[l].xp then
            level = l
            break
        end
    end
    return level
end

-- Progresso percentual (0-100) dentro do nível atual
function GetXPProgress(xp)
    xp = xp or 0
    local level = GetPlayerLevel(xp)
    if level >= #Config.Levels then return 100 end
    local cur  = Config.Levels[level].xp
    local nxt  = Config.Levels[level + 1].xp
    if nxt <= cur then return 100 end
    return math.floor(((xp - cur) / (nxt - cur)) * 100)
end

-- Quanto de XP falta para o próximo nível (0 se nível máximo)
function GetXPToNextLevel(xp)
    xp = xp or 0
    local level = GetPlayerLevel(xp)
    if level >= #Config.Levels then return 0 end
    return Config.Levels[level + 1].xp - xp
end

-- XP de início do próximo nível (para a UI)
function GetNextLevelXP(xp)
    xp = xp or 0
    local level = GetPlayerLevel(xp)
    if level >= #Config.Levels then return Config.Levels[level].xp end
    return Config.Levels[level + 1].xp
end

-- Multiplicador de pagamento do nível atual
function GetLevelMultiplier(xp)
    return Config.Levels[GetPlayerLevel(xp)].multiplier
end

-- Lista de destinos liberados pelo nível (com flag locked para a UI)
function GetDestinationsForLevel(level)
    local list = {}
    for i, dest in ipairs(Config.DestinationAirports) do
        list[#list + 1] = {
            index    = i,
            name     = dest.name,
            minLevel = dest.minLevel or 1,
            payMin   = dest.payMin or (Config.DeliveryReward and Config.DeliveryReward.min) or 0,
            payMax   = dest.payMax or (Config.DeliveryReward and Config.DeliveryReward.max) or 0,
            baseXP   = dest.baseXP or 0,
            locked   = level < (dest.minLevel or 1),
        }
    end
    return list
end

-- Lista de aeronaves liberadas pelo nível (com flag locked para a UI)
function GetPlanesForLevel(level)
    local list = {}
    for i, plane in ipairs(Config.Planes) do
        list[#list + 1] = {
            index    = i,
            model    = plane.model,
            label    = plane.label,
            minLevel = plane.minLevel or 1,
            speed    = plane.speed or '',
            desc     = plane.desc or '',
            image    = plane.image or '',
            locked   = level < (plane.minLevel or 1),
        }
    end
    return list
end

-- Formata valor como moeda brasileira (R$ 1.234)
function FormatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)
    local formatted = tostring(amount):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
    return "R$ " .. formatted
end
