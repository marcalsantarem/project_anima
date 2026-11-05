# Roadmap de versões — Project: Anima

> Visão do dono do projeto (2026-11-05, decisão 53). **Não é definitivo**: guia a ordem das versões. As tarefas técnicas de cada marco ficam no [backlog](backlog.md), quebradas pelo AG00 quando o marco começar.
> Cada marco = uma versão com **tag** (nome entre parênteses), fechada com PR `dev → main`. Versões fechadas importantes ganham branch própria (decisão 52; a primeira é `demo` = v0.1.0).

| Marco | Versão | Nome da tag | Foco |
|---|---|---|---|
| M1 | v0.1.0 | Vertical slice | o que já está mapeado |
| M2 | v0.2.0 | **Versão Alfa** | ciclo básico do meta + áudio básico |
| M3 | v0.2.1 | Hangar | menu reestruturado |
| M4 | v0.2.2 | Núcleos | talentos |
| M5 | v0.2.3 | Módulos | 3 novos Módulos e seleção |
| M6 | v0.2.4 | Recompensas | recompensas durante a partida |
| M7 | v0.2.5 | Componentes | equipamentos |
| M8 | v0.2.6 | Configurações e Localização | opções e idiomas |
| M9 | v0.2.7 | Onboarding | tutoriais |
| M10 | v0.3.0 | **Versão Beta** (demo pública) | expansão de conteúdo |
| M11 | v0.3.1 | Desktop | build desktop |
| M12 | v0.3.2 | Skins | skins do Anima |
| M13 | v0.4.0 | Expansão: Componentes | 6 espaços, raridades, fusão |
| M14 | v0.4.1 | Expansão: Módulos | mais Módulos e Fragmentos de Módulo |
| M15 | v0.4.2 | Expansão: Núcleos | árvore maior |
| M16 | v0.5.0 | Efeitos de áudio | sons de UI, Módulos e efeitos |
| M17 | v0.6.0 | Expansão: fases | fase infinita e recompensas maiores |
| M18 | v0.7.0 | Backend | nuvem, login e ranking |
| M19 | v0.8.0 | Jogador | perfil |
| — | até v1.0.0 | TBD | baús semanais, mobile, monetização, lançamento |

## M1 — v0.1.0 — Vertical slice
- O que já temos mapeado (backlog M1).

## M2 — v0.2.0 — Versão Alfa
Demo básica:
- Menu e botões holográficos
- Ciclo "jogar → ganhar → voltar"
- Moedas
- Save local
- Nível de conta
- Moeda e XP por partida, resultado com recompensa
- Música de entrada
- Som de ataque básico

## M3 — v0.2.1 — Hangar
- Reestruturar o menu para comportar todos os botões do hangar.

## M4 — v0.2.2 — Núcleos
- Criar tela de Núcleos.
- Criar árvore pequena de Núcleos (talentos), com 10 a 12.
- Aplicar os efeitos dos Núcleos nas partidas.
- Criar a compra dos talentos com Moedas e salvar localmente.

## M5 — v0.2.3 — Módulos
- Criar tela de Módulos.
- Implementar Módulo de controle (congelamento).
- Implementar Módulo de defesa (escudo).
- Implementar Módulo de ataque (choque que se espalha).
- Desbloquear os slots de Módulos na partida conforme o nível da conta.
- Criar a evolução dos Módulos por Moedas (a cada nível, o efeito aumenta um pouco).
- Criar tela de seleção de Módulos (haverá mais de 4; o jogador escolhe qual vai em cada slot).

## M6 — v0.2.4 — Recompensas
- Criar recompensas durante a partida, permitindo escolher entre recuperar vida ou um baú (neste momento, só com Moedas).

## M7 — v0.2.5 — Componentes
Componentes (antigos "Fragmentos", renomeados; decisão 54):
- Criar Componentes, itens que podem ser equipados.
- Criar Componentes no save (3 neste momento: 1 de ATK, 1 de DEF e 1 híbrido que pode ser os dois).
  - ATK = adiciona Atk power ou Atk spd.
  - DEF = adiciona Defesa ou Vida máxima.
- Criar o drop de Componentes.
- Adicionar os Componentes às recompensas durante a partida e no final.
- Criar tela de Componentes com inventário e lugar para equipar no personagem.
- Aplicar os efeitos dos Componentes.
- Criar o upgrade de Componentes com Moedas, aumentando seus adicionais.

## M8 — v0.2.6 — Configurações e Localização
- Criar tela de configurações com volume, habilitar sons, efeitos ligados/desligados e idioma.
- Criar a localização de tudo que é escrito no jogo para inglês e espanhol.

## M9 — v0.2.7 — Onboarding
Tutoriais para os primeiros momentos do jogo:
- Início de jogo.
- Equipar Núcleo.
- Equipar Módulo.
- Equipar Componentes.

## M10 — v0.3.0 — Versão Beta (demo pública)
Expansão de conteúdo:
- Criar 5 fases inteiras.
- Criar novos tipos de inimigos.
- Criar 2 novos chefes.
- Definir tipos de fases e os tipos de inimigos por fase.
- Definir a progressão de fases e salvar a progressão localmente.
- Criar recompensas durante a partida.
- Testar o balanceamento.
- Polir gráficos, efeitos e gameplay.

## M11 — v0.3.1 — Desktop
- Criar a build para desktop.

## M12 — v0.3.2 — Skins
- Permitir trocar a skin do Anima.
- Criar tela de skins, com as que o jogador tem e as bloqueadas.
- Criar 2 skins padrão desbloqueáveis com Moeda.

## M13 — v0.4.0 — Expansão: Componentes
- Aumentar para 6 a quantidade de equipáveis, ajustando a tela e o save local.
- Criar raridade para os Componentes: básico (sem cor, nível máx. 10) → especial (verde, máx. 20) → raro (azul, máx. 30) → épico (laranja, máx. 40) → mítico (vermelho, máx. 50).
- Criar a fusão de Componentes para aumentar a raridade e os atributos.

## M14 — v0.4.1 — Expansão: Módulos
- Criar mais Módulos.
- Criar **Fragmentos de Módulos** (decisão 54).
- Criar a atualização de Módulos usando Fragmentos.

## M15 — v0.4.2 — Expansão: Núcleos
- Expandir a árvore de Núcleos compráveis.

## M16 — v0.5.0 — Efeitos de áudio
- Sons de UI, Módulos e efeitos.

## M17 — v0.6.0 — Expansão: fases
- Criar fase infinita.
- Criar recompensas maiores durante a partida (tiro duplo, aumento maior de vida, tiro de fogo etc.), escolhendo 1 entre 3 opções entre as ondas.
- Criar mais fases.

## M18 — v0.7.0 — Backend
- Conta guest, save na nuvem, economia validada no servidor, Remote Config.
- Login com Google e Apple.
- Ranking de jogadores.

## M19 — v0.8.0 — Jogador
- Tela de perfil do usuário.
- Escolha de nome.
- Envio de foto.

## A definir até a v1.0.0
- Baús de recompensa semanais.
- Mobile (lojas).
- Monetização.
- Lançamento.

## Ideias futuras
- Missões.
- Passe de batalha.
- Duelo de progressão entre jogadores em fases infinitas.

## Pontos a confirmar com o dono
- No M8, os itens estavam marcados "v0.5.6" e "v0.5.7": entendido como erro de digitação (o marco é v0.2.6).
- No M12, "desbloqueáveis com gold": entendido como **Moeda** (Gold foi renomeado na decisão 40).
- O áudio básico (música de entrada e tiro) entra no M2; os demais sons, no M16.
