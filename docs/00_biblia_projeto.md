# Project: Anima

> **Status:** v1.1, **APROVADA pelo usuário em 2026-11-03**. A v1.1 traz a nova progressão, o M1 como demo polida e os agentes AG08 e AG09.
> Mantida pelo AG00 (Game Dev Líder). Hierarquia de verdade: usuário > esta Bíblia > [decisoes.md](decisoes.md) > documento do agente dono.
> Itens **[A DEFINIR]** não têm decisão. Itens **[PROPOSTA]** aguardam aprovação. Ninguém inventa fatos além do que está aqui.
> O GDD original está em [gdd.md](gdd.md).

## Pitch e pilares

> Um receptáculo neutro no centro da arena resiste a hordas que chegam de todos os lados. Ele dispara sozinho; você escolhe **o momento** de liberar meteoros, ondas de congelamento e escudos. Entre as partidas, funde cards, evolui atributos e dá ao Anima uma alma, e um visual, só seus.
> Partidas de 3 a 10 minutos, no navegador, sem instalar nada.

**Pilares:**
1. **Timing é tudo:** sem movimento, a habilidade do jogador está em **quando** usar cada skill. Poucas decisões, todas importantes.
2. **Progressão que se sente:** cada nível, Módulo, Fragmento e upgrade muda números **e** o visual.
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
- **Upgrades da partida:** em **tempo real**, por uma **fileira de 5 botões acima das skills** (Atk power, Atk spd, Defesa, Vida máxima, Cooldown), pagos com as **Partículas** da partida. Cada toque compra 1 nível, com custo crescente; valem só para aquela partida.

## Glossário do jogo (decidido pelo usuário em 2026-11-04; decisão 40)

Nomes oficiais que o jogador vê. Os **identificadores de código continuam em inglês** e **não serão renomeados agora** (ex.: `skill_meteor`, `particles`); a troca dos textos nos docs e na UI é gradual.

| Nome oficial | Era chamado de | O que é | Estado |
|---|---|---|---|
| **Módulo** | skill, poder ativo | poder ativo com cooldown (ex.: o meteoro); a conta abre os slots de Módulo nos níveis 3, 7 e 12 | M1: 1 Módulo (meteoro) |
| **Partículas** | moeda da partida | moeda dropada pelos inimigos mortos; compra os upgrades da partida e **some no fim dela**. **Não cai no mapa por enquanto** (só aumenta o contador; pode mudar depois). Ícone: **estrela verde, como um "chipzinho"** | M1 (o ícone ainda é dourado: T-160 e T-161) |
| **Moeda** | Gold | moeda do jogo (meta): sobe nível de Módulos, Fragmentos, Núcleos etc. Ícone: **moeda dourada** | futuro (M2+) |
| **Componente** | Fragmento, módulo (equipamento) | equipamento do Anima (3 no M7, 6 espaços no M13), com raridade e fusão | M7 e M13 (decisão 54) |
| **Fragmento** | — | **Fragmento de Módulo**: item usado para atualizar Módulos | M14 (decisão 54) |
| **Núcleo** (talento) | talento, árvore de talentos | cada nó da árvore, comprado com Moeda | futuro; **atenção:** colide com o "Núcleo" que já nomeia a vida do Anima no HUD (ver nota) |

> **Colisão de nome (resolvida, decisão 41):** a barra de vida do Anima no HUD passa a se chamar **"ENERGIA"**; "Núcleo" fica para os talentos.

## Progressão (decidida pelo usuário em 2026-11-03; detalhe no AG04)

- **Nível da conta (do jogador):** sobe com XP das partidas. Ele desbloqueia os **slots de Módulo** (as skills):
  - a conta começa com **0 skills**;
  - o **slot 1** abre no nível **3**, o **slot 2** no nível **7** e o **slot 3** no nível **12**;
  - os valores são ajustáveis no balanceamento.
  - **[A DEFINIR]:** se a conta ganha outros prêmios por nível.
