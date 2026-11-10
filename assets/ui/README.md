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
| `ui_upgrade_cost_pill.png` | 224×50 | 112×25 | Pílula escura do custo, **sem texto nem estrela** |
| `ui_upgrade_cost_pill_max.png` | 224×50 | 112×25 | Pílula dourada (`#F5B83D`, contorno `ink` 2 px), **sem texto** |

Corpo em (2, 2) do canvas 1x, tamanho 128×80; sombra até y = 88. Layout interno (1x, relativo ao corpo): ícone Ø 40 com centro em (31, 28); "Nv X" centrado em (90, 36); pílula em (9, 52).

**Texto das pílulas (T-154, BRF-073):** a arte das duas pílulas **não tem texto** (fonte do tema e localização ficam na UI). A UI desenha, a 1x, com a fonte bold do tema (Outfit 800), tamanho **20 px**:
- **MAX** (`ui_upgrade_cost_pill_max`): centralizado na pílula (horizontal e vertical), **branco** (`text_primary`) com contorno `ink` de **6 px** (total; `draw_string_outline` antes do `draw_string`).
- **Custo** (`ui_upgrade_cost_pill`): estrela `ui_icon_particles` de 20 px a 4 px da borda esquerda, centrada na vertical; número alinhado à direita, 8 px antes da borda, branco (ou `danger`/`text_secondary` conforme o estado). Fundo escuro: contorno opcional.

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
| `ui_button_secondary.png` | 192×144 | 52 / 52 / 52 / 68 | Botão secundário (BRF-073): branco → lavanda claro (`#FFFFFF`→`#E4DDFA`), contorno `ink`, sombra 6 px. Mesma geometria do botão grande; texto `text_on_light` sem contorno. Uso: "Voltar ao título", pausa |
| `ui_button_secondary_pressed.png` | 192×144 | 52 / 52 / 52 / 68 | Pressionado: corpo desce 4 px (1x), `#EDE8FF`→`#D3C9F5`; content margins iguais às do `button_big(true)` |
| `ui_pill_wave.png` | 192×96 | 48 / 40 / 48 / 48 | Pílula "ONDA x/y" (BRF-073): roxo `#8E72EC`→`#6E54C8`, contorno `ink`, brilho no topo, sombra 6 px. Canvas 1x 96×48, corpo 92×40 (raio 18). Altura ideal 48 (1x); estica na largura. Content margins sugeridas (1x): 20 / 6 / 20 / 12; texto `LabelHud` branco com contorno, centrado |
| `ui_pill_particles.png` | 192×104 | 48 / 44 / 48 / 52 | Pílula de Partículas (BRF-073): branca (`#FFFFFF`→`#ECE7FA`), contorno `ink`, sombra 6 px. Canvas 1x 96×52, corpo 92×44 (raio 20). Altura ideal 52 (1x); estica na largura. Content margins sugeridas (1x): 10 / 6 / 20 / 12; estrela `ui_icon_particles` de 32 px à esquerda e número em `text_on_light` (sem contorno) à direita |

Pílulas e botões têm uma faixa central de 4 px (1x) na vertical: em alturas maiores que o canvas o degradê estica, mas os cantos ficam intactos. Conferência das margens com texto de teste sobre o chão creme e o roxo do HUD: `_src/pills_check.png` (gerada pelo `gen_ui.py`).

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

## Menus holográficos (T-189, BRF-110)

Menu principal e Resultado do M2 (`docs/arte.md` §11, mockups `assets/mockups/mockup_holo_*.png`). Fonte: `_src/gen_ui_holo.py` (mesmo pipeline; não toca nas peças acima). Regenerar: `python assets/ui/_src/gen_ui_holo.py`. Validação: `_src/holo_compare.png` (mockup | peças a 2x | peças a 1x) e `_src/holo_check_*.png` (375×812).
**Escala:** o PNG é 2x do mockup de 375 px; no viewport de 720, **1 px do PNG ≈ 1 px de tela** (×0,96). Por isso as margens abaixo valem direto em `texture_margin_*` do `StyleBoxTexture` (ou `patch_margin_*` do `NinePatchRect`), sem `scale`. Total: 20 PNG, **~65 KB**. RGBA (alfa suave dos brilhos; paleta indexada piorava as bordas e o ganho seria de poucos KB). Use o filtro linear padrão (não o "nearest").

