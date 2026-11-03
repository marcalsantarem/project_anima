# Divisão do trabalho em agentes

## Modelo de coordenação (Decidido)

- O **Claude principal é o game dev líder**. É o único agente que conversa com o dono do projeto.
- Ele faz quatro coisas:
  - quebra os pedidos em tarefas e as distribui entre os agentes especialistas;
  - revisa e integra o que eles entregam;
  - decide as questões que cruzam domínios, registrando-as em [decisoes.md](decisoes.md);
  - responde pelos commits na `dev`.
- O dono do projeto **não aciona agentes diretamente**. Pedidos, dúvidas e aprovações passam sempre pelo líder.

## Mecanismo

- **(Decidido)** Cada especialista é uma **sessão própria do Claude Code**. O líder inicia a sessão com um briefing quando há trabalho para ela e acompanha o resultado. Elas não trabalham por iniciativa própria.
- **(Proposta) Regras para as sessões**, já que o git só permite a `dev`:
  - Trabalham na **mesma pasta e na branch `dev`**, sem worktrees, porque cada worktree exige uma branch própria.
  - **Não fazem commit nem push.** O líder revisa o resultado e faz o commit.
  - Duas sessões só rodam ao mesmo tempo se mexerem em **arquivos diferentes**. As pastas de cada especialista ajudam a garantir isso. Se houver sobreposição, uma roda depois da outra.
  - Arquivos compartilhados, como `project.godot`, autoloads e Input Map, só são alterados pelo líder ou com autorização dele no briefing.

## Ordem de entrada (Decidido)

O primeiro marco é o **protótipo jogável do combate**. Nele entram **Gameplay**, **UI/Web** e **QA**. **Meta-jogo** e **Backend** entram quando o combate estiver validado.

## Especialistas

O papel de cada agente está detalhado em `docs/agentes/AGxx_nome.md`, e as regras comuns em [agentes/_regras-comuns.md](agentes/_regras-comuns.md). Códigos: AG01 Gameplay, AG02 UI/Web, AG03 QA, AG04 Meta-jogo, AG05 Backend.

## Imprescindíveis

| Agente | Responsabilidade | Pastas principais |
|---|---|---|
| **Gameplay / Combate** | Arena, Anima, ataque automático, skills e cooldowns, inimigos, ondas e chefe, projéteis e colisões | `src/match`, `data/skills`, `data/enemies`, `data/waves` |
| **Meta-jogo / Dados** | Cards, raridades, fusão, atributos, talentos e economia (lógica pura) | `src/meta`, `data/cards`, `data/stats` |
| **Backend** | Interface `Backend`, save local e, depois, o provedor escolhido (auth, banco, regras, lógica no servidor, config remota, hosting) | `src/backend`, `web/` |
| **UI / Plataforma Web** | HUD, menus e hangar, retrato e responsividade, toque/mouse/teclado, exportação Web e desempenho no Safari do iOS | `src/ui`, `web/` |
| **QA / Revisor** | Testes automatizados, revisão entre domínios e verificação dos builds no PC e no iPhone | `tests/` |

## Opcionais (mais adiante)

| Agente | Responsabilidade | Observação |
|---|---|---|
| **Balanceamento** | Curvas de dificuldade, taxas de drop, custos | Pode começar dentro do Meta-jogo |
| **VFX / Arte técnica** | Shaders, partículas, efeitos por raridade e skin | A arte em si vem de fora |
| **Monetização** | Ads, compras, loja | Só depois que o loop principal estiver divertido |
| **DevOps** | Deploy automático de previews | Pode ficar com o Backend no início |
