# Project: Anima

> **Status:** v0.1, **rascunho** (2026-11-03). Ainda não foi aprovada pelo usuário.
> Mantida pelo AG00 (Game Dev Líder). Hierarquia de verdade: usuário > esta Bíblia > [decisoes.md](decisoes.md) > documento do agente dono.
> Itens **[A DEFINIR]** não têm decisão. Itens **[PROPOSTA]** aguardam aprovação. Ninguém inventa fatos além do que está aqui.
> O GDD original está em [gdd.md](gdd.md).

## Pitch e pilares

> Um receptáculo neutro no centro da arena resiste a hordas que chegam de todos os lados. Ele dispara sozinho; você escolhe **o momento** de liberar meteoros, ondas de congelamento e escudos. Entre as partidas, funde cards, evolui atributos e dá ao Anima uma alma, e um visual, só seus.
> Partidas de 3 a 10 minutos, no navegador, sem instalar nada.

**Pilares [PROPOSTA]:**
1. **Timing é tudo:** sem movimento, a habilidade do jogador está em **quando** usar cada skill. Poucas decisões, todas importantes.
2. **Progressão que se sente:** cada fusão e cada nível muda números **e** o visual da skill.
3. **Clareza no caos:** centenas de projéteis, e mesmo assim tudo legível numa tela de celular.
4. **Zero atrito:** abriu o link, está jogando, no PC ou no iPhone.

## Premissa (origem: usuário)

- **Anima** vem do latim "alma, sopro vital". É um receptáculo **neutro e inerte**, que ganha vida, forma e estilo pela alma que o jogador infunde: skins, elementos e cards.
- O avatar neutro permite skins de qualquer temática (arcana, cyberpunk, espectral…) sem quebrar o universo.
- **Ainda não definido:** quem ou o que ataca o Anima, o cenário e o mundo, se haverá narrativa além do tema, e os nomes de fases, inimigos e skills. O AG00 propõe opções; nada vira fato sem aprovação.

## Público

- Casual a mid-core, fãs de loops de progressão, visual vibrante e decisões táticas curtas.
- Sessões de 3 a 10 min.
- Classificação-alvo: **[A DEFINIR]** (sugestão: livre/10+, sem violência gráfica).

## Gameplay (resumo; detalhe em `docs/gameplay.md` pelo AG01)

- O Anima fica **fixo no centro**; **não há joystick**.
- O ataque básico é automático, no inimigo mais próximo ou de maior prioridade.
- Skills ativas com cooldown, em botões (toque) ou nas teclas `1` `2` `3` `Espaço`:
  - **Área:** meteoro, míssil;
  - **Controle:** EMP, congelamento;
  - **Defesa:** escudo do Núcleo, invulnerabilidade.
- Ondas (`Wave X/Y`) até o **chefe**. Se o HP do Núcleo chegar a zero, é derrota.
- **Meta:**
  - Cards de skill: Comum → Raro → Épico → Lendário. **Fusão de 3 cards idênticos** gera a raridade seguinte.
  - Atributos permanentes: dano, velocidade de ataque, vida, armadura, regeneração, redução de cooldown.
  - Árvore de talentos comprada com moedas.

## Roadmap [PROPOSTA]

| Marco | Objetivo | Agentes |
|---|---|---|
| **M0 — Fundação** | Docs, ambiente, projeto Godot, exportação Web vazia rodando no PC e no iPhone | AG00, AG02 |
| **M1 — Protótipo do combate** *(decidido como 1º marco jogável)* | Partida completa e divertida com placeholders | AG01, AG02, AG03 |
| **M2 — Meta-jogo local** | Cards, fusão, atributos e talentos, com save local | AG04, AG02, AG05 (local) |
| **M3 — Online** | Backend escolhido: conta guest, sincronização, economia no servidor, config remota | AG05, AG04 |
| **M4 — Monetização e polimento** | Ads, loja, skins, arte e áudio finais | **[A DEFINIR]** |

## Escopo atual: M1 (protótipo do combate)

### DENTRO
| Área | Quantidade |
|---|---|
| Arena | 1, em retrato |
| Anima | 1, placeholder geométrico |
| Ataque automático | 1 tipo de projétil |
| Skills | 3: área, controle e defesa. O 4º slot (`Espaço`) está **[A DEFINIR]** |
| Inimigos | 3–4 arquétipos (corredor, tanque, atirador, enxame) |
| Fase | 1, com ~10 ondas e 1 chefe |
| HUD | HP do Núcleo, `Wave X/Y`, moedas (contagem só na partida), pausa, botões de skill |
| Telas | Toque para começar → Partida → Resultado (vitória ou derrota) → Jogar de novo |
| Plataforma | Chrome no PC e Safari no iPhone, retrato, toque + mouse + teclado |
| Idioma | Português do Brasil |

