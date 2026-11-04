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

Hoje `stage_01` tem 3 ondas de teste, que dão ~5, ~10 e ~16 Partículas (corredor 1, enxame 1 × 5–8, atirador 2, tanque 4). A curva de 10 ondas é da T-116; **suposição** para calibrar: crescimento de ~6 por onda.

| Onda | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 (chefe) |
|---|---|---|---|---|---|---|---|---|---|---|
| Partículas na onda | 5 | 10 | 16 | 22 | 28 | 34 | 40 | 46 | 52 | 50 ao matar |
| Acumulado | 5 | 15 | 31 | 53 | 81 | 115 | 155 | 201 | 253 | — |

- Os 50 do chefe só chegam no fim, então o gasto útil é **~250 Partículas** (o chefe ogro da T-150 não invoca minions). T-166: o chefe ficou sem defesa; T-173: mais fácil (HP 1100, 140 px/s, golpe 20 a cada 1,8 s; era 1200, 160 px/s, 30 a cada 1,5 s); as Partículas não mudaram (simulação em `docs/gameplay.md`).
- **Distribuído:** ~24 níveis (Nv 5 em todos = 225). Ex.: dano 15, cadência 2,8/s → DPS ~42 (base 20, +110%). Na simulação do BRF-051 o bot compra ~25–28 níveis na partida (inclui os 50 do chefe).
- **Focado:** um upgrade chega ao Nv 9–10 (201–284) e sobra pouco para o resto.
- **MAX** em um upgrade custa 284 (mais que a fase 1 antes do chefe); os 5 no MAX custam 1420. O MAX é meta de fases mais longas, não da fase 1.
- Ritmo: a 1ª compra sai já na onda 1; depois ~1 compra a cada 10–15 s de partida.
- **Validação pendente:** se a T-116 der muito mais ou muito menos que ~250 Partículas antes do chefe, ajustar só o multiplicador (hoje 4) da curva de custo, mantendo a razão 1,4.
