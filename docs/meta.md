# Meta-jogo e economia (AG04)

> Documento do AG04. Modelo geral em "Progressão" da [Bíblia](00_biblia_projeto.md). Tem os upgrades da partida (M1) e os Núcleos (T-203); Fragmentos, nível de conta, Núcleos (talentos) e economia de Moeda entram no M2.
>
> **Economia do M2 (XP, Moeda, níveis):** ver [economia.md](economia.md).

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
- **M2 (Proposta):** quando houver Componentes, o "base" passa a ser o valor já com Componentes e Núcleos (vindo do `MatchConfig`); os upgrades multiplicam por cima.
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

### API da lógica pura do meta (T-186, `src/meta/`)

- `MetaRewards.compute(result, rewards, first_win_today) -> {xp, coins, breakdown}`: soma `kills_by_type` × pesos (float), arredonda só no total, derrota ×0,7, bônus de 1ª vitória só em vitória. Usa `result.kills_by_type` (campo do `MatchResult`, T-287).
- `MetaProgress.apply_xp(profile, xp, progression) -> {levels_gained, new_level, slots_unlocked}` (várias subidas; teto 30: o XP excedente é **descartado** e `xp` fica 0); `slots_for_level(level, progression)`.
- `MetaDaily.is_first_win_today(profile, today)` / `mark_first_win(profile, today)`; `today` injetado (`YYYY-MM-DD`, data local); `PlayerProfile.last_first_win_date` ("" por padrão; save antigo carrega com "", sem subir o esquema).
- `MetaFlow.settle(profile, result, rewards, progression, today) -> {xp, coins, levels_gained, new_level, slots_unlocked, first_win_bonus}`: aplica no perfil, **não salva** (quem chama salva pelo `Backend`).
- Testes: `tests/unit/meta/test_meta_logic.gd` (195 / 295 XP, derrota onda 3 = 19, limites, teto, bônus do dia).

## Núcleos (talentos) (T-203, BRF-151)

> Dados: `data/talents/talent_tree.tres` + um `talent_<nome>.tres` por talento (`TalentData` e `TalentTree`, em `src/meta/`). Textos: chaves `TALENT_*` em `data/i18n/strings.csv`. Lógica de compra: T-204; efeitos na partida: T-205. Liberam no **NV 3** (`nuclei`).

### Princípios
- 12 talentos em **3 ramos** (Ataque, Defesa, Economia) × **4 camadas**, comprados com **Moeda**, permanentes, valem em toda partida via `MatchConfig`.
- Só atributos que já existem (mais 3 contas simples: cura por onda, Partículas iniciais, ganho de Moeda). Bônus pequenos por nível: os talentos dão **~15 a 30%** e os upgrades da partida continuam sendo a alavanca forte.
- 1 compra = +1 nível. `values` (efeito acumulado) e `costs` são tabelas por nível; a tabela é a verdade.

### Árvore (grade: coluna, linha; linha 0 no topo = camada raiz)
Pré-requisito = `talento >= nível`. Camadas 1 e 2 exigem o nó acima; a **camada 3 (capstone)** exige o nó acima no Nv 3 **e** um nó de outro ramo (amarra os ramos, sem ciclo).

| id | Nome | Ramo | (col,lin) | Efeito (acumulado) | Níveis | Custo por nível | Total | Pré-requisitos |
|---|---|---|---|---|---|---|---|---|
| `talent_sharp_core` | Núcleo Afiado | Ataque | (0,0) | `stat_damage` 8·11·14·17·20% | 5 | 50·70·90·125·165 | 500 | — |
| `talent_quick_pulse` | Pulso Veloz | Ataque | (0,1) | `stat_fire_rate` +3%/nível → +15% | 5 | 120·160·220·295·400 | 1195 | sharp_core 1 |
| `talent_arcane_burst` | Surto Arcano | Ataque | (0,2) | `stat_skill_damage` +5%/nível → +25% | 5 | 250·340·455·615·830 | 2490 | quick_pulse 3 |
| `talent_piercing_ray` | Raio Perfurante | Ataque | (0,3) | `stat_pierce` +1 (compra única) | 1 | 1500 | 1500 | arcane_burst 3, deflect 1 |
| `talent_hardened_shell` | Casca Reforçada | Defesa | (1,0) | `stat_core_hp_max` 8·11·14·17·20% | 5 | 50·70·90·125·165 | 500 | — |
| `talent_deflect` | Desvio | Defesa | (1,1) | `stat_damage_taken` −2%/nível → −10% | 5 | 120·160·220·295·400 | 1195 | hardened_shell 1 |
| `talent_wave_mend` | Reparo de Onda | Defesa | (1,2) | `stat_wave_heal` +2% do HP máx/nível → 10% | 5 | 250·340·455·615·830 | 2490 | deflect 3 |
| `talent_bastion` | Bastião | Defesa | (1,3) | `stat_core_hp_max` +15% (compra única) | 1 | 1500 | 1500 | wave_mend 3, seed_charge 1 |
| `talent_particle_magnet` | Ímã de Partículas | Economia | (2,0) | `stat_particle_gain` 6·8·10·13·15% | 5 | 50·70·90·125·165 | 500 | — |
| `talent_seed_charge` | Carga Inicial | Economia | (2,1) | `stat_start_particles` +3/nível → +15 | 5 | 120·160·220·295·400 | 1195 | particle_magnet 1 |
| `talent_cool_mind` | Mente Fria | Economia | (2,2) | `stat_cooldown` −2%/nível → −10% | 5 | 250·340·455·615·830 | 2490 | seed_charge 3 |
| `talent_golden_core` | Núcleo Dourado | Economia | (2,3) | `stat_coin_gain` +5%/nível → +15% | 3 | 600·900·1300 | 2800 | cool_mind 3, quick_pulse 1 |

