# BRF-091 — AG01 — T-118 rodada 2: reduzir draw calls + correções do log
**Leia:** `docs/agentes/AG01_gameplay.md`, `docs/perf.md` (medições), `docs/gameplay.md` (Limites de desempenho). **Regra:** respostas curtas; sem commit/push/branches.
**Medição de referência (iPhone 11 Pro, Safari, `?debug=1&stress=150,300`, 60 s, sem Modo de Pouca Energia):** 44,2 fps médio, mín 40,1, p95 27 ms; draw calls 509 → 691 conforme projéteis/efeitos sobem; nós ~3300. Meta: ≥ 50 fps. Tempo por quadro acompanha o nº de draw calls.
**Fazer (nesta ordem, medindo draw calls no PC com o overlay após cada passo):**
1. **Barra de vida:** esconder (não só deixar invisível: sem desenhar) enquanto o inimigo está com vida cheia; mostrar ao primeiro dano. Chefe pode continuar sempre visível.
2. **Sombra + corpo:** reduzir a um desenho só por inimigo se possível (sombra no próprio sprite/atlas ou compartilhada), sem mudar a aparência.
3. Procure outros ganhos baratos de draw calls (projéteis e efeitos com atlas/material compartilhado, evitar `modulate` por instância que quebra o batching, `z_index`/ordem que intercalam texturas). Só faça o que o perfil justificar; registre antes/depois.
4. **Modo de estresse:** faça os projéteis em voo chegarem ao alvo `M` (hoje o pico foi 52 com `stress=150,300`): mantenha M projéteis (inimigos/Anima) vivos de verdade.
5. **Correções do log:** (a) a linha do tempo arredonda o tempo errado (ex.: `00:45.0` aparece depois de `00:45.9`; devia ser `00:46.0`; veja `src/debug/log_report.gd`/formatação de tempo); (b) no bloco ESTRESSE o `canvas` vem `[0.0, 616.0, 616.0]` com largura zero; corrija a leitura do tamanho do canvas.
**Aparência e jogabilidade não mudam.** Testes GUT dos itens 1, 4 e 5; GUT completo passando (rode em segundo plano, leva ~4 min).
**Arquivos permitidos:** `src/match/`, `src/debug/`, `tests/unit/`, `assets/` só se preciso para atlas (avise), `docs/gameplay.md`, `docs/perf.md`. **Proibido:** `src/ui/`, `web/`, `netlify/`, `project.godot`.
**Entrega:** até 6 linhas: draw calls antes/depois no PC, o que mudou, testes, o que o dono deve medir no iPhone (a mesma URL).
