# Economia do M2: XP, Moeda e níveis (AG04, BRF-106)

> Dados em `data/meta/progression_m2.tres` e `data/meta/rewards_m2.tres` (Resources `ProgressionData` e `RewardData`, em `src/meta/`). Lógica de cálculo: T-186. **Nada depende do tempo** (decisão 59): só monstros derrotados, ondas e resultado. Partículas não entram no meta. Sem gasto de Moeda no M2 (1º gasto no M4).

## Recompensas por partida

`total = Σ(kills × valor do tipo) + ondas concluídas × bônus de onda (+ bônus de vitória)`; na **derrota** o total é multiplicado por `defeat_multiplier` = 0,8 (paga menos, mas paga). Arredondar para inteiro.

| Fonte | XP | Moeda |
|---|---|---|
| runner | 2 | 1 |
| swarm (por membro) | 1 | 1 |
| shooter | 4 | 3 |
| tank | 6 | 4 |
| chefe (boss_warden) | 60 | 40 |
| onda concluída | 5 | 3 |
| bônus de vitória | 40 | 50 |

A "variação por partida" da Moeda vem do desempenho (quantos monstros e ondas), sem sorteio.

## Curva de XP (nível N para N+1)

| N→N+1 | 1→2 | 2→3 | 3→4 | 4→5 | 5→6 | 6→7 | 7→8 | 8→9 | 9→10 | 10→11 | 11→12 | 12→13 | 13→14 | 14→15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| XP | 40 | 60 | 120 | 190 | 300 | 520 | 700 | 850 | 1000 | 1100 | 1250 | 1400 | 1550 | 1700 |
| Acumulado | 40 | 100 | 220 | 410 | 710 | 1230 | 1930 | 2780 | 3780 | 4880 | 6130 | 7530 | 9080 | 10780 |

Slots: nível 3, 7 e 12 (`slot_unlock_levels`). Nível máximo no M2: 15.

## O que uma partida rende (fase 1, calculado de `stage_01.tres`)

Fase 1 inteira: 92 runners, ~98 membros de swarm (15 grupos × 6,5), 7 shooters, 10 tanks, 1 chefe.

| Partida | XP | Moeda |
|---|---|---|
| Derrota na onda 3 (ondas 1 e 2 concluídas, onda 3 toda morta) | ~52 | ~29 |
| Derrota na onda 6 (~metade do XP da fase) | ~190 | ~120 |
| Vitória (10 ondas + chefe) | ~520 | ~371 |

Vitória: kills 430 XP / 291 Moeda + ondas 50 / 30 + bônus 40 / 50.

## Metas de partidas por nível

Premissa de jogador: partidas 1–2 caem na onda ~3; 3–8 chegam à onda 6–9 (média ~200 XP); da 9 em diante ~70% de vitórias (média ~450 XP).

| Marco | Acumulado | Partidas |
|---|---|---|
| Nível 3 (slot 1) | 100 | ~2 |
| Nível 7 (slot 2) | 1230 | ~8 (104 + 6×200 = 1304) |
| Nível 12 (slot 3) | 6130 | ~19–20 (1304 + 11×450 ≈ 6250) |
| Nível 15 | 10780 | ~30 |

Justificativa: a proposta do briefing (2, 8, 20) se manteve; o slot 1 chega rápido para o jogador ter a primeira skill ainda na primeira sessão, e o ritmo desacelera conforme a vitória se torna comum. O dono pode mexer só nos números do `.tres`.

## Perguntas em aberto para o dono

1. Bônus de primeira vitória de cada fase (XP/Moeda extra)? Sugestão: +100 XP, +100 Moeda.
2. Multiplicador de anúncio (rewarded ad dobra a Moeda): fica para o M12+; confirmar x2 e se vale para XP.
3. A derrota deve pagar 80% ou outro percentual? E o chefe derrotado numa derrota (não ocorre hoje) conta?
4. Fases futuras: escalar os valores por fase ou manter o mesmo peso por tipo de monstro?
5. Aceita a progressão de nível passar de ~30 partidas até o 15 no M2, ou prefere teto menor?
