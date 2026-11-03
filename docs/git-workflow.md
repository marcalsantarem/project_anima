# Fluxo de trabalho com Git

Regras definidas pelo dono do projeto. Elas valem para qualquer pessoa ou agente (inclusive o Claude) que trabalhe neste repositório.

## Branches

| Branch | Uso | Regras |
|---|---|---|
| `main` | Versões estáveis e marcos | **Protegida.** Push direto bloqueado; só recebe mudanças por Pull Request. |
| `dev` | Desenvolvimento do dia a dia | **Única branch onde se faz commit.** |

- **Não crie outras branches** (feature, fix, experimento etc.) sem pedido explícito do dono do projeto.
- **Não faça commit nem push na `main`.**

## Commits

- O Claude pode fazer commit e push na `dev` **por conta própria** quando fizer sentido: ao concluir uma etapa, para salvar trabalho funcional ou antes de uma mudança arriscada.
- Mensagens em português, curtas e no imperativo. Exemplo: `Adiciona lógica de fusão de cards`.
- Cada commit deve deixar o projeto abrindo no editor sem erros.

## Pull Requests

- Os PRs vão sempre de `dev` para `main`.
- **Só são abertos quando o dono do projeto pedir**, ao atingir um marco.
- A descrição resume o que entrou desde o último PR e o que ainda está pendente ou não foi verificado.
