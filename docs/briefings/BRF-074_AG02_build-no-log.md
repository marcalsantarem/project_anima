# BRF-074 — AG02 — T-165 Versão e build no cabeçalho do log
**Contexto:** o cabeçalho do log sai com `versão` e `build` vazios. O dono precisa saber **qual commit** testou no iPhone.
**Fazer:**
- No deploy (`.github/workflows/deploy-web.yml`), depois do export e do `web/copy_pwa.sh`, **injete** o SHA curto (`${GITHUB_SHA::7}`), o SHA completo, a branch (`${GITHUB_REF_NAME}`), a data/hora UTC do build e o número da execução (`${GITHUB_RUN_NUMBER}`) no site gerado em `build/web/`: o caminho **mais simples e robusto** (ex.: substituir um marcador no `index.html` por um `<script>` inline com `window.ANIMA_BUILD = {...}`, ou um `build-info.js` carregado antes do engine com `?v=<sha>`). Sem segredos e **sem risco de cache antigo**. Coloque a lógica num script versionado (ex.: `web/inject_build.sh build/web`), chamado pelo workflow, testável localmente com variáveis de ambiente.
- Sem as variáveis (export local, editor): `window.ANIMA_BUILD` ausente ⇒ o log mostra `"dev local"`, sem erro.
- Godot (`src/debug/`): lê o objeto via `JavaScriptBridge` (com guarda `OS.has_feature("web")`) e preenche no cabeçalho `build: {sha, sha_full, branch, built_at, run}` e `version` (`application/config/version` se existir; senão a constante `"0.1.0-demo"` em `src/debug/`, documentada; **não mexa em `project.godot`**). No resumo em texto: linha `Build: <sha> (<branch>) · <data> · exec #<n>`; também no overlay `?debug=1`.
- **Menu de pausa:** em letra pequena e discreta (cinza claro, canto inferior) `v0.1.0-demo · <sha>`.
- Documente em `docs/debug.md` e `docs/setup.md`.
**Arquivos permitidos:** `web/`, `.github/workflows/deploy-web.yml`, `src/debug/`, `src/ui/screens/` (só a linha de versão da pausa), `docs/debug.md`, `docs/setup.md`, `tests/unit/debug`. **Proibido:** `src/match/`, `project.godot`, `assets/`. O AG08 trabalha em `assets/ui/` ao mesmo tempo.
**Validação:** export Web funciona; simule a injeção local (`GITHUB_SHA=abc1234def... GITHUB_REF_NAME=dev GITHUB_RUN_NUMBER=42 bash web/inject_build.sh build/web`) e confira o resultado; teste unitário do parse (com e sem dados); GUT completo.
**Entrega:** no máximo 6 linhas.