- **Módulos (as skills):** são "poderes especiais" ativos, com cooldown. São desbloqueadas pela progressão e não são cards.
  - **[A DEFINIR]:** como cada skill evolui.
- **Componentes** (ex-Fragmentos, decisão 54): são os equipamentos do Anima (**6 espaços** a partir do M13), melhorados com **Moeda**. Têm raridade Comum → Raro → Épico → Lendário.
  - **Fusão:** Componentes idênticos da mesma raridade viram 1 da raridade seguinte.
- **Upgrades da partida:** comprados durante a partida com **Partículas** e perdidos ao fim.
- **Moedas:**
  - **Moeda:** a moeda do jogo (meta), dourada. A quantidade ganha varia a cada partida jogada.
  - **Partículas:** a moeda da partida, estrela verde (chip). Começa em zero, é zerada a cada partida e não cai no mapa por enquanto.
- **Núcleos (a árvore de talentos):** continua, comprada com Moeda. O detalhe fica no AG04.
- **[A DEFINIR]:** quais atributos os Fragmentos dão (dano, velocidade de ataque, vida, armadura, regeneração, redução de cooldown).

## Roadmap (decisão 53, 2026-11-05)

Visão do dono, **não definitiva**; detalhe completo em [docs/roadmap.md](roadmap.md). Cada marco = uma versão com tag e PR `dev → main`; versões fechadas importantes ganham branch própria (decisão 52).

| Marco | Versão | Tag | Foco |
|---|---|---|---|
| M1 | v0.1.0 | Vertical slice | combate e visual (só tag, sem branch) |
| M2 | v0.2.0 | **Versão Alfa** (branch `alfa`) | menu holográfico, ciclo jogar → ganhar → voltar, Moeda, save local, nível de conta, XP, música de entrada e som do tiro |
| M3 | v0.2.1 | Hangar | menu reestruturado |
| M4 | v0.2.2 | Núcleos | árvore de 10–12 talentos |
| M5 | v0.2.3 | Módulos | congelamento, escudo, choque; seleção; slots por nível; evolução com Moeda |
| M6 | v0.2.4 | Recompensas | vida ou baú durante a partida |
| M7 | v0.2.5 | Componentes | equipamentos (ex-Fragmentos), drop, inventário, upgrade |
| M8 | v0.2.6 | Configurações e Localização | volume, sons, efeitos, idioma; inglês e espanhol |
| M9 | v0.2.7 | Onboarding | tutoriais |
| M10 | v0.3.0 | **Versão Beta** (demo pública, branch `beta`) | 5 fases, inimigos, 2 chefes, progressão, polimento |
| M11 | v0.3.1 | Desktop | build desktop |
| M12 | v0.3.2 | Skins | skins do Anima |
| M13 | v0.4.0 | Expansão: Componentes | 6 espaços, raridades, fusão |
| M14 | v0.4.1 | Expansão: Módulos | mais Módulos, Fragmentos de Módulo |
| M15 | v0.4.2 | Expansão: Núcleos | árvore maior |
| M16 | v0.5.0 | Efeitos de áudio | sons de UI, Módulos e efeitos |
| M17 | v0.6.0 | Expansão: fases | fase infinita, recompensas maiores |
| M18 | v0.7.0 | Backend | nuvem, login Google/Apple, ranking |
| M19 | v0.8.0 | Jogador | perfil |
| — | até v1.0.0 | TBD | baús semanais, mobile, monetização, lançamento |

## Escopo atual: M1 (demo do combate)

