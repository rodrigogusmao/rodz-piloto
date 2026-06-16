Config = {}

-- ============================================================
--  GERAL
-- ============================================================
Config.Debug       = false   -- true: exibe zonas ox_target visualmente
Config.JobName     = "pilot" -- nome do job no framework

-- ============================================================
--  NPC INSTRUTOR DE VOO
--  Coordenadas, direção e modelo do ped fixo no aeroporto
-- ============================================================
Config.InstructorNPC = {
    coords  = vec3(-934.51, -2966.49, 13.95),
    heading = 151.42,
    model   = 's_m_m_pilot_01'
}

-- ============================================================
--  ZONA DE COLETA DE CAIXAS (aeroporto de origem)
--  Área onde o jogador pega as caixas antes de carregar no avião
-- ============================================================
Config.BoxPickupZone = {
    coords  = vec3(-929.68, -2961.62, 13.95),
    heading = 150.0,
    size    = vec3(3, 3, 2)  -- tamanho da BoxZone
}

-- ============================================================
--  AVIÕES
-- ============================================================
Config.PlaneSpawn = {
    coords  = vec3(-946.92, -2985.47, 13.95),
    heading = 60.0
}

-- Aeronaves liberadas por nível. Quanto maior o nível, melhores os modelos.
-- model     → modelo do veículo (spawn name)
-- label     → nome exibido na NUI
-- minLevel  → nível mínimo do piloto para usar
-- desc      → descrição curta exibida no card
-- speed     → rótulo de desempenho (apenas informativo na UI)
-- image     → foto exibida no card. Pode ser:
--             - nome de arquivo local em html/img/planes/ (ex: 'mammatus.png')
--             - URL completa (ex: 'https://site.com/mammatus.png')
Config.Planes = {
    { model = 'mammatus',  label = 'Mammatus',      minLevel = 1, speed = 'Lenta',        desc = 'Monomotor básico de treino. Ideal para iniciantes.', image = 'https://docs.fivem.net/vehicles/mammatus.webp' },
    { model = 'velum',     label = 'Velum',         minLevel = 2, speed = 'Média',        desc = 'Bimotor leve, mais estável em voos médios.',         image = 'https://docs.fivem.net/vehicles/velum.webp' },
    { model = 'cuban800',  label = 'Cuban 800',     minLevel = 4, speed = 'Média',        desc = 'Robusto e confiável para rotas longas.',             image = 'https://docs.fivem.net/vehicles/cuban800.webp' },
    { model = 'vestra',    label = 'Vestra',        minLevel = 8, speed = 'Muito rápida', desc = 'Jato executivo. Alta velocidade e alcance.',         image = 'https://docs.fivem.net/vehicles/vestra.webp' },
    { model = 'luxor',     label = 'Luxor',         minLevel = 10, speed = 'Muito rápida', desc = 'Jato de luxo. O topo da aviação de carga.',         image = 'https://docs.fivem.net/vehicles/luxor.webp' },
}

-- Mantido por compatibilidade (lista simples de modelos)
Config.AvailablePlanes = {
    'mammatus',
    'velum',
    'cuban800'
}

-- ============================================================
--  PREÇOS
-- ============================================================
Config.LicensePrice   = 4000    -- Brevê de Piloto (R$)
Config.ParachutePrice = 20000   -- Paraquedas (R$)

-- ============================================================
--  CAIXAS
-- ============================================================

-- Itens usados nas rotas normais e missões especiais
Config.AvailableBoxes = {
    'caixa_correios',
    'caixa_contrabando',
    'caixa_drogas',
    'caixa_eletronicos'
}

-- Quantidade de caixas geradas por missão
Config.BoxesPerMission = {
    min = 3,
    max = 7
}

-- Prop visual na mão do jogador enquanto carrega uma caixa
Config.BoxProp = {
    model    = 'prop_cs_cardbox_01',
    bone     = 28422,
    offset   = vec3(0.0, -0.2, -0.1),
    rotation = vec3(0.0, 0.0, 0.0)
}

-- ============================================================
--  RECOMPENSAS
-- ============================================================
Config.DeliveryReward = {
    min = 350,
    max = 1200
}

Config.SpecialMissionReward = {
    min = 500,
    max = 1500
}

-- ============================================================
--  AEROPORTOS DE DESTINO
--  planeCoords  → onde o avião deve pousar
--  deliveryPoints → pontos de entrega a pé no aeroporto
--  blipColor    → cor do blip no mapa (FiveM color index)
-- ============================================================
Config.DestinationAirports = {
    {
        name           = "Sandy Shores",
        planeCoords    = vec3(1720.6, 3306.82, 41.22),
        blipColor      = 5,
        minLevel       = 1,      -- nível mínimo do piloto para esta rota
        payMin         = 350,    -- pagamento por caixa (antes do multiplicador de nível)
        payMax         = 700,
        baseXP         = 12,     -- XP por caixa entregue
        deliveryPoints = {
            vec3(1722.17, 3302.96, 40.22),
           
        }
    },
    {
        name           = "Grapeseed",
        planeCoords    = vec3(2362.12, 3133.46, 48.21),
        blipColor      = 3,
        minLevel       = 2,
        payMin         = 500,
        payMax         = 950,
        baseXP         = 18,
        deliveryPoints = {
            vec3(2344.54, 3143.22, 47.21),
          
        }
    },
    {
        name           = "Zancudo",
        planeCoords    = vec3(-2296.58, 3179.66, 32.81),
        blipColor      = 1,
        minLevel       = 4,
        payMin         = 750,
        payMax         = 1300,
        baseXP         = 28,
        deliveryPoints = {
            vec3(-2297.22, 3180.00, 31.81),

        }
    },
    {
        name           = "Cayo Perico",
        planeCoords    = vec3(4434.64, -4469.43, 4.33),
        blipColor      = 6,
        minLevel       = 7,
        payMin         = 1100,
        payMax         = 2000,
        baseXP         = 45,
        deliveryPoints = {
            vec3(4434.69, -4469.44, 3.33),
           
        }
    }
}