| Arquivo | PNG | Margens 9-patch E/D/C/B (px do PNG) | Uso / o que o AG02 faz |
|---|---|---|---|
| `ui_holo_panel.png` | 192×192 | 72/72/72/72 | Painel chanfrado (moldura `holo_line_dim`, miolo `holo_panel` 78%, colchetes ciano nos cantos sup. esq./inf. dir.). Sem brilho: corpo = canvas, `expand_margin` 0. Título e varredura por cima |
| `ui_holo_panel_gold.png` | 192×192 | 72/72/72/72 | Aviso de desbloqueio (moldura dourada, miolo `#1E1A14` 88%, brilho dourado pintado). Corpo a 16 px da borda: **`expand_margin` 16** nos 4 lados |
| `ui_holo_pill.png` | 96×64 | 20/20/20/20 | Pílula da Moeda e fundo do botão da engrenagem (44×44 no mockup ≈ 84 px). Sem brilho; o brilho da pílula da Moeda é opcional com `ui_holo_glow` atrás |
| `ui_holo_btn_primary_normal.png` | 192×160 | **48/48/56/56** | Jogar/Continuar. Brilho ciano pintado: **`expand_margin` 16** nos 4 lados (o retângulo do botão = corpo). Inclui filete branco e base escura de 12 px. Texto `holo_ink` |
| `ui_holo_btn_primary_pressed.png` | 192×160 | **48/48/56/56** | Pressionado: degradê mais escuro, corpo 6 px mais baixo, brilho menor. Mesmo canvas: troca direta. Mover o texto 6 px (content margin topo +6) |
| `ui_holo_btn_secondary_normal.png` | 128×96 | 24/24/24/24 | Secundário: moldura ciano 4 px + miolo `holo_panel` 90%. Corpo ocupa 92 px de altura; 4 px livres embaixo (espaço do pressionado). Texto `holo_text` |
| `ui_holo_btn_secondary_pressed.png` | 128×96 | 24/24/24/24 | Moldura `holo_text2`, miolo `#0E5A70`, corpo 4 px mais baixo |
| `ui_holo_btn_secondary_disabled.png` | 128×96 | 24/24/24/24 | Tokens `holo_dis_*`; texto `holo_dis_text` |
| `ui_holo_bar_track.png` | 64×32 | 8/8/8/8 | Trilho da barra de XP (moldura `holo_line_dim` 2 px, fundo `#071A2B`). Altura 24 px no menu, 28 no Resultado |
| `ui_holo_bar_fill.png` | 64×24 | 6/6/6/6 | Enchimento violeta → ciano (o degradê acompanha a largura). Recuo de 4 px dentro do trilho. `TextureProgressBar` com `nine_patch_stretch` ou `NinePatchRect` com largura = progresso |
| `ui_holo_bar_tip.png` | 16×40 | — | Ponta clara com brilho; centro horizontal na borda direita do enchimento, centrada na vertical. Marcas de 25% no Resultado: `ColorRect` 2 px `#021423` 70% |
| `ui_holo_level_badge.png` | 128×144 | — | Selo hexagonal sem número (hexágono em y 2–142). Resultado: tamanho nativo; menu: escala 0,8125 (52×58 do mockup). Número `holo_text` 800 por cima |
| `ui_holo_level_ring.png` | 192×192 | — | Anel tracejado da subida de nível, centrado no selo (diâmetro 164 px do anel). Girar (`rotation`) e sumir (`modulate.a`) por `Tween` |
| `ui_holo_slot_ready.png` | 128×128 | — | Slot liberado do aviso (corpo 120×120 + 4 px de brilho). Ícone `ui_icon_unlock_holo` a 64 px centrado por cima |
| `ui_icon_xp.png` | 64×64 | — | Ícone de XP (88 px no Resultado: escala 1,375 aceitável; ou 64 nativo) |
| `ui_icon_settings.png` | 48×48 | — | Engrenagem `holo_text2`, centrada na pílula 84×84. Sem ação no M2 |
| `ui_icon_lock_holo.png` / `ui_icon_unlock_holo.png` | 64×64 | — | Cadeado fechado (`holo_muted`) / aberto (ciano) |
| `ui_holo_scanline.png` | 256×4 | 64/64/0/0 | Linha de varredura (ciano 55%, pontas que somem). Estica na largura do painel; `modulate.a` 0,5 na animação |
| `ui_holo_glow.png` | 128×128 | — | Brilho radial **branco**: tingir com `modulate` (`holo_line` ou `gold`) e `CanvasItemMaterial` com `blend_mode = Add`. Pode esticar (ex.: elipse atrás da pílula da Moeda, ou o pulsar do Jogar, já que o brilho do botão é pintado) |

## Botão de velocidade x1/x2 (T-274, BRF-121)

