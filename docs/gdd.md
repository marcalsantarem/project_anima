# GAME DESIGN DOCUMENT (GDD): "PROJECT: ANIMA" (WEB-FIRST)

> Documento original do dono do projeto. As decisões técnicas posteriores, que podem divergir deste texto, estão em [decisoes.md](decisoes.md).

## 1. VISÃO GERAL DO PROJETO & CONCEITO CHAVE
* **Título do Jogo:** Project: Anima
* **Gênero:** Hybrid-Casual / Base Defense + Bullet Hell / Action Meta-RPG.
* **Plataformas-Alvo:** **Web-First (Navegadores Desktop e Mobile, ex: Safari no iPhone e Chrome no PC)**, com facilidade de testes instantâneos via link e escalabilidade futura para aplicativos nativos (Mobile Stores / Steam).
* **Público-Alvo:** Jogadores casuais a mid-core que apreciam loops de progressão viciantes, estilos visuais vibrantes e ação com tomada de decisão tática de curta duração (sessões de 3 a 10 minutos).
* **Core Premise:** Um jogo de defesa de base central em que o jogador controla um "Receptáculo/Avatar Neutro" (O Anima) posicionado no centro fixo da arena. O Anima dispara ataques básicos automaticamente, enquanto o jogador intervém ativamente através do acionamento estratégico de Skills Ativas (com tempos de recarga/cooldown) ativadas por botões na tela (toque) ou atalhos de teclado/clique no PC.

---

## 2. NARRATIVA & IDENTIDADE VISUAL
* **Significado do Nome ("Anima"):** Do latim *Anima* ("alma", "sopro vital"). Representa um receptáculo neutro e inerte que ganha vida, forma e estilo através da "alma" (skin, elementos e cards) infundida pelo jogador.
* **Estética Visual (Inspirada no Archero):**
  * **Perspectiva:** Visão superior limpa (Top-Down / Isométrica suave).
  * **Paleta & Estilo:** "Cyber-Mystic Minimal" e Hyper-casual polido. Cores suaves/escuras nos cenários para alto contraste com projéteis vibrantes, efeitos de partículas coloridos e barras de status nítidas.
  * **Skins & Receptáculos:** O avatar neutro permite total flexibilidade visual para colecionáveis de skins (Mágico/Arcano, Cyberpunk, Sombrio/Espectro, etc.) sem quebrar a lógica do universo.

---

## 3. LOOP DE GAMEPLAY & MECÂNICAS CORE

### A. Em Batalha (In-Match / Active Loop)
* **Posicionamento:** Fixo no centro da tela. O jogo **NÃO utiliza Joystick de movimento**.
* **Ataque Automático (Idle Side):** O Anima mira e dispara tiros básicos automaticamente no inimigo mais próximo ou com maior prioridade.
* **Skills Ativas (Action Side):** O jogador possui slots na interface para utilizar habilidades ativas com tempo de recarga (Cooldown):
  * *Skill de Área (Ex: Meteoro / Míssil):* Dano massivo concentrado em grupo de inimigos.
  * *Skill de Controle de Grupo (Ex: Onda EMP / Congelamento):* Paralisa ou desacelera hordas em momentos críticos.
  * *Skill Defensiva/Utilitária (Ex: Escudo do Núcleo / Invulnerabilidade):* Absorve ou reflete dano temporariamente.
* **Condição de Vitória/Derrota:** Sobreviver a ondas sucessivas de inimigos (*Wave: X/Y* no topo da tela) até o Chefe da fase. Se a barra de HP do Anima/Núcleo chegar a zero, a partida encerra.

### B. Meta-Game & Progressão (Out-of-Match / Retenção)
Inspirado na malha de retenção e "farm" do *Archero*:
* **Sistema de Cards de Skills (Raridade & Fusão):**
  * As skills ativas são representadas por Cards equipáveis.
  * *Raridades:* Comum (Cinza) ➡️ Raro (Azul) ➡️ Épico (Roxo) ➡️ Lendário (Dourado).
  * *Sistema de Fusão (Loot Loop):* A junção de 3 Cards idênticos da mesma raridade permite a fusão para o nível de raridade superior, desbloqueando buffs numéricos e novos efeitos visuais para a skill.
* **Atributos Permanentes (Módulos de Stats):**
  * Evolução contínua de atributos do Anima na oficina/hangar (Dano Base, Velocidade de Ataque, Vida Máxima, Armadura, Regeneração e Redução de Cooldown).
  * Árvore de Talentos fixa mantida via moedas obtidas em todas as partidas.

---

## 4. ESTRUTURA DE MONETIZAÇÃO (MODELO HÍBRIDO)
1. **Rewarded Ads & Engajamento Web:**
   * Vídeos premiados para multiplicar moedas ou reviver instantaneamente.
   * Recompensas diárias e abertura de caixas de suprimento no menu.
2. **In-App Purchases / Web Microtransactions & Skins:**
   * Venda de Skins cosméticas para o Anima (alterando visual e efeitos de projéteis).
   * Pacotes de Moeda Premium para compra direta de Caixas de Cards.

---

## 5. ARQUITETURA TÉCNICA & STACK DE DESENVOLVIMENTO

### Engine & Client-Side (Web-First)
* **Engine:** Godot Engine (Godot 4.x) com exportação otimizada para **HTML5 / WebGL**.
* **Vantagem Web-First:** Testes instantâneos e sem atrito via navegador (Safari no iPhone, Chrome no PC) sem necessidade de builds nativas complexas a cada alteração.
* **Linguagem:** GDScript ou C#.
* **Responsividade:** Layout adaptável para telas verticais (modo retrato) focando na experiência mobile-web sem perder o apelo visual.

### Backend & Nuvem
* **Plataforma Cloud:** Google Firebase.
* **Autenticação:** Firebase Auth (Login Anônimo/Guest inicial sincronizado na nuvem).
* **Banco de Dados (Inventário & Progressão):** Firebase Firestore para salvar o estado global do jogador (Cards de Skills, Níveis de Fusão, Atributos e Coins) acessível de qualquer navegador.
* **Remote Config:** Para balanceamento dinâmico de atributos e taxas de drop sem precisar atualizar o código web.

---

## 6. INTERFACE DE USUÁRIO (UI/UX)
* **In-Game HUD:**
  * Topo: Barra de HP do Núcleo, Barra de Progresso de Ondas (*Wave: X/Y*), Contador de Moedas e Pausa.
  * Centro: Arena e combate automático do Anima (sem controle de movimento).
  * Canto Inferior: Botões circulares limpos das **Skills Ativas**, exibindo tempo de cooldown regressivo em segundos e indicativo visual quando prontas.
* **Controles Cross-Device:**
  * **Mobile (Safari/Chrome):** Toque direto na tela com um dedo nos botões de skills.
  * **Desktop (PC):** Cliques de mouse nas skills ou atalhos de teclado (`1`, `2`, `3`, `Espaço`).