-- ============================================================
--  MISSÕES ESPECIAIS
--  Locais de coleta da encomenda (entrega sempre num aeroporto acima)
-- ============================================================
Config.SpecialMissionLocations = {
    vec3(1692.27,  3287.87, 41.15),
    vec3(2122.67,  4796.78, 41.20),
    vec3(-1152.81, -2703.23, 13.80),
    vec3(1562.69,  6446.32, 25.32),
    vec3(-3140.56, 1124.36, 20.69)
}

-- ============================================================
--  MINIGAMES (decolagem / pouso)
--  Desative com Config.EnableMinigames = false
-- ============================================================
Config.EnableMinigames = false      

Config.TakeoffMinigame = {
    keys     = {'W', 'A', 'D'},
    duration = 5000,   -- duração total do skill check (ms)
    delay    = 2000    -- penalidade em caso de falha (ms)
}

Config.LandingMinigame = {
    duration       = 4000,
    successMessage = false
}

-- ============================================================
--  BLIPS
--  sprite → índice do ícone (gtav blip sprite list)
--  color  → índice de cor do FiveM
--  scale  → tamanho no mapa
-- ============================================================
Config.Blips = {
    instructor = {
        sprite = 307,   -- avião
        color  = 5,     -- amarelo
        scale  = 0.8,
        label  = "Instrutor de Voo"
    },
    boxpickup = {
        sprite = 478,   -- caixa
        color  = 3,     -- azul
        scale  = 0.7,
        label  = "Coleta de Caixas"
    }
}

-- ============================================================
--  ANIMAÇÕES
-- ============================================================
Config.Animations = {
    pickupBox = {
        dict = 'anim@heists@box_carry@',
        anim = 'idle',
        flag = 49
    },
    carryBox = {
        dict = 'anim@heists@box_carry@',
        anim = 'idle',
        flag = 49
    },
    dropBox = {
        dict = 'anim@heists@box_carry@',
        anim = 'putdown_low',
        flag = 1
    },
    giveItem = {
        dict = 'mp_common',
        anim = 'givetake1_a'
    }
}

-- ============================================================
--  SISTEMA DE CHAVES (mri_Qcarkeys)
--  exportName          → dar chave temporária ao spawnar o avião
--  removeExportName    → remover da lista interna de chaves
--  removeItemExportName → remover o item físico do inventário
-- ============================================================
Config.KeySystem = {
    enabled              = true,
    resourceName         = 'mri_Qcarkeys',
    exportName           = 'GiveTempKeys',
    removeExportName     = 'RemoveTempKeys',
    removeItemExportName = 'RemoveKeyItem'
}

-- ============================================================
--  SISTEMA DE NÍVEL / XP
--  xp         → XP acumulado necessário para alcançar o nível
--  label      → título do piloto no nível
--  multiplier → multiplicador de pagamento aplicado às entregas
--  color      → cor hex usada na NUI
-- ============================================================
Config.Levels = {
    [1]  = { xp = 0,     label = "Aspirante",     multiplier = 1.00, color = "#9ca3af" },
    [2]  = { xp = 600,   label = "Aprendiz",      multiplier = 1.10, color = "#60a5fa" },
    [3]  = { xp = 1600,  label = "Piloto Jr.",    multiplier = 1.20, color = "#34d399" },
    [4]  = { xp = 3200,  label = "Piloto",        multiplier = 1.35, color = "#a78bfa" },
    [5]  = { xp = 5600,  label = "Veterano",      multiplier = 1.50, color = "#f472b6" },
    [6]  = { xp = 9000,  label = "Comandante",    multiplier = 1.70, color = "#fb923c" },
    [7]  = { xp = 14000, label = "Capitão",       multiplier = 1.95, color = "#fbbf24" },
    [8]  = { xp = 21000, label = "Ás",            multiplier = 2.25, color = "#f87171" },
    [9]  = { xp = 30000, label = "Lendário",      multiplier = 2.60, color = "#c084fc" },
    [10] = { xp = 42000, label = "Comandante Mór", multiplier = 3.00, color = "#f59e0b" },
}

-- ============================================================
--  GANHO DE XP
--  completionBonus    → XP extra ao concluir toda a missão
--  clandestinePayMult → multiplicador de pagamento das rotas clandestinas
--  clandestineXPMult  → multiplicador de XP das rotas clandestinas
--  specialReward já usa Config.SpecialMissionReward para pagamento
-- ============================================================
Config.XP = {
    completionBonus    = 50,    -- XP de bônus por missão concluída
    specialBaseXP      = 60,    -- XP base de uma missão especial
    clandestinePayMult = 1.25,  -- rotas clandestinas pagam mais...
    clandestineXPMult  = 0.50,  -- ...mas dão menos XP (sem brevê oficial)
}