HUD da partida, estilo `ui_holo_*` (mesma escala: **1 px do PNG ≈ 1 px de tela**, sem `scale`). Fonte: `_src/gen_ui_speed.py` (importa os helpers do `gen_ui_holo.py`); regenerar: `python assets/ui/_src/gen_ui_speed.py`. Validação: `_src/speed_sheet.png` (4 estados, 2x/1x, sobre creme e roxo), `_src/speed_check_x1.png`, `_src/speed_check_tray.png` (bandeja: não cabe) e a prévia `docs/img/botao-velocidade.png`.

| Arquivo | PNG | Uso |
|---|---|---|
| `ui_speed_x1.png` | 96×96 | Normal: painel escuro, moldura ciano, ">" + "x1" |
| `ui_speed_x1_pressed.png` | 96×96 | Pressionado do x1: moldura `holo_text2`, miolo `#0E5A70`, corpo 4 px mais baixo |
| `ui_speed_x2.png` | 96×96 | Ativo: ciano cheio (como o primário), brilho forte, ">>" + "x2" em `holo_ink` |
| `ui_speed_x2_pressed.png` | 96×96 | Pressionado do x2: degradê mais escuro, brilho menor, corpo 4 px mais baixo |

- **Texto na arte** ("x1"/"x2", Outfit 800, e as setas): o AG02 só troca a textura (`TextureButton`: `texture_normal`/`texture_pressed` por estado). Números não precisam de localização.
- Corpo 68×68 px em (14, 10) do PNG, base escura até y 84; o resto é brilho. Alvo de toque: o retângulo inteiro (96×96) ou ≥ 64×64 centrado no corpo (centro do corpo em (48, 44)).
- **Posição sugerida:** fileira do topo, à direita da pausa (centro do corpo em x ~157 no viewport 720, alinhado na vertical com a pausa), entre a pausa e a pílula "ONDA". Ao lado das skills não cabe sem mexer nos slots (sobram ~78 px à direita do slot 3).

- **Draw calls:** todas as peças estão em PNG separados; para o batching do Compatibility, o AG07/AG02 pode montar o atlas `atlas_ui_holo` (cabem num 512×512) se o profiler pedir.
- **Não incluídos:** Moeda (`ui_icon_coin`, T-162; as folhas usam um provisório), peças do hangar (slots bloqueado/próximo, molduras por raridade, M3). O brilho do painel "Subida de nível" do mockup é opcional (`ui_holo_glow` esticado atrás, `modulate.a` ~0,3).

## HUD holográfico da partida (T-289, BRF-125, decisão 64)

Todo o HUD da partida no estilo `ui_holo_*` (guia: `docs/arte.md` §12). Fonte: `_src/gen_ui_hud.py` (importa os helpers do `gen_ui_holo.py`); regenerar: `python assets/ui/_src/gen_ui_hud.py`. Desenho direto em px do viewport 720: **1 px do PNG = 1 px de tela**, sem `scale`. Total: 26 PNG, **~110 KB** (RGBA). Validação: `_src/hud_sheet.png` (todas as peças sobre navy e sobre o chão) e os mockups `docs/img/hud-holo-mockup.png` (720×1280) e `docs/img/hud-holo-mockup-375x812.png`.

