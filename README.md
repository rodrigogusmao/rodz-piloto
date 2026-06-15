# ✈️ rodz-piloto

Sistema completo de **trabalho de piloto aéreo** para servidores FiveM com framework **Qbox / QBCore / MRI**.

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Dependências](#-dependências)
- [Instalação](#-instalação)
- [Configuração](#-configuração)
- [Itens de Inventário](#-itens-de-inventário)
- [Como Funciona](#-como-funciona)
- [Missões](#-missões)
- [Sistema de Chaves](#-sistema-de-chaves)
- [Estrutura de Arquivos](#-estrutura-de-arquivos)

---

## 🎯 Visão Geral

O `rodz-piloto` adiciona um job completo de piloto no aeroporto. O jogador pode:

- Comprar um **brevê de piloto** para acessar rotas oficiais
- Realizar **rotas de entrega aérea** entre aeroportos
- Fazer **missões especiais** de coleta e entrega de encomendas
- Fazer **rotas clandestinas** sem brevê (maior risco, maior ganho)

---

## 📦 Dependências

| Recurso | Obrigatório | Descrição |
|---|---|---|
| `ox_lib` | ✅ | Menus, notificações, progress, skill check |
| `ox_target` | ✅ | Zonas e targets de interação |
| `ox_inventory` | ✅ | Inventário de itens |
| `oxmysql` | ✅ | Banco de dados |
| `qbx_core` | ✅* | Framework principal (Qbox) |
| `qb-core` | ✅* | Framework principal (QBCore) — alternativa ao Qbox |
| `mri_Qcarkeys` | ✅ | Sistema de chaves de veículos |

> *O script detecta automaticamente qual framework está rodando em runtime — basta ter **um** dos dois.

---

## 🚀 Instalação

### 1. Copiar o recurso

```
resources/
└── [addons]/
    └── rodz-piloto/   ← cole aqui
```

### 2. Adicionar os itens ao ox_inventory

Abra `ox_inventory/data/items.lua` e adicione o conteúdo do arquivo `data/items.lua` deste recurso dentro da tabela de itens:

```lua
-- Em ox_inventory/data/items.lua
return {
    -- ... seus itens existentes ...

    -- Cole aqui o conteúdo de rodz-piloto/data/items.lua
    ["breve_piloto"] = { ... },
    ["parachute"]    = { ... },
    -- etc.
}
```

> As imagens PNG de cada item devem estar em `ox_inventory/web/images/`.

### 3. Adicionar o job ao framework

#### Qbox (qbx_core)
```sql
INSERT INTO jobs (name, label) VALUES ('pilot', 'Piloto');
INSERT INTO job_grades (job_name, grade, label, salary) VALUES ('pilot', 0, 'Piloto', 0);
```

#### QBCore (qb-core)
Adicione em `qb-core/shared/jobs.lua`:
```lua
['pilot'] = {
    label = 'Piloto',
    grades = {
        ['0'] = { name = 'Piloto', payment = 0 }
    }
}
```

### 4. Registrar no server.cfg

```cfg
ensure mri_Qcarkeys    # deve iniciar ANTES do rodz-piloto
ensure rodz-piloto
```

### 5. Reiniciar o servidor

```
restart rodz-piloto
```

---

## ⚙️ Configuração

Todas as opções estão no arquivo `config.lua`. As principais:

### Job e Debug
```lua
Config.Debug   = false   -- true: exibe zonas ox_target visualmente
Config.JobName = "pilot"
```

### NPC Instrutor
```lua
Config.InstructorNPC = {
    coords  = vec3(-934.51, -2966.49, 13.95),
    heading = 151.42,
    model   = 's_m_m_pilot_01'
}
```

### Preços
```lua
Config.LicensePrice   = 4000    -- Brevê de Piloto
Config.ParachutePrice = 20000   -- Paraquedas
```

### Missões
```lua
Config.BoxesPerMission = { min = 3, max = 7 }

Config.DeliveryReward       = { min = 350, max = 1200 }
Config.SpecialMissionReward = { min = 500, max = 1500 }
```

### Aeroportos de Destino

Cada aeroporto tem coordenadas de pouso e pontos de entrega a pé:

```lua
Config.DestinationAirports = {
    {
        name           = "Sandy Shores",
        planeCoords    = vec3(1720.6, 3306.82, 41.22),
        blipColor      = 5,
        deliveryPoints = {
            vec3(1705.2, 3290.5, 41.15),
            -- ...
        }
    },
    -- ...
}
```

### Minigames
```lua
Config.EnableMinigames = true   -- false para desativar

Config.TakeoffMinigame = {
    keys     = {'W', 'A', 'D'},
    duration = 5000,
    delay    = 2000
}
```

### Sistema de Chaves
```lua
Config.KeySystem = {
    enabled              = true,
    resourceName         = 'mri_Qcarkeys',
    exportName           = 'GiveTempKeys',
    removeExportName     = 'RemoveTempKeys',
    removeItemExportName = 'RemoveKeyItem'
}
```

> Se usar outro sistema de chaves, basta alterar o `resourceName` e os nomes dos exports.

---

## 🎒 Itens de Inventário

| Item | Label | Stack | Uso |
|---|---|---|---|
| `breve_piloto` | Brevê de Piloto | Não | Autoriza rotas oficiais |
| `parachute` | Paraquedas | Não | Salto de emergência |
| `caixa_correios` | Caixa dos Correios | Sim | Carga das rotas |
| `caixa_contrabando` | Caixa de Contrabando | Sim | Carga das rotas |
| `caixa_drogas` | Caixa de Drogas | Sim | Carga das rotas |
| `caixa_eletronicos` | Caixa de Eletrônicos | Sim | Carga das rotas |

---

## 🛫 Como Funciona

### Fluxo de uma rota normal

```
1. Falar com o NPC Instrutor de Voo no aeroporto
2. Comprar o Brevê de Piloto (R$ 4.000)
3. Selecionar "Iniciar Rota de Entrega"
4. O servidor sorteia: aeroporto destino + quantidade de caixas (3-7)
5. Um avião de trabalho é spawnado e a chave é entregue automaticamente
6. Coletar as caixas na zona de coleta (interação no target)
7. Depositar cada caixa no avião (target no avião)
8. Voar até o aeroporto destino marcado no GPS
9. Retirar as caixas do avião e entregar nos pontos marcados
10. Receber o pagamento por caixa entregue (R$ 350-1.200 cada)
11. Devolver o avião ao aeroporto de origem (ou pegar nova rota)
```

### Minigames

| Gatilho | Mecânica | Penalidade |
|---|---|---|
| Velocidade > 80 km/h + altitude > 5m | Skill check decolagem (easy, easy, medium) | Delay de 2 segundos |
| Altitude < 10m após decolar | Skill check pouso (medium, medium) | Nenhuma — aviso visual |

---

## 📋 Missões

### Rota Normal (requer brevê)
- Entrega de 3-7 caixas entre aeroportos
- Pagamento por caixa entregue (R$ 350-1.200)

### Missão Especial (requer brevê)
- Buscar uma encomenda em local específico no mapa
- Levar ao aeroporto designado
- Pagamento único de R$ 500-1.500

### Rota Clandestina (sem brevê)
- Disponível no menu do instrutor para qualquer jogador
- Caixas de contrabando, drogas ou eletrônicos
- Mesmo pagamento da rota normal, sem precisar de brevê
- Alto risco — sem proteção legal

---

## 🔑 Sistema de Chaves

O recurso integra com o `mri_Qcarkeys` para gerenciar acesso ao avião de trabalho:

| Evento | Ação |
|---|---|
| Avião spawnado | `GiveTempKeys` + key item no inventário |
| Missão cancelada | `RemoveTempKeys` + `RemoveKeyItem` |
| Avião devolvido | `RemoveTempKeys` + `RemoveKeyItem` |
| Avião deletado | `RemoveTempKeys` + `RemoveKeyItem` |

---

## 📁 Estrutura de Arquivos

```
rodz-piloto/
├── fxmanifest.lua
├── config.lua              ← toda a configuração aqui
├── README.md
├── data/
│   └── items.lua           ← itens para adicionar no ox_inventory
├── locales/
│   └── pt-br.lua           ← textos e notificações em PT-BR
├── client/
│   ├── main.lua            ← menu do NPC, compras
│   ├── targets.lua         ← criação do NPC e zonas ox_target
│   ├── vehicle.lua         ← spawn e gerenciamento do avião
│   ├── delivery.lua        ← sistema de rotas, blips e entregas
│   ├── minigame.lua        ← skill checks de decolagem e pouso
│   └── props.lua           ← prop de caixa na mão do jogador
└── server/
    ├── main.lua            ← compras e callbacks de validação
    ├── delivery.lua        ← lógica autoritativa de rotas e chaves
    ├── missions.lua        ← missões especiais
    └── clandestine.lua     ← rotas clandestinas
```

---

## 🛡️ Segurança (Anti-Exploit)

Toda validação crítica ocorre **server-side**:

- Brevê verificado no inventário via `ox_inventory` antes de cada ação
- Missões simultâneas bloqueadas por `citizenid`
- Índice de ponto de entrega validado (1 ≤ idx ≤ máximo)
- Ponto de entrega já usado bloqueado
- Tentativa de depositar sem ter coletado: bloqueado + log no console

---

## 📝 Notas

- O estado das missões é mantido **em memória** — não persiste entre reinicializações do servidor
- Ao reiniciar o recurso, o avião spawnado é automaticamente deletado no client
- Blips do job só aparecem **durante a missão ativa** para não poluir o mapa
- Compatible com: **Qbox (qbx_core)** · **QBCore (qb-core)** · **MRI**

---

*Desenvolvido por Rodz Development | MRI*
