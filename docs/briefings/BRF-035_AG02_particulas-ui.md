# BRF-035 — AG02 — T-141 Partículas na UI
**Objetivo e pronto quando:** ver T-141 em [docs/backlog.md](../backlog.md). Depois, na mesma sessão, faça o BRF-036 (T-135).
**Contexto:** a T-140 renomeou na arena `coins_changed` → `particles_changed(total)` e `Arena.coins` → `Arena.particles`; o alias `coins_changed` ainda existe e `MatchResult.coins` (em `src/core/`) ainda tem o nome antigo e é lido por `src/ui/screens/result_screen.gd`.
**Fazer:** HUD e Resultado mostram "Partículas" (texto e ícone de estrela), ligados a `particles_changed`; remova a dependência do alias; nenhuma menção a "moedas" para a moeda da partida na UI e em `docs/ui.md`. Renomear `MatchResult.coins` → `particles` está **autorizado** neste briefing (em `src/core/match_result.gd`, e nos usos em `src/match/` e `tests/`, só a troca do nome); depois remova o alias `coins_changed` de `src/match/arena/arena.gd` (edição mínima autorizada, só essa remoção). Atualize os testes afetados.
**Arquivos permitidos:** `src/ui/hud/`, `src/ui/screens/`, `docs/ui.md`, `src/core/match_result.gd`, usos do campo em `src/match/` e `tests/`, e a remoção do alias em `arena.gd`. O AG01 trabalha em `src/match/` ao mesmo tempo: faça só edições mínimas e pontuais lá, nunca reescreva arquivos.
**Validação:** `--import` e GUT completo passando.
**Entrega:** no máximo 10 linhas por tarefa.
