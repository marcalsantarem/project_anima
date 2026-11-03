# BRF-012 — AG01 — T-104 Ataque automático com pool
**Objetivo e pronto quando:** ver T-104 em [docs/backlog.md](../backlog.md). Os parâmetros estão em [docs/gameplay.md](../gameplay.md); as layers, em [docs/arquitetura.md](../arquitetura.md).
**Escopo:** sem alocação por tiro nem por frame (alvo: Safari no iPhone). Os parâmetros de tiro ficam em `.tres`.
**Arquivos permitidos:** `src/match/`, `data/anima/`, `data/projectiles/`, `tests/unit/match/`, `docs/gameplay.md`.
**Proibido:** `project.godot`, `src/core/`, `src/ui/`.
- Não ligue a arena ao SceneFlow; isso fica para a T-122.
**Validação:**
- A arena roda headless sem erros.
- O GUT inteiro passa, com testes de mira, dano, morte e reuso do pool.
**Entrega:** formato padrão, com no máximo 10 linhas.
