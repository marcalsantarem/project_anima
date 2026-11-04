# Backlog

> Mantido pelo AG06. O status reflete o que o AG00 confirmou. Formato e regras em [agentes/AG06_backlog.md](agentes/AG06_backlog.md). Andamento dos marcos em [marcos.md](marcos.md).

## Quadro

| ID | Título | Marco | Dono | Status |
|---|---|---|---|---|
| T-001 | Layers de colisão nomeadas | M0 | AG07 | feita |
| T-002 | Instalar GUT e teste smoke headless | M0 | AG03 | feita |
| T-003 | `docs/ui.md` (tokens, layout, fluxo de telas) | M0 | AG02 | feita |
| T-004 | Preset Web + HTML shell mínimo | M0 | AG02 | feita |
| T-005 | Build vazio no Chrome PC e no iPhone | M0 | AG02 | em validação |
| T-006 | Cena de estresse para confirmar metas de desempenho | M0 | AG02 | pronta p/ briefing |
| T-007 | ADR das metas de desempenho e da exportação single-threaded | M0 | AG07 | a fazer |
| T-008 | Deploy automático Web (GitHub Actions → Netlify) | M0 | AG02 | feita |
| T-101 | `docs/gameplay.md` (parâmetros e sinais) | M1 | AG01 | feita |
| T-102 | Autoload de fluxo de cenas | M1 | AG07 | feita |
| T-103 | Protótipo cinza: arena, Anima, 1 inimigo | M1 | AG01 | feita |
| T-104 | Ataque automático com pool | M1 | AG01 | feita |
| T-105 | Ondas por dados, HP do Núcleo, moedas, vitória/derrota | M1 | AG01 | feita |
| T-106 | Tema base e componentes de UI | M1 | AG02 | feita |
| T-107 | Overlay de debug Web (FPS, logs) | M1 | AG02 | pronta p/ briefing |
| T-108 | Base de skills + skill de área | M1 | AG01 | feita |
| T-109 | Skill de controle | M2 | AG01 | a fazer |
| T-110 | Skill de defesa | M2 | AG01 | a fazer |
| T-111 | Arquétipos: tanque, atirador, enxame | M1 | AG01 | feita |
| T-112 | HUD ligado aos sinais | M1 | AG02 | feita |
| T-113 | Telas: toque para começar, pausa, resultado | M1 | AG02 | feita |
| T-114 | Testes GUT de ondas, dano e cooldowns | M1 | AG03 | feita |
| T-115 | Chefe da fase 1 | M1 | AG01 | pronta p/ briefing |
| T-116 | Fase 1 completa (~10 ondas + chefe) | M1 | AG01 | a fazer |
| T-117 | Game feel | M1 | AG01 + AG09 | a fazer |
| T-118 | Desempenho no iPhone (150 inimigos / 300 projéteis) | M1 | AG01 | a fazer |
| T-119 | Otimização do build Web | M1 | AG02 | a fazer |
| T-120 | Validação do M1 | M1 | AG03 | a fazer |
| T-121 | Tema global no `project.godot` | M1 | AG07 | feita |
| T-122 | Ligar a arena real ao SceneFlow | M1 | AG07 | feita |
| T-123 | Seed no `Arena._rng` para testes determinísticos | M1 | AG01 | pronta p/ briefing |
| T-124 | Pasta `src/fx/` em `docs/estrutura.md` | M1 | AG07 | pronta p/ briefing |
| T-125 | Proposta da skill de área: meteoro × onda de choque | M1 | AG01 + AG08 | pronta p/ briefing |
| T-126 | Guia de estilo `docs/arte.md` + mockup da arena | M1 | AG08 | pronta p/ briefing |
| T-127 | Arte do Anima, inimigos, chefe, projéteis e fundo | M1 | AG08 | feita |
| T-128 | Ícones e arte da UI | M1 | AG08 | a fazer |
| T-129 | `docs/vfx.md` + pool de efeitos | M1 | AG09 | a fazer |
| T-130 | VFX do ataque, acertos e mortes | M1 | AG09 | a fazer |
| T-131 | VFX da skill e do chefe | M1 | AG09 | a fazer |
| T-132 | Modo de efeitos reduzidos | M1 | AG09 | a fazer |
| T-133 | Dados e balanceamento dos upgrades da partida | M1 | AG04 | feita |
| T-134 | Lógica dos upgrades em tempo real (5 atributos) | M1 | AG01 | a fazer |
| T-135 | Fileira de 5 botões de upgrade no HUD | M1 | AG02 | a fazer |
| T-136 | Slots 2 e 3 do HUD bloqueados (cadeado) | M1 | AG02 | feita |
| T-137 | Trocar placeholders da partida pela arte final | M1 | AG01 | feita (sem chefe) |
| T-138 | Aplicar a arte da UI no HUD e nas telas | M1 | AG02 | a fazer |
| T-139 | Ajustar a skill de área à opção escolhida | M1 | AG01 | bloqueada |
| T-140 | Moeda da partida vira Partículas: sinais, código e `gameplay.md` | M1 | AG01 | feita |
| T-141 | Moeda da partida vira Partículas: HUD, telas e `ui.md` | M1 | AG02 | a fazer |
| T-142 | Novo guia de estilo 2D cartoon 3/4 + mockups PNG | M1 | AG08 | pronta p/ briefing |
| T-143 | Pipeline e fonte da arte final (opções e custos) | M1 | AG08 | pronta p/ briefing |
| T-144 | Arena em 3/4: Y-sort, âncoras, sombras, spawn | M1 | AG01 | feita |
| T-145 | Retema da UI no estilo cartoon (tokens, tema, fonte) | M1 | AG02 | feita |
| T-146 | Remover mockups rejeitados e excluir referências do export Web | M1 | AG07 | pronta p/ briefing |
| T-147 | Anima com skin trocável (Resource de aparência) | M2 | AG01 | a fazer |

