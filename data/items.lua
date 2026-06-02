-- =======================================================================================
-- ITENS PARA ADICIONAR NO OX_INVENTORY
-- =======================================================================================
-- INSTRUÇÕES:
-- 1. Abra seu arquivo de itens do ox_inventory (geralmente ox_inventory/data/items.lua)
-- 2. Copie e cole os itens abaixo dentro da tabela de itens
-- 3. Certifique-se de ter as imagens PNG correspondentes em ox_inventory/web/images/
-- =======================================================================================

["breve_piloto"] = {
    label = "Brevê de Piloto",
    weight = 100,
    stack = false,
    close = true,
    description = "Carteira de Piloto - Autoriza pilotagem de aeronaves.",
    client = { image = "breve_piloto.png" }
},

["parachute"] = {
    label = "Paraquedas",
    weight = 5000,
    stack = false,
    close = true,
    description = "Paraquedas para saltos de emergência.",
    client = { image = "parachute.png" }
},

["caixa_correios"] = {
    label = "Caixa dos Correios",
    weight = 2500,
    stack = true,
    close = true,
    description = "Caixa lacrada dos Correios para entrega aérea.",
    client = { image = "caixa_correios.png" }
},

["caixa_contrabando"] = {
    label = "Caixa de Contrabando",
    weight = 3000,
    stack = true,
    close = true,
    descripion = "Caixa suspeita com conteúdo desconhecido.",
    client = { image = "caixa_contrabando.png" }
},

["caixa_drogas"] = {
    label = "Caixa de Drogas",
    weight = 2000,
    stack = true,
    close = true,
    description = "Caixa ilegal com substâncias controladas.",
    client = { image = "caixa_drogas.png" }
},

["caixa_eletronicos"] = {
    label = "Caixa de Eletrônicos",
    weight = 3500,
    stack = true,
    close = true,
    description = "Caixa com equipamentos eletrônicos importados.",
    client = { image = "caixa_eletronicos.png" }
},
