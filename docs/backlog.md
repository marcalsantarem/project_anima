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
| T-109 | Skill de controle | M1 | AG01 | pronta p/ briefing |
| T-110 | Skill de defesa | M1 | AG01 | a fazer |
| T-111 | Arquétipos: tanque, atirador, enxame | M1 | AG01 | feita |
| T-112 | HUD ligado aos sinais | M1 | AG02 | feita |
| T-113 | Telas: toque para começar, pausa, resultado | M1 | AG02 | feita |
| T-114 | Testes GUT de ondas, dano e cooldowns | M1 | AG03 | feita |
| T-115 | Chefe da fase 1 | M1 | AG01 | pronta p/ briefing |
| T-116 | Fase 1 completa (~10 ondas + chefe) | M1 | AG01 | a fazer |
| T-117 | Game feel | M1 | AG01 | a fazer |
| T-118 | Desempenho no iPhone (150 inimigos / 300 projéteis) | M1 | AG01 | a fazer |
| T-119 | Otimização do build Web | M1 | AG02 | a fazer |
| T-120 | Validação do M1 | M1 | AG03 | a fazer |
| T-121 | Tema global no `project.godot` | M1 | AG07 | pronta p/ briefing |
| T-122 | Ligar a arena real ao SceneFlow | M1 | AG07 | pronta p/ briefing |
| T-123 | Seed no `Arena._rng` para testes determinísticos | M1 | AG01 | pronta p/ briefing |

## Próximas prontas p/ briefing

> **Decisão 21:** só o usuário libera briefings. A lista abaixo é sugestão; nada começa sem o OK dele.

1. **T-109** (AG01, skill de controle) → **T-110**; **T-123** (AG01, seed) é pequena e pode vir antes. **T-115** (AG01, chefe) em paralelo só com outra sessão do AG01.
2. **T-121** (AG07, tema global) → depois **T-122** (AG07, arena no SceneFlow).
3. **T-107** (AG02, overlay de debug) ou **T-006** (AG02, cena de estresse); o AG02 está livre.
- Paralelo possível: AG01 ‖ T-121/T-122 ‖ T-107 (arquivos diferentes).

## Paralelismo e conflitos

- **Ondas paralelas possíveis:**
  - M0: {T-001} ‖ {T-002} ‖ {T-003} ‖ {T-004 → T-005, T-006} ‖ {T-101}.
  - M1 início: {T-102} ‖ {T-103 → T-104 → T-105} ‖ {T-106, T-107}.
  - M1 meio: {T-108 → T-109 → T-110} ‖ {T-111} só com duas sessões do AG01 (pastas `skills/` × `enemies/`); {T-112, T-113} ‖ AG01; {T-114} após T-105.
- **Não paralelizar:**
  - T-001 e T-102 (ambas em `project.godot`);
  - T-102 com qualquer task que mexa em `project.godot`;
  - T-112 e T-113 (ambas em `src/ui/`, mesmo dono: em sequência);
  - T-117 com T-112/T-113 (o game feel toca o HUD).

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

## M1 — Protótipo do combate

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
- **Depende de:** T-105 · **Desbloqueia:** T-109
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** sistema de skill com cooldown acionado por Input Action (slot 1); skill de área causa dano na região; sinais de cooldown para a UI.
- **Decisão:** slots de skill numerados a partir de 1 (1-based).

### T-109 — Skill de controle
- **Marco:** M1 · **Dono:** AG01 · **Status:** pronta p/ briefing
- **Depende de:** T-108 · **Desbloqueia:** T-110
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 2 aplica lentidão/atordoamento em área; efeito visível e com duração por dados.

### T-110 — Skill de defesa
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-109 · **Desbloqueia:** T-116
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 3 protege o Núcleo (escudo ou invulnerabilidade) por tempo definido em dados.

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
- **Depende de:** T-111 · **Desbloqueia:** T-116
- **Arquivos:** `src/match/enemies/boss/`, `data/enemies/boss_*.tres`
- **Pronto quando:** chefe com fases por vida, ao menos 2 padrões de ataque e aviso visual antes de cada padrão.

### T-116 — Fase 1 completa
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-110, T-111, T-115 · **Desbloqueia:** T-117, T-118, T-120
- **Arquivos:** `data/waves/stage_01*`
- **Pronto quando:** ~10 ondas + chefe; partida de 3–10 min; curva de dificuldade descrita em `docs/gameplay.md`.
- **Nota:** o balanceamento das ondas conta com as skills.

### T-117 — Game feel
- **Marco:** M1 · **Dono:** AG01 (com AG02 no HUD) · **Status:** a fazer
- **Depende de:** T-112, T-116 · **Desbloqueia:** T-120
- **Arquivos:** `src/match/`, `src/ui/hud/` (parte do AG02, em briefing próprio)
- **Pronto quando:** flash de acerto, tremor de câmera, números de dano e feedback de skill pronta/usada; sem alocação por frame.

### T-118 — Desempenho no iPhone
- **Marco:** M1 · **Dono:** AG01 (medição com AG03) · **Status:** a fazer
- **Depende de:** T-006, T-107, T-116 · **Desbloqueia:** T-120
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
- **Depende de:** T-113, T-114, T-116, T-117, T-118, T-119 · **Desbloqueia:** fechamento do M1
- **Arquivos:** `docs/qa/QA-001_m1.md`
- **Pronto quando:** checklist AG03 §5 executado (partida completa, simulação de 5 min, build medido, checklist do iPhone para o usuário); veredito passa/não passa.

### T-121 — Tema global no `project.godot`
- **Marco:** M1 · **Dono:** AG07 · **Status:** pronta p/ briefing
- **Depende de:** T-106 · **Desbloqueia:** T-112, T-113
- **Arquivos:** `project.godot`
- **Pronto quando:** o tema base do AG02 é o tema global do projeto; telas existentes abrem com a fonte Outfit sem erros.

### T-122 — Ligar a arena real ao SceneFlow
- **Marco:** M1 · **Dono:** AG07 · **Status:** pronta p/ briefing
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

---

## Depois (M2+, sem tasks)

- 4º slot de skill (`Espaço`) — **[A definir]**, depende de decisão do usuário.
- Cards, raridades e fusão; atributos permanentes; árvore de talentos; save local (M2).
- Escolha do backend, conta guest, sincronização, economia no servidor, Remote Config (M3).
- Ads, loja, skins, arte e áudio finais, mais fases, localização (M4).
