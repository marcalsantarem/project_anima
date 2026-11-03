# Backlog

> Mantido pelo AG06. O status reflete o que o AG00 confirmou. Formato e regras em [agentes/AG06_backlog.md](agentes/AG06_backlog.md). Andamento dos marcos em [marcos.md](marcos.md).

## Quadro

| ID | Título | Marco | Dono | Status |
|---|---|---|---|---|
| T-001 | Layers de colisão nomeadas | M0 | AG07 | pronta p/ briefing |
| T-002 | Instalar GUT e teste smoke headless | M0 | AG03 | em andamento |
| T-003 | `docs/ui.md` (tokens, layout, fluxo de telas) | M0 | AG02 | em andamento |
| T-004 | Preset Web + HTML shell mínimo | M0 | AG02 | a fazer |
| T-005 | Build vazio no Chrome PC e no iPhone | M0 | AG02 | bloqueada |
| T-006 | Cena de estresse para confirmar metas de desempenho | M0 | AG02 | a fazer |
| T-007 | ADR das metas de desempenho e da exportação single-threaded | M0 | AG07 | a fazer |
| T-101 | `docs/gameplay.md` (parâmetros e sinais) | M1 | AG01 | em andamento |
| T-102 | Autoload de fluxo de cenas | M1 | AG07 | a fazer |
| T-103 | Protótipo cinza: arena, Anima, 1 inimigo | M1 | AG01 | a fazer |
| T-104 | Ataque automático com pool | M1 | AG01 | a fazer |
| T-105 | Ondas por dados, HP do Núcleo, moedas, vitória/derrota | M1 | AG01 | a fazer |
| T-106 | Tema base e componentes de UI | M1 | AG02 | a fazer |
| T-107 | Overlay de debug Web (FPS, logs) | M1 | AG02 | a fazer |
| T-108 | Base de skills + skill de área | M1 | AG01 | a fazer |
| T-109 | Skill de controle | M1 | AG01 | a fazer |
| T-110 | Skill de defesa | M1 | AG01 | a fazer |
| T-111 | Arquétipos: tanque, atirador, enxame | M1 | AG01 | a fazer |
| T-112 | HUD ligado aos sinais | M1 | AG02 | a fazer |
| T-113 | Telas: toque para começar, pausa, resultado | M1 | AG02 | a fazer |
| T-114 | Testes GUT de ondas, dano e cooldowns | M1 | AG03 | a fazer |
| T-115 | Chefe da fase 1 | M1 | AG01 | a fazer |
| T-116 | Fase 1 completa (~10 ondas + chefe) | M1 | AG01 | a fazer |
| T-117 | Game feel | M1 | AG01 | a fazer |
| T-118 | Desempenho no iPhone (150 inimigos / 300 projéteis) | M1 | AG01 | a fazer |
| T-119 | Otimização do build Web | M1 | AG02 | a fazer |
| T-120 | Validação do M1 | M1 | AG03 | a fazer |

## Próximas prontas p/ briefing

1. **T-001** (AG07): pronta, aguarda a sessão do AG07 ser aberta.
2. **T-004** (AG02, preset Web): pode rodar em paralelo, em outra sessão.
3. **T-102** (AG07): depois da T-001 (mesmo `project.godot`).
2. Também paralelizável com elas: **T-004** (AG02, outra sessão; mexe em `export_presets.cfg` e `web/`).

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
- **Marco:** M0 · **Dono:** AG07 · **Status:** pronta p/ briefing
- **Depende de:** — · **Desbloqueia:** T-103
- **Arquivos:** `project.godot`
- **Pronto quando:**
  - layers 2D nomeadas (sugestão: `anima`, `core`, `enemy`, `player_projectile`, `enemy_projectile`, `skill_area`);
  - tabela de layers e máscaras registrada em `docs/estrutura.md` ou `docs/arquitetura.md`;
  - projeto abre sem erros.

### T-002 — Instalar GUT e teste smoke headless
- **Marco:** M0 · **Dono:** AG03 · **Status:** em andamento
- **Depende de:** — · **Desbloqueia:** T-114, T-120
- **Arquivos:** `addons/gut/`, `.gutconfig.json`, `tests/unit/test_smoke.gd`
- **Pronto quando:**
  - versão do GUT compatível com Godot 4.7.2 instalada;
  - o comando headless do `CLAUDE.md` roda e passa 1 teste smoke;
  - comandos repassados ao AG00 para o `CLAUDE.md`; `project.godot` não é alterado.
- **Briefing:** BRF-004

