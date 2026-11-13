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

## Custos dos Núcleos (T-203, BRF-151)

Árvore de 12 talentos, **18 355 Moeda** no total (tabela em [meta.md](meta.md), "Núcleos (talentos)"). Com ~1015 Moeda/dia do mediano e 50% da renda para Núcleos (o resto para Componentes): ~36 dias (~5 semanas); com 100%: ~18 dias. As raízes custam 50 Moeda no Nv 1 (compra na 1ª partida após o NV 3).

## Simulação com Núcleos (T-209, BRF-157)

Ferramenta: `tests/tools/run_talents.gd` (bot x1, seeds 1 a 100, mesmos perfis de `run_progression.gd`; bônus via `MatchConfig.talent_bonuses`, `stat_coin_gain` via `MetaRewards`). Modos: `--mode=bench --states=none,first,p25,p50,p100` (estados fixos) e `--mode=campaign --share=0.5|1.0 --per-day=4` (joga em sequência, compra e mede os dias).

**Política do bot:** reserva `share` da Moeda de cada partida (50% referência, o resto iria para Componentes; variante 100%) e compra, enquanto der, o próximo nível **mais barato** disponível; empate = alterna ramos (Ataque → Defesa → Economia). A ordem só depende da Moeda: raízes, camada 1, camada 2, Núcleo Dourado e por fim os capstones. Marcos = prefixo da ordem até gastar 25% (4 635), 50% (9 435) e 100% (18 355) da árvore.

| Perfil | Estado | Vitórias | Onda média da derrota | Duração média (mín.) | XP/partida | Moeda/partida |
|---|---|---|---|---|---|---|
| Mediano | sem Núcleos | 100% | — | 221 s (210) | 189 | 225 |
| Mediano | 1º talento (Núcleo Afiado Nv 1) | 100% | — | 218 s (208) | 189 | 226 |
| Mediano | 25% | 100% | — | 207 s (198) | 194 | 231 |
| Mediano | 50% | 100% | — | 205 s (197) | 195 | 243 |
| Mediano | 100% | 100% | — | 200 s (193) | 195 | 267 |
| Fraco | sem Núcleos | 0% | 5,0 | 87 s (65) | 34 | 34 |
| Fraco | 1º talento | 0% | 5,0 | 87 s (65) | 34 | 34 |
| Fraco | 25% | 0% | 6,1 | 115 s (80) | 50 | 51 |
| Fraco | 50% | 0% | 6,2 | 117 s (80) | 51 | 54 |
| Fraco | 100% | 0% | 7,5 | 149 s (103) | 77 | 93 |

Medido com o Nv 1 antigo das raízes (+4%); com o Nv 1 novo (+8%) o 1º talento dá o mesmo resultado no bot (mediano 218 s; fraco 5,0 a 5,1). Os marcos de 25% em diante têm as raízes no máximo, que não mudou.

**Dias até a árvore (campanha, 4 partidas/dia, bônus do dia):**

| Perfil | Share | 1º talento | 25% | 50% | 100% |
|---|---|---|---|---|---|
| Mediano | 50% | partida 1 (NV 3) | dia 9 | dia 19 | **dia 34** (NV 30) |
| Mediano | 100% | partida 1 | dia 5 | dia 10 | dia 17 (NV 20) |
| Fraco | 50% | partida 6 (dia 2) | dia 56 | dia 104 | dia 178 |
| Fraco | 100% | partida 6 | dia 28 | dia 52 | dia 89 |

**Avaliação:**
- **Fase 1 não fica trivial:** com a árvore inteira o mediano termina em ~200 s (mín. 193 s), acima dos 3 min. A duração quase não cai porque o ritmo é das ondas, não do dano.
- **Fraco não fica travado:** a árvore leva a queda da onda 5 para a 7,5 e a renda de 34 para 93 Moeda por partida (×2,7), mas ele **nunca vence** (passivo com 15% do HP é o piso artificial). As vitórias dele dependem de skills e upgrades, não dos Núcleos.
- **1º talento:** 50 Moeda (0,3% da árvore) não muda métrica de bot em nenhum perfil. Para ficar perceptível no número mostrado, as 3 raízes passaram a ter o **Nv 1 dobrado** (o máximo não mudou).
- Custos confirmados: os ~36/18 dias estimados no T-203 deram 34/17 na simulação. **Custos sem mudança.**

**Ajustes (só `data/talents/`):** `talent_sharp_core` e `talent_hardened_shell` 4·8·12·16·20% → **8·11·14·17·20%**; `talent_particle_magnet` 3·6·9·12·15% → **6·8·10·13·15%**. Total da árvore continua 18 355.

**Riscos:** as descrições `TALENT_*_DESC` das 3 raízes ("4% por nível", "3% por nível") ficaram desatualizadas (`data/i18n/`, fora do escopo do AG04). O bot mediano vence sempre, então os Núcleos não mudam a taxa de vitória dele; o efeito no jogador real (que perde) fica entre os dois perfis.