### FORA (até depois do M1)
Cards e fusão, atributos, talentos, save, backend, contas, ads, compras, skins, arte e áudio finais, mais de uma fase, localização, builds nativos.

## Referências (gênero e estrutura, **nunca para copiar**)

- **Archero:** malha de retenção e progressão (cards, farm, sessões curtas) e a clareza da vista de cima.
- **Gêneros:** tower/base defense, bullet hell e survivor-likes, pela densidade de inimigos e projéteis.

Proibido usar personagens, criaturas, nomes, ícones, sons, interface ou arte de qualquer jogo existente.

## Plataforma e restrições do navegador (detalhes no `CLAUDE.md`)

- Godot 4.x, GDScript **[PROPOSTA]**, renderer Compatibility (WebGL 2), exportação **single-threaded**.
- Metas iniciais (a confirmar no M0):
  - 60 fps no PC; **≥ 50 fps no iPhone** com ~150 inimigos e ~300 projéteis;
  - download inicial de **≤ ~15 MB**.
- O áudio só toca depois do primeiro toque, por isso há a tela "toque para começar".
- Backend **[A DEFINIR]**: Firebase é o favorito e Nakama a alternativa.

## Time e responsabilidades

| Código | Agente | Responsável por | Entra em |
|---|---|---|---|
| AG00 | Game Dev Líder | Plano, Bíblia, decisões, briefings, integração, arquivos compartilhados, commits | Sempre |
| AG01 | Gameplay / Combate | Arena, Anima, ataque automático, skills, inimigos, ondas, chefe | M1 |
| AG02 | UI / Plataforma Web | HUD, telas, entrada, tema, exportação Web, desempenho no Safari | M0/M1 |
| AG03 | QA / Revisor | Testes, revisão, medições, veredito passa ou não passa | M1 |
| AG04 | Meta-jogo / Dados | Cards, fusão, atributos, talentos, economia | M2 |
| AG05 | Backend | Interface `Backend`, save, provedor online, segurança | M2/M3 |

Equipe: 1 usuário + agentes de IA. O prazo é por marcos, sem datas fixas.

### Comando e delegação

Cada agente roda numa **sessão própria** do Claude Code, com o nome do agente. O **AG00 comanda**: tudo passa por ele.

| Sessão | Instrução |
|---|---|
| AG00_gamedev-lider (sessão principal) | [agentes/AG00_gamedev-lider.md](agentes/AG00_gamedev-lider.md) |
| AG01_gameplay | [agentes/AG01_gameplay.md](agentes/AG01_gameplay.md) |
| AG02_uiweb | [agentes/AG02_uiweb.md](agentes/AG02_uiweb.md) |
| AG03_qa | [agentes/AG03_qa.md](agentes/AG03_qa.md) |
| AG04_metajogo | [agentes/AG04_metajogo.md](agentes/AG04_metajogo.md) |
| AG05_backend | [agentes/AG05_backend.md](agentes/AG05_backend.md) |

Regras:
1. **Usuário → AG00 → agentes.** O usuário fala só com o AG00, que transforma o pedido em briefing e delega.
2. **Nenhum agente trabalha sem briefing** em `docs/briefings/BRF-xxx_AGxx_<entrega>.md` (modelo em `AG00` §5), com critério de pronto.
3. **A entrega volta ao AG00** no formato *entregue · validação · suposições · não testado · próximo passo*. O AG00 valida, integra, faz o commit e decide o próximo passo.
4. **Agentes não pedem trabalho uns aos outros.** Se um precisa de algo, pede ao AG00. Todos podem ler os documentos uns dos outros.
5. **Decisões criativas, de escopo e de stack** sobem ao usuário pelo AG00, com 2 ou 3 opções e uma recomendação.
6. Cada agente escreve só nas suas pastas ([estrutura.md](estrutura.md)). `docs/00_*`, `decisoes.md`, `briefings/`, `agentes/` e os arquivos compartilhados são do AG00.
7. Todos trabalham na `dev`, na mesma pasta. **Só o AG00 faz commit.** Sessões em paralelo só com arquivos diferentes.
8. **Economia de tokens** em todas as interações.

## Links

- Decisões: [decisoes.md](decisoes.md) · Estrutura: [estrutura.md](estrutura.md) · Setup: [setup.md](setup.md) · Git: [git-workflow.md](git-workflow.md)
- GDD original: [gdd.md](gdd.md) · Agentes: [agentes/](agentes/) · Briefings: `briefings/`
