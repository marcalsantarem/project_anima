# Git

## Branches

Só existem duas branches permanentes:

| Branch | Papel | Quem escreve |
|---|---|---|
| `dev` | Todo o trabalho do dia a dia | Só o líder (AG00) faz commit e push |
| `main` | Versões fechadas | Ninguém escreve direto. Só recebe Pull Request `dev` → `main` |

- A `main` é **protegida** no GitHub: sem push direto.
- **Não se cria outra branch** (nem por feature, nem por versão) sem pedido explícito do dono. Versões fechadas ficam marcadas por **tag** na `main` ([Deploy.md](Deploy.md)), não por branch.
- Os agentes especialistas **nunca** fazem commit, push, branch, `checkout`, `reset` nem `stash`. Eles só editam os arquivos permitidos no briefing.

## Quando fazer commit

- Ao **fechar uma etapa**: uma task (ou um grupo pequeno de tasks entregues juntas) conferida e com a suíte de testes verde.
- **Não** fazer commit a cada pequena alteração. Agrupe.
- Briefings podem ir num commit próprio quando são escritos antes de disparar uma onda de agentes (ex.: `BRF-156 e BRF-157 (T-208, T-209)`).
- Antes do commit: confira o `git status` e não inclua arquivos gerados pela engine ou lixo de build (ex.: `*.import` soltos, `build/`).

## Mensagem de commit

- Em pt-BR, começando pelo id da task e citando o briefing:
  `T-209 balanceamento com Núcleos pela simulação do bot (BRF-157)`
- Várias tasks juntas: `T-210 validação do M4, T-300 ressalvas do QA e versão 0.2.2 (BRF-160, BRF-161, BRF-162)`.
- Termina com a linha de coautoria do Claude.

## Quando fazer push

- Logo depois de cada commit na `dev`. O líder faz isso **por conta própria**, sem pedir permissão, e avisa o dono no relatório.
- Push na `main`: nunca. Push de tag: só depois do merge do PR ([Deploy.md](Deploy.md)).

## Pull Request

- Sempre `dev` → `main`, **só no fim de um marco** e só quando o dono quiser.
- Quem abre e faz o merge é o **dono**. O líder entrega o título, a descrição e o link ([Deploy.md](Deploy.md)).
