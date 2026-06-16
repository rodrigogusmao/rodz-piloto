# ✈️ rodz-piloto

Sistema completo de **trabalho de piloto aéreo** para FiveM (**Qbox / QBCore / MRI**), com **interface NUI estilo tablet** e **sistema de XP / nível** que libera rotas que pagam mais e aeronaves melhores.

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Dependências](#-dependências)
- [Instalação](#-instalação)
- [Interface (NUI Tablet)](#-interface-nui-tablet)
- [Sistema de XP / Nível](#-sistema-de-xp--nível)
- [Configuração](#-configuração)
- [Itens de Inventário](#-itens-de-inventário)
- [Como Funciona](#-como-funciona)
- [Controles](#-controles)
- [Sistema de Chaves](#-sistema-de-chaves)
- [Banco de Dados](#-banco-de-dados)
- [Estrutura de Arquivos](#-estrutura-de-arquivos)
- [Segurança (Anti-Exploit)](#-segurança-anti-exploit)
- [Notas](#-notas)

---

## 🎯 Visão Geral

O `rodz-piloto` adiciona um job de piloto no aeroporto, operado por uma **NUI estilo tablet**. O jogador pode:

- Comprar **brevê de piloto** e **paraquedas** na loja
- Realizar **rotas de entrega aérea** entre aeroportos
- Subir de **nível (XP)** para liberar **destinos que pagam mais** e **aeronaves melhores**
- Fazer **rotas clandestinas** sem brevê (paga mais, dá menos XP, sem proteção legal)

A interface segue o **mri-ui-kit** (mesmas cores, fonte Saira e padrões de componente do ecossistema MRI), reproduzido em HTML/CSS/JS puro — sem build, igual ao padrão dos recursos `mri_*`.

---

## 📦 Dependências

| Recurso | Obrigatório | Descrição |
|---|---|---|
| `ox_lib` | ✅ | Notificações, progress, skill check, callbacks |
| `ox_target` | ✅ | Zonas e targets de interação |
| `ox_inventory` | ✅ | Inventário de itens |
| `oxmysql` | ✅ | Persistência de XP/progresso |
| `qbx_core` | ✅* | Framework principal (Qbox) |
| `qb-core` | ✅* | Framework principal (QBCore) — alternativa ao Qbox |
| `mri_Qcarkeys` | ✅ | Sistema de chaves de veículos |

> *O script detecta o framework automaticamente em runtime — basta ter **um** dos dois.

---

## 🚀 Instalação

### 1. Copiar o recurso
```
resources/
└── [rodz]/
    └── rodz-piloto/   ← cole aqui
```

### 2. Adicionar os itens ao ox_inventory
Copie o conteúdo de `data/items.lua` para o `ox_inventory/data/items.lua`:
```lua
["breve"]            = { ... },
["parachute"]        = { ... },
["caixa_correios"]   = { ... },
["caixa_contrabando"]= { ... },
["caixa_drogas"]     = { ... },
["caixa_eletronicos"]= { ... },
```
> As imagens PNG dos itens devem ficar em `ox_inventory/web/images/`.

### 3. Adicionar o job ao framework

**Qbox (qbx_core)**
```sql
INSERT INTO jobs (name, label) VALUES ('pilot', 'Piloto');
INSERT INTO job_grades (job_name, grade, label, salary) VALUES ('pilot', 0, 'Piloto', 0);
```

**QBCore (qb-core)** — em `qb-core/shared/jobs.lua`:
```lua
['pilot'] = { label = 'Piloto', grades = { ['0'] = { name = 'Piloto', payment = 0 } } }
```

### 4. Banco de dados
A tabela `rodz_piloto_players` é **criada automaticamente** no primeiro boot. Se preferir importar manualmente, use o `database.sql`.

### 5. server.cfg
```cfg
ensure mri_Qcarkeys    # deve iniciar ANTES do rodz-piloto
ensure rodz-piloto
```

---

## 📱 Interface (NUI Tablet)

A NUI é aberta interagindo (ox_target) com o **NPC Instrutor de Voo** no aeroporto. Abas:

| Aba | Conteúdo |
|---|---|
| **Dashboard** | Perfil (nível, XP, multiplicador), estatísticas (entregas, total ganho, XP), rota ativa e progressão de níveis |
| **Rotas** | Destinos liberados pelo nível (os melhores pagam mais) + rota clandestina |
| **Aeronaves** | Modelos liberados pelo nível, com foto; seleção da aeronave usada na próxima rota |
| **Loja** | Compra de brevê e paraquedas |
| **Histórico** | Últimas entregas (destino, caixas, pagamento, XP) |

Fecha com o botão **Fechar** ou tecla **ESC**.

---

## 📈 Sistema de XP / Nível

- Cada entrega concede **XP** e **dinheiro**. O pagamento é `faixa do destino × multiplicador do nível`.
- Subir de nível aumenta o **multiplicador** e libera **destinos** e **aeronaves** de `minLevel` maior.
- Progresso (XP, nível, entregas, total ganho, histórico) **persiste** na tabela `rodz_piloto_players`.

Configurado em `Config.Levels` (10 níveis):
```lua
Config.Levels = {
    [1]  = { xp = 0,     label = "Aspirante",      multiplier = 1.00, color = "#9ca3af" },
    [2]  = { xp = 600,   label = "Aprendiz",       multiplier = 1.10, color = "#60a5fa" },
    -- ... até ...
    [10] = { xp = 42000, label = "Comandante Mór", multiplier = 3.00, color = "#f59e0b" },
}
```

---

## ⚙️ Configuração

Tudo em `config.lua`. Principais blocos:

### Aeronaves (liberadas por nível)
```lua
Config.Planes = {
    { model = 'mammatus', label = 'Mammatus', minLevel = 1,  speed = 'Lenta',        desc = '...', image = 'https://docs.fivem.net/vehicles/mammatus.webp' },
    { model = 'velum',    label = 'Velum',    minLevel = 2,  speed = 'Média',        desc = '...', image = '...' },
    { model = 'cuban800', label = 'Cuban 800',minLevel = 4,  speed = 'Média',        desc = '...', image = '...' },
    { model = 'vestra',   label = 'Vestra',   minLevel = 8,  speed = 'Muito rápida', desc = '...', image = '...' },
    { model = 'luxor',    label = 'Luxor',    minLevel = 10, speed = 'Muito rápida', desc = '...', image = '...' },
}
```
> `image` aceita **URL completa** ou **nome de arquivo local** em `html/img/planes/` (ex.: `'mammatus.png'`). Se a imagem falhar, o card cai num ícone automaticamente.

### Destinos (recompensa e nível por rota)
```lua
Config.DestinationAirports = {
    {
        name = "Sandy Shores", planeCoords = vec3(...), blipColor = 5,
        minLevel = 1, payMin = 350, payMax = 700, baseXP = 12,
        deliveryPoints = { vec3(...) }
    },
    -- Grapeseed (nv.2), Zancudo (nv.4), Cayo Perico (nv.7) ...
}
```

### Ganho de XP e clandestina
```lua
Config.XP = {
    completionBonus    = 50,    -- XP extra ao concluir a missão
    clandestinePayMult = 1.25,  -- clandestina paga mais...
    clandestineXPMult  = 0.50,  -- ...e dá menos XP
}
```

### Preços, caixas, minigames, chaves
```lua
Config.LicensePrice   = 4000
Config.ParachutePrice = 20000
Config.BoxesPerMission = { min = 3, max = 7 }
Config.EnableMinigames = true
Config.KeySystem = { enabled = true, resourceName = 'mri_Qcarkeys', exportName = 'GiveTempKeys', removeExportName = 'RemoveTempKeys', removeItemExportName = 'RemoveKeyItem' }
```

---

## 🎒 Itens de Inventário

| Item | Label | Stack | Uso |
|---|---|---|---|
| `breve` | Brevê de Piloto | Não | Autoriza rotas oficiais |
| `parachute` | Paraquedas | Não | Salto de emergência |
| `caixa_correios` | Caixa dos Correios | Sim | Carga das rotas |
| `caixa_contrabando` | Caixa de Contrabando | Sim | Carga das rotas |
| `caixa_drogas` | Caixa de Drogas | Sim | Carga das rotas |
| `caixa_eletronicos` | Caixa de Eletrônicos | Sim | Carga das rotas |

---

## 🛫 Como Funciona

```
1. Interagir com o NPC Instrutor de Voo → abre o tablet
2. (Loja) Comprar o Brevê de Piloto
3. (Aeronaves) Selecionar uma aeronave liberada pelo seu nível
4. (Rotas) Escolher um destino liberado → o avião spawna com a chave
5. Coletar as caixas na zona de coleta
6. Depositar cada caixa no avião (o HUD mostra carregadas/total)
7. Voar até o aeroporto destino marcado no GPS
8. Retirar as caixas do avião e entregar nos pontos marcados
9. Receber pagamento + XP por caixa (o HUD mostra entregues/total)
10. Devolver o avião / iniciar nova rota com a mesma aeronave
```

### Minigames
| Gatilho | Mecânica | Penalidade |
|---|---|---|
| Velocidade alta + decolando | Skill check de decolagem | Delay |
| Altitude baixa após decolar | Skill check de pouso | Aviso visual |

### Rota Clandestina
Disponível na aba Rotas sem precisar de brevê. Paga mais e dá menos XP (`Config.XP`). Alto risco, sem proteção legal.

---

## 🎮 Controles

| Tecla | Ação |
|---|---|
| **F6** | Cancela a missão, deleta o avião e remove a chave (rebindável em Configurações → Controles) |
| **ESC** | Fecha o tablet |

---

## 🔑 Sistema de Chaves

Integra com `mri_Qcarkeys`:

| Evento | Ação |
|---|---|
| Avião spawnado | `GiveTempKeys` + chave no inventário |
| Missão cancelada (F6 / tablet) | `RemoveTempKeys` + `RemoveKeyItem` |
| Avião devolvido | `RemoveTempKeys` + `RemoveKeyItem` |
| Avião deletado/destruído | `RemoveTempKeys` + `RemoveKeyItem` |

> Para outro sistema de chaves, altere `Config.KeySystem`.

---

## 🗄️ Banco de Dados

Tabela `rodz_piloto_players` (criada no boot):

| Coluna | Tipo | Descrição |
|---|---|---|
| `citizenid` | VARCHAR(50) PK | Identificador do personagem |
| `xp` | INT | XP acumulado |
| `level` | INT | Nível atual |
| `total_deliveries` | INT | Total de missões concluídas |
| `total_earned` | BIGINT | Total ganho |
| `history` | LONGTEXT | Últimas 20 entregas (JSON) |

---

## 📁 Estrutura de Arquivos

```
rodz-piloto/
├── fxmanifest.lua
├── config.lua              ← toda a configuração
├── database.sql            ← tabela de progressão (auto-criada no boot)
├── README.md
├── data/
│   └── items.lua           ← itens para o ox_inventory
├── locales/
│   └── pt-br.lua           ← textos e notificações
├── shared/
│   └── utils.lua           ← helpers de XP/nível (client + server)
├── html/                   ← NUI tablet (mri-ui-kit)
│   ├── index.html
│   ├── style.css
│   ├── app.js
│   └── img/planes/         ← (opcional) fotos locais das aeronaves
├── client/
│   ├── nui.lua             ← ponte da NUI (tablet) ↔ jogo
│   ├── main.lua            ← compras e ações no mundo
│   ├── targets.lua         ← NPC e zonas ox_target
│   ├── vehicle.lua         ← spawn/gerência do avião
│   ├── delivery.lua        ← rotas, blips, entregas, HUD, F6
│   ├── minigame.lua        ← skill checks
│   └── props.lua           ← prop de caixa na mão
└── server/
    ├── progression.lua     ← XP/nível, persistência, callback de perfil
    ├── main.lua            ← compras e validações
    ├── delivery.lua        ← lógica autoritativa de rotas, pagamento, chaves
    └── missions.lua        ← missão especial (lógica server-side)
```

---

## 🛡️ Segurança (Anti-Exploit)

Validação crítica **server-side**:
- Brevê verificado no inventário antes de cada ação oficial
- Destino e aeronave validados pelo **nível** do jogador
- Missões simultâneas bloqueadas por `citizenid`
- Índice de ponto de entrega validado e ponto já usado bloqueado
- Depositar/retirar caixa sem ter coletado: bloqueado + log

---

## 📝 Notas

- O **progresso (XP/nível/estatísticas) persiste** no banco; o **estado da missão em andamento** é mantido em memória (não sobrevive a um restart com missão ativa).
- Ao reiniciar o recurso, o avião spawnado é removido automaticamente.
- Blips do job só aparecem **durante a missão ativa**.
- A **missão especial** possui lógica server-side, mas o fluxo client-side (coleta/entrega/HUD) ainda **não está implementado** — por isso não é exposta na NUI.
- Compatível com **Qbox (qbx_core)** · **QBCore (qb-core)** · **MRI**.

---

*Desenvolvido por Rodz Development | MRI*