### DENTRO
| Área | Quantidade |
|---|---|
| Arena | 1, em retrato |
| Anima | 1, com arte final de demo |
| Ataque automático | 1 tipo de projétil |
| Skills | **1**: a de área (meteoro ou onda de choque), já liberada no slot 1. Os slots 2 e 3 aparecem bloqueados |
| Upgrades da partida | Fileira de 5 botões de compra em tempo real, acima das skills, pagos com Partículas |
| Visual | **Polido, nível de demo:** arte, VFX, partículas e game feel finais para esta fase (AG08 + AG09) |
| Inimigos | 3–4 arquétipos (corredor, tanque, atirador, enxame) |
| Fase | 1, com ~10 ondas e 1 chefe |
| HUD | HP do Núcleo, `Wave X/Y`, Partículas, pausa, botões de skill |
| Telas | Toque para começar → Partida → Resultado (vitória ou derrota) → Jogar de novo |
| Plataforma | Chrome no PC e Safari no iPhone, retrato, toque + mouse + teclado |
| Idioma | Português do Brasil |

### FORA (até depois do M1)
Nível de conta, Módulos de controle e defesa, Fragmentos e fusão, Núcleos (talentos), save, backend, contas, ads, compras, skins, áudio final, mais de uma fase, localização, builds nativos.

## Referências (gênero, estrutura e acabamento, **nunca para copiar**)

- **Archero:** malha de retenção e progressão (equipamentos, farm, sessões curtas) e **referência de acabamento visual**: 2D cartoon casual colorido, câmera 3/4, UI com botões grandes e molduras por raridade (decisões 31–34). Tema próprio: Cyber-Mystic.
- **Gêneros:** tower/base defense, bullet hell e survivor-likes, pela densidade de inimigos e projéteis.

Proibido usar personagens, criaturas, nomes, ícones, sons, interface ou arte de qualquer jogo existente.

## Plataforma e restrições do navegador (detalhes no `CLAUDE.md`)

- Godot 4.7, GDScript, testes com GUT, renderer Compatibility (WebGL 2), exportação **single-threaded**.
- Metas iniciais (a confirmar no M0):
  - 60 fps no PC; **média ≥ 45 fps no iPhone 11 Pro** no pior caso (150 inimigos vivos; meta revisada pelo dono em 2026-11-06, ver `docs/adr/0001-desempenho-e-exportacao-web.md`);
  - download inicial de **≤ ~15 MB**.
- O áudio só toca depois do primeiro toque, por isso há a tela "toque para começar".
- Backend **[A DEFINIR]**: Firebase é o favorito e Nakama a alternativa.

## Time e responsabilidades

| Código | Agente | Responsável por | Entra em |
|---|---|---|---|
| AG00 | Game Dev Líder | Gerencia (não implementa): plano, Bíblia, decisões, briefings, validação, integração, commits | Sempre |
| AG01 | Gameplay / Combate | Arena, Anima, ataque automático, skills, inimigos, ondas, chefe | M1 |
| AG02 | UI | HUD, telas, menus, entrada, tema, localização (chaves), tutoriais | M0/M1 |
| AG03 | QA / Revisor | Testes, revisão, medições, veredito passa ou não passa | M1 |
| AG04 | Meta-jogo / Dados | Nível de conta, Núcleos, Módulos (evolução), Componentes, fusão, upgrades da partida (dados e balanceamento), economia | M1/M2 |
| AG05 | Backend | Interface `Backend`, save, provedor online, segurança | M2/M3 |
| AG06 | Backlog | **Arquivado** (decisão 57): o AG00 mantém o backlog | — |
| AG07 | Arquiteto Técnico | `project.godot` (Input Map, layers, autoloads), `src/core/`, arquitetura, contratos entre módulos, ADRs, metas de desempenho | Sempre |
| AG08 | Diretor de Arte | Direção visual, paleta, sprites, ícones, fundo da arena, arte da UI, guia de estilo (`docs/arte.md`) | M1 em diante |
| AG09 | VFX | Shaders, partículas, brilho, impactos, telegraphs e feedback visual, dentro do orçamento do iPhone | M1 em diante |
| AG10 | Plataforma | Exportação Web (`export_presets.cfg`, `web/`), PWA, deploy, tamanho e desempenho do build, build desktop | M1 em diante |
| AG11 | Áudio | Música, efeitos, mixagem, barramentos e desbloqueio de áudio na web | M2 em diante |
| AG12 | Conteúdo / Fases | Fases, ondas, distribuição de inimigos e curva de dificuldade (em dados) | M10 em diante |

