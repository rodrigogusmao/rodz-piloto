-- =======================================================================================
-- SERVER/PROGRESSION.LUA
-- Sistema de Nível / XP do piloto (persistência em banco)
-- Compatível com: Qbox (qbx_core) | QBCore (qb-core) | MRI
-- Funções globais expostas: PilotoGetData, PilotoSave, PilotoBuildPayload
-- =======================================================================================

local _QBX    = GetResourceState('qbx_core') ~= 'missing' and exports.qbx_core or nil
local _QBCore = (not _QBX and GetResourceState('qb-core') ~= 'missing') and exports['qb-core']:GetCoreObject() or nil

local function GetPlayer(src)
    if _QBX    then return _QBX:GetPlayer(src) end
    if _QBCore then return _QBCore.Functions.GetPlayer(src) end
    return nil
end

-- Cache em memória: citizenid -> { citizenid, xp, level, total_deliveries, total_earned, history = {} }
local cache = {}

-- =======================================================================================
-- BANCO DE DADOS
-- =======================================================================================
local function dbGet(citizenid)
    return MySQL.single.await('SELECT * FROM rodz_piloto_players WHERE citizenid = ?', { citizenid })
end

local function dbCreate(citizenid)
    MySQL.insert.await('INSERT INTO rodz_piloto_players (citizenid) VALUES (?)', { citizenid })
    return { citizenid = citizenid, xp = 0, level = 1, total_deliveries = 0, total_earned = 0, history = '[]' }
end

-- Carrega (ou cria) os dados do piloto para o cache e retorna a tabela mutável
function PilotoGetData(citizenid)
    if not citizenid then return nil end
    if cache[citizenid] then return cache[citizenid] end

    local data = dbGet(citizenid)
    if not data then data = dbCreate(citizenid) end

    local history = {}
    local ok, decoded = pcall(json.decode, data.history or '[]')
    if ok and type(decoded) == 'table' then history = decoded end

    cache[citizenid] = {
        citizenid        = citizenid,
        xp               = data.xp or 0,
        level            = data.level or 1,
        total_deliveries = data.total_deliveries or 0,
        total_earned     = data.total_earned or 0,
        history          = history,
    }
    return cache[citizenid]
end

-- Persiste o cache no banco
function PilotoSave(citizenid)
    local data = cache[citizenid]
    if not data then return end
    MySQL.update(
        'UPDATE rodz_piloto_players SET xp=?, level=?, total_deliveries=?, total_earned=?, history=? WHERE citizenid=?',
        { data.xp, data.level, data.total_deliveries, data.total_earned, json.encode(data.history), citizenid }
    )
end

-- =======================================================================================
-- PAYLOAD PARA A NUI (perfil completo: nível, XP, stats, destinos e aeronaves)
-- =======================================================================================
function PilotoBuildPayload(src)
    local player = GetPlayer(src)
    if not player then return nil end

    local citizenid = player.PlayerData.citizenid
    local data  = PilotoGetData(citizenid)
    local level = GetPlayerLevel(data.xp)
    data.level  = level

    local hasLicense = (exports.ox_inventory:Search(src, 'count', 'breve') or 0) > 0

    -- Lista explícita de níveis (array) para evitar ambiguidade de índice no JSON
    local levelsArr = {}
    for i = 1, #Config.Levels do
        local lv = Config.Levels[i]
        levelsArr[i] = { level = i, xp = lv.xp, label = lv.label, multiplier = lv.multiplier, color = lv.color }
    end

    return {
        xp             = data.xp,
        level          = level,
        levelLabel     = Config.Levels[level].label,
        levelColor     = Config.Levels[level].color,
        multiplier     = Config.Levels[level].multiplier,
        xpProgress     = GetXPProgress(data.xp),
        xpToNext       = GetXPToNextLevel(data.xp),
        nextLevelXP    = GetNextLevelXP(data.xp),
        totalDeliveries = data.total_deliveries,
        totalEarned    = data.total_earned,
        history        = data.history,
        hasLicense     = hasLicense,
        licensePrice   = Config.LicensePrice,
        parachutePrice = Config.ParachutePrice,
        levels         = levelsArr,
        destinations   = GetDestinationsForLevel(level),
        planes         = GetPlanesForLevel(level),
    }
end

-- =======================================================================================
-- AWARD: aplica XP e dinheiro, recalcula nível, salva. Retorna info de level-up.
-- =======================================================================================
function PilotoAward(src, citizenid, money, xp)
    local data = PilotoGetData(citizenid)
    if not data then return end

    local oldLevel = GetPlayerLevel(data.xp)
    data.xp           = data.xp + (xp or 0)
    data.total_earned = data.total_earned + (money or 0)
    data.level        = GetPlayerLevel(data.xp)

    local leveledUp = data.level > oldLevel
    if leveledUp then
        TriggerClientEvent('rodz-piloto:client:levelUp', src, {
            level = data.level,
            label = Config.Levels[data.level].label,
            multiplier = Config.Levels[data.level].multiplier,
        })
    end
    return leveledUp, data.level
end

-- Registra uma entrega concluída (incrementa contador e histórico)
function PilotoRecordCompletion(citizenid, entry)
    local data = PilotoGetData(citizenid)
    if not data then return end
    data.total_deliveries = data.total_deliveries + 1
    if entry then
        table.insert(data.history, 1, entry)
        if #data.history > 20 then table.remove(data.history) end
    end
    PilotoSave(citizenid)
end

-- =======================================================================================
-- CALLBACKS
-- =======================================================================================
lib.callback.register('rodz-piloto:server:getProfile', function(source)
    return PilotoBuildPayload(source)
end)

-- =======================================================================================
-- TABELA DO BANCO
-- =======================================================================================
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rodz_piloto_players` (
            `citizenid`        VARCHAR(50) NOT NULL,
            `xp`               INT NOT NULL DEFAULT 0,
            `level`            INT NOT NULL DEFAULT 1,
            `total_deliveries` INT NOT NULL DEFAULT 0,
            `total_earned`     BIGINT NOT NULL DEFAULT 0,
            `history`          LONGTEXT,
            `created_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print("^2[RODZ-PILOTO]^7 Tabela rodz_piloto_players verificada/criada")
end)

print("^2[RODZ-PILOTO]^7 Server progression initialized successfully")
