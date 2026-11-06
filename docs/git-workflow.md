# Fluxo de trabalho com Git

Regras definidas pelo dono do projeto. Elas valem para qualquer pessoa ou agente (inclusive o Claude) que trabalhe neste repositório.

## Branches

| Branch | Uso | Regras |
|---|---|---|
| `main` | Versão estável mais atual | **Protegida.** Push direto bloqueado; só recebe mudanças por Pull Request. Publica no site oficial. |
| `dev` | Desenvolvimento do dia a dia (versão de trabalho) | **Única branch onde se faz commit.** Publica em `dev--projectanimagame.netlify.app`. |
| `alfa`, `beta` (versões fechadas) | Versões fechadas e jogáveis que não mudam mais: `alfa` = v0.2.0 (M2), `beta` = v0.3.0 (M10) | Criada a partir da tag **só quando o dono pedir**, ao fechar o marco; publica em `<branch>--projectanimagame.netlify.app`; **sem commits depois de criada** (decisões 52 e 55). |

- **Não crie outras branches** (feature, fix, experimento etc.) sem pedido explícito do dono do projeto.
- **Não faça commit nem push na `main`.**

## Commits

- O Claude líder faz commit e push na `dev` **por conta própria**, agrupando o trabalho: ao concluir uma etapa ou antes de uma mudança arriscada. Evite um commit por pequena alteração.
- As sessões especialistas não fazem commit.
- Mensagens em português, curtas e no imperativo. Exemplo: `Adiciona lógica de fusão de cards`.
- Cada commit deve deixar o projeto abrindo no editor sem erros.

## Pull Requests

- Os PRs vão sempre de `dev` para `main`.
- **Só são abertos quando o dono do projeto pedir**, ao atingir um marco.
- A descrição resume o que entrou desde o último PR e o que ainda está pendente ou não foi verificado.

## Versões

- Cada marco fecha com PR `dev → main`, **tag** `v0.x.0` na `main` e a versão aparecendo no título do jogo (`src/debug/build_info.gd`).
- Fluxo de release: o dono pede o PR `dev → main`; depois do merge, o AG00 cria a tag na `main` (`git tag v0.x.0 && git push origin v0.x.0`). A tag dispara o build, o link `https://<tag-com-hifens>--projectanimagame.netlify.app` (ex. `v0-1-0`) e a GitHub Release com o zip do build (`docs/setup.md`, Deploy). Tag nunca publica em produção.
- Versões fechadas importantes ganham uma branch própria a partir da tag (`alfa` = v0.2.0, `beta` = v0.3.0; a v0.1.0 fica só na tag; decisão 55), criada só quando o dono pedir.
