# Listagem de tasks

Toda vez que o líder fecha uma etapa, ou o dono pede a lista de tasks, a resposta usa **sempre** este modelo.

## Modelo

**M4 (v0.2.2): Núcleos**
- ✅ T-203: design da árvore de Núcleos (AG04 (Meta-jogo))
- ✅ T-204: lógica dos Núcleos, compra e save (AG04 (Meta-jogo) + AG05 (Backend))
- 🔄 T-207: tela de Núcleos (AG02 (UI))
- ⬜ T-210: validação e tag v0.2.2 (AG03 (QA) + AG00 (Líder))

**M5 (v0.2.3): Módulos**
- ⬜ T-211: design dos Módulos (AG04 (Meta-jogo))

## Regras

- **Agrupado por marco.** Título do marco em negrito, com a versão e o nome: `**M4 (v0.2.2): Núcleos**`.
- **Uma linha por task:** ícone, id, descrição curta e agente.
- **Ícones:**
  - ✅ feita
  - 🔄 em andamento (agente trabalhando agora)
  - ⬜ a fazer
- **Agente sempre com o nome:** `AG04 (Meta-jogo)`, nunca só `AG04`.
- Mostrar o **marco atual inteiro** (feitas e pendentes) e o **próximo** quando fizer sentido.
- Tasks feitas em bloco podem ser resumidas numa linha (`✅ T-203 a T-209: árvore, lógica, efeitos…`).
- **Sem tabelas.** Simples e visual.
- Os dados vêm de `docs/backlog.md`. A lista e o backlog precisam bater.
- Depois da lista, uma linha com o próximo passo sugerido (ex.: "Posso começar pelo T-211; o T-214 pode ir em paralelo").
