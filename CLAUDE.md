# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Idioma:** documentação, commits e conversa em português (pt-BR). Identificadores de código em inglês.
>
> **Status:** fase de ideação. Quase nada aqui é definitivo. Itens marcados **[Proposta]** são sugestões ainda não aprovadas e itens **[A definir]** estão em aberto. Não trate uma proposta como decisão: pergunte antes de agir com base nela.

## Economia de tokens (regra obrigatória)

Priorize sempre o **menor gasto de tokens** possível, em tudo:
- **Respostas e relatórios:** curtos e diretos, sem repetir contexto já conhecido.
- **Leitura:** só leia o necessário (trechos em vez de arquivos inteiros, buscas direcionadas).
- **Briefings:** objetivos. O líder garante que as sessões especialistas sigam esta mesma regra.
- **Commits:** agrupe o trabalho e faça commit ao fechar uma etapa, não a cada pequena alteração.

## Git (regras obrigatórias)

- **Trabalhe e faça commit somente na branch `dev`.** O líder faz commit e push por conta própria ao concluir uma etapa de trabalho.
- **A `main` é protegida.** Nunca faça commit nem push nela; ela só recebe mudanças por Pull Request de `dev` → `main`, aberto **apenas quando o dono do projeto pedir**.
- **Não crie outras branches** sem pedido explícito.
- Detalhes em [docs/git-workflow.md](docs/git-workflow.md).

## Papel do Claude

O Claude principal é o **game dev líder** do projeto e o **único interlocutor** do dono. Ele **gerencia e não implementa**: quebra o trabalho, distribui as tarefas entre agentes especialistas, revisa e integra o que eles entregam, registra as decisões e faz os commits. Código, cenas e configurações do Godot são sempre feitos por um agente. Cada especialista é uma **sessão própria** iniciada pelo líder. Veja a [Bíblia](docs/00_biblia_projeto.md) (Time e Comando) e [docs/agentes/](docs/agentes/).

**Se você é uma sessão especialista:**
- Trabalhe só no escopo e nos arquivos do seu briefing.
- Não faça commit, push nem crie branches.
- Não altere arquivos compartilhados (`project.godot`, autoloads, Input Map) sem autorização no briefing.
- Ao terminar, reporte o que mudou e o que não foi verificado.

## Documentação

| Arquivo | Conteúdo |
|---|---|
| [docs/00_biblia_projeto.md](docs/00_biblia_projeto.md) | **Bíblia do projeto**: pitch, escopo do marco atual, roadmap, time e regras de comando. **Leia primeiro.** |
| [docs/gdd.md](docs/gdd.md) | GDD original |
| [docs/decisoes.md](docs/decisoes.md) | Registro de decisões, com estado de cada uma. **Atualize quando algo for decidido.** |
| [docs/estrutura.md](docs/estrutura.md) | Estrutura de pastas e regras de dependência entre módulos |
| [docs/agentes/](docs/agentes/) | Instruções de cada agente (`AGxx_nome.md`) |
| `docs/briefings/` | Briefings do líder para os agentes (`BRF-xxx_AGxx_<entrega>.md`) |
| [docs/setup.md](docs/setup.md) | Ferramentas a instalar |
| [docs/git-workflow.md](docs/git-workflow.md) | Fluxo de branches, commits e PRs |

## O projeto

**Project: Anima** é um jogo hybrid-casual de defesa de base com bullet hell e meta-RPG, pensado primeiro para a web. O GDD completo está em [docs/gdd.md](docs/gdd.md).

- O jogador controla o **Anima**, um receptáculo neutro **fixo no centro** da arena. **Não há joystick nem movimento.**
- O ataque básico é automático e mira no inimigo mais próximo ou de maior prioridade.
- O jogador age por **Skills Ativas com cooldown**: área, controle de grupo e defensiva. No mobile são botões de toque; no PC, clique ou as teclas `1`, `2`, `3` e `Espaço`.
- A partida avança por ondas (`Wave X/Y`) até o chefe e termina se o HP do Núcleo chegar a zero. Cada sessão dura de 3 a 10 minutos.
- **Progressão** (detalhe na seção "Progressão" da Bíblia; substitui os cards do GDD):
  - **Nível da conta:** desbloqueia os slots de skill (slot 1 no nível 3, slot 2 no 7 e slot 3 no 12). A conta começa sem skills.
  - **Moedas:** **Gold** é a do jogo (meta), com ganho variável por partida. **Partículas** é a da partida: começa em zero e é zerada a cada partida.
  - **Módulos:** são os equipamentos do Anima, melhorados com Gold, com raridade e **fusão** (3 iguais viram 1 da raridade seguinte).
  - **Upgrades da partida:** comprados entre ondas com Partículas; valem só para ela.
  - **Árvore de talentos:** comprada com Gold.
