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

## Curva de XP (nível N para N+1, teto 30)

Custo por nível crescente, sem degraus (passo de +30 a +60 por nível).

| N→N+1 | XP para subir | Acumulado |
|---|---|---|
| 1→2 | 50 | 50 |
| 2→3 | 70 | 120 |
| 3→4 | 80 | 200 |
| 4→5 | 100 | 300 |
| 5→6 | 140 | 440 |
| 6→7 | 180 | 620 |
| 7→8 | 230 | 850 |
| 8→9 | 360 | 1210 |
| 9→10 | 410 | 1620 |
| 10→11 | 460 | 2080 |
| 11→12 | 500 | 2580 |
| 12→13 | 560 | 3140 |
| 13→14 | 600 | 3740 |
| 14→15 | 640 | 4380 |
| 15→16 | 680 | 5060 |
| 16→17 | 720 | 5780 |
| 17→18 | 760 | 6540 |
| 18→19 | 800 | 7340 |
| 19→20 | 840 | 8180 |
| 20→21 | 900 | 9080 |
| 21→22 | 950 | 10030 |
| 22→23 | 1000 | 11030 |
| 23→24 | 1040 | 12070 |
| 24→25 | 1090 | 13160 |
| 25→26 | 1140 | 14300 |
| 26→27 | 1190 | 15490 |
| 27→28 | 1240 | 16730 |
| 28→29 | 1290 | 18020 |
| 29→30 | 1340 | 19360 |

Slots: nível **2, 5 e 8** (`slot_unlock_levels`, decisão 63). Demais desbloqueios (`feature_unlock_levels`, só dado): Núcleos 3, Componentes 4, botão x2 6, fusão de Componentes 7; helper `ProgressionData.is_unlocked(feature, level)`.

## Metas de partidas por nível

Modelo de XP médio por partida: P1 a P4 = derrotas nas ondas 3, 4, 6 e 7 (19, 31, 58, 75; acumulado 183); P5 a P20 ~120 (derrotas nas ondas 8 e 9 e as primeiras vitórias, com bônus do dia); P21 em diante ~160 (~55% de vitórias de 195, resto derrotas ~100, mais o bônus diário diluído).

| Marco | Acumulado | Partidas |
|---|---|---|
| Nível 2 (slot 1) | 50 | **2** (P1 = 19, P2 = 31: soma exata 50) |
| Nível 3 (Núcleos) | 120 | 3 |
| Nível 4 (Componentes) | 200 | 4 |
| Nível 5 (slot 2) | 300 | **5** (P4 acumula 183, P5 ~120) |
| Nível 6 (x2) | 440 | 6 |
| Nível 7 (fusão) | 620 | 8 |
| Nível 8 (slot 3) | 850 | **~10** (2 a 3 dias a 4/dia) |
| Nível 20 | 8180 | ~58 |
| Nível 30 | 19360 | ~128 |

**Justificativa do nível 30:** 128 partidas a 3 a 5 por dia = 26 a 43 dias (~4 a 6 semanas, 4/dia ≈ 32 dias), pois a curva dos níveis 2 a 8 foi suavizada (degraus 70, 80, 100, 140, 180, 230; total -420 XP; do nível 9 em diante igual). Slot 1 na 2ª partida; slot 2 na 1ª sessão (5 partidas); slot 3 em 2 a 3 dias; depois o ritmo desacelera. Só os números do `.tres` precisam mudar para reajustar.

## Perguntas em aberto para o dono

1. Fases futuras: escalar os valores por fase ou manter o mesmo peso por tipo de monstro?
2. O bônus diário deve valer também em fases já vencidas, ou só em qualquer vitória (como está)?

> Multiplicador de anúncio (rewarded ad): fora do escopo agora; nota M12+.
