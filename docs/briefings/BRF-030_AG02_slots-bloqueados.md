# BRF-030 — AG02 — T-136 Slots 2 e 3 bloqueados (cadeado)
**Objetivo e pronto quando:** ver T-136 em [docs/backlog.md](../backlog.md).
**Contexto:** decisão 25 (slot 1 no nível 3, slot 2 no 7, slot 3 no 12) e o mockup `assets/backgrounds/mockup_cartoon_a_upgrades.png`: slot 1 ativo; slots 2 e 3 cinza, com cadeado, texto "NV 7" / "NV 12" e badge de número. Os componentes já foram retemados na T-145 (`SkillButton`, `Hud`).
**Fazer:** estado "bloqueado" no `SkillButton` (cadeado, nível de desbloqueio, não responde a toque nem a `skill_2`/`skill_3`, foco/acessibilidade coerentes); o HUD mostra os slots 2 e 3 bloqueados por padrão no M1, configurável por dado (ex.: lista de níveis de desbloqueio), sem depender do nível de conta, que é do M2. Atualize `docs/ui.md` e a cena de demo.
**Arquivos permitidos:** `src/ui/`, `docs/ui.md`, `tests/` (só da UI). Não toque em `src/match/` nem em `project.godot`.
**Validação:** GUT passando e as cenas de demo abrem sem erro; confira a imagem renderizada contra o mockup.
**Entrega:** no máximo 10 linhas.
