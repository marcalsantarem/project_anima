# Economia do M2: XP, Moeda e níveis (AG04, BRF-106 e BRF-108)

> Dados em `data/meta/progression_m2.tres` e `data/meta/rewards_m2.tres` (Resources `ProgressionData` e `RewardData`, em `src/meta/`). Lógica de cálculo: T-186. **Nada depende do tempo** (decisão 59). Partículas não entram no meta. Sem gasto de Moeda no M2 (1º gasto no M4).

## Recompensas por partida

**XP e Moeda vêm só dos monstros derrotados** (chefe incluso). Sem bônus por onda nem de vitória.
`total = round(Σ kills × valor do tipo)`; na **derrota** o total é multiplicado por `defeat_multiplier` = **0,7**. Arredondar só no total (valores por monstro podem ser fracionários).

| Monstro | XP | Moeda |
|---|---|---|
| runner | 1 | 1 |
| swarm (por membro) | 0,5 | 0,5 |
| shooter | 2 | 3 |
| tank | 2 | 3 |
| chefe (boss_warden) | 20 | 40 |

Fase 1 inteira (92 runners, ~98 membros de swarm, 7 shooters, 10 tanks, 1 chefe): **~195 XP / ~232 Moeda**.

| Partida (fase 1) | XP | Moeda |
|---|---|---|
| Derrota na onda 3 (ondas 1 a 3 mortas: 27 / 27 bruto) | ~19 | ~19 |
| Derrota na onda 6 (ondas 1 a 6 mortas: 83 / 86 bruto) | ~58 | ~60 |
| Vitória (10 ondas + chefe) | ~195 | ~232 |
| Vitória com bônus do dia | ~295 | ~347 |

## Bônus da primeira vitória do dia

- **Valor:** +100 XP e +115 Moeda (~50% da recompensa de uma vitória completa). Pago só em **vitória** (chefe derrotado), uma vez por dia, somado ao total (não sofre multiplicador).
- **Dia:** data **local** do aparelho em `YYYY-MM-DD`. Vira à meia-noite local.
- **Campo:** `PlayerProfile.last_first_win_date: String`, vazio = nunca. Paga se `hoje != last_first_win_date`; depois grava `hoje`. Entra na T-186 (campo e lógica).
- **Risco (sem defesa agora):** o save e o relógio são manipuláveis. Adiantar/atrasar o relógio ou editar o save repete o bônus (ganho limitado a +100 XP e +115 Moeda por repetição). Relógio atrasado para uma data anterior ao `last_first_win_date` não deve pagar (regra: pagar só se `hoje > last_first_win_date`). Defesa real exige data do servidor (backend, depois).

## Curva de XP (nível N para N+1, teto 30; revista no BRF-132 / T-195)

Custo por nível crescente, sem queda. Os degraus 4 a 7 são iguais (500) para manter a curva monotônica.

| N→N+1 | XP para subir | Acumulado |
|---|---|---|
| 1→2 | 50 | 50 |
| 2→3 | 150 | 200 |
| 3→4 | 300 | 500 |
| 4→5 | 500 | 1000 |
| 5→6 | 500 | 1500 |
| 6→7 | 500 | 2000 |
| 7→8 | 500 | 2500 |
| 8→9 | 700 | 3200 |
| 9→10 | 750 | 3950 |
| 10→11 | 800 | 4750 |
| 11→12 | 850 | 5600 |
| 12→13 | 900 | 6500 |
| 13→14 | 950 | 7450 |
| 14→15 | 1000 | 8450 |
| 15→16 | 1050 | 9500 |
| 16→17 | 1100 | 10600 |
| 17→18 | 1150 | 11750 |
| 18→19 | 1200 | 12950 |
| 19→20 | 1250 | 14200 |
| 20→21 | 1300 | 15500 |
| 21→22 | 1350 | 16850 |
| 22→23 | 1400 | 18250 |
| 23→24 | 1450 | 19700 |
| 24→25 | 1500 | 21200 |
| 25→26 | 1550 | 22750 |
| 26→27 | 1600 | 24350 |
| 27→28 | 1650 | 26000 |
| 28→29 | 1700 | 27700 |
| 29→30 | 1750 | 29450 |

Slots: nível **2, 5 e 8** (`slot_unlock_levels`, decisão 63). Demais desbloqueios (`feature_unlock_levels`, só dado): Núcleos 3, Componentes 4, botão x2 6, fusão de Componentes 7; helper `ProgressionData.is_unlocked(feature, level)`.

## Simulação de progressão (BRF-132, T-195)

Substitui o modelo de XP estimado. Ferramenta: `tests/tools/run_progression.gd` (bot em x1, seeds 1 a 100 por perfil, rewards de `rewards_m2.tres`, derrota x0,7, 1ª vitória do dia, 20 ordens circulares das seeds para a média). Comando: `godot --headless --path . --fixed-fps 60 -s tests/tools/run_progression.gd -- --seeds=100 --per-day=4`.

**Perfis:** *mediano* = bot atual (vence 100% das partidas; ~189 XP e ~225 Moeda por partida, sem o bônus do dia). *Fraco* = bot passivo (sem skill nem upgrades) com Núcleo a 15% do HP, só nesta ferramenta; perde nas ondas 4 a 6 (75% na 5) e rende ~34 XP e ~34 Moeda por partida. O passivo sem handicap cai nas ondas 7 e 8 (~64 XP).

Partidas até cada nível (4 partidas por dia; com 5 por dia muda <= 3 partidas, ex.: N30 = 141):

| Nível | Alvo (dec. 63) | Mediano antes | Mediano depois | Fraco antes | Fraco depois |
|---|---|---|---|---|---|
| 2 | 1 a 2 | 1 | **1** | 1 | **2** |
| 5 | 4 a 6 (1ª sessão) | 2 | **5** | 5 | 30 |
| 8 | 10 a 14 (2 a 3 dias) | 4 | **12** | 14 | 74 |
| 12 | ref. | 13 | 26 | 41 | 165 |
| 20 | ref. | 39 | 67 | 129 | 418 |
| 30 | 4 a 6 semanas | 91 (23 dias) | **138 (~35 dias)** | 305 | 866 |

*Antes* = curva antiga (N5 = 300, N8 = 850, N30 = 19360 XP); o "fraco antes" foi medido com o passivo sem handicap (cai nas ondas 7 e 8, ~64 XP), então não é comparável: o fraco "depois" é mais fraco por definição.

**Ajuste:** só `progression_m2.tres` (curva); `rewards_m2.tres` não mudou. O modelo antigo subestimava o XP do bot (~120 a 160 por partida contra ~189 reais), então os níveis vinham cedo demais. Nova curva: acumulado 50 / 200 / 500 / 1000 (N5) / 1500 / 2000 / 2500 (N8) / 29450 (N30). Nível 2 continua na 1ª partida do mediano e na 2ª do fraco; N5 na 1ª sessão (5 partidas); N8 em 3 dias; N30 em ~5 semanas.

**Risco:** o jogador fraco simulado leva ~30 partidas até o N5 (7 dias) e 74 até o N8: para ele a curva é lenta. O bot mediano vence sempre, então o mediano real (que perde parte das partidas) fica entre os dois perfis. Alavancas se o dono quiser acelerar o fraco sem mexer no mediano: subir `defeat_multiplier` (0,7) ou o XP por monstro das ondas 3 a 6 (runner/swarm/shooter).
