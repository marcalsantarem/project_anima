# BRF-029 — AG01 — T-140 Moeda da partida vira Partículas
**Objetivo e pronto quando:** ver T-140 em [docs/backlog.md](../backlog.md).
**Contexto:** decisão 29: a moeda da partida chama-se **Partículas**, começa em 0 e zera a cada partida (Gold é a moeda do meta-jogo e não aparece na partida). Hoje o código e os docs dizem "coins/moedas".
**Fazer:** renomear no código de `src/match/` (e em `src/core/` só os campos de `MatchResult`/`MatchConfig` se for inevitável, informando ao AG00): sinal `coins_changed` → `particles_changed(total)`, campos e variáveis, `.tres` de dados se houver; atualizar `docs/gameplay.md` e `docs/arquitetura.md` (contrato de sinais). A UI (T-141, AG02) consome os novos nomes depois: **liste na entrega todo símbolo renomeado** (antigo → novo) e deixe um alias temporário `coins_changed` apenas se a UI atual quebrar sem ele; nesse caso diga qual arquivo da UI usa.
**Arquivos permitidos:** `src/match/`, `data/`, `docs/gameplay.md`, `docs/arquitetura.md`, `tests/` (ajustar nomes). Não toque em `src/ui/`.
**Validação:** `--import` e GUT completo passando (inclui `tests/integration/test_match_hud.gd`; se ele quebrar só por nome do sinal, avise em vez de editar a UI).
**Entrega:** no máximo 10 linhas.