## Próximas prontas p/ briefing

> **Decisão 21:** só o usuário libera briefings. A lista abaixo é sugestão; nada começa sem o OK dele.

1. **T-142** (AG08, novo guia + mockups PNG): caminho crítico da arte, dos VFX, da T-144 e da T-145; precisa da aprovação do usuário.
2. **T-143** (AG08, fonte da arte final): gera a decisão 34. Pode ir junto da T-142 no mesmo disparo.
3. **T-125** (AG01 + AG08, meteoro × onda de choque): libera a T-139.
4. **T-133** (AG04, upgrades da partida): libera a T-134 e a T-135.
- Mockup aprovado: **A "Jardim Arcano"** (decisão 36). A HUD deve ter a fileira de upgrades (decisão 35); a T-145 e a T-128 devem considerá-la.
- Também prontas: **T-146** (AG07), **T-140** (AG01), **T-136** (AG02), **T-123** e **T-115** (AG01), **T-107** e **T-006** (AG02).

## Paralelismo e conflitos

- **Feito até aqui:** M0 e o núcleo do M1 (T-101 a T-108, T-111 a T-114, T-121, T-122).
- **Trilhas paralelas do M1 (demo):**
  - Arte: {T-142, T-143} → {T-127, T-128} (AG08, em sequência).
  - Refatorações do novo estilo: T-142 → T-144 (AG01, `src/match/`) e T-142 → T-145 (AG02, `src/ui/`).
  - VFX: T-124 → T-129 → T-130 → T-131 → T-132 (AG09; a T-124 é do AG07).
  - Upgrades: T-133 (AG04) → T-134 (AG01) → T-135 (AG02, HUD).
  - Combate: T-123, T-115, T-139, T-116, T-137 (AG01, em sequência; `skills/` × `enemies/` só em paralelo com duas sessões).
  - UI: T-136 → T-135 → T-138 (AG02, `src/ui/`, em sequência); T-107 e T-006 em outra sessão.
- **Não paralelizar:**
  - T-134 com T-139 ou T-116 (mesmo dono e `src/match/`);
  - T-135, T-136, T-138, T-141 e T-145 (mesma pasta `src/ui/`);
  - T-144 com outras tasks do AG01 em `src/match/`;
  - T-137 com outras tasks do AG01 que mexam nas cenas de `match/`;
  - T-117: as partes do AG01, AG09 e AG02 em briefings separados, cada uma nos seus arquivos.

---

## M0 — Fundação

### T-001 — Layers de colisão nomeadas
- **Marco:** M0 · **Dono:** AG07 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-103
- **Arquivos:** `project.godot`
- **Pronto quando:**
  - layers 2D nomeadas: `anima`, `enemies`, `player_projectiles`, `enemy_projectiles`, `skill_areas`, `shield`;
  - tabela de layers e máscaras registrada em `docs/arquitetura.md`;
  - projeto abre sem erros.

