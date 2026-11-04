# BRF-015 — AG01 — T-111 Arquétipos: tanque, atirador e enxame
**Objetivo e pronto quando:** ver T-111 em [docs/backlog.md](../backlog.md).
**Contexto:**
- Projéteis inimigos não usam ciano: siga a paleta de [docs/ui.md](../ui.md).
- Os projéteis inimigos colidem com o Anima, conforme as layers de [docs/arquitetura.md](../arquitetura.md).
- Inclua os novos arquétipos numa onda de `stage_01.tres` (ou numa fase de teste) para validar.
**Arquivos permitidos:** `src/match/`, `data/enemies/`, `data/projectiles/`, `data/waves/`, `tests/unit/match/`, `docs/gameplay.md`.
**Proibido:** `project.godot`, `src/core/`, `src/ui/`.
**Validação:** a arena roda headless sem erros e o GUT inteiro passa, com testes do comportamento de cada arquétipo.
**Entrega:** formato padrão, com no máximo 10 linhas.