Raízes com o **Nv 1 dobrado** (T-209: o 1º talento precisa ser perceptível; o máximo não mudou). Custo por nível = `base × 1,35^(n−1)` arredondado a 5 (base 50, 120 e 250 nas camadas 0, 1 e 2); capstones com preço fixo. **Total da árvore: 18 355 Moeda** (82 níveis).

### Regras de soma
- **Ordem:** `valor da partida = base × (1 + Σ Núcleos + Σ Componentes) × (1 + upgrade da partida)`. Núcleos e Componentes (futuros) somam no **mesmo termo aditivo**; os upgrades multiplicam por cima (coerente com "Upgrades da partida"). Arredondar só no fim.
- **Reduções** (`stat_damage_taken`, `stat_cooldown`): fator `(1 − Σ Núcleos − Σ Componentes) × (1 − upgrade)`. **Teto de redução total: −50%** (fator mínimo 0,5); dano recebido mínimo 1.
- **Vida máxima:** `round(base × (1 + Σ%)) + 10 × nível do upgrade` (o upgrade é fixo). Teto dos Núcleos: +40% (hoje +35%).
- **Implementado (T-205, BRF-154):** regras acima em `MatchUpgrades.apply`; detalhes em [gameplay.md](gameplay.md) ("Núcleos na partida").
- **Cadência:** teto final **4,2 tiros/s** (substitui o 3,6 quando há Núcleos: 2 × 1,15 × 1,8 = 4,14; ~3 tiros em voo, cabe no pool de 64). **O AG01 deve confirmar.**
- **Tetos dos Núcleos sozinhos:** dano +20%, cadência +15%, dano de Módulos +25%, Partículas +15%, Moeda +15%. Dano com upgrade no MAX: ×2,4.
- `stat_pierce`, `stat_start_particles` e `stat_wave_heal` são **aditivos puros**. `stat_coin_gain` é do meta (`MetaRewards`, T-204): multiplica o total de Moeda da partida (`round(total × (1 + g))`), depois do ×0,7 da derrota e antes do bônus do dia.
- **Respec (Proposta, decisão do dono):** recomendo **grátis e com 100% de reembolso**, fora de partida. Justificativa: a árvore inteira é comprável (só a ordem importa), então o respec não vira sumidouro de Moeda nem exploit; evita compra "errada" frustrante e deixa testar builds. Reembolso = soma dos custos **da tabela atual** dos níveis comprados (o save guarda só níveis, então rebalancear custos não corrompe). Sem respec, a Moeda gasta se perde para sempre.
- **Save (T-204):** `PlayerProfile.talents: Dictionary` `{id: nível}`; ausente = 0. Compra = transação (nível < máx, pré-requisitos ok, `coins >= custo`; tudo ou nada).
- **Respec (decidido):** grátis, 100% de reembolso, só fora de partida. **Tetos finais:** redução de dano e de cooldown −50%, HP máx dos Núcleos +40% (a árvore dá +35%, sob o teto), cadência final 4,2 tiros/s (AG01).

### API (T-204)
- `MetaTalents` (`src/meta/meta_talents.gd`, estático): `level(profile, id)`, `next_cost(profile, tree, id)` (0 se máx), `prereq_status(profile, tree, id) -> [{id, need, have}]` (só o que falta), `can_buy(profile, tree, id) -> MetaTalents.Reason` (`OK, MAX, LOCKED_PREREQ, NO_COINS, FEATURE_LOCKED` [nível da conta < 3], `UNKNOWN`), `buy(...) -> {ok, reason, cost, level}` (tudo ou nada), `spent_coins`, `respec(profile, tree) -> reembolso`, `coin_gain(talents, tree)`. Quem chama salva pelo `Backend`.
- `TalentBonuses.resolve(talents, tree) -> Dictionary` (`src/meta/talent_bonuses.gd`): `{&"stat_x": float}` só com valor > 0, tetos já aplicados (`CAPS`). Percentuais e reduções = fração positiva somada (0,12 = 12%); `stat_pierce`, `stat_start_particles` e `stat_wave_heal` = valor aditivo. Sem `stat_coin_gain`. Vai em `MatchConfig.talent_bonuses` (`SceneFlow.build_match_config`, só com `nuclei` liberado).
- `MetaRewards.compute(..., coin_gain := 0.0)` e `MetaFlow.settle(..., today, tree := null)`: o ganho de Moeda multiplica depois do ×0,7 e antes do bônus do dia. `PlayerProfile.sanitize(tree := null)` satura níveis em 0..máx e remove ids desconhecidos (com a árvore).