- **Monetização:** rewarded ads (multiplicar moedas ou reviver), skins cosméticas e moeda premium.
- **Visual:** tema Cyber-Mystic em **2D cartoon casual**: colorido, formas arredondadas, contorno e sombra suave, **câmera 3/4**. O Anima é um núcleo (objeto) no centro, pronto para skins. UI com botões grandes e molduras por raridade. Interface em **modo retrato**. Guia em `docs/arte.md`.
- O Archero é referência de **gênero, retenção e acabamento visual**. Inspiração de estilo, nunca cópia: não copie arte, nomes, assets, ícones nem layouts de jogos existentes.

## Stack

| Camada | Escolha | Observações |
|---|---|---|
| Engine | Godot 4.x (versão estável mais recente), exportação **Web** | Renderer **Compatibility** (WebGL 2) |
| Linguagem | **GDScript** | O Godot 4 com C#/.NET não exporta para Web. Escolher C# acaba com o web-first. |
| Backend | **[A definir]**. Favorito: Firebase (Auth anônimo, Firestore, Remote Config, Hosting). Alternativa a avaliar: **Nakama** | No protótipo, salvar localmente. Decidir antes de implementar cards, fusão e economia (ver Arquitetura). |
| Lógica no servidor | Depende do backend: Cloud Functions (Firebase, exige o plano Blaze) ou o runtime do Nakama | |
| Testes | **GUT** | |
| Ads / pagamentos web | **[A definir]** | O AdMob não cobre web. Avaliar Google H5 Games Ads ou SDKs de portais. Pagamentos: Stripe ou similar. |

## Restrições técnicas importantes (web/iPhone)

- **Exportação Web single-threaded (Thread Support desligado).** Com threads, o jogo precisa de SharedArrayBuffer e dos headers COOP/COEP. Isso complica a hospedagem e o Safari no iOS. Single-threaded roda em qualquer hosting estático.
- O alvo de desempenho é o **Safari no iPhone**. Cuidado com:
  - partículas em excesso: prefira `CPUParticles2D` ou pools a muitas instâncias;
  - alocação por frame;
  - o tamanho do `.pck` e do `.wasm`.
- Áudio na web só começa depois da primeira interação do usuário. Planeje uma tela de "toque para começar".
- Toda interface deve funcionar em retrato com toque e com mouse e teclado, usando as Input Actions do projeto, nunca teclas fixas no código.

## Arquitetura [Proposta]

Ainda não há código. As pastas já existem (com `.gitkeep`) e o projeto Godot ficará na raiz. Para o mapa das pastas e as regras de dependência entre `src/match`, `src/meta`, `src/backend` e `src/ui`, veja [docs/estrutura.md](docs/estrutura.md). Os princípios abaixo orientam a estrutura inicial:

- **Dados separados de lógica.** Skills, cards, inimigos, ondas e tabelas de atributos ficam em `Resource`s (`.tres`) e são carregados pelo código. Os valores de balanceamento podem ser sobrescritos pelo Remote Config.
- **Lógica de meta-jogo pura**, sem depender de cena nem de rede: fusão, custos, cálculo de atributos e drops. Isso facilita testar de forma isolada e, se preciso, replicar no servidor.
- **Camada de backend atrás de uma interface** (autoload `Backend`). O jogo nunca chama um provedor diretamente.
  - **Primeira implementação: local.** Salva em `user://`, que na web vira IndexedDB. Ela serve para o protótipo, para o editor e para os testes.
  - Se a escolha for Firebase: não há SDK para Godot. Na web, usar o **Firebase JS SDK via `JavaScriptBridge`**, com scripts no HTML shell da exportação.
  - Se a escolha for Nakama: existe um SDK oficial para Godot, que também funciona na web.
- **Economia com autoridade no servidor**, depois que o backend for escolhido. O cliente web é totalmente manipulável. Por isso, fusão, gasto e ganho de moedas e abertura de caixas devem ser validados no servidor. O cliente só exibe o estado.
- **Fluxo de cenas:** Boot (auth + config) → Menu/Hangar (meta) → Partida (arena) → Resultado. A partida não conversa com o backend: ela produz um resultado que o meta-jogo envia.

## Comandos

`godot` = `"/c/Program Files/Godot/Godot_v4.7.2-stable_win64.exe"` (Godot 4.7.2 nesta máquina; não está no PATH).

```bash
# Abrir o editor
godot --editor --path .

# Testes (GUT 9.7.1, lê .gutconfig.json: tests/unit e tests/integration). Num clone limpo, rode antes: godot --headless --path . --import
godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit
# Um único arquivo de teste
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_smoke.gd -gexit

# Exportar para Web (precisa de um preset "Web" em export_presets.cfg e dos export templates)
godot --headless --path . --export-release "Web" build/web/index.html

```

O comando de deploy para um link de teste (iPhone/PC) depende do hosting escolhido **[A definir]**. Com o Firebase, seria `firebase hosting:channel:deploy preview`.

Para iterar rápido no PC, use o botão "Remote Debug → Run in Browser" do editor Godot.
