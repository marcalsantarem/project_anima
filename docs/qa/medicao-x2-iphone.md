# Medição do x2 no iPhone (T-276, BRF-135)

Objetivo: saber se o x2 aguenta no iPhone com carga (referência: 46,9 fps com 150 inimigos em x1, T-007).

## Como medir
1. Abra no iPhone (Safari) o link de teste + `?debug=1&stress=150,300&speed=1&tag=iphone11-safari-x1-150`. A `tag` é livre (até 64 caracteres, sem espaços): use uma por rodada, ex. `iphone11-app-x2-300`; ela identifica o ensaio no banco. A partida roda 60 s sozinha (Núcleo imortal) e abre o Resultado.
2. Repita com `&speed=2`, e depois com `stress=300,300`. Ordem: x1 150, x2 150, x1 300, x2 300.
3. Repita tudo no modo app (tela de início / PWA). Use o mesmo link e feche o app entre medições. Deixe o aparelho carregado e frio (sem modo de baixo consumo).
4. Em cada medição, no Resultado toque em **Enviar log** e espere "Enviado ✔". **Não há mais visualizador**: cada rodada precisa ser **enviada**, uma por vez (limite de 20 envios por hora por rede). Os números saem do banco (consultas em `docs/logs-api.md`); o `resumo` do log traz tag, fps médio, p95 e resultado.
5. No modo app (PWA), a `tag` só vale se o link salvo na tela de início já tiver o `?tag=`: ajuste o link antes de adicioná-lo.
- `speed` só vale com `?debug=1` e **não** altera a velocidade salva do jogo.

## Antes de medir: Modo de Pouca Energia (iPhone)
As partidas reais no iPhone rodaram a ~30 fps (PC: ~60) com quadros presos em 33 ms: suspeita de **Modo de Pouca Energia** (iOS limita o `requestAnimationFrame` a 30 Hz). O Safari não expõe esse modo, então o log infere pela cadência: `header.env.raf_hz_inicio` (início) e `web_end.raf_hz_fim` (fim), mais `suspeita_30fps_cap` (true se ~30 Hz ±4 com `Engine.max_fps == 0`). A linha de cadência do `resumo` mostra `cadência rAF: 30 Hz (possível Pouca Energia)` ou `60 Hz`. **Se aparecer 30 Hz, desligue o Modo de Pouca Energia (Ajustes > Bateria) e repita a rodada**: o fps medido não vale para decidir o x2. O log traz também `por_velocidade` (fps de x1 e x2 separados) e a velocidade real (`velocidade_inicial`).

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
