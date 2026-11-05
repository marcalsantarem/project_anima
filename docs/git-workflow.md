# Fluxo de trabalho com Git

Regras definidas pelo dono do projeto. Elas valem para qualquer pessoa ou agente (inclusive o Claude) que trabalhe neste repositório.

## Branches

| Branch | Uso | Regras |
|---|---|---|
| `main` | Versão estável mais atual | **Protegida.** Push direto bloqueado; só recebe mudanças por Pull Request. Publica no site oficial. |
| `dev` | Desenvolvimento do dia a dia (versão de trabalho) | **Única branch onde se faz commit.** Publica em `dev--projectanimagame.netlify.app`. |
| `demo` (e outras de versão fechada) | Versões fechadas e jogáveis que não mudam mais (ex.: **demo v1**, o M1) | Criada a partir da `main` **só quando o dono pedir**, ao fechar o marco; publica em `demo--projectanimagame.netlify.app`; **sem commits depois de criada** (decisão 52). |

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
- Versões fechadas importantes ganham uma branch própria a partir da tag (ex.: `demo` = v0.1, o M1), criada só quando o dono pedir.