Equipe: 1 usuário + agentes de IA. O prazo é por marcos, sem datas fixas.

### Comando e delegação

Cada agente roda numa **sessão própria** do Claude Code, com o nome do agente. O **AG00 comanda**: tudo passa por ele.

| Sessão | Instrução |
|---|---|
| AG00_gamedev-lider (sessão principal) | [agentes/AG00_gamedev-lider.md](agentes/AG00_gamedev-lider.md) |
| AG01_gameplay | [agentes/AG01_gameplay.md](agentes/AG01_gameplay.md) |
| AG02 (UI) | [agentes/AG02_uiweb.md](agentes/AG02_uiweb.md) |
| AG03_qa | [agentes/AG03_qa.md](agentes/AG03_qa.md) |
| AG04_metajogo | [agentes/AG04_metajogo.md](agentes/AG04_metajogo.md) |
| AG05_backend | [agentes/AG05_backend.md](agentes/AG05_backend.md) |
| AG06 (Backlog, arquivado) | [agentes/AG06_backlog.md](agentes/AG06_backlog.md) |
| AG07 (Arquiteto) | [agentes/AG07_arquiteto.md](agentes/AG07_arquiteto.md) |
| AG08 (Arte) | [agentes/AG08_arte.md](agentes/AG08_arte.md) |
| AG09 (VFX) | [agentes/AG09_vfx.md](agentes/AG09_vfx.md) |
| AG10 (Plataforma) | [agentes/AG10_plataforma.md](agentes/AG10_plataforma.md) |
| AG11 (Áudio) | [agentes/AG11_audio.md](agentes/AG11_audio.md) |
| AG12 (Conteúdo/Fases) | [agentes/AG12_conteudo.md](agentes/AG12_conteudo.md) |

Regras:
1. **Usuário → AG00 → agentes.** O usuário fala só com o AG00, que transforma o pedido em briefing e delega.
2. **Nenhum agente trabalha sem briefing** em `docs/briefings/BRF-xxx_AGxx_<entrega>.md` (modelo em `AG00` §5), com critério de pronto.
3. **A entrega volta ao AG00** no formato *entregue · validação · suposições · não testado · próximo passo*. O AG00 valida, integra, faz o commit e decide o próximo passo.
4. **Agentes não pedem trabalho uns aos outros.** Se um precisa de algo, pede ao AG00. Todos podem ler os documentos uns dos outros.
5. **Decisões criativas, de escopo e de stack** sobem ao usuário pelo AG00, com 2 ou 3 opções e uma recomendação.
6. Cada agente escreve só nas suas pastas ([estrutura.md](estrutura.md)). `docs/00_*`, `decisoes.md`, `briefings/` e `agentes/` são do AG00; os arquivos compartilhados do Godot são do AG07.
7. Todos trabalham na `dev`, na mesma pasta. **Só o AG00 faz commit.** Sessões em paralelo só com arquivos diferentes.
8. **Economia de tokens** em todas as interações.

## Links

- Jogo: [produção](https://projectanimagame.netlify.app) · [dev](https://dev--projectanimagame.netlify.app)
- Backlog: [backlog.md](backlog.md) · Marcos: [marcos.md](marcos.md) · Decisões: [decisoes.md](decisoes.md) · Estrutura: [estrutura.md](estrutura.md) · Setup: [setup.md](setup.md) · Git: [git-workflow.md](git-workflow.md)
- GDD original: [gdd.md](gdd.md) · Agentes: [agentes/](agentes/) · Briefings: `briefings/`
