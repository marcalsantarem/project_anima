# BRF-018 — AG02 — T-113 Telas: toque para começar, pausa e resultado
**Objetivo e pronto quando:** ver T-113 em [docs/backlog.md](../backlog.md).
**Contexto:** a T-121 (tema global) e a T-122 (ligação ao SceneFlow) ainda não foram feitas. Por isso:
- Faça as telas como cenas independentes em `src/ui/screens/`, com o tema aplicado na raiz de cada uma, como no HUD.
- **Não mexa no SceneFlow:** o AG07 troca os placeholders de `src/core/placeholder/` pelas suas telas na T-122. Na entrega, informe o contrato de cada tela: sinais e métodos, como `show_result(result: MatchResult)` e `start_requested`.
- **Pausa:** ouça só o `pause_requested` do HUD, ou só a action `pause`; escolha um e documente.
  - A pausa usa `get_tree().paused` e a tela de pausa funciona com o jogo pausado.
- **Toque para começar:** é o primeiro gesto do usuário, que destrava o áudio na web. Mantenha o texto "Project: Anima / Criado por Marçal Santarem".
**Arquivos permitidos:** `src/ui/screens/`, `src/ui/hud/` (ajustes da pausa), `src/ui/demo/` e `docs/ui.md`.
**Proibido:** `project.godot`, `src/core/`, `src/match/`, `tests/` (o AG03 está trabalhando lá).
**Validação:**
- As cenas rodam headless sem erros.
- O GUT inteiro passa.
- O export Web continua funcionando.
**Entrega:** formato padrão, com no máximo 10 linhas.
