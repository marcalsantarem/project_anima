# BRF-004 — AG03 — T-002 Instalar GUT e teste smoke
**Objetivo:** GUT compatível com Godot 4.7.2 em `addons/gut/`, com 1 teste smoke passando headless.
**Contexto:** AG03 §3. Godot: `"/c/Program Files/Godot/Godot_v4.7.2-stable_win64.exe"`. Exemplo de comando no `CLAUDE.md` (Comandos).
**Escopo:**
- Baixe o GUT **só do repositório oficial** (github.com/bitwes/Gut), na release compatível com 4.x.
- **Não** edite o `project.godot` (é do AG07): a CLI do GUT não exige o plugin ativado.
- **Não** edite o `CLAUDE.md`: informe na entrega os comandos que funcionaram.
**Arquivos permitidos:** `addons/gut/`, `.gutconfig.json`, `tests/unit/test_smoke.gd`.
**Pronto quando:**
- `test_smoke.gd` passa pelo comando headless;
- os comandos "todos os testes" e "um arquivo" estão confirmados na entrega;
- a versão do GUT está informada.
**Entrega:** formato padrão, com no máximo 10 linhas.
