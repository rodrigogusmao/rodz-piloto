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

Config.AvailablePlanes = {
    'cuban800',
    'velum',
    'mammatus'
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
        deliveryPoints = {
            vec3(1705.2, 3290.5, 41.15),
            vec3(1738.9, 3295.7, 41.12),
            vec3(1710.5, 3315.2, 41.18),
        }
    },
    {
        name           = "Grapeseed",
        planeCoords    = vec3(2362.12, 3133.46, 48.21),
        blipColor      = 3,
        deliveryPoints = {
            vec3(2350.5, 3120.8, 48.20),
            vec3(2375.3, 3140.2, 48.19),
            vec3(2368.7, 3125.1, 48.22),
        }
    },
    {
        name           = "Zancudo",
        planeCoords    = vec3(-2296.58, 3179.66, 32.81),
        blipColor      = 1,
        deliveryPoints = {
            vec3(-2310.2, 3165.4, 32.80),
            vec3(-2285.9, 3190.8, 32.82),
            vec3(-2305.1, 3175.2, 32.79),
        }
    },
    {
        name           = "Cayo Perico",
        planeCoords    = vec3(4434.64, -4469.43, 4.33),
        blipColor      = 6,
        deliveryPoints = {
            vec3(4420.1, -4455.2, 4.30),
            vec3(4445.8, -4480.5, 4.35),
            vec3(4430.2, -4475.1, 4.32),
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
Config.EnableMinigames = true

Config.TakeoffMinigame = {
    keys     = {'W', 'A', 'D'},
    duration = 5000,   -- duração total do skill check (ms)
    delay    = 2000    -- penalidade em caso de falha (ms)
}

Config.LandingMinigame = {
    duration       = 4000,
    successMessage = true
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