| Arquivo | PNG | 9-slice E/D/C/B | `expand_margin` | Uso |
|---|---|---|---|---|
| `ui_hud_pill_wave.png` | 112×80 | 40/40/28/28 | 8 | Pílula "ONDA X/Y" (moldura ciano, brilho, colchetes). Corpo 96×64 em (8, 8) |
| `ui_hud_pill.png` | 112×80 | 40/40/28/28 | 8 | Pílula de Partículas (moldura `holo_line_dim`, sem brilho); ícone `ui_icon_particles` 32 px à esquerda |
| `ui_hud_btn_pause.png` / `_pressed.png` | 96×96 | — | — | Pausa com "II" na arte (geometria do `ui_speed_x1`: corpo 68×68 em (14, 10), centro (48, 44)). Alvo de toque 88×88 mantido. Substitui `ui_icon_pause` |
| `ui_hud_bar_track.png` | 80×56 | 20/20/20/20 | 8 | Trilho da Energia (corpo 64×40) |
| `ui_hud_bar_track_boss.png` | 80×56 | 20/20/20/20 | 8 | Trilho do chefe: moldura magenta `#FF4F8B` com brilho. Altura 32 |
| `ui_hud_bar_fill.png` | 64×32 | 10/10/10/10 | — | Enchimento **branco** da Energia: tingir por `modulate` (`UiTokens.core_hp_color`, como hoje). Recuo de 4 px dentro do trilho. Barra fantasma: o mesmo PNG com `modulate` branco a 45% |
| `ui_hud_bar_fill_boss.png` | 64×32 | 10/10/10/10 | — | Enchimento do chefe já colorido (magenta → vermelho); `modulate` branco. Altura 24 |
| `ui_hud_bar_flash.png` | 80×56 | 20/20/20/20 | 8 | Contorno branco com brilho por cima do trilho: estado de dano = `modulate` `danger` + `Tween` de alfa 1 → 0 (~250 ms) |
| `ui_hud_bar_tip.png` | 16×48 | — | — | Ponta branca com brilho (tingível): centro x na borda direita do enchimento, centrada na barra; `scale.y` 0,8 no chefe |
| `ui_hud_icon_energy.png` | 56×64 | — | — | Diamante ciano à esquerda da Energia (no lugar do cristal desenhado; corpo 40×52, sobra de brilho de 8) |
| `ui_hud_icon_boss.png` | 56×56 | — | — | Emblema do chefe (hexágono com chifres, magenta), à esquerda da barra do chefe (48 px) |
| `ui_hud_tray.png` | 64×80 | 8/8/24/8 | topo 12 | Fundo da bandeja: linha ciano no topo com brilho para cima (12 px sobre a arena) e miolo **opaco** `#06182A` |
| `ui_hud_tray_band.png` | 64×32 | 4/4/4/6 | — | Faixa dos upgrades (mais clara, filete `holo_line_dim` embaixo, 2 px). Altura 96 |
| `ui_hud_skill_ready.png` | 176×184 | — | — | Slot pronto: anel ciano 6 px + brilho, marcas a 45°. **Centro do círculo em (88, 88)**, raio 72 (Ø144), base escura 6 px abaixo |
| `ui_hud_skill_cooldown.png` | 176×184 | — | — | Slot em recarga: anel `holo_line_dim`, sem brilho |
| `ui_hud_skill_cooldown_ring.png` | 176×184 | — | — | Anel de progresso da recarga (ciano com brilho): `TextureProgressBar` radial (`fill_mode` horário, `radial_center` (88, 88)) por cima de `_cooldown`; enche à medida que a recarga passa |
| `ui_hud_skill_cooldown_mask.png` | 144×144 | — | — | Véu do setor restante (`#021423` 62%), mesmo uso do `ui_skill_cooldown_mask` |
| `ui_hud_skill_locked.png` | 176×184 | — | — | Bloqueado: tokens `holo_dis_*`, anel tracejado. Por cima: `ui_icon_lock_holo` 64 px e "NV n" |
| `ui_hud_skill_empty.png` | 176×184 | — | — | Liberado sem Módulo: anel tracejado `holo_line_dim`, sem ícone |
| `ui_hud_key_badge.png` / `_off.png` | 44×44 | — | — | Badge da tecla (corpo 36×36 em (4, 4)); `_off` no bloqueado. Centro em (cx + 52, cy − 60) do slot |
| `ui_hud_upgrade_normal.png` | 144×96 | — | 8 | Upgrade comprável. Corpo 128×80 em (8, 8); poço do ícone centrado em (39, 36) r 24 (= `ICON_C` + 8) e faixa do custo = `UpgradeButton.PILL` + (8, 8). Tamanho fixo |
| `ui_hud_upgrade_pressed.png` | 144×96 | — | 8 | Pressionado (moldura `holo_text2`, miolo `#0E5A70`); mantém a escala 0,94 do código |
| `ui_hud_upgrade_disabled.png` | 144×96 | — | 8 | Sem Partículas: `holo_dis_*`, sem brilho; ícone a 55%, custo `#FF9AA6` |
| `ui_hud_upgrade_max.png` | 144×96 | — | 8 | Máximo: moldura e faixa douradas; "MAX" em `gold` |

- **Texto fica na UI** (Outfit 800, `holo_text` com contorno `#021423` de 4–5 px, como no mockup): "ONDA X/Y", número de Partículas, "ENERGIA atual / máx", "Boss" e números do chefe, "Nv n", custos, "MAX", "NV n", dígitos das teclas e os segundos da recarga. Só a pausa ("II") e a velocidade têm o símbolo na arte.
- Ícones de upgrade e de Módulo atuais mantidos sem recolorir (funcionam sobre o fundo escuro).
- Peças antigas (`ui_skill_frame_*`, `ui_upgrade_*`, `ui_pill_*`, `ui_bar_*`, `ui_icon_pause`) ficam até o AG02 aplicar a T-290; depois podem sair do `.pck`.