### T-002 — Instalar GUT e teste smoke headless
- **Marco:** M0 · **Dono:** AG03 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-114, T-120
- **Arquivos:** `addons/gut/`, `.gutconfig.json`, `tests/unit/test_smoke.gd`
- **Pronto quando:**
  - versão do GUT compatível com Godot 4.7.2 instalada;
  - o comando headless do `CLAUDE.md` roda e passa 1 teste smoke;
  - comandos repassados ao AG00 para o `CLAUDE.md`; `project.godot` não é alterado.
- **Briefing:** BRF-004

### T-003 — `docs/ui.md`
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-106, T-112, T-113
- **Arquivos:** `docs/ui.md`
- **Pronto quando:** tokens (cores, tipografia, espaçamento), layout em retrato com safe area, posição dos botões de skill e fluxo de telas do M1 documentados.
- **Briefing:** BRF-002

### T-004 — Preset Web + HTML shell mínimo
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita
- **Depende de:** requisitos técnicos do AG07 (Compatibility, sem threads) · **Desbloqueia:** T-005, T-006, T-107
- **Arquivos:** `export_presets.cfg`, `web/`
- **Pronto quando:**
  - preset "Web": Compatibility, Thread Support desligado;
  - shell com meta viewport sem zoom, `touch-action: none` e bloqueio de gestos do Safari;
  - `--export-release "Web"` gera `build/web/index.html` sem erros; tamanho do build medido.
- **Briefing:** BRF-005

### T-005 — Build vazio no Chrome PC e no iPhone
- **Marco:** M0 · **Dono:** AG02 · **Status:** em validação
- **Depende de:** T-004, T-008 · **Desbloqueia:** T-007
- **Situação:** build no ar em dev--projectanimagame.netlify.app e conferido no PC; falta o teste do usuário no iPhone.
- **Arquivos:** `web/`, `docs/setup.md` (seção de deploy de teste, com autorização)
- **Pronto quando:**
  - build abre no Chrome do PC sem erros no console;
  - checklist rodado pelo usuário no iPhone: carrega, toque responde, sem zoom/scroll, retrato ok;
  - procedimento de deploy de teste documentado.

### T-006 — Cena de estresse para confirmar metas
- **Marco:** M0 · **Dono:** AG02 · **Status:** pronta p/ briefing
- **Depende de:** T-004 (T-005 para medir no iPhone) · **Desbloqueia:** T-007, T-118
- **Arquivos:** `tests/perf/` (cena isolada, sem lógica de jogo)
- **Pronto quando:** cena com ~150 sprites móveis e ~300 projéteis em pool roda no build Web; fps medido no PC e no iPhone e registrado.

### T-007 — ADR das metas de desempenho e da exportação single-threaded
- **Marco:** M0 · **Dono:** AG07 · **Status:** a fazer
- **Depende de:** T-002, T-005, T-006 · **Desbloqueia:** fechamento do M0
- **Arquivos:** `docs/adr/`
- **Pronto quando:** ADR com as medições de T-005/T-006, metas de fps e tamanho confirmadas ou ajustadas e recomendação sobre a decisão #4; o AG00 usa a ADR para atualizar `decisoes.md` e a Bíblia.

### T-008 — Deploy automático Web (GitHub Actions → Netlify)
- **Marco:** M0 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-004 · **Desbloqueia:** T-005
- **Arquivos:** `.github/workflows/deploy-web.yml`
- **Pronto quando:** push em `dev` publica em dev--projectanimagame.netlify.app; push em `main` publica em projectanimagame.netlify.app.
- **Briefing:** BRF-006, BRF-007
- **Obs.:** entregue fora do backlog e registrado depois.

---

## M1 — Demo do combate

### T-101 — `docs/gameplay.md`
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-103, T-112
- **Arquivos:** `docs/gameplay.md`
- **Pronto quando:** pilares, loop, parâmetros do Anima e do ataque, 3 skills, 4 arquétipos, chefe, formato dos dados de onda e **lista de sinais expostos à UI** documentados (modelo AG01 §5).
- **Briefing:** BRF-003

### T-102 — Autoload de fluxo de cenas
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** T-001 (mesmo `project.godot`) · **Desbloqueia:** T-113
- **Arquivos:** `src/core/`, `project.godot` (autoload, cena principal)
- **Pronto quando:** autoload troca entre Toque para começar → Partida → Resultado com cenas placeholder; partida recebe config e devolve resultado (sem `meta/` nem `backend/`).