### T-003 — `docs/ui.md`
- **Marco:** M0 · **Dono:** AG02 · **Status:** em andamento
- **Depende de:** — · **Desbloqueia:** T-106, T-112, T-113
- **Arquivos:** `docs/ui.md`
- **Pronto quando:** tokens (cores, tipografia, espaçamento), layout em retrato com safe area, posição dos botões de skill e fluxo de telas do M1 documentados.
- **Briefing:** BRF-002

### T-004 — Preset Web + HTML shell mínimo
- **Marco:** M0 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** requisitos técnicos do AG07 (Compatibility, sem threads) · **Desbloqueia:** T-005, T-006, T-107
- **Arquivos:** `export_presets.cfg`, `web/`
- **Pronto quando:**
  - preset "Web": Compatibility, Thread Support desligado;
  - shell com meta viewport sem zoom, `touch-action: none` e bloqueio de gestos do Safari;
  - `--export-release "Web"` gera `build/web/index.html` sem erros; tamanho do build medido.

### T-005 — Build vazio no Chrome PC e no iPhone
- **Marco:** M0 · **Dono:** AG02 · **Status:** bloqueada
- **Depende de:** T-004 · **decisão pendente: como servir o link de teste** (hosting de preview ou servidor local na rede) · **Desbloqueia:** T-007
- **Arquivos:** `web/`, `docs/setup.md` (seção de deploy de teste, com autorização)
- **Pronto quando:**
  - build abre no Chrome do PC sem erros no console;
  - checklist rodado pelo usuário no iPhone: carrega, toque responde, sem zoom/scroll, retrato ok;
  - procedimento de deploy de teste documentado.

### T-006 — Cena de estresse para confirmar metas
- **Marco:** M0 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-004 (T-005 para medir no iPhone) · **Desbloqueia:** T-007, T-118
- **Arquivos:** `tests/perf/` (cena isolada, sem lógica de jogo)
- **Pronto quando:** cena com ~150 sprites móveis e ~300 projéteis em pool roda no build Web; fps medido no PC e no iPhone e registrado.

### T-007 — ADR das metas de desempenho e da exportação single-threaded
- **Marco:** M0 · **Dono:** AG07 · **Status:** a fazer
- **Depende de:** T-002, T-005, T-006 · **Desbloqueia:** fechamento do M0
- **Arquivos:** `docs/adr/`
- **Pronto quando:** ADR com as medições de T-005/T-006, metas de fps e tamanho confirmadas ou ajustadas e recomendação sobre a decisão #4; o AG00 usa a ADR para atualizar `decisoes.md` e a Bíblia.

---

## M1 — Protótipo do combate

### T-101 — `docs/gameplay.md`
- **Marco:** M1 · **Dono:** AG01 · **Status:** em andamento
- **Depende de:** — · **Desbloqueia:** T-103, T-112
- **Arquivos:** `docs/gameplay.md`
- **Pronto quando:** pilares, loop, parâmetros do Anima e do ataque, 3 skills, 4 arquétipos, chefe, formato dos dados de onda e **lista de sinais expostos à UI** documentados (modelo AG01 §5).
- **Briefing:** BRF-003

### T-102 — Autoload de fluxo de cenas
- **Marco:** M1 · **Dono:** AG07 · **Status:** a fazer
- **Depende de:** T-001 (mesmo `project.godot`) · **Desbloqueia:** T-113
- **Arquivos:** `src/core/`, `project.godot` (autoload, cena principal)
- **Pronto quando:** autoload troca entre Toque para começar → Partida → Resultado com cenas placeholder; partida recebe config e devolve resultado (sem `meta/` nem `backend/`).

### T-103 — Protótipo cinza: arena, Anima, 1 inimigo
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-001, T-101 · **Desbloqueia:** T-104
- **Arquivos:** `src/match/arena/`, `src/match/anima/`, `src/match/enemies/`, `data/enemies/enemy_runner.tres`
- **Pronto quando:** arena em retrato; Anima fixo no centro; inimigo corredor nasce na borda, anda até o centro e causa dano ao Núcleo; valores vêm de `.tres`.

### T-104 — Ataque automático com pool
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-103 · **Desbloqueia:** T-105
- **Arquivos:** `src/match/anima/`, `src/match/projectiles/`, `data/`
- **Pronto quando:** mira no inimigo mais próximo/prioritário; projéteis reutilizados por pool (sem instanciar por tiro); dano e morte do inimigo funcionam.

