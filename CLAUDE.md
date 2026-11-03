# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Idioma:** documentação, commits e conversa em português (pt-BR). Identificadores de código em inglês.
>
> **Status:** fase de ideação. Quase nada aqui é definitivo. Itens marcados **[Proposta]** são sugestões ainda não aprovadas e itens **[A definir]** estão em aberto. Não trate uma proposta como decisão: pergunte antes de agir com base nela.

## Git (regras obrigatórias)

- **Trabalhe e faça commit somente na branch `dev`.** Faça commit e push na `dev` por conta própria sempre que fizer sentido salvar o trabalho.
- **A `main` é protegida.** Nunca faça commit nem push nela; ela só recebe mudanças por Pull Request de `dev` → `main`, aberto **apenas quando o dono do projeto pedir**.
- **Não crie outras branches** sem pedido explícito.
- Detalhes em [docs/git-workflow.md](docs/git-workflow.md).

## Papel do Claude

O Claude principal é o **game dev líder** do projeto e o **único interlocutor** do dono. Ele quebra o trabalho, distribui as tarefas entre agentes especialistas (subagentes), revisa e integra o que eles entregam, registra as decisões e faz os commits. Veja [docs/agentes.md](docs/agentes.md).

## Documentação

| Arquivo | Conteúdo |
|---|---|
| [docs/gdd.md](docs/gdd.md) | GDD original |
| [docs/decisoes.md](docs/decisoes.md) | Registro de decisões, com estado de cada uma. **Atualize quando algo for decidido.** |
| [docs/estrutura.md](docs/estrutura.md) | Estrutura de pastas e regras de dependência entre módulos |
| [docs/agentes.md](docs/agentes.md) | Proposta de divisão do trabalho em agentes |
| [docs/setup.md](docs/setup.md) | Ferramentas a instalar |
| [docs/git-workflow.md](docs/git-workflow.md) | Fluxo de branches, commits e PRs |

## O projeto

**Project: Anima** é um jogo hybrid-casual de defesa de base com bullet hell e meta-RPG, pensado primeiro para a web. O GDD completo está em [docs/gdd.md](docs/gdd.md).

- O jogador controla o **Anima**, um receptáculo neutro **fixo no centro** da arena. **Não há joystick nem movimento.**
- O ataque básico é automático e mira no inimigo mais próximo ou de maior prioridade.
- O jogador age por **Skills Ativas com cooldown**: área, controle de grupo e defensiva. No mobile são botões de toque; no PC, clique ou as teclas `1`, `2`, `3` e `Espaço`.
- A partida avança por ondas (`Wave X/Y`) até o chefe e termina se o HP do Núcleo chegar a zero. Cada sessão dura de 3 a 10 minutos.
- **Meta-jogo:**
  - As skills são **Cards** com raridade Comum → Raro → Épico → Lendário.
  - **Fusão:** 3 cards idênticos da mesma raridade viram 1 card da raridade seguinte.
  - Atributos permanentes: dano, velocidade de ataque, vida, armadura, regeneração e redução de cooldown.
  - Árvore de talentos comprada com moedas.
- **Monetização:** rewarded ads (multiplicar moedas ou reviver), skins cosméticas e moeda premium para caixas de cards.
- **Visual:** "Cyber-Mystic Minimal", top-down. Cenário escuro e suave contrastando com projéteis e partículas vibrantes. Interface em **modo retrato**.
- O Archero serve só de **referência de gênero e de retenção**. Não copie arte, nomes, assets nem o visual de jogos existentes.

## Stack

| Camada | Escolha | Observações |
|---|---|---|
| Engine | Godot 4.x (versão estável mais recente), exportação **Web** | Renderer **Compatibility** (WebGL 2) |
| Linguagem | **GDScript** **[Proposta]** | O Godot 4 com C#/.NET não exporta para Web. Escolher C# acaba com o web-first. |
| Backend | **[A definir]**. Favorito: Firebase (Auth anônimo, Firestore, Remote Config, Hosting). Alternativa a avaliar: **Nakama** | No protótipo, salvar localmente. Decidir antes de implementar cards, fusão e economia (ver Arquitetura). |
| Lógica no servidor | Depende do backend: Cloud Functions (Firebase, exige o plano Blaze) ou o runtime do Nakama | |
| Testes | GUT ou gdUnit4 **[A definir]** | |
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

## Comandos [Previstos — ajuste quando o projeto existir]

```bash
# Abrir o editor
godot --editor --path .

# Rodar testes headless (exemplo com GUT)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
# Um único arquivo de teste
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_fusion.gd -gexit

# Exportar para Web (precisa de um preset "Web" em export_presets.cfg e dos export templates)
godot --headless --path . --export-release "Web" build/web/index.html

```

O comando de deploy para um link de teste (iPhone/PC) depende do hosting escolhido **[A definir]**. Com o Firebase, seria `firebase hosting:channel:deploy preview`.

Para iterar rápido no PC, use o botão "Remote Debug → Run in Browser" do editor Godot.
