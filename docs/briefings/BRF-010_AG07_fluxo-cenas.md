# BRF-010 — AG07 — T-102 Autoload de fluxo de cenas
**Objetivo e pronto quando:** ver T-102 em [docs/backlog.md](../backlog.md). O fluxo é **Toque para começar → Partida → Resultado → Toque para começar**.
**Contexto:**
- `MatchResult` e os sinais estão em [docs/gameplay.md](../gameplay.md).
  - Defina `MatchConfig` (mínimo) e `MatchResult` como tipos em `src/core/`.
  - Documente o contrato em `docs/arquitetura.md`.
- **A partida placeholder fica em `src/core/`:** o AG01 está criando agora a arena real em `src/match/`. Não toque nessa pasta.
  - O caminho da cena de partida deve ser fácil de trocar depois (uma constante ou o `MatchConfig`).
- **A tela de toque para começar** mantém o texto atual de `main.tscn`.
  - Ela é placeholder: o AG02 fará a versão final (T-113).
  - Na web, o toque também destrava o áudio.
**Arquivos permitidos:** `src/core/`, `project.godot` (autoload e cena principal), `docs/arquitetura.md`, `tests/unit/core/` (opcional).
**Validação:** o projeto abre headless sem erros, os testes do GUT passam e o export Web continua funcionando.
**Entrega:** formato padrão, com no máximo 10 linhas. Liste as mudanças em `project.godot`.
