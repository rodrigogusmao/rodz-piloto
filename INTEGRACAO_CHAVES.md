
# 🔑 Integração com Sistema de Chaves (tokyo_Qkeys)

## Resumo
O `rodz-piloto` agora se integra automaticamente com o `tokyo_Qkeys` para gerenciar chaves temporárias dos aviões de trabalho.

## Funcionamento
O `rodz-piloto` agora se integra automaticamente com o `tokyo_Qkeys` para gerenciar chaves temporárias dos aviões de trabalho.
### 1. Ao Spawnar Avião
```lua
-- client/vehicle.lua (linha ~35)
TriggerServerEvent('rodz-piloto:server:registerPlane', netId, plate)

O servidor recebe e executa:
```lua
TriggerServerEvent('rodz-piloto:server:removePlane', plate)
```

### 2. Ao Deletar Avião
TriggerServerEvent('rodz-piloto:server:removePlane', plate)
ensure rodz-piloto

O servidor remove a chave:
```lua
-- server/main.lua
exports.tokyo_Qkeys:RemoveTempKeys(src, plate)
[RODZ-PILOTO] Chave temporária dada para jogador 1 (Placa: ABC123)

## Exports Utilizados

[RODZ-PILOTO] Chave temporária removida do jogador 1 (Placa: ABC123)
```lua
exports.tokyo_Qkeys:GiveTempKeys(source, plate)
```
- **source**: ID do jogador
 Verifique se `tokyo_Qkeys` está iniciado ANTES do `rodz-piloto`
- **Retorno**: Não retorna valor, notifica o jogador automaticamente

### RemoveTempKeys
```lua
exports.tokyo_Qkeys:RemoveTempKeys(source, plate)
```
- **source**: ID do jogador
- **plate**: Placa do veículo
- **Retorno**: Não retorna valor, remove a chave silenciosamente

## Casos de Uso

### ✅ Cenário 1: Missão Normal
1. Jogador pega avião → Recebe chave temporária
2. Completa missão → Deleta avião → Chave removida

### ✅ Cenário 2: Avião Destruído
1. Thread de monitoramento detecta destruição
2. Cancela rota → Deleta avião → Chave removida

### ✅ Cenário 3: Jogador Sai do Job
1. Ao sair do emprego, aviões são deletados
2. Chaves são automaticamente removidas

## Requisitos

- Script `tokyo_Qkeys` deve estar iniciado antes do `rodz-piloto`
- Adicionar no `fxmanifest.lua`:
```lua
dependencies {
    'tokyo_Qkeys'
}
```

## Logs

### Sucesso
```
[RODZ-PILOTO] Chave temporária dada para jogador 1 (Placa: ABC123)
[RODZ-PILOTO] Chave temporária removida do jogador 1 (Placa: ABC123)
```

### Erro
```
[RODZ-PILOTO] ERRO: Falha ao dar chave para jogador 1 (Placa: ABC123)
[RODZ-PILOTO] AVISO: Falha ao remover chave do jogador 1 (Placa: ABC123)
```

## Troubleshooting

### Chave não é dada ao spawnar
- Verifique se `tokyo_Qkeys` está iniciado ANTES do `rodz-piloto`
- Confira os logs do servidor (deve aparecer a notificação de chave recebida)
- Teste o export manualmente no console: `exports.tokyo_Qkeys:GiveTempKeys(1, 'ABC123')`
- Verifique se o Framework está configurado corretamente no `tokyo_Qkeys/shared/init.lua`

### Chave não é removida ao deletar
- Verifique se a placa está sendo enviada corretamente
- A chave pode ter sido removida manualmente pelo jogador
- Teste o export: `exports.tokyo_Qkeys:RemoveTempKeys(1, 'ABC123')`

### Não precisa declarar dependency
- O `tokyo_Qkeys` não requer dependência explícita no fxmanifest
- Basta garantir que ele inicie antes do `rodz-piloto` no `server.cfg`:
```cfg
ensure tokyo_Qkeys
ensure rodz-piloto
```
