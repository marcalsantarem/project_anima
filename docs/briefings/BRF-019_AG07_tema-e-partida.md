# BRF-019 — AG07 — T-121 Tema global + T-122 Partida real no SceneFlow
**Objetivo e pronto quando:** ver T-121 e T-122 em [docs/backlog.md](../backlog.md). Faça nesta ordem. O objetivo é **o jogo publicado no link da dev ser jogável**: título → partida real com HUD e pausa → resultado → título.
**Contexto:**
- **Tema:** na seção `[gui]`, use `theme/custom="res://src/ui/theme/anima_theme.tres"`.
- **Contrato de montagem:** está em [docs/ui.md](../ui.md) §10c, e o exemplo pronto é `src/ui/demo/screens_demo.gd`.
  - O `bind` do HUD e da pausa vem antes de a arena entrar na árvore.
  - `restart_requested` liga em `start_match`.
- **Placeholders:** troque os de `src/core/placeholder/` pelas telas reais de `src/ui/screens/` e aponte `DEFAULT_MATCH_SCENE` para a arena real.
  - Se os placeholders ficarem sem uso, apague-os.
- Atualize `tests/integration/test_match_flow.gd` se o fluxo mudar.
**Arquivos permitidos:** `project.godot`, `src/core/`, `docs/arquitetura.md`, `tests/integration/test_match_flow.gd`.
**Proibido:** `src/match/`, `src/ui/`. Se precisar de algo lá, informe na entrega.
**Validação:**
- O projeto abre headless sem erros.
- O GUT inteiro passa.
- O export Web funciona, e a main_scene leva ao fluxo completo.
**Entrega:** formato padrão, com no máximo 10 linhas.
