# BRF-005 — AG02 — T-004 Preset Web + HTML shell mínimo
**Objetivo e pronto quando:** ver T-004 em [docs/backlog.md](../backlog.md).
**Decisões para o ui.md (aplique junto):**
- Sincronize os sinais com [docs/gameplay.md](../gameplay.md), que é o contrato oficial.
- Slots de skill são **1-based** (1 a 3).
- A fonte Outfit está aprovada (OFL, em `assets/fonts/`).
- O 4º slot fica em "Depois".
**Autorizado:** criar e editar `export_presets.cfg` e `web/`. **Não** edite o `project.godot` (é do AG07): se precisar de algo nele, informe na entrega.
**Arquivos permitidos:** `export_presets.cfg`, `web/`, `docs/ui.md`, `assets/fonts/`.
**Validação mínima:**
- exportação headless para `build/web/` sem erros;
- abre localmente no Chrome. Use o "Executar no navegador" do editor ou um servidor local; `file://` não funciona.
**Entrega:** formato padrão, com no máximo 10 linhas, incluindo o tamanho do build.
