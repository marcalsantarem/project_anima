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
| 2→3 | 100 | 150 |
| 3→4 | 130 | 280 |
| 4→5 | 170 | 450 |
| 5→6 | 220 | 670 |
| 6→7 | 280 | 950 |
| 7→8 | 320 | 1270 |
| 8→9 | 360 | 1630 |
| 9→10 | 410 | 2040 |
| 10→11 | 460 | 2500 |
| 11→12 | 500 | 3000 |
| 12→13 | 560 | 3560 |
| 13→14 | 600 | 4160 |
| 14→15 | 640 | 4800 |
| 15→16 | 680 | 5480 |
| 16→17 | 720 | 6200 |
| 17→18 | 760 | 6960 |
| 18→19 | 800 | 7760 |
| 19→20 | 840 | 8600 |
| 20→21 | 900 | 9500 |
| 21→22 | 950 | 10450 |
| 22→23 | 1000 | 11450 |
| 23→24 | 1040 | 12490 |
| 24→25 | 1090 | 13580 |
| 25→26 | 1140 | 14720 |
| 26→27 | 1190 | 15910 |
| 27→28 | 1240 | 17150 |
| 28→29 | 1290 | 18440 |
| 29→30 | 1340 | 19780 |

Slots: nível 3, 7 e 12 (`slot_unlock_levels`).

## Metas de partidas por nível

Modelo de XP médio por partida: P1 a P4 = derrotas nas ondas 3, 4, 6 e 7 (19, 31, 58, 75; acumulado 183); P5 a P20 ~120 (derrotas nas ondas 8 e 9 e as primeiras vitórias, com bônus do dia); P21 em diante ~160 (~55% de vitórias de 195, resto derrotas ~100, mais o bônus diário diluído).

| Marco | Acumulado | Partidas |
|---|---|---|
| Nível 3 (slot 1) | 150 | **4** (3 derrotas somam 108, a 4ª passa de 150; com a 1ª vitória na 4ª também) |
| Nível 7 (slot 2) | 950 | ~11 |
| Nível 12 (slot 3) | 3000 | ~26 |
| Nível 20 | 8600 | ~61 |
| Nível 30 | 19780 | ~131 |

**Justificativa do nível 30:** 131 partidas a 3 a 5 por dia = 26 a 44 dias (~4 a 6 semanas, 4/dia ≈ 33 dias). Slot 1 na primeira sessão de ~4 partidas; slot 2 em 2 a 3 dias; slot 3 em ~1 semana; depois o ritmo desacelera. Só os números do `.tres` precisam mudar para reajustar.

## Perguntas em aberto para o dono

1. Fases futuras: escalar os valores por fase ou manter o mesmo peso por tipo de monstro?
2. O bônus diário deve valer também em fases já vencidas, ou só em qualquer vitória (como está)?

> Multiplicador de anúncio (rewarded ad): fora do escopo agora; nota M12+.
