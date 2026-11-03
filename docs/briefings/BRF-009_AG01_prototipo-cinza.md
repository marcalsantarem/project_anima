# BRF-009 — AG01 — T-103 Protótipo cinza: arena, Anima e 1 inimigo
**Objetivo e pronto quando:** ver T-103 em [docs/backlog.md](../backlog.md).
**Contexto:**
- Os parâmetros e o contrato de sinais estão em [docs/gameplay.md](../gameplay.md).
- As layers estão em [docs/arquitetura.md](../arquitetura.md).
- Ao mesmo tempo, o AG07 faz o fluxo de cenas (T-102), com uma partida placeholder em `src/core/`. A ligação à sua arena fica para depois.
**Arquivos permitidos:** `src/match/`, `data/enemies/` e testes GUT de unidade da sua lógica em `tests/unit/match/` (opcional).
**Proibido:** `project.godot`, `src/core/`, `src/ui/`.
- A arena deve rodar sozinha: o AG00 a abre com `--path . res://...arena.tscn`.
**Validação:** a cena roda headless sem erros e os testes do GUT passam.
**Entrega:** formato padrão, com no máximo 10 linhas. Inclua o caminho da cena da arena.
