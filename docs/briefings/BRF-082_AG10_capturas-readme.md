# BRF-082 — AG10 (Plataforma) — Capturas novas do README
**Contexto:** as imagens de `docs/img/` estão desatualizadas: o título ainda é o cartoon (hoje é o visual tecnológico da T-179) e o chefe ainda aparece com a barra de defesa (removida na T-166).
**Fazer:** substitua, com o **jogo real** renderizado (não mockup) em 720×1474 (retrato do iPhone do dono), PNG ≤ ~400 KB cada:
- `docs/img/splash.png`: a arte da splash tecnológica (`assets/splash/tech/`), com "PROJECT: ANIMA".
- `docs/img/titulo.png`: tela de título atual (logo do estúdio, versão, "Toque para começar").
- `docs/img/partida.png`: partida no meio de uma onda com horda, Partículas e a fileira de upgrades; de preferência com a prévia de mira do meteoro ou o meteoro caindo.
- `docs/img/chefe-ogro.png`: luta contra o ogro com a barra "Boss" no topo; se der, ele atordoado após o meteoro. Pode ser 1 captura ou até 3 lado a lado (largura ≤ 1200).
Use seed fixa e um script temporário de captura (janela com renderização, não `--headless`; ex.: `get_viewport().get_texture().get_image().save_png()`). Apague o script ao final ou deixe em `tests/tools/` só se for reaproveitável. Mantenha os nomes dos arquivos (o README já aponta para eles).
**Arquivos permitidos:** `docs/img/`, `tests/tools/` (script de captura). **Proibido:** `src/`, `assets/`, `data/`, `project.godot`, `README.md`.
**Validação:** abra cada PNG e confira que mostra o estado descrito; `--import` e GUT completo passando.
**Entrega:** no máximo 8 linhas (entregue · tamanho dos arquivos · o que cada imagem mostra · não testado).
