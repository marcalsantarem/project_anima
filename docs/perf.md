# Medições de desempenho (T-006)

Cena de estresse: `tests/perf/stress.tscn` (sem lógica de jogo; sprites reais de inimigo + projéteis). O overlay mostra FPS atual/médio/mínimo e as contagens (médio e mínimo contam após 2 s de aquecimento).

## Como gerar e abrir
1. `bash tests/perf/export_perf.sh` gera `build/perf/` (preset "Web Perf", `.pck` de ~1 MB). Exporta de uma cópia temporária do projeto, então `project.godot` e o build do jogo não são tocados.
2. Servir a pasta: `cd build/perf && python -m http.server 8765` e abrir `http://localhost:8765/index.html`.
3. Parâmetros: `?enemies=150&projectiles=300` (padrão 150/300). `&seconds=15` loga `PERF_RESULT ...` no console (automação).

## Passo a passo no iPhone (dono)
1. No PC: gerar o build (passo 1) e servir na rede local: `python -m http.server 8765 --bind 0.0.0.0` dentro de `build/perf`. (Alternativa: subir `build/perf` num site Netlify de teste separado, nunca no site do jogo.)
2. iPhone no mesmo Wi-Fi: Safari em `http://<IP-do-PC>:8765/index.html` (IP via `ipconfig`).
3. Deixar rodar ~30 s com o aparelho parado e anotar FPS médio e mínimo do overlay. Repetir com `?enemies=300&projectiles=600` para ver a margem.
4. Registrar na tabela abaixo: aparelho, iOS, contagens, fps médio/mín.

## Resultados
| Data | Aparelho | Navegador | Inimigos / projéteis | FPS médio | FPS mín | Obs. |
|---|---|---|---|---|---|---|
| 2026-11-06 | PC Windows 11 | Chrome headless, render por software (SwiftShader), 15 s | 150 / 300 | 59,9 | 52,1 | sem GPU real |
| 2026-11-06 | PC Windows 11 | Chrome headless, SwiftShader, 12 s | 300 / 600 | 34,3 | 26,4 | dobro da meta |
| 2026-11-06 | iPhone (Safari, aba; modelo a anotar) | Safari, build `e30ca1c` v0.1.0-demo, `?debug=1&stress=150,300` | 150 inimigos, 1 a 36 proj. em voo, fx 17 | 29,3 (34 ms; máx 55) | n/d (51 quadros > 50 ms) | **INVÁLIDA: Modo de Pouca Energia ligado (limite de 30 fps do iOS)**; log id 8. Overlay: draw 592, nós 3334, viewport 375x616 (dpr a conferir). Dono, captura de tela |
| 2026-11-06 | iPhone 11 Pro 256 GB (iOS 18.7, Safari), sem Modo de Pouca Energia | Safari, build `f54fc3d`, `?debug=1&stress=150,300`, 60 s | 150 inimigos, até 52 proj. em voo, fx até 44 | **44,2** (p95 27 ms; começa em ~52 e cai para ~43 conforme o draw sobe de 509 para ~690) | 40,1 (1 quadro > 50 ms) | **abaixo da meta de 50**, mas perto. dpr 3, draw 509→691, nós ~3300. O stress pedia 300 proj., só chegaram a 52 em voo. Dono, log enviado |

Limite: o PC mediu com render por software (sem GPU), então vale como piso; o dado que decide a meta é o do iPhone.

## Rodada 2 (BRF-091, T-118)
- Barra de vida dos inimigos comuns fica escondida (sem desenhar) com vida cheia; aparece ao primeiro dano e some ao reciclar. Esperado: -1 draw call por inimigo intacto (~150 no pico do estresse). Chefe inalterado.
- Sombra + corpo: mantidos separados (a sombra é `draw_circle` com z -1, já agrupada entre todos os inimigos; fundir exigiria atlas novo). Sem outros ganhos justificados sem perfil de GPU.
- Estresse: o projétil do estresse agora atravessa inimigos (`pierce` 1000, dano 0) e tem alcance sorteado (900 a 1400 px), para manter ~M projéteis em voo (antes sumiam ao tocar um inimigo: pico 52).
- Log: linha do tempo arredonda o tempo todo (`45.96` vira `00:46.0`); `canvas` do bloco ESTRESSE agora é [largura, altura] (largura da janela interna; o shell só informava topo/base/altura).
- Draw calls antes/depois no PC: não medidos (sem GPU/overlay nesta sessão). Medir no iPhone com a mesma URL.
