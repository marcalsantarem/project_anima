# BRF-142 · AG07 · Versão 0.2.0 (T-197)

**Objetivo:** subir a versão do jogo de 0.1.0 para 0.2.0 para o fechamento do M2.

**Escopo (só isto):**
- `project.godot`: `config/version="0.2.0"`.
- `src/debug/build_info.gd`: `DEFAULT_VERSION := "0.2.0"` (e o exemplo do comentário, se citar a versão).
- `tests/unit/debug/test_build_info.gd`: atualizar as expectativas de 0.1.0 para 0.2.0.
- Não mexer em `tests/unit/debug/test_log_enriched.gd` (dado antigo de log, deve continuar 0.1.0).

**Pronto quando:** suíte GUT toda verde (`godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit`).

Sem commit, push nem branch. Reporte curto: arquivos alterados e resultado dos testes.
