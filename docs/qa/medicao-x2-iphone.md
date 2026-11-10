# Medição do x2 no iPhone (T-276, BRF-135)

Objetivo: saber se o x2 aguenta no iPhone com carga (referência: 46,9 fps com 150 inimigos em x1, T-007).

## Como medir
1. Abra no iPhone (Safari) o link de teste + `?debug=1&stress=150,300&speed=1`. A partida roda 60 s sozinha (Núcleo imortal) e abre o Resultado.
2. Repita com `&speed=2`, e depois com `stress=300,300`. Ordem: x1 150, x2 150, x1 300, x2 300.
3. Repita tudo no modo app (tela de início / PWA). Use o mesmo link e feche o app entre medições. Deixe o aparelho carregado e frio (sem modo de baixo consumo).
4. Em cada medição, no Resultado abra o log e copie a linha `ESTRESSE ... speed=2` (traz fps médio, mín, p95 em ms, quadros >50 ms). Mande o log ou a linha.
- `speed` só vale com `?debug=1` e **não** altera a velocidade salva do jogo.

## Anotar
fps médio · fps mínimo · p95 do quadro (ms) · quadros >50 ms. Se o jogo "andar mais devagar que x2" (câmera lenta sob carga), anote.

## Tabela

| Modo | Inimigos | Vel. | fps médio | fps mín | p95 (ms) | quadros >50 ms | Obs. |
|---|---|---|---|---|---|---|---|
| Safari | 150 | x1 | | | | | |
| Safari | 150 | x2 | | | | | |
| Safari | 300 | x1 | | | | | |
| Safari | 300 | x2 | | | | | |
| App | 150 | x1 | | | | | |
| App | 150 | x2 | | | | | |
| App | 300 | x1 | | | | | |
| App | 300 | x2 | | | | | |

Critério sugerido: x2 com 150 inimigos mantendo fps médio >= 40 e p95 <= 33 ms. Abaixo disso, considerar limitar `max_physics_steps_per_frame` ou travar o x2 no aparelho (`can_use_speed`).

## Referência do PC (relativa, NÃO é o iPhone)
Godot headless (sem render), `tests/tools/measure_stress.gd`, 13 s, 300 projéteis. Carga = CPU de lógica+física por segundo real (1,0 = um núcleo).

| Inimigos | Vel. | Carga | ms CPU/passo | p95 quadro (ms) |
|---|---|---|---|---|
| 150 | x1 | 0,41 | 6,8 | 3,0 |
| 150 | x2 | 0,48 | 8,0 | 3,7 |
| 300 | x1 | 0,56 | 9,3 | 4,5 |
| 300 | x2 | 0,70 | 11,6 | 6,9 |

Leitura: x2 não dobra o custo (60 passos/s nos dois), custa +17% (150) a +25% (300) por passo (inclui a forma extra anti-túnel dos projéteis). Comando: `godot --headless --path . -s tests/tools/measure_stress.gd -- --enemies=150 --projectiles=300 --speed=2 --seconds=13`.
