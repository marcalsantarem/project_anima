# Marcos e tasks

## Marcos

- O projeto é dividido em **marcos** (M1, M2, M3…). Cada marco é uma entrega jogável/usável e vira **uma versão** (`v0.2.2`) com PR e tag.
- O roteiro fica em `docs/roadmap.md`: marco, versão, nome e objetivo de uma linha.
  ```
  | M4 | v0.2.2 | Núcleos | árvore de talentos |
  ```
- Marcos pequenos e frequentes são melhores que marcos grandes: o dono testa mais cedo e corrige o rumo.

## Tasks

- Cada marco é quebrado em **tasks** numeradas (`T-203`), registradas em `docs/backlog.md`, numa tabela:
  ```
  | T-205 | Partida aplica os Núcleos comprados (via MatchConfig) (tam. M) | M4 | AG01 | feita |
  ```
  Colunas: id · descrição curta · marco · agente(s) · estado (`a fazer`, `em andamento`, `feita`, com nota curta se houver ressalva).
- **Uma task, um agente dono.** Quando duas áreas são necessárias, a task cita as duas (`AG04 + AG05`), mas cada uma recebe seu próprio briefing com arquivos separados.
- **Tamanho:** P = até 1 sessão de agente, M = 1 a 2, G = 3 ou mais. Task G costuma ser quebrada.
- Os ids nunca são reaproveitados. Task nova no meio do marco pega o próximo id livre (ex.: `T-299` dentro do M4).

## Ordem típica de um marco

1. **Design** (dados, regras, custos): o agente de meta-jogo ou de gameplay. As outras tasks dependem dele.
2. **Arte** pode correr em paralelo ao design quando não depende dele.
3. **Lógica** e **efeitos** (pura, testável, sem tela).
4. **Tela / UI** em cima da lógica.
5. **VFX / áudio** em cima da tela.
6. **Balanceamento** (simulação ou bot).
7. **Validação e fechamento** (QA + líder): sempre a última task do marco, que termina na tag ([Validacao.md](Validacao.md), [Deploy.md](Deploy.md)).

## Paralelismo

- O líder dispara em **ondas**: tudo que não depende de outra task e não toca nos mesmos arquivos roda junto.
- Quando duas tasks precisam conversar (ex.: a lógica entrega bônus que a partida usa), o líder define o **contrato** (nomes, formato) nos dois briefings para os agentes trabalharem em paralelo. Quem cria um campo compartilhado vai primeiro, ou o outro confere se ele existe antes de usar.
- Se o dono pedir para disparar uma task que depende de outra ainda não pronta, o líder explica e dispara na ordem certa, avisando.

## Ressalvas e mudanças do dono

- Achados do QA viram uma task de ressalvas no mesmo marco (ex.: `T-300 Ressalvas do QA do M4`).
- Mudança de ideia do dono no meio do marco vira **decisão** ([Decisoes.md](Decisoes.md)) e uma task nova, antes de fechar o marco.
