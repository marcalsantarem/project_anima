# BRF-038 — AG07 — T-146 Remover mockups rejeitados e filtrar o export Web
**Objetivo e pronto quando:** ver T-146 em [docs/backlog.md](../backlog.md).
**Fazer:**
- Remover `assets/backgrounds/mockup_arena.svg` e `mockup_arena_b.svg` (os rejeitados, com seus `.import`).
- **Manter** no repositório `mockup_cartoon_a*` e `mockup_cartoon_b*` (referências da demo e da 2ª fase).
- Configurar o preset Web (`export_presets.cfg`) para excluir do pacote `assets/backgrounds/mockup_*` e `assets/sprites/_src/`; confira se há outras pastas só de referência.
- Remover do `assets/LICENSES.md` apenas as linhas dos mockups apagados, com **edição pontual** (outro agente edita o arquivo ao mesmo tempo); ajustar referências em `docs/arte.md` se existirem, sem reescrever o guia.
**Arquivos permitidos:** `assets/backgrounds/`, `export_presets.cfg`, `assets/LICENSES.md`, `docs/arte.md` (só referências).
**Validação:** export Web (`--export-release "Web" build/web/index.html`) funciona e o `.pck` não contém os mockups (informe o tamanho antes e depois); GUT completo passando.
**Entrega:** no máximo 10 linhas.
