# BRF-016 — AG02 — T-112 HUD ligado aos sinais
**Objetivo e pronto quando:** ver T-112 em [docs/backlog.md](../backlog.md).
**Contexto:**
- Sinais e slots seguem [docs/gameplay.md](../gameplay.md); a arena é `res://src/match/arena/arena.tscn`.
- Para os toques, use o método público da arena que aciona a skill por slot (T-108).
- Use os componentes da T-106. **O tema global ainda não está no `project.godot` (T-121):** aplique o `anima_theme.tres` na raiz do HUD.
- **Pausa:** o botão só emite um pedido de pausa, pelo sinal ou pela action `pause`. A tela de pausa é da T-113.
- O HUD não conhece nós internos da arena: ele recebe a arena por um método `bind(arena)` e só escuta os sinais.
- Crie uma cena de teste em `src/ui/demo/` com a arena e o HUD juntos. A ligação ao SceneFlow é da T-122.
**Arquivos permitidos:** `src/ui/hud/`, `src/ui/demo/`, `src/ui/components/` (ajustes) e `docs/ui.md`.
**Proibido:** `project.godot`, `src/core/`, `src/match/`.
**Validação:**
- A cena de teste roda headless sem erros.
- O GUT inteiro passa.
- O export Web continua funcionando.
**Entrega:** formato padrão, com no máximo 10 linhas.
