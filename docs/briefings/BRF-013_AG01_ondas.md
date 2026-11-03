# BRF-013 — AG01 — T-105 Ondas, HP do Núcleo, moedas, vitória e derrota
**Objetivo e pronto quando:** ver T-105 em [docs/backlog.md](../backlog.md).
**Contexto:**
- Siga o contrato de sinais e o `MatchResult` de [docs/gameplay.md](../gameplay.md).
- Use o `MatchResult` que já existe em `src/core/match_result.gd`, do AG07: não crie outro.
  - Se precisar de um campo novo, informe na entrega.
- Implemente `setup(config: MatchConfig)` e `match_ended(result)` na raiz da arena, conforme o contrato em [docs/arquitetura.md](../arquitetura.md).
- Avalie se vale reaproveitar os inimigos, como já é feito com os projéteis. Se não fizer agora, justifique na entrega.
**Arquivos permitidos:** `src/match/`, `data/waves/`, `data/enemies/`, `tests/unit/match/`, `docs/gameplay.md`.
**Proibido:** `project.godot`, `src/core/`, `src/ui/`.
- A ligação da arena ao SceneFlow fica para a T-122.
**Validação:**
- A arena roda headless sem erros até a vitória e, com o ataque desligado, até a derrota.
- O GUT inteiro passa.
**Entrega:** formato padrão, com no máximo 10 linhas.