### T-103 — Protótipo cinza: arena, Anima, 1 inimigo
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-001, T-101 · **Desbloqueia:** T-104
- **Arquivos:** `src/match/arena/`, `src/match/anima/`, `src/match/enemies/`, `data/enemies/enemy_runner.tres`
- **Pronto quando:** arena em retrato; Anima fixo no centro; inimigo corredor nasce na borda, anda até o centro e causa dano ao Núcleo; valores vêm de `.tres`.

### T-104 — Ataque automático com pool
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-103 · **Desbloqueia:** T-105
- **Arquivos:** `src/match/anima/`, `src/match/projectiles/`, `data/`
- **Pronto quando:** mira no inimigo mais próximo/prioritário; projéteis reutilizados por pool (sem instanciar por tiro); dano e morte do inimigo funcionam.
- **Decisão:** projéteis inimigos sem ciano.

### T-105 — Ondas por dados, HP do Núcleo, moedas, vitória/derrota
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-104 · **Desbloqueia:** T-108, T-111, T-112, T-114
- **Arquivos:** `src/match/waves/`, `src/match/arena/`, `data/waves/`
- **Pronto quando:** spawner lê ondas de `.tres` (3 ondas de teste); sinais de HP, `Wave X/Y`, moedas e fim de partida emitidos; HP zero = derrota; última onda = vitória.

### T-106 — Tema base e componentes de UI
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-003 · **Desbloqueia:** T-112, T-113, T-121
- **Arquivos:** `src/ui/theme/`, `src/ui/components/`
- **Pronto quando:** tema base aplicado; botão, barra de vida e botão de skill com cooldown visual funcionam com toque, mouse e Input Actions; cena de demonstração.
- **Decisão:** fonte Outfit.

### T-107 — Overlay de debug Web
- **Marco:** M1 · **Dono:** AG02 · **Status:** pronta p/ briefing
- **Depende de:** T-004 · **Desbloqueia:** T-118
- **Arquivos:** `src/ui/debug/`
- **Pronto quando:** FPS, contagem de nós e últimos logs visíveis na tela; liga/desliga por Input Action; fora dos builds release ou desligado por padrão.

### T-108 — Base de skills + skill de área
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-105 · **Desbloqueia:** T-109 (M2), T-139
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** sistema de skill com cooldown acionado por Input Action (slot 1); skill de área causa dano na região; sinais de cooldown para a UI.
- **Decisão:** slots de skill numerados a partir de 1 (1-based).

