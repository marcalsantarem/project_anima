# Meta-jogo e economia (AG04)

> Documento do AG04. Modelo geral em "Progressão" da [Bíblia](00_biblia_projeto.md). Por enquanto só tem os upgrades da partida (M1); Fragmentos, nível de conta, Núcleos (talentos) e economia de Moeda entram no M2.

## Upgrades da partida

Base: decisão 35 (5 botões em tempo real, pagos com **Partículas**, valem só para a partida). Cada toque compra **1 nível** do upgrade, sem pausar. Nível inicial 0; **nível máximo 10** (Nv 10 = MAX no botão).

### Efeitos

`L` = nível atual (0–10). Os valores base vêm de [gameplay.md](gameplay.md) (`AnimaData`, `ProjectileData`, skills).

| id | Atributo afetado | Por nível | Tipo | Nv 10 (teto) | Regra |
|---|---|---|---|---|---|
| `upgrade_atk_power` | `ProjectileData.damage` (10) | +10% do base (+1) | aditivo sobre o base | +100% → 20 | `dano = base × (1 + 0,10·L)`, arredondado |
| `upgrade_atk_spd` | `AnimaData.fire_rate` (2 tiros/s) | +8% do base | aditivo sobre o base | +80% → 3,6 tiros/s | `cadência = base × (1 + 0,08·L)` |
| `upgrade_defense` | dano recebido pelo Núcleo | −4% | redução percentual | −40% | `dano = max(1, round(dano × (1 − 0,04·L)))`; aplica **antes** do escudo da `skill_aegis` |
| `upgrade_max_hp` | `AnimaData.core_hp_max` (100) | +10 HP (+10% do base) | aditivo | +100 → 200 | ao comprar, o HP atual também sobe 10 (não é cura total) |
| `upgrade_cooldown` | cooldown de todas as skills | −4% | redução percentual | −40% | `cd = base × (1 − 0,04·L)`; vale a partir do próximo uso (não mexe no cooldown em curso) |

- Os percentuais somam sobre o **valor base** (sem juros compostos entre níveis), o que deixa a curva previsível e fácil de exibir.
- **M2 (Proposta):** quando houver Fragmentos, o "base" passa a ser o valor já com Fragmentos e Núcleos (vindo do `MatchConfig`); os upgrades multiplicam por cima.
- Tetos de segurança: cadência ≤ 3,6 tiros/s cabe no pool de 64 projéteis (vida do tiro ≈ 0,67 s → ~3 em voo); redução de dano e de cooldown nunca passam de 40%; dano mínimo recebido = 1.

### Custo

Mesma curva para os 5 upgrades, independente por upgrade:
`custo(N) = ceil(4 × 1,4^(N−1))` (BRF-051: multiplicador 5 → 4 para os upgrades chegarem mais cedo), onde `N` é o nível que está sendo comprado (1–10).

| Nível comprado | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Custo (Partículas) | 4 | 6 | 8 | 11 | 16 | 22 | 31 | 43 | 60 | 83 |
| Acumulado | 4 | 10 | 18 | 29 | 45 | 67 | 98 | 141 | 201 | 284 |

- **A tabela é a fonte da verdade** (evita erro de arredondamento de float no `ceil`). Guardar como lista de inteiros no `.tres`.
- Compra = transação: só aplica se `particles ≥ custo` e `L < 10`; desconta e sobe o nível juntos. Senão, não faz nada (o botão mostra indisponível / MAX).

### Formato sugerido para o `.tres` (T-134, AG01)

`UpgradeData`: `id: StringName`, `stat: StringName`, `per_level: float`, `mode` (`ADD_PCT_BASE` | `ADD_FLAT` | `REDUCTION_PCT`), `max_level: int = 10`, `costs: PackedInt32Array` (nos `.tres`: [4, 6, 8, 11, 16, 22, 31, 43, 60, 83]).

| id | stat | per_level | mode |
|---|---|---|---|
| `upgrade_atk_power` | `stat_damage` | 0.10 | `ADD_PCT_BASE` |
| `upgrade_atk_spd` | `stat_fire_rate` | 0.08 | `ADD_PCT_BASE` |
| `upgrade_defense` | `stat_damage_taken` | 0.04 | `REDUCTION_PCT` |
| `upgrade_max_hp` | `stat_core_hp_max` | 10 | `ADD_FLAT` |
| `upgrade_cooldown` | `stat_cooldown` | 0.04 | `REDUCTION_PCT` |

### Estimativa na fase 1 (10 ondas)

Calculada de `data/waves/stage_01.tres` com o drop atual (runner 2, swarm 2 por membro, shooter 3, tank 5, chefe 51). O enxame vem em grupo de 5–8 (média 6,5), cada membro dropa 2. A onda 10 é só o chefe.

| Onda | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 (chefe) |
|---|---|---|---|---|---|---|---|---|---|---|
| Partículas na onda | 10 | 20 | 31 | 46 | 51 | 56 | 62 | 83 | 91 | 51 ao matar |
| Acumulado | 10 | 30 | 61 | 107 | 158 | 214 | 276 | 359 | 450 | 501 |

- Os 51 do chefe só chegam no fim, então o gasto útil é **~450 Partículas** (antes ~250; o chefe ogro não invoca minions). T-166: o chefe ficou sem defesa; T-173: mais fácil (HP 1100, 140 px/s, golpe 20 a cada 1,8 s); a simulação está em `docs/gameplay.md`.
- **Distribuído:** ~34 níveis (Nv 6 em todos = 5 × 67 = 335; sobram ~115 para levar 2–3 upgrades ao Nv 7–8).
- **Focado:** 1 upgrade no MAX (284) e ~165 restantes dão outro upgrade até o Nv 8–9 (141–201) ou dois até o Nv 5–6.
- **MAX** em um upgrade custa 284 (agora cabe antes do chefe); os 5 no MAX custam 1420 (~2,8x o total da fase 1). O MAX em todos continua sendo meta de fases mais longas.
- Ritmo: a 1ª compra sai já na onda 1 (10 Partículas); depois ~1 compra a cada 8–12 s de partida.
- **Recomendação (sem mudança aplicada):** o total subiu ~80%. Se a fase 1 ficar fácil demais com upgrades, subir o multiplicador da curva (4 → 6, MAX ~426) ou reduzir o teto por upgrade para manter ~1 upgrade maximizável por partida; validar em simulação (BRF-051) antes de mexer nos `.tres`.
