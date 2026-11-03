# BRF-017 — AG03 — T-114 Testes GUT de ondas, dano e cooldowns
**Objetivo e pronto quando:** ver T-114 em [docs/backlog.md](../backlog.md).
**Contexto:**
- O AG01 já criou testes de unidade em `tests/unit/match/`. Não os duplique.
- Cubra as lacunas e crie testes de integração em `tests/integration/`: a partida inteira, da arena e das ondas até o HUD e o `match_ended`.
- Se algum teste revelar um bug, **não corrija o código**: reporte o bug na entrega, com o passo a passo para reproduzir.
**Arquivos permitidos:** `tests/`.
**Validação:** o GUT inteiro roda headless e passa, exceto os bugs reportados, marcados com `pending` e justificados.
**Entrega:** formato padrão, com no máximo 10 linhas. Inclua o total de testes.