### T-105 — Ondas por dados, HP do Núcleo, moedas, vitória/derrota
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-104 · **Desbloqueia:** T-108, T-111, T-112, T-114
- **Arquivos:** `src/match/waves/`, `src/match/arena/`, `data/waves/`
- **Pronto quando:** spawner lê ondas de `.tres` (3 ondas de teste); sinais de HP, `Wave X/Y`, moedas e fim de partida emitidos; HP zero = derrota; última onda = vitória.

### T-106 — Tema base e componentes de UI
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-003 · **Desbloqueia:** T-112, T-113
- **Arquivos:** `src/ui/theme/`, `src/ui/components/`
- **Pronto quando:** tema base aplicado; botão, barra de vida e botão de skill com cooldown visual funcionam com toque, mouse e Input Actions; cena de demonstração.

### T-107 — Overlay de debug Web
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-004 · **Desbloqueia:** T-118
- **Arquivos:** `src/ui/debug/`
- **Pronto quando:** FPS, contagem de nós e últimos logs visíveis na tela; liga/desliga por Input Action; fora dos builds release ou desligado por padrão.

### T-108 — Base de skills + skill de área
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-105 · **Desbloqueia:** T-109
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** sistema de skill com cooldown acionado por Input Action (slot 1); skill de área causa dano na região; sinais de cooldown para a UI.

### T-109 — Skill de controle
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-108 · **Desbloqueia:** T-110
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 2 aplica lentidão/atordoamento em área; efeito visível e com duração por dados.

### T-110 — Skill de defesa
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-109 · **Desbloqueia:** T-116
- **Arquivos:** `src/match/skills/`, `data/skills/`
- **Pronto quando:** slot 3 protege o Núcleo (escudo ou invulnerabilidade) por tempo definido em dados.

### T-111 — Arquétipos: tanque, atirador, enxame
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-105 · **Desbloqueia:** T-115, T-116
- **Arquivos:** `src/match/enemies/`, `data/enemies/`, `src/match/projectiles/` (projétil inimigo)
- **Pronto quando:** 3 novos arquétipos com comportamento distinto; atirador usa pool de projéteis inimigos; todos por `.tres`.

### T-112 — HUD ligado aos sinais
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-101, T-105, T-106 (sinais de skill de T-108 podem ser simulados) · **Desbloqueia:** T-117
- **Arquivos:** `src/ui/hud/`
- **Pronto quando:** HP do Núcleo, `Wave X/Y`, moedas, pausa e 3 botões de skill reagem só por sinais; funciona em retrato com safe area.

### T-113 — Telas: toque para começar, pausa, resultado
- **Marco:** M1 · **Dono:** AG02 · **Status:** a fazer
- **Depende de:** T-102, T-106, T-112 (mesma pasta) · **Desbloqueia:** T-120
- **Arquivos:** `src/ui/screens/`
- **Pronto quando:** toque para começar libera o áudio; pausa manual e ao perder o foco da aba; resultado de vitória/derrota com moedas e "Jogar de novo".

### T-114 — Testes GUT de ondas, dano e cooldowns
- **Marco:** M1 · **Dono:** AG03 · **Status:** a fazer
- **Depende de:** T-002, T-105 (cooldown após T-108) · **Desbloqueia:** T-120
- **Arquivos:** `tests/unit/`, `tests/integration/`
- **Pronto quando:** testes cobrem leitura de ondas, dano/HP do Núcleo, vitória/derrota e cooldown; rodam headless e passam.

### T-115 — Chefe da fase 1
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-111 · **Desbloqueia:** T-116
- **Arquivos:** `src/match/enemies/boss/`, `data/enemies/boss_*.tres`
- **Pronto quando:** chefe com fases por vida, ao menos 2 padrões de ataque e aviso visual antes de cada padrão.

### T-116 — Fase 1 completa
- **Marco:** M1 · **Dono:** AG01 · **Status:** a fazer
- **Depende de:** T-110, T-111, T-115 · **Desbloqueia:** T-117, T-118, T-120
- **Arquivos:** `data/waves/stage_01*`
- **Pronto quando:** ~10 ondas + chefe; partida de 3–10 min; curva de dificuldade descrita em `docs/gameplay.md`.

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

---

## Depois (M2+, sem tasks)

- 4º slot de skill (`Espaço`) — **[A definir]**, depende de decisão do usuário.
- Cards, raridades e fusão; atributos permanentes; árvore de talentos; save local (M2).
- Escolha do backend, conta guest, sincronização, economia no servidor, Remote Config (M3).
- Ads, loja, skins, arte e áudio finais, mais fases, localização (M4).
