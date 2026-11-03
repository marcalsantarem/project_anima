# BRF-014 — AG01 — T-108 Base de skills + skill de área
**Objetivo e pronto quando:** ver T-108 em [docs/backlog.md](../backlog.md).
**Contexto:**
- Use os sinais `cooldown_changed`, `skill_used` e `skill_ready` de [docs/gameplay.md](../gameplay.md).
- Use as Input Actions `skill_1..3`, nunca teclas fixas.
- A base deve aceitar as skills de controle e de defesa (T-109 e T-110) sem refatoração.
- A UI também precisa acionar a skill por slot, porque o botão de toque vem na T-112. Exponha um método público para isso.
**Arquivos permitidos:** `src/match/`, `data/skills/`, `tests/unit/match/`, `docs/gameplay.md`.
**Proibido:** `project.godot`, `src/core/`, `src/ui/`.
**Validação:** a arena roda headless sem erros e o GUT inteiro passa, com testes de cooldown e de dano em área.
**Entrega:** formato padrão, com no máximo 10 linhas.
