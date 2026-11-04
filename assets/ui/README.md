# Arte da UI (T-128, BRF-037)

Estilo A "Jardim Arcano" (`docs/arte.md` §6), formas do mockup `assets/backgrounds/mockup_cartoon_a_upgrades.png`, cores do `docs/ui.md`. Todos os PNG estão em **2x** com fundo transparente: na tela (720×1280) use metade do tamanho (`scale = 0.5`, `expand_mode` ou `custom_minimum_size` em 1x).
Fonte: `_src/gen_ui.py` (SVG por código → Chrome headless). Para regenerar, rode `python assets/ui/_src/gen_ui.py`. A pasta `_src/` tem `.gdignore`; `_src/contact_sheet.png` é a folha de contato (1x e 44 px).
**Sombra embutida:** botões, molduras e painel têm uma base escura (`ink`) 6 px (1x) abaixo do corpo. Por isso o canvas é mais alto que o corpo.

## Ícones

| Arquivo | PNG (2x) | Tela (1x) | Uso |
|---|---|---|---|
| `ui_icon_upgrade_atk_power.png` | 128×128 | 64×64 (40 no botão) | Atk power: espada num círculo laranja |
| `ui_icon_upgrade_atk_speed.png` | 128×128 | 64×64 | Atk spd: setas duplas, círculo âmbar |
| `ui_icon_upgrade_defense.png` | 128×128 | 64×64 | Defesa: escudo hexagonal, círculo azul |
| `ui_icon_upgrade_max_hp.png` | 128×128 | 64×64 | Vida máxima: coração com "+", círculo rosa |
| `ui_icon_upgrade_cooldown.png` | 128×128 | 64×64 | Cooldown: ampulheta, círculo verde-água |
| `ui_icon_skill_pulse.png` | 128×128 | 64×64 (~88 na moldura) | Skill de área atual (pulso). **Provisório até a T-125**: para trocar, edite só `G_SKILL_PULSE` no script |
| `ui_icon_skill_meteor.png` | 128×128 | 64×64 (~88 na moldura) | Skill do slot 1: meteoro de fogo (BRF-047). Substitui o `ui_icon_skill_pulse.png`, mantido até o AG02 trocar o uso. Fonte: `G_SKILL_METEOR` |
| `ui_icon_lock.png` | 128×128 | 64×64 | Cadeado dos slots bloqueados (acima do texto "NV 7"/"NV 12") |
| `ui_icon_particles.png` | 128×128 | 64×64 (24–32 no HUD/pílula) | **Partículas** (decisão 40, BRF-061): estrela verde de 4 pontas com facetas tipo "chip", núcleo claro e brilho. Fonte: `g_particles(P_GREEN)` |
| `ui_icon_particles_off.png` | 128×128 | 64×64 | Variante apagada (cinza-lilás) para custo sem Partículas (alternativa ao `modulate.a`) |
| `ui_icon_particle.png` | 64×64 | 32×32 | **Obsoleto**: estrela dourada, reservada para a Moeda do M2. Não usar para Partículas |
| `ui_icon_pause.png` | 128×128 | 64×64 | Botão de pausa completo (quadrado branco + barras), canto superior esquerdo |

Ícone sem Partículas: `modulate.a = 0.55` (o círculo fica colorido; o mockup usa cinza, aceitável a 55%).

## Botão de upgrade (128×80 em 1x)

| Arquivo | PNG (2x) | Canvas 1x | Uso |
|---|---|---|---|
| `ui_upgrade_btn_normal.png` | 264×180 | 132×90 | Comprável: corpo roxo + anel ciano interno |
| `ui_upgrade_btn_disabled.png` | 264×180 | 132×90 | Sem Partículas: cinza, sem anel |
| `ui_upgrade_btn_max.png` | 264×180 | 132×90 | Nível máximo: moldura dourada |
| `ui_upgrade_cost_pill.png` | 224×50 | 112×25 | Pílula escura do custo (estrela + número) |
| `ui_upgrade_cost_pill_max.png` | 224×50 | 112×25 | Pílula dourada com "MAX" |

Corpo em (2, 2) do canvas 1x, tamanho 128×80; sombra até y = 88. Layout interno (1x, relativo ao corpo): ícone Ø 40 com centro em (31, 28); "Nv X" centrado em (90, 36); pílula em (9, 52).

## Moldura circular das skills (Ø 144 em 1x)

| Arquivo | PNG (2x) | Canvas 1x | Uso |
|---|---|---|---|
| `ui_skill_frame_ready.png` | 320×336 | 160×168 | Pronta: anel ciano + halo |
| `ui_skill_frame_cooldown.png` | 320×336 | 160×168 | Recarga: sem halo, anel escuro |
| `ui_skill_frame_locked.png` | 320×336 | 160×168 | Bloqueada: cinza (+ `ui_icon_lock` e "NV X") |
| `ui_skill_cooldown_mask.png` | 280×280 | 140×140 | Véu `cooldown_dim` (#1A0F2E a 55%) para `TextureProgressBar` radial, centrado no botão |

Centro do círculo em (80, 80) do canvas 1x (r = 72); a sombra vai até y = 158. Badge da tecla continua desenhado pela UI.

## Barra, painel e botão grande (9-patch / `NinePatchRect` ou `StyleBoxTexture`)

Margens em **px do PNG (2x)**; em 1x, metade.

| Arquivo | PNG (2x) | Margens E / C / D / B (esq./cima/dir./baixo) | Uso |
|---|---|---|---|
| `ui_bar_track.png` | 128×72 | 32 / 0 / 32 / 0 | Trilho (`bar_track`), com sombra. Estica só na horizontal: mantenha a altura em 36 (1x). Preenchimento com 4 px (1x) de folga |
| `ui_bar_fill.png` | 96×48 | 24 / 0 / 24 / 0 | Altura fixa 24 (1x). Preenchimento **branco**: tingir com `self_modulate` (`core_hp`, `boss_hp`) |
| `ui_bar_shine.png` | 96×16 | 8 / 0 / 8 / 0 | Brilho opcional por cima do preenchimento (topo, 35% branco) |
| `ui_panel.png` | 192×192 | 56 / 56 / 56 / 68 | Painel com moldura roxa e miolo `bg_panel`. Conteúdo a 20 px (1x) da borda (26 embaixo) |
| `ui_button_big_normal.png` | 192×144 | 52 / 52 / 52 / 68 | Botão principal (ciano, `accent`), texto `text_on_light` |
| `ui_button_big_pressed.png` | 192×144 | 52 / 52 / 52 / 68 | Pressionado: corpo desce 4 px (1x) e escurece; mesmo canvas, troca direta |

Barra: use `TextureProgressBar` com `nine_patch_stretch = true` e as mesmas margens, ou `NinePatchRect` + recorte.

## Paleta de Partículas (coleta, para o AG09)

Verde-limão/esmeralda, sem ciano e distinto do verde das barras de vida (`#3FD27F`). Mesmos tokens de `P_GREEN` no `gen_ui.py`.

| Tom | Hex | Uso sugerido |
|---|---|---|
| Claro | `#D2FFB0` | núcleo, brilho, faísca |
| Médio | `#7CF05A` | corpo da partícula |
| Médio-escuro | `#3CC23A` | faceta sombreada, rastro |
| Escuro | `#1F8A3B` | borda, fim do rastro |
| Contorno | `#124F24` | contorno do ícone |
