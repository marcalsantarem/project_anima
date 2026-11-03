# BRF-006 — AG02 — Deploy automático no Netlify (substitui o caminho da T-005)

**Objetivo:** reproduzir o fluxo do dunwick com GitHub Actions.
- Push na `dev` → build Web → `dev--<site>.netlify.app`.
- Push na `main`, ou seja, merge de PR → build Web → `<site>.netlify.app`, em produção.

**Contexto:**
- O site no Netlify já existe, **sem ligação com o Git**. O Netlify não faz build.
- Os secrets de repositório já estão criados no GitHub: `NETLIFY_SITE_ID` e `NETLIFY_AUTH_TOKEN`.
- O repositório é público, então os minutos do Actions são gratuitos.
- O preset "Web" já existe (`export_presets.cfg`, BRF-005).

**Escopo:**
- Crie `.github/workflows/deploy-web.yml` com 1 workflow e jobs para `dev` e `main`, sem duplicar passos à toa.
- Passos:
  1. Instale o Godot 4.7.2 Linux e os export templates **só de fontes oficiais**: as releases de `godotengine/godot-builds` ou uma action amplamente usada com versão fixa. Faça cache dos templates.
  2. Rode `--import` e depois os testes do GUT (comando no `CLAUDE.md`). **Se algum teste falhar, não há deploy.**
  3. Exporte com `--export-release "Web" build/web/index.html`.
  4. Faça o deploy com o `netlify-cli`, em versão fixa: `deploy --dir=build/web --no-build`.
     - Na `dev`, use `--alias dev`.
     - Na `main`, use `--prod`.
- Todas as actions com versão fixa. Os secrets só via `secrets.*`, nunca impressos no log.

**Arquivos permitidos:** `.github/workflows/`. Se precisar de ajuste no `project.godot`, informe na entrega.

**Validação:** você não faz commit. Valide a sintaxe localmente, como conseguir. O AG00 faz o commit na `dev` e confere a execução no GitHub.

**Pronto quando:** o workflow está pronto para o primeiro push; a entrega explica como conferir o resultado e quais são as URLs esperadas.

**Entrega:** formato padrão, com no máximo 10 linhas.