### T-109 — Skill de controle
- **Marco:** M2 (movida do M1, decisão #28) · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-108 · **Desbloqueia:** T-110
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 2 (desbloqueado por nível de conta) aplica lentidão/atordoamento em área; efeito visível e com duração por dados.

### T-110 — Skill de defesa
- **Marco:** M2 (movida do M1, decisão #28) · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-109 · **Desbloqueia:** —
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 3 (desbloqueado por nível de conta) protege o Núcleo (escudo ou invulnerabilidade) por tempo definido em dados.

### T-111 — Arquétipos: tanque, atirador, enxame
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-105 · **Desbloqueia:** T-115, T-116
- **Arquivos:** `src/match/enemies/`, `data/enemies/`, `src/match/projectiles/` (projétil inimigo)
- **Pronto quando:** 3 novos arquétipos com comportamento distinto; atirador usa pool de projéteis inimigos; todos por `.tres`.
- **Decisão:** projéteis inimigos sem ciano.

### T-112 — HUD ligado aos sinais
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-101, T-105, T-106 (sinais de skill de T-108 podem ser simulados) · **Desbloqueia:** T-117
- **Arquivos:** `src/ui/hud/`
- **Pronto quando:** HP do Núcleo, `Wave X/Y`, moedas, pausa e 3 botões de skill reagem só por sinais; funciona em retrato com safe area.

### T-113 — Telas: toque para começar, pausa, resultado
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-102, T-106, T-112 (mesma pasta), T-121, T-122 · **Desbloqueia:** T-120
- **Arquivos:** `src/ui/screens/`
- **Pronto quando:** toque para começar libera o áudio; pausa manual e ao perder o foco da aba; resultado de vitória/derrota com moedas e "Jogar de novo".
- **Nota:** ouvir só um aviso de pausa (evitar pausa duplicada entre a pausa manual e a perda de foco).

### T-114 — Testes GUT de ondas, dano e cooldowns
- **Marco:** M1 · **Dono:** AG03 · **Status:** feita
- **Depende de:** T-002, T-105 (cooldown após T-108) · **Desbloqueia:** T-120
- **Arquivos:** `tests/unit/`, `tests/integration/`
- **Pronto quando:** testes cobrem leitura de ondas, dano/HP do Núcleo, vitória/derrota e cooldown; rodam headless e passam.

### T-115 — Chefe da fase 1
- **Marco:** M1 · **Dono:** AG01 · **Status:** pronta p/ briefing
- **Depende de:** T-111 · **Desbloqueia:** T-116, T-127 (arte do chefe), T-131
- **Arquivos:** `src/match/enemies/boss/`, `data/enemies/boss_*.tres`
- **Pronto quando:** chefe com fases por vida, ao menos 2 padrões de ataque e aviso visual (telegraph) antes de cada padrão; vencível com 1 skill + upgrades da partida.

### T-116 — Fase 1 completa
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-111, T-115, T-134, T-139 · **Desbloqueia:** T-117, T-118, T-120
- **Arquivos:** `data/waves/stage_01*`
- **Pronto quando:** ~10 ondas + chefe; partida de 3–10 min; curva de dificuldade descrita em `docs/gameplay.md`.
- **Nota:** o balanceamento conta com **1 skill (slot 1) + upgrades da partida** (decisões #27 e #28); os valores de upgrade vêm da T-133.

### T-117 — Game feel
- **Marco:** M1 · **Dono:** AG01 + AG09 (com AG02 no HUD) · **Status:** a fazer
- **Depende de:** T-112, T-116, T-130 · **Desbloqueia:** T-120
- **Arquivos:** AG01: `src/match/` · AG09: `src/fx/` · AG02: `src/ui/hud/` (cada parte em briefing próprio, sem paralelo nos mesmos arquivos)
- **Pronto quando:**
  - AG01: tremor de câmera, hit-stop, números de dano e sinais de feedback;
  - AG09: flash de acerto e feedback visual de skill pronta/usada, via pool;
  - sem alocação por frame; nível de demo aprovado pelo usuário.

### T-118 — Desempenho no iPhone
- **Marco:** M1 · **Dono:** AG01 (medição com AG03) · **Status:** a fazer
- **Depende de:** T-006, T-107, T-116, T-132 · **Desbloqueia:** T-120
- **Arquivos:** `src/match/`
- **Pronto quando:** ≥ 50 fps no iPhone com ~150 inimigos e ~300 projéteis (ou a meta revisada em T-007); medições registradas.
- **Proposta (AG01):** pool de inimigos (reutilizar instâncias em vez de instanciar/liberar por spawn).

### T-119 — Otimização do build Web
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-113, T-116 · **Desbloqueia:** T-120
- **Arquivos:** `export_presets.cfg`, `web/`
- **Pronto quando:** download inicial ≤ ~15 MB (ou meta revisada); tela de carregamento na estética do jogo; primeiro frame < 5 s em 4G (estimado).

### T-120 — Validação do M1
- **Marco:** M1 · **Dono:** AG03 · **Status:** a fazer
- **Depende de:** T-113, T-114, T-116, T-117, T-118, T-119, T-131, T-132, T-135, T-136, T-137, T-138 · **Desbloqueia:** fechamento do M1
- **Arquivos:** `docs/qa/QA-001_m1.md`
- **Pronto quando:** checklist AG03 §5 executado (partida completa, simulação de 5 min, build medido, checklist do iPhone para o usuário); **qualidade visual de demo** conferida contra `docs/arte.md` e `docs/vfx.md` (arte final em tudo, sem placeholder, efeitos reduzidos funcionando); veredito passa/não passa.

### T-121 — Tema global no `project.godot`
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** T-106 · **Desbloqueia:** T-112, T-113
- **Arquivos:** `project.godot`
- **Pronto quando:** o tema base do AG02 é o tema global do projeto; telas existentes abrem com a fonte Outfit sem erros.

### T-122 — Ligar a arena real ao SceneFlow
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** T-102, T-103 · **Desbloqueia:** T-113
- **Arquivos:** `src/core/`
- **Pronto quando:** o SceneFlow abre a arena real (no lugar do placeholder), chama `setup(config)` e vai para o Resultado ao receber `match_ended`.
- **Notas:** chamar `hud.bind(arena)` antes de a arena entrar na árvore; `DEFAULT_MATCH_SCENE` ainda aponta para o placeholder.
- **Contrato de montagem (`docs/ui.md` §10c):** montar HUD + PauseScreen junto da arena; chamar `bind` antes de a arena entrar na árvore; ligar `restart_requested` → `start_match`.

### T-123 — Seed no `Arena._rng` para testes determinísticos
- **Marco:** M1 · **Dono:** AG01 · **Status:** pronta p/ briefing
- **Depende de:** T-105 · **Desbloqueia:** T-120 (simulação reproduzível)
- **Arquivos:** `src/match/arena/`
- **Pronto quando:** a arena aceita uma seed (por exemplo, via `setup(config)`); com a mesma seed, duas execuções geram os mesmos spawns; os testes do AG03 podem fixá-la.
- **Origem:** sugestão do AG03.

### T-124 — Pasta `src/fx/` em `docs/estrutura.md`
- **Marco:** M1 · **Dono:** AG07 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-129
- **Arquivos:** `docs/estrutura.md`, `src/fx/.gitkeep`
- **Pronto quando:** `src/fx/` (efeitos, shaders, pool), `assets/ui/` e `assets/backgrounds/` documentados; regra de dependência definida (`fx/` reage a sinais e não altera o estado de `match/`).

### T-142 — Novo guia de estilo 2D cartoon 3/4 + mockups PNG
- **Marco:** M1 · **Dono:** AG08 · **Status:** pronta p/ briefing
- **Depende de:** decisões 31–33 · **Desbloqueia:** T-127, T-128, T-129, T-144, T-145
- **Arquivos:** `docs/arte.md` (reescrever), `assets/backgrounds/` (mockups), `assets/LICENSES.md`
- **Pronto quando:** guia com paleta (clara e saturada, mantendo a regra ciano = jogador), contorno, sombra, proporções, perspectiva 3/4, núcleo-Anima, silhuetas por arquétipo e molduras por raridade; 2 mockups renderizados em **PNG** 720×1280 (arena com HUD); nada copiado de jogos existentes; **aprovado pelo usuário**.

### T-143 — Pipeline e fonte da arte final
- **Marco:** M1 · **Dono:** AG08 · **Status:** pronta p/ briefing
- **Depende de:** — · **Desbloqueia:** decisão 34, T-127, T-128
- **Arquivos:** seção em `docs/arte.md`
- **Pronto quando:** comparadas as opções (gerada pelos agentes, pacotes CC0/pagos 2D cartoon, IA de imagem, artista) em qualidade, custo, prazo e licença; formato técnico definido (PNG, resolução, atlas, escala); recomendação para o usuário decidir.

### T-144 — Arena em 3/4
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** T-142 · **Desbloqueia:** T-137
- **Arquivos:** `src/match/`, `docs/gameplay.md`, testes em `tests/`
- **Pronto quando:** ordenação por Y, sprites ancorados na base, sombra no chão, área de spawn e limites adaptados à perspectiva; colisões no plano do chão; testes passando.

### T-145 — Retema da UI no estilo cartoon
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-142 · **Desbloqueia:** T-138
- **Arquivos:** `docs/ui.md`, `src/ui/theme/`, `src/ui/components/`, `assets/fonts/`
- **Pronto quando:** tokens e tema refeitos (botões grandes com contorno e sombra, painéis com moldura, cores por raridade); fonte arredondada OFL avaliada; HUD e telas atuais continuam funcionando.

### T-146 — Remover mockups rejeitados e excluir referências do export Web
- **Marco:** M1 · **Dono:** AG07 · **Status:** pronta p/ briefing
- **Depende de:** — · **Desbloqueia:** —
- **Arquivos:** `assets/backgrounds/mockup_arena*.svg`, `assets/LICENSES.md`, `export_presets.cfg`
- **Pronto quando:** mockups A/B removidos; filtro do preset Web exclui mockups e referências; export e testes OK.

### T-147 — Anima com skin trocável
- **Marco:** M2 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-137 · **Desbloqueia:** skins (M4)
- **Arquivos:** `src/match/anima/`, `data/`
- **Pronto quando:** a aparência do Anima (sprite e cor dos projéteis) vem de um Resource; trocar de skin não exige mudar código.

### T-125 — Proposta da skill de área: meteoro × onda de choque
- **Marco:** M1 · **Dono:** AG01 + AG08 · **Status:** pronta p/ briefing
- **Depende de:** — · **Desbloqueia:** T-139, T-128 (ícone), T-131
- **Arquivos:** `docs/gameplay.md` (seção da skill, AG01); esboço visual em `assets/` (AG08)
- **Pronto quando:** as 2 opções descritas (jogabilidade, leitura visual, custo de VFX no iPhone), com recomendação; **o usuário decide via AG00**.

### T-126 — Guia de estilo `docs/arte.md` + mockup da arena
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita, **rejeitada** (substituída pela T-142)
- **Depende de:** — (alinhar com os tokens do `docs/ui.md`) · **Desbloqueia:** T-127, T-128, T-129
- **Arquivos:** `docs/arte.md`, mockup em `assets/backgrounds/`, `assets/LICENSES.md`
- **Pronto quando:** paleta, formas, silhuetas por arquétipo, tamanhos, nomes e checklist de asset documentados; mockup da arena em retrato com Anima, inimigos, projéteis e HUD; **aprovado pelo usuário**.

### T-127 — Arte do Anima, inimigos, chefe, projéteis e fundo
- **Marco:** M1 · **Dono:** AG08 · **Status:** feita
- **Depende de:** T-142, T-143 (o chefe também depende da T-115) · **Desbloqueia:** T-137
- **Arquivos:** `assets/sprites/`, `assets/backgrounds/`, `assets/LICENSES.md`
- **Pronto quando:** Anima, 4 arquétipos, chefe, projéteis (inimigos sem ciano) e fundo seguem o `docs/arte.md`; silhuetas distintas; tamanhos para 720×1280; licenças registradas.

### T-128 — Ícones e arte da UI
- **Marco:** M1 · **Dono:** AG08 · **Status:** a fazer
- **Depende de:** T-142, T-143, T-125 (ícone da skill), T-133 (ícones dos upgrades) · **Desbloqueia:** T-138
- **Arquivos:** `assets/ui/`
- **Pronto quando:** ícone da skill, cadeado dos slots, ícones dos upgrades, botões, barras e painéis no estilo do guia; legíveis no toque no iPhone.

### T-129 — `docs/vfx.md` + pool de efeitos
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-124, T-142 · **Desbloqueia:** T-130, T-131, T-132
- **Nota:** VFX no estilo cartoon (formas sólidas, contorno, cores vivas, poucas partículas).
- **Arquivos:** `docs/vfx.md`, `src/fx/`
- **Pronto quando:** catálogo de efeitos com os sinais de que cada um depende; pool de efeitos reutilizável (sem instanciar por evento), com teste ou cena de demonstração.

### T-130 — VFX do ataque, acertos e mortes
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-129 · **Desbloqueia:** T-117, T-132
- **Arquivos:** `src/fx/`, `assets/vfx/`
- **Pronto quando:** rastro/brilho do projétil, impacto e morte de inimigo via pool, ligados por sinais; custo medido no build Web.
- **Nota:** se faltar algum sinal em `match/`, pedir ao AG00 (vira task do AG01).

### T-131 — VFX da skill e do chefe
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-129, T-139, T-115 · **Desbloqueia:** T-132, T-120
- **Arquivos:** `src/fx/`, `assets/vfx/`
- **Pronto quando:** telegraph e impacto da skill escolhida; telegraphs e efeitos dos padrões do chefe; custo medido.

### T-132 — Modo de efeitos reduzidos
- **Marco:** M1 · **Dono:** AG09 · **Status:** a fazer
- **Depende de:** T-130, T-131 · **Desbloqueia:** T-118, T-120
- **Arquivos:** `src/fx/`
- **Pronto quando:** uma configuração reduz partículas, brilho e tremor sem perder a leitura dos telegraphs; ganho de fps medido.

### T-133 — Dados e balanceamento dos upgrades da partida
- **Marco:** M1 · **Dono:** AG04 · **Status:** feita
- **Depende de:** — · **Desbloqueia:** T-134, T-128
- **Arquivos:** `docs/meta.md` (seção de upgrades da partida)
- **Pronto quando:** os 5 upgrades (Atk power, Atk spd, Defesa, Vida máxima, Cooldown) com efeito por nível, nível máximo e curva de custo em Partículas documentados, com valores coerentes com as Partículas ganhas na fase 1 e com tetos que não quebrem o balanceamento (ex.: redução de cooldown).

### T-134 — Lógica dos upgrades em tempo real (5 atributos)
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-133, T-105, T-140 · **Desbloqueia:** T-135, T-116
- **Arquivos:** `src/match/upgrades/`, `data/upgrades/`
- **Pronto quando:** `Arena.buy_upgrade(id)->bool` compra 1 nível durante a partida, sem pausar; desconta Partículas e aplica o efeito até o fim; custo cresce por nível e há nível máximo; sinais `upgrade_changed(id, level, next_cost)` e `can_afford` para a UI; valores em `.tres`; testes GUT da compra e da aplicação.

### T-135 — Fileira de 5 botões de upgrade no HUD
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-134, T-141 (os sinais podem ser simulados antes) · **Desbloqueia:** T-138, T-120
- **Arquivos:** `src/ui/hud/`, `src/ui/components/`
- **Pronto quando:** fileira de 5 botões acima da linha de skills (Atk power, Atk spd, Defesa, Vida máxima, Cooldown), cada um com ícone, nível e custo em Partículas; desabilitado quando não há Partículas ou no nível máximo; alvo de toque de 44 px ou mais; funciona com toque, mouse e teclado em retrato; não cobre inimigos nem as skills.

### T-136 — Slots 2 e 3 do HUD bloqueados (cadeado)
- **Marco:** M1 · **Dono:** AG02 · **Status:** feita
- **Depende de:** T-112 · **Desbloqueia:** T-138, T-120
- **Arquivos:** `src/ui/hud/`
- **Pronto quando:** slots 2 e 3 visíveis com cadeado e sem ação (toque e teclas `2`/`3` ignorados); ícone provisório até a T-128.

### T-137 — Trocar placeholders da partida pela arte final
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-127, T-144 · **Desbloqueia:** T-120
- **Arquivos:** `src/match/` (cenas)
- **Pronto quando:** Anima, inimigos, chefe, projéteis e fundo usam a arte final; colisões continuam corretas; nenhum placeholder geométrico.

### T-138 — Aplicar a arte da UI no HUD e nas telas
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-128, T-135, T-136, T-145 · **Desbloqueia:** T-120
- **Arquivos:** `src/ui/`
- **Pronto quando:** HUD, telas e tela de upgrade usam os ícones e a arte final; legibilidade conferida no iPhone.

### T-139 — Ajustar a skill de área à opção escolhida
- **Marco:** M1 · **Dono:** AG01 · **Status:** bloqueada
- **Depende de:** T-125 (**decisão do usuário: meteoro ou onda de choque**) · **Desbloqueia:** T-116, T-131
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** a skill do slot 1 tem o comportamento da opção escolhida (área, dano e cooldown em dados); sinais para VFX e UI.

### T-140 — Moeda da partida vira Partículas: sinais, código e `gameplay.md`
- **Marco:** M1 · **Dono:** AG01 · **Status:** feita
- **Depende de:** decisão #29 · **Desbloqueia:** T-141, T-134
- **Arquivos:** `src/match/`, `data/`, `docs/gameplay.md`, `tests/` (só os testes afetados, com aviso ao AG03)
- **Pronto quando:** sinais, variáveis e dados da moeda da partida usam o nome Partículas; começa em 0 e zera a cada partida; testes GUT passam.
- **Nota:** o identificador em código não deve colidir com nós de partículas do Godot nem com `src/fx/`; o AG07 confirma o nome (decisão do AG00).

### T-141 — Moeda da partida vira Partículas: HUD, telas e `ui.md`
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-140 · **Desbloqueia:** T-135, T-138
- **Arquivos:** `src/ui/hud/`, `src/ui/screens/`, `docs/ui.md`
- **Pronto quando:** HUD e Resultado mostram "Partículas"; ligados aos sinais renomeados; nenhuma menção a "moedas" para a moeda da partida.

---

## Pendências a decidir

- **Voltar ao título a partir do Resultado:** hoje "Jogar de novo" vai direto para a partida. Exigiria um sinal novo no ResultScreen (AG02). Decisão do usuário via AG00.

## Depois (M2+; só T-109 e T-110 já têm task)

- **M2:**
  - nível de conta (XP das partidas);
  - desbloqueio dos slots: slot 1 no nível 3, slot 2 no nível 7, slot 3 no nível 12 (ajustáveis; decisão #25 revisada);
  - skills de controle e defesa (T-109, T-110);
  - **Gold** (moeda do meta-jogo, decisão #29): calculado a partir do `MatchResult`, com ganho variável por partida;
  - módulos: equipamentos do Anima, melhorados com Gold, com raridade;
  - fusão de módulos 3→1;
  - **árvore de talentos comprada com Gold** (decisão #30);
  - save local.
- **[A definir] para o M2:** evolução das skills; atributos dos módulos; prêmios por nível de conta além dos slots.
- **M3:** escolha do backend, conta guest, sincronização, economia no servidor, Remote Config.
- **M4:** ads, loja, skins, áudio final, lojas nativas, mais fases, localização.
