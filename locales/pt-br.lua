Locale = {
    -- Geral
    not_pilot = 'Você não é um piloto credenciado',
    cancel = 'Cancelar',
    
    -- NPC Instrutor
    npc_label = 'Falar com Instrutor de Voo',
    npc_menu_title = 'Instrutor de Voo',
    
    -- Brevê
    buy_license = 'Comprar Brevê de Piloto (R$ 4.000)',
    license_purchased = 'Brevê de Piloto adquirido com sucesso! Você já pode voar',
    license_already_owned = 'Você já possui um Brevê de Piloto',
    no_license = 'Você precisa ter um Brevê de Piloto para trabalhar como piloto',
    
    -- Paraquedas
    buy_parachute = 'Comprar Paraquedas (R$ 20.000)',
    parachute_purchased = 'Paraquedas adquirido com sucesso!',
    
    -- Dinheiro
    no_money = 'Você não tem dinheiro suficiente (R$ %s)',
    inventory_full = 'Seu inventário está cheio! Libere espaço',
    
    -- Rotas
    start_route = 'Iniciar Rota de Entrega',
    route_started = 'Rota iniciada! Destino: %s',
    route_canceled = 'Rota cancelada',
    return_plane = 'Devolver Avião',
    continue_routes = 'Pegar Mais Rotas',
    plane_returned = 'Avião devolvido com sucesso!',
    new_route_started = 'Nova rota iniciada com o mesmo avião!',
    
    -- Aviões
    plane_spawned = 'Avião liberado! Vá até a pista',
    plane_destroyed = 'Seu avião foi destruído! Rota cancelada',
    
    -- Caixas
    pickup_box_label = 'Pegar Caixa para Entrega',
    box_picked = 'Caixa coletada: %s',
    box_delivered = 'Caixa entregue! Pagamento: R$ %s',
    no_box = 'Você não tem caixas para entregar',
    
    -- Baú do Avião (Sistema Externo)
    open_plane_storage = 'Abrir Baú do Avião',
    store_box = 'Guardar Caixa no Avião',
    box_stored = 'Caixa armazenada no baú do avião',
    
    -- Entrega
    deliver_boxes = 'Entregar Caixas',
    delivery_complete = 'Entrega completa! Você recebeu R$ %s',
    go_to_destination = 'Vá até o aeroporto de destino marcado no mapa',
    
    -- Missão Especial
    special_mission = 'Missão Especial (R$ 500 - R$ 1.500)',
    special_mission_started = 'Missão especial iniciada! Vá até o ponto marcado',
    special_box_picked = 'Encomenda especial coletada! Entregue no aeroporto',
    special_mission_complete = 'Missão especial completa! Você recebeu R$ %s',
    
    -- Minigames
    takeoff_minigame_title = 'Sequência de Decolagem',
    takeoff_failed = 'Falha na decolagem! Aguarde 2 segundos...',
    takeoff_success = 'Decolagem bem sucedida!',
    
    landing_minigame_title = 'Estabilizar Aeronave',
    landing_failed = 'Pouso instável! Tenha cuidado',
    landing_success = 'Pouso perfeito!',
    
    -- Markers
    press_to_interact = '[E] Interagir',
    
    -- Notificações do Sistema
    route_active = 'Você já tem uma rota ativa',
    need_plane = 'Você precisa estar em um avião de trabalho',
    too_far = 'Você está muito longe do destino',

    -- Rota Clandestina
    start_clandestine_route = 'Rota Clandestina (sem brevê)',
}

function locale(key, ...)
    local text = Locale[key] or key
    if ... then
        return string.format(text, ...)
    end
    return text
end
