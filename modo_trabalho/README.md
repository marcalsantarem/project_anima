# Modo de trabalho

Método usado no Project: Anima, escrito para ser copiado em projetos novos. Cada arquivo trata de um assunto e vale sozinho.

| Arquivo | Assunto |
|---|---|
| [Delegacao.md](Delegacao.md) | O dono fala só com o líder (AG00); como o líder conversa com os agentes |
| [Distribuicao_agents.md](Distribuicao_agents.md) | Agentes especialistas: tipos, definição e quando dividir um agente |
| [Time_inicial.md](Time_inicial.md) | Time base de qualquer projeto de jogo e agentes reservados |
| [Briefings.md](Briefings.md) | Como o líder escreve o pedido para cada agente |
| [Tasks.md](Tasks.md) | Marcos de entrega quebrados em tasks menores, uma por agente |
| [Listagem_tasks.md](Listagem_tasks.md) | Modelo visual obrigatório para listar tasks |
| [Git.md](Git.md) | Branches `main` e `dev`, quando fazer commit e push |
| [Deploy.md](Deploy.md) | Fechamento do marco: PR, texto do PR, tag de versão e deploy |
| [Validacao.md](Validacao.md) | Como o líder confere o trabalho e como o QA fecha um marco |
| [Decisoes.md](Decisoes.md) | Registro numerado das decisões do dono |
| [Economia_tokens.md](Economia_tokens.md) | Regra de gasto mínimo de tokens |

## Em um projeto novo

1. Copie esta pasta para a raiz do projeto.
2. Crie o `CLAUDE.md` apontando para ela. Diga ali que o Claude principal é o **AG00 (Líder)**, que gerencia e não implementa.
3. Crie `docs/agentes/` com um arquivo por agente ([Distribuicao_agents.md](Distribuicao_agents.md)), `docs/briefings/`, `docs/backlog.md`, `docs/roadmap.md` e `docs/decisoes.md`.
4. Crie a branch `dev` e proteja a `main` ([Git.md](Git.md)).
5. Defina os marcos e quebre o primeiro em tasks ([Tasks.md](Tasks.md)).

## Idioma

Documentação, commits, briefings e conversa em **português (pt-BR)**. Identificadores de código em inglês.