### Custos × economia
Renda do mediano: ~225 Moeda × 4 partidas + 115 do bônus do dia = **~1015 por dia**. Os Componentes também gastam Moeda, então assumo **50% da renda** para Núcleos (~507/dia).

| Cenário | Moeda/dia para Núcleos | Árvore inteira (18 355) |
|---|---|---|
| Mediano, 100% da renda | 1015 | ~18 dias (~2,5 semanas) |
| **Mediano, 50% (referência)** | **507** | **~36 dias (~5 semanas)** |
| Mediano, 40% | 406 | ~45 dias (~6,5 semanas) |
| Fraco (~34/partida, 136/dia), 50% | 68 | ~270 dias: meta de longo prazo; os primeiros nós valem cedo |

- **1º talento:** o mediano chega ao NV 3 na 1ª partida (200 XP) com ~340 Moeda (225 + 115): compra a raiz (50) e ainda sobram níveis. O fraco chega ao NV 3 em ~4 partidas com ~140 Moeda e também compra. Toda raiz custa 50 no Nv 1 (teste: <= 60).
- **Raízes completas** (3 × 500 = 1500): ~3 dias do mediano a 100%. Camada 1 completa (3 × 1195): mais ~4 dias. Os capstones ficam para as semanas 4 a 6.
- **Medido (T-209):** árvore inteira no dia 34 (50%) e 17 (100%) do mediano; fraco 178 e 89 dias. Ver [economia.md](economia.md), "Simulação com Núcleos".
- Risco: a Moeda tem outros sumidouros (Componentes, M13); recalibrar quando a economia deles existir.

### Lista para o AG08 (ícones)
Cor do ramo: Ataque = vermelho/laranja; Defesa = azul; Economia = verde/dourado. Estilo de `docs/arte.md`, formas arredondadas.

| id | Conceito (1 linha) | Ramo |
|---|---|---|
| `talent_sharp_core` | cristal com ponta afiada brilhando | Ataque |
| `talent_quick_pulse` | onda de pulso com setas de velocidade | Ataque |
| `talent_arcane_burst` | explosão arcana em estrela | Ataque |
| `talent_piercing_ray` | raio atravessando dois círculos | Ataque |
| `talent_hardened_shell` | casca de cristal reforçada | Defesa |
| `talent_deflect` | escudo desviando uma seta | Defesa |
| `talent_wave_mend` | coração com onda de cura | Defesa |
| `talent_bastion` | torre de cristal | Defesa |
| `talent_particle_magnet` | ímã atraindo estrelinhas verdes | Economia |
| `talent_seed_charge` | bateria com Partículas | Economia |
| `talent_cool_mind` | relógio com floco de gelo | Economia |
| `talent_golden_core` | núcleo dourado com moeda | Economia |

### Lista de efeitos de partida para o AG01 (talento → atributo → valor)
Entram no `MatchConfig` já resolvidos pelo AG04 (o gameplay não conhece talentos).

| Talento | Atributo | Valor por nível | Teto | Obs. |
|---|---|---|---|---|
| sharp_core | `stat_damage` | +4% (ADD_PCT_BASE) | +20% | dano do projétil básico |
| quick_pulse | `stat_fire_rate` | +3% (ADD_PCT_BASE) | +15% | teto final 4,2 tiros/s |
| arcane_burst | `stat_skill_damage` | +5% (ADD_PCT_BASE) | +25% | dano dos Módulos (meteoro, pulso); **atributo novo** |
| piercing_ray | `stat_pierce` | +1 (ADD_FLAT) | 1 | soma em `ProjectileData.pierce` do tiro básico |
| hardened_shell, bastion | `stat_core_hp_max` | +4% por nível; +15% (ADD_PCT_BASE) | +35% | o HP inicial é o máximo |
| deflect | `stat_damage_taken` | −2% (REDUCTION_PCT) | −10% | com o upgrade, teto −50% |
| wave_mend | `stat_wave_heal` | +2% do HP máx (ADD_FLAT, fração) | 10% | **cura nova:** no início de cada onda, emite `core_hp_changed`; não passa do máximo |
| particle_magnet | `stat_particle_gain` | +3% (ADD_PCT_BASE) | +15% | acumular a fração entre drops (drops são inteiros pequenos); **atributo novo** |
| seed_charge | `stat_start_particles` | +3 (ADD_FLAT) | +15 | Partículas ao iniciar a partida (hoje 0); **atributo novo** |
| cool_mind | `stat_cooldown` | −2% (REDUCTION_PCT) | −10% | com o upgrade, teto −50% |
| golden_core | `stat_coin_gain` | +5% (ADD_PCT_BASE) | +15% | **só no meta** (AG04, `MetaRewards`); não vai para a partida |
