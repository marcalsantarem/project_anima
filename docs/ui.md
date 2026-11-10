# UI — Project: Anima

> Dono: AG02. Escopo: M1 (protótipo do combate). Itens **[Proposta]** aguardam aprovação do AG00; **[A definir]** estão em aberto.
> Fonte: Bíblia (escopo M1), AG02 §3–6. O contrato oficial de sinais fica em [docs/gameplay.md](gameplay.md) ("Sinais expostos à UI").

## 1. Princípios

1. **Touch first:** um polegar, iPhone em retrato. Alvo de toque mínimo de **88 px** na resolução base.
2. **A UI não tem lógica de jogo.** Ela lê o estado por sinais (§6) e dispara Input Actions (§7).
3. **O centro é do combate.** Nada de UI fixa sobre a zona de combate (§4.2) nem sobre avisos de ataque.
4. **Uma fonte de estilo:** um único `Theme` com os tokens abaixo. Cores e tamanhos nunca são fixados nas cenas.
5. **Movimento curto:** animações de UI com **≤ 200 ms**, só `modulate`, `scale` e `position` (sem shaders na UI).

## 2. Tela e escala

| Item | Valor |
|---|---|
| Resolução base | **720×1280** (retrato) |
| Stretch | mode `canvas_items`, aspect `expand` |
| Proporções testadas | 16:9 (720×1280) até 19.5:9 (720×1560) |
| Desktop | janela larga: pillarbox (faixas laterais na cor `bg_void`), jogo centralizado em retrato |
| Orientação | retrato; em paisagem no celular, aviso "Gire o aparelho" **[Proposta]** |

Com aspect `expand`, telas mais altas ganham altura extra. Essa altura vai para a **zona de combate**, nunca para o HUD.

## 3. Tokens

### 3.1 Cores (cartoon claro "Jardim Arcano", T-145)

Fonte única: `src/ui/theme/ui_tokens.gd`. Estilo das decisões 31–36 e do [docs/arte.md](arte.md) §6.

| Token | Hex | Uso |
|---|---|---|
| `ink` / `line` | `#3A2A55` | contorno de tudo (4 px), sombra de base, texto sobre fundo claro |
| `bg_void` | `#7C6BC9` | fundo das telas (lavanda) |
| `bg_panel` | `#8E7CD8` | painéis, pílula "ONDA", cartões |
| `bg_panel_alt` | `#5A4A9A` | bandeja inferior (skills) |
| `tray_band` | `#64549F` | faixa da fileira de upgrades |
| `bg_dim` | `ink` a 70% | véu atrás da pausa |
| `surface` | `#FFFFFF` | botão secundário, pílula de Partículas, botão de pausa |
| `text_primary` | `#FFFFFF` + contorno `ink` | texto sobre painéis e arena |
| `text_secondary` | `#E2DAFF` | rótulos, legendas |
| `text_on_light` | `#3A2A55` | texto de botão claro/ciano |
| `accent` | `#2FE6D2` (ciano) | foco, skill pronta, botão principal, cristal da barra de Energia |
| `skill_fill` / `badge` / `locked` | `#957CE6` / `#CDF1FF` / `#9D98AE` | slot de skill, badge da tecla, bloqueado/desabilitado |
| `bar_track` | `#5B4A7A` | trilho das barras |
| `core_hp` | `#6CF0A4` → `#FFC93D` → `#FF5A6E` | Energia: > 50% / 25–50% / < 25% |
| `boss_hp` | `#FF5A6E` (= `danger`) | barra "Boss" (decisão 39) |
| `danger` | `#FF5A6E` | dano, derrota |
| `particles` | `#7CF05A` | número de Partículas (sempre com contorno `ink`; decisão 40, T-161) |
| `gold` | `#FFC93D` | "Vitória", "+1" de nível, MAX; reservado à futura Moeda (M2) |
| `cooldown_dim` | `#1A0F2E` a 55% | véu da skill em recarga |
| `highlight` | branco a 18% | faixa de brilho no topo de botões e barras |

**Raridade:** comum `#9AA4B8` · raro `#3D8BF5` · épico `#A04DF5` · lendário `#F5B83D` (`RARITY_*`; molduras no arte.md §6).

**Regras:**
- Texto claro sempre com contorno `ink` (`outline_size` 8 no tema); texto escuro só sobre `surface`/`accent`.
- **Projéteis inimigos não usam `accent`** (ciano), para não confundir ameaça com UI.

### 3.2 Tipografia

- **Fonte:** *Outfit* variável (OFL), em `assets/fonts/`, com o `OFL.txt` ao lado. Avaliada na T-145: arredondada o bastante no peso 800 e já usada nos mockups; **fica**.
- **Pesos:** 600 (corpo) e 800 (títulos, HUD, botões), do mesmo arquivo variável (sem custo de build).
- **Números do HUD:** algarismos tabulares; milhar com ponto (`1.250`, `UiTokens.format_int`).

| Token | Tamanho (px base) | Peso | Uso |
|---|---|---|---|
| `font_display` | 72 | 800 | "Vitória" / "Derrota" |
| `font_title` | 48 | 800 | títulos de tela, segundos do cooldown |
| `font_hud` | 32 | 800 | "ONDA X/Y", Partículas |
| `font_body` | 28 | 600/800 | textos de tela, botões |
| `font_caption` | 22 | 800 | número na barra, badge da tecla, rótulos |

Mínimo absoluto: **22 px** na base (~11 pt no iPhone).

### 3.3 Espaçamento e forma

| Token | Valor |
|---|---|
| `space_xs / s / m / l / xl` | 8 / 16 / 24 / 32 / 48 px |
| `margin_screen` | 16 px (além da safe area) |
| `radius_s / m / l` | 12 / 20 / 28 px; pílulas 40 px; skills são círculos |
| `touch_min` | 88 px |
| `border` | 4 px `ink` em botões, painéis, barras e skills; foco = borda `accent` 4 px por fora |
| `shadow_base` | 6 px: sombra sólida `ink` sob botões e painéis (borda inferior mais grossa); ao pressionar, o botão "afunda" |
| `anim_fast / anim_ui` | 100 / 200 ms, ease-out |

## 4. Layout da partida (retrato)

Referência: [`mockup_cartoon_a_upgrades.png`](../assets/backgrounds/mockup_cartoon_a_upgrades.png).

```
y=0    ┌──────────────────────────────┐
       │  safe area topo (notch)      │
       ├──────────────────────────────┤ ← topo do HUD = safe_top + 16
       │ [II]   (ONDA 3/10)  (★ 1.250)│  linha 1: 88 px
       │ ◆ [ENERGIA 1.170 / 1.500 ██] │  linha 2: 44 px
       │   [Boss ████████ 2.140/2.500]│  linha 3: 36 px (só com chefe, +52)
       ├──────────────────────────────┤ ← y 164 (216 c/ chefe) + safe_top
       │       ZONA DE COMBATE        │  Anima no centro; a arena encolhe (AG01)
       ├──────────────────────────────┤ ← bandeja, y 1014 − safe_bottom (266 px)
       │ [up][up][up][up][up]         │  fileira de upgrades 5 × 128×80 (T-135), padding 6
       ├──────────────────────────────┤
       │   (1)      (2)      (3)      │  skills Ø 144 (+6 sombra), gap 8 acima, cy ≈ 1194
       │ max(8, inset da UI) (§9.1)   │  fundo da bandeja até a borda
y=1280 └──────────────────────────────┘
```

### 4.1 Topo (`Hud/Top`)

| Elemento | Posição | Tamanho | Notas |
|---|---|---|---|
| Pausa | linha 1, à esquerda | **88×88**, botão claro | "II"; também `Esc` |
| Velocidade | linha 1, à direita da pausa | **88×88** (arte 96, corpo 68), `TextureButton` | x1/x2 (T-275, decisão 59): mostra `SpeedController.chosen`, toque ou tecla `F` (`toggle_speed`) alterna; só na partida; sem efeito em pausa ou após `match_ended` |
| "ONDA X/Y" | linha 1, centro | pílula `bg_panel`, `font_hud` | pulso de escala (200 ms) ao trocar de onda |
| Partículas | linha 1, à direita | pílula `surface`, ícone verde `ui_icon_particles` (`StarIcon`) + número `particles` com contorno `ink` | total de Partículas da partida, com milhar |
| Energia (vida do Anima) | linha 2, largura total | altura 40 px, cristal `accent` à esquerda | texto "ENERGIA atual / máx" (decisão 41), cor por faixa, flash `danger` e barra fantasma |
| Barra "Boss" | linha 3, mesma largura útil da barra de Energia | controle 36 px, trilho 32 px (~89% da Energia) | vermelha (`boss_hp`), rótulo "Boss" à esquerda e "atual / máx" à direita, com contorno; fade de 200 ms ao aparecer (`boss_spawned` ou `boss_hp_changed`) e ao sumir (`boss_defeated`, vida 0 ou `match_ended`); queda do preenchimento em 150 ms (BRF-058) |

- **Sem faixa de fundo (BRF-039):** o fundo da arena passa por trás do topo; os elementos ficam sobrepostos a ele. Para leitura, um degradê `holo_bg` (alfa 0,6 → 0) cobre só a altura do topo (`Hud/Root/TopScrim`). Pílulas e barra mantêm o contorno.

### 4.2 Zona de combate

- Vai do fim do HUD do topo ao início da bandeja. **Nenhuma UI fixa entra aqui.**
- Textos flutuantes (dano, "Onda 3!") são permitidos, curtos (≤ 1 s) e **fora** do círculo central de raio ~160 px em volta do Anima **[Proposta]**.
- O Anima fica no centro da tela; o encolhimento da arena para caber a bandeja (87%) é do AG01 (T-144).

### 4.3 Bandeja inferior (`Hud/Tray`)

- Painel opaco `holo_tray` `#06182A` (`ui_hud_tray`, linha ciano no topo) de largura total; vai até a borda inferior, cobrindo a safe area (a safe area entra como margem interna; os botões ficam acima dela). Pilha (BRF-066): contorno 4 + faixa 96 (6 + 80 + 6 + contorno 4) + respiro 8 (`Hud.SKILLS_TOP_PAD`) + slot 150 (Ø 144 + sombra 6) + max(8, inset inferior da UI) (§9.1, T-172).
- **Fileira de upgrades** (`Hud.upgrade_row`, decisão 35): faixa `ui_hud_tray_band` com 80 px úteis (padding 6, `Hud.UPGRADE_BAND_PAD`), 5 botões `UpgradeButton` de 128×80 com gap 12 e margem 16 (5×128 + 4×12 = 688 = 720 − 2×16), na ordem `UpgradeButton.IDS` (§5.4). A faixa fica abaixo da arena: não cobre inimigos nem os slots.
- **3 slots de skill de Ø 144 px**, gap 66, centros em x = 150 / 360 / 570, cy ≈ 1194 sem safe area.
- Slots 2 e 3 bloqueados com cadeado e "NV 5"/"NV 8" (T-136, decisão 63). Os níveis vêm de `Hud.slot_unlock_levels` (padrão `Hud.DEFAULT_UNLOCK_LEVELS = [0, 5, 8]`, 0 = liberado: o HUD ainda não recebe o nível da conta, então o slot 1 fica liberado); o meta-jogo passa `[2, 5, 8]` (`ProgressionData.slot_unlock_levels`) com `set_slot_unlock_levels()`.

**HUD holográfico (T-290, BRF-127, decisão 64; `docs/arte.md` §12):** pílulas, pausa, barras (Energia e chefe), bandeja, slots e upgrades usam as peças `ui_hud_*` 1:1 (`UiArt.hud_*`, `UiNinePatch.expand` para o brilho que passa do retângulo). Textos com contorno `holo_bg` de 5 px (`UiTokens.HOLO_OUTLINE`). Chefe em `boss_holo` `#FF4F8B` (`UiBar.boss_art`); a cor da página na partida é `holo_tray`. `SkillButton.set_empty()` / `Hud.set_slot_empty()` mostram o slot liberado sem Módulo (visual, não ligado por padrão); `UpgradeButton` mostra a moldura pressionada enquanto o toque/clique está segurado. Posições, tamanhos e sinais não mudaram. Capturas: `docs/img/hud-holo-aplicado-{375x812,1280x720}.png`.
- **Área de toque = o círculo inteiro.** Toques entre os botões não fazem nada.

### 4.4 Alturas para o gameplay (BRF-039)

| API | Valor (base 720 px de largura) | Uso |
|---|---|---|
| `Hud.TOP_INSET` | 164 px | altura do topo (margem 16 + linha 1 88 + gap 16 + barra 44), sem safe area e sem a barra do chefe |
| `Hud.BOSS_BAR_INSET` | 52 px | altura extra do topo com a barra "Boss" (gap 16 + barra 36); `top_inset()` já soma enquanto ela está visível |
| `Hud.TRAY_HEIGHT` | 266 px | altura da bandeja (upgrades + skills), sem safe area (era 282 até a BRF-066). Medida |
| `hud.top_inset()` / `hud.tray_height()` | constante + safe area | valores reais em tempo de execução, em px da resolução base |

Teste: `tests/unit/ui/test_hud_layout.gd` confere as constantes contra o layout e, com safe area simulada (`ScreenKit.simulated_safe_area`), que a bandeja termina na borda da tela.

## 5. Componentes

### 5.1 `SkillButton`

| Estado | Visual |
|---|---|
| `ready` | círculo `skill_fill` com contorno e sombra de base `ink`, anel `accent` grosso, halo pulsando (1 vez a cada 1,5 s) |
| `cooldown` | véu `cooldown_dim` com setor radial regressivo, segundos em `font_title` com contorno (inteiros; 1 decimal abaixo de 1 s), anel fino escuro |
| `disabled` | fundo `locked`, ícone `text_secondary`, sem anel (ex.: fim da partida) |
| `locked` | fundo `locked`, sem anel nem halo, cadeado branco com contorno `ink` e "NV x" (`font_hud`) abaixo; badge mantido. `set_locked(true, nivel)` |
| `pressed` | escala 0,92 por 100 ms; volta em 100 ms |

- **Bloqueado (T-136):** não responde a toque nem clique (o evento é consumido, não vaza para a arena) e engole a action `skill_<slot>` no `_input`, antes do `SkillController`. Ignora `skill_used`, `cooldown_changed`, `skill_ready` e `set_disabled`. Cursor "proibido" e `accessibility_name` com o nível. `set_locked(false)` volta a `ready`.
- **Uso confirmado** (`skill_used`): flash curto branco no anel + "afundar" (escala 0,88 → 1 em 200 ms, T-117), e o botão entra em `cooldown`.
- **Toque em recarga:** sem `skill_used`, o botão só treme de leve (100 ms), para mostrar que a skill está indisponível.
- **Cooldown com no máximo ~10 sinais/s:** o setor radial é interpolado localmente entre um sinal e outro, porque é só visual. O valor de verdade é sempre o último `remaining` recebido. Os segundos são arredondados para cima.
- **Pulso de pronto (T-117):** na transição `cooldown → ready` (`skill_ready`, mesmo se o `cooldown_changed` com 0 chegar antes): escala 1 → 1,12 → 1 em 0,3 s + halo `accent` e anel branco que apagam em 0,3 s (`ready_glow`). Sem pulso no início da partida (sem recarga antes).
- **Badge da tecla:** quadradinho `badge` no canto superior direito com a tecla do Input Map (ou o número do slot), sempre visível (mockup aprovado).
- **Toque e clique** disparam a mesma Input Action (§7). O botão não chama a skill diretamente.
- **Arrastar para mirar (T-178, decisão 46; `drag_aim`, ligado no HUD):** com o botão `ready`, o toque só decide ao soltar: sem passar de `AIM_THRESHOLD` (24 px) = **toque simples** (`activated` ao soltar, alvo automático); passou = modo mira: anel extra `accent` (ou `danger` se o ponto é inválido) e ícone a 55%, sinais `aim_started(slot)`, `aim_moved(slot, at)` e `aim_ended(slot, at, cancelled)` com `at` em coordenadas do viewport. Soltar sobre o próprio botão, ou o botão sair de `ready` no meio (recarga, `disabled`, `locked`) = `cancelled`. Em recarga/bloqueado não há mira (recarga: aciona ao apertar e treme, como antes). O release do toque/mouse é tratado mesmo fora do círculo.
- **HUD ↔ Arena na mira:** `aim_moved` → `can_aim_at(at)` ? `show_skill_aim(slot, at)` : `hide_skill_aim()` + anel `danger`; `aim_ended` → `hide_skill_aim()` e, se não cancelado e `can_aim_at`, `use_skill(slot, at)` (falhou = treme). Arena sem essa API: soltar fora do botão vale como toque simples.
- Arte (T-138): molduras `ui_skill_frame_ready/cooldown/locked` (pronta tem halo fixo + halo pulsante desenhado), ícone por `icon_texture` (88 px; padrão do `Icon.CIRCLE` = meteoro, `UiArt.SKILL_METEOR_PATH`). No HUD (BRF-050, decisão 37) o ícone vem de `Hud.slot_icon_paths` (slot 1 = `ui_icon_skill_meteor.png`, o mesmo PNG de `SkillData.icon`; caminho inexistente cai no meteoro padrão) ou de `Hud.set_slot_icon(slot, tex)`, sem ler `src/match/`; cadeado `ui_icon_lock` (64 px), véu `ui_skill_cooldown_mask` como setor texturizado (buffers reaproveitados). `disabled` usa a moldura cinza e o ícone a 55%. Losango/hexágono desenhados só como fallback sem arte.

### 5.2 `Bar` (Energia / chefe)

- Arte (T-138): trilho `ui_bar_track` (altura fixa 36, centrado no controle), preenchimento `ui_bar_fill` branco (24 px, 4 px de folga) tingido pelo token (`core_hp_*`, `boss_hp`), brilho `ui_bar_shine`; texto `label_prefix` + "atual / máx" com contorno. Opções: `track_height` (escala trilho, preenchimento e brilho), `title` (rótulo à esquerda; números vão para a direita) e `fill_time` (queda animada). Barra "Boss": trilho 32, `fill_time` 0,15 s.
- **Interpolação:** o preenchimento principal vai direto ao novo valor, e uma "barra fantasma" clara vai atrás em ~300 ms, mostrando quanto foi perdido.

### 5.3 `Button` (telas)

- Altura mínima de 88 px, largura ≥ 360 px nos botões principais, `radius_m`, contorno `ink` 4 px e sombra de base de 6 px (pressionado = afunda).
- Principal: fundo `accent`, texto `text_on_light`. Secundário: fundo `surface`, texto `text_on_light`. Desabilitado: `locked`.
- Arte (T-138): `ButtonPrimary` usa `ui_button_big_normal/pressed` (9-patch; pressionado desce 4 px; desabilitado = normal esmaecido). O secundário (`Button`, padrão) usa `ui_button_secondary/_pressed` (T-153, BRF-075), com a mesma geometria e content margins: Resultado ("Voltar ao título", "Enviar log") e pausa ("Recomeçar", "Debug"). O foco segue em `StyleBoxFlat`.
- Painéis (`PanelContainer`): `ui_panel` (9-patch, conteúdo a 20 px, 26 embaixo). `PanelPill` = `ui_pill_wave` (ONDA x/y, content 20/6/20/12) e `PanelPillLight` = `ui_pill_particles` (estrela de 32 px e número `text_on_light` sem contorno, content 10/6/20/12), ambos `UiNinePatch` a 0,5 (T-153). Só o `PanelTray` segue em `StyleBoxFlat`. "MAX" do `UpgradeButton`: a arte não tem texto e o jogo desenha centralizado, branco com contorno `ink` de 6 px, bold, 20 px (T-154). Título, pausa e resultado usam o cartão central (`ScreenKit.card`).
- **9-patch em 2x:** `UiNinePatch` (`src/ui/theme/ui_nine_patch.gd`) desenha o PNG em escala 0,5 com as margens do README; o `StyleBoxTexture` desenharia as bordas no tamanho do PNG (o dobro). Texturas e tamanhos em `UiArt` (`src/ui/theme/ui_art.gd`). Filtro Linear (padrão do projeto), sem mipmaps.
- Foco por teclado visível (borda `accent` 4 px por fora); `Enter`/`Espaço` ativam.

### 5.4 `UpgradeButton` (T-135, decisão 35)

- `src/ui/components/upgrade_button.gd`. 128×80 (alvo de toque inteiro, ≥ 44 px). Ícone circular à esquerda, "Nv N" à direita e pílula de custo embaixo (ícone `ui_icon_particles` + número com milhar).
- Estados: **comprável** (fundo azul, anel `accent`), **sem Partículas** (fundo `locked`-claro, ícone apagado, custo rosado), **MAX** (moldura dourada, pílula dourada "MAX"), **desabilitado** (antes do 1º `upgrade_changed` e após `match_ended`).
- Toque/clique/`ui_accept` emitem `buy_requested(id)` **só se comprável**; nos outros estados o botão treme. Compra = afunda (≤ 150 ms) + "+1" `gold` que sobe e some (2 × `ANIM_UI`) quando o nível sobe.
- Teclado: `focus_mode = ALL` (Tab/setas) com anel `accent` por fora; `Enter` compra. **`Espaço` nunca compra** (é `skill_4`): o botão ignora eventos que casam com `skill_*`/`pause`. Clique/toque soltam o foco, para o anel só aparecer pelo teclado.
- Nomes (`accessibility_name`): Atk power, Atk spd, Defesa, Vida máxima, Cooldown. Arte (T-138): molduras `ui_upgrade_btn_normal/disabled/max` (canvas 132×90 em (−2, −2), sombra até y = 88), ícone `ui_icon_upgrade_*` Ø 40 em (31, 28) (`icon_texture` sobrescreve), pílula `ui_upgrade_cost_pill(_max)` em (9, 52) com o ícone `ui_icon_particles` 20 px (sem Partículas no estado desabilitado: `ui_icon_particles_off`); sem Partículas = ícone do upgrade a 55%. O `ui_icon_particle` dourado é obsoleto (reservado à Moeda do M2).
- Desenho só quando o estado muda (sem `_process`, StyleBoxes em cache).
- **Primeira vez comprável (T-117):** pop discreto 1 → 1,06 → 1 (2 × `ANIM_FAST`) e sinal `first_affordable(id)`, uma vez por partida.
- **Pílula de Partículas (T-117, `Hud.particles_pill`):** pulso 1,06 (200 ms) quando o saldo sobe (gasto não pulsa; não reinicia no meio de um pulso) e 1,12 quando um upgrade fica comprável pela 1ª vez (tem prioridade).
- **HUD (T-138):** pausa = `ui_icon_pause` (64 px, alvo de toque 88 px); ícone de Partículas (`StarIcon`) usa `ui_icon_particles` (verde, T-161) no HUD e no Resultado. Pílulas do topo e cristal da barra de Energia continuam desenhados (sem arte).

**Sem tooltips (BRF-039):** nenhum controle do HUD ou das telas usa `tooltip_text`; no toque o Godot exibia o tooltip sobre os botões. A descrição fica só em `accessibility_name`.

## 6. Ligação com o gameplay (contrato em [docs/gameplay.md](gameplay.md))

Os sinais são emitidos pelo nó raiz `Match`.

| Sinal | Consumidor | Efeito |
|---|---|---|
| `core_hp_changed(current, max)` | Bar de Energia | valor, cor por faixa, flash de dano |
| `wave_changed(current, total)` | rótulo "ONDA X/Y" | texto + pulso |
| `skill_used(slot)` | SkillButton[slot] | flash de acionamento (§5.1) |
| `cooldown_changed(slot, remaining, total)` | SkillButton[slot] | estado `cooldown`, setor e segundos (≤ ~10×/s, interpolado) |
| `skill_ready(slot)` | SkillButton[slot] | estado `ready` + flash |
| `particles_changed(total)` | rótulo de Partículas | `total` é o acumulado da partida: o rótulo anima do valor exibido até ele (≤ 200 ms), sem somar nada |
| `boss_spawned(id)` | Barra "Boss" | mostrar com fade (o `id` não é exibido) |
| `boss_hp_changed(current, max)` | Barra "Boss" | valor (mostra se ainda oculta); ocultar ao chegar a 0 |
| `boss_defeated` | Barra "Boss" | ocultar com fade |
| `upgrade_changed(id, level, max_level, next_cost)` | UpgradeButton[id] | nível, custo (`-1` = MAX); "+1" quando o nível sobe |
| `match_ended(result)` | fluxo de telas | abrir Resultado com `result`; HUD desabilita skills, pausa e upgrades |

- A UI **só ouve** esses sinais. Ela não lê nós da arena nem faz cálculos de jogo.
- `MatchResult`: `outcome` (`victory`|`defeat`), `wave_reached`, `waves_total`, `particles`, `enemies_killed`, `duration_s`.
- **`slot` é 1-based** (1 a 3) e casa com `skill_1`..`skill_3`.
- Compra: `UpgradeButton.buy_requested(id)` → `Hud` chama `Arena.buy_upgrade(id)`; se devolver `false`, o botão treme. A habilitação usa o `total` de `particles_changed` (imediato; só o número do topo anima).

## 7. Entrada

| Ação (Input Map) | Toque / mouse | Teclado |
|---|---|---|
| `skill_1`..`skill_3` | botão de skill | `1` `2` `3` |
| `skill_4` | Depois (fora do M1) | `Espaço` |
| `pause` | botão ⏸ | `Esc` |
| `toggle_speed` | botão x1/x2 | `F` |
| `ui_accept` (telas) | botão | `Enter` / `Espaço` |

- Nada de teclas fixas no código: tudo via Input Actions. Alterar o Input Map exige autorização do AG00.
- Durante a partida, `Espaço` é `skill_4`. No HUD, só os botões de upgrade aceitam `ui_accept`, e apenas por `Enter` (eventos que também são `skill_*`/`pause` são ignorados).
- **Multitoque:** é possível tocar duas skills ao mesmo tempo (cada botão trata o próprio toque).
- **Mira pela tecla (T-178):** com o Módulo `ready`, apertar `skill_<slot>` não dispara mais na hora: o `Hud._input` consome a action, põe o botão em "mirando" e mostra a prévia no cursor (`show_skill_aim` a cada movimento do mouse). Clique esquerdo numa área válida (`can_aim_at`) com a tecla pressionada = `use_skill(slot, cursor)` (o clique é consumido e não chega ao foco manual da arena); clique fora da área segue normal. **Soltar a tecla sem ter clicado = alvo automático** (o disparo pela tecla passou de "ao apertar" para "ao soltar"; apertar e soltar rápido continua sendo o automático). Em recarga ou bloqueado a action segue o caminho antigo (o `SkillController` recusa e o botão treme).

## 8. Fluxo de telas do M1

```
Boot/Loading (HTML shell) → Toque para começar → Partida ⇄ Pausa → Resultado → (Jogar de novo) → Partida
                                                                   → (Voltar ao título) → Toque para começar
```

| Tela | Conteúdo | Saídas |
|---|---|---|
| **Loading** (HTML, em `web/`) | logo/nome em texto, barra de progresso `accent` sobre `bg_void` | automática → Toque para começar |
| **Toque para começar** | continuação da splash tecnológica (§11.1): mesma arte e título; botão holográfico "Toque para começar" pulsando no lugar da barra; sai com véu escuro de 0,3 s | qualquer toque, clique ou tecla → **libera o áudio** → Partida |
| **Partida** | HUD (§4) | ⏸ / `Esc` → Pausa; `match_ended` → Resultado |
| **Pausa** (overlay) | véu `bg_panel` sobre o jogo, título "Pausado", botões **Continuar**, **Recomeçar** e **Voltar ao menu** | Continuar / `Esc` → Partida; Recomeçar → nova Partida; Voltar ao menu → Menu (T-288) |
| **Resultado** | "Vitória" (`gold`) ou "Derrota" (`danger`) em `font_display`, num cartão com moldura; "Onda wave_reached/waves_total", ícone verde + "Partículas: N", inimigos derrotados, tempo (mm:ss); botões **Jogar de novo** (primário, foco inicial) e **Voltar ao título** (secundário, abaixo; T-155) | Jogar de novo → nova Partida (`play_again_requested`); Voltar ao título → Toque para começar (`title_requested`) |

- **Perda de foco** (troca de aba ou app, `NOTIFICATION_APPLICATION_FOCUS_OUT` / `visibilitychange`): abre a Pausa automaticamente. A volta **não** retoma sozinha; o jogador toca em Continuar.
- **Sem menu/hangar no M1** (meta-jogo fora do escopo). "Jogar de novo" volta direto à partida.
- **Voltar ao título (T-155):** o `SceneFlow` troca a cena inteira (a partida, com Arena, HUD, Pausa e efeitos, é liberada como em "Jogar de novo") e abre o Título novo. O Título **pede o toque de novo**, por simplicidade: o áudio já está liberado e o gesto só confirma o início.
- Transições entre telas: fade de 200 ms.
- Textos em pt-BR, guardados em um só lugar (prontos para `tr()` no futuro) **[Proposta]**.

## 9. Safe area

- **Fonte do valor [Proposta]:** o HTML shell lê `env(safe-area-inset-*)` via CSS (com `viewport-fit=cover`) e o Godot recebe os valores por `JavaScriptBridge`. Fora da web, ou se falhar, usa `DisplayServer.get_display_safe_area()`; se nada vier, aplica a margem fixa de 24 px.
- Os insets são convertidos de px CSS para px da resolução base e aplicados como margem nos contêineres `HudTop` e `HudSkills` (e nas telas). A zona de combate não muda.
- A confirmar no iPhone (T-005): se o Safari reporta os insets em tela cheia e em modo navegador.

### 9.1 Altura do canvas, inset inferior e cor da página (T-172)

- **Altura = área visível real:** o shell faz `window.innerHeight` (que o Godot usa no canvas) devolver o **menor** entre o `innerHeight` nativo e `visualViewport.height` (sem zoom). **Nunca** `lvh` nem `screen.height`: no Safari do iPhone em aba, o web view acaba em ~768 de 812 px CSS e a faixa de baixo é do navegador (testado pelo dono: esticar o canvas cortou os slots). Em `visualViewport` `resize` e `orientationchange`, o shell avisa o Godot com um `resize`. `html`/`body`/splash/logo usam `inset: 0` (nunca mais altos que a área visível).
- **Inset inferior** (`ScreenKit.ui_bottom_inset`): o shell informa `covers_bottom` (base do canvas ≥ altura da tela − 1).
  - não cobre (Safari em aba, o normal): inset inferior **0**; sob os slots fica só a folga mínima de 8 px;
  - cobre (tela cheia/standalone): `max(12, 0,5 × inset)` px da resolução base acima da borda;
  - `ScreenKit.safe_area()` devolve `bottom` (já pela regra), `bottom_raw` e `covers_bottom`. HUD: folga sob os slots = `max(8, bottom)`; `tray_height() = 266 − 8 + max(8, bottom)` (a Arena segue por ela, via `SceneFlow`).
- **Cor da página = cor da etapa:** o Safari pinta a faixa abaixo do web view com o fundo da página. `animaSetPageColor(cor)` troca juntos o fundo de `html`/`body` e o `theme-color`: logo `#000000` → splash `#4E3F8F` (base do degradê) → título `#4E3F8F` → partida `#5A4A9A` (bandeja) → resultado `#7C6BC9`. No Godot: `ScreenKit.set_page_color()` (título, HUD e resultado).

```
iPhone 375×812 CSS, Safari em aba (k = 1,92 px do jogo/CSS)
┌ canvas = innerHeight 768 CSS ───┐
│ ...                             │
│ [up][up][up][up][up]            │
│ (1)  (2)  (3)  slots inteiros   │
│ 8 px do jogo (inset 0)          │
└─────────────────────────────────┘ y 768
  faixa do Safari 44 CSS, pintada com a cor da etapa (#5A4A9A na partida)
└ tela 812 ┘
```

## 9b. Debug e logs (T-107, BRF-063)

- **Resultado, fundo (T-277, BRF-093, decisão 60):** `assets/backgrounds/result_tech_bg_dim.webp` num `TextureRect` `Background` em tela cheia (`Ignore Size` + `Keep Aspect Covered`), atrás do cartão. Só o fundo mudou; o cartão roxo e os botões seguem no estilo atual até o M2 (T-180/T-190). Capturas: `docs/img/resultado-vitoria.png`, `resultado-derrota.png`.
- **Resultado com recompensa (T-191, BRF-115):** holográfico (mockup `mockup_holo_result.png`; peças `ui_holo_*`). `ResultScreen.set_reward(summary)` (chaves: `xp`, `coins`, `first_win_bonus`, `levels_gained`, `slots_unlocked`, `level_before/after`, `xp_before/after`, `xp_to_next_before/after` (0 = teto → "MAX"), `result_outcome`); sem ele não há seção de recompensa. Painéis: Recompensas (XP e Moeda contam de 0 ao valor em 1 s, selo "1ª vitória do dia" se `first_win_bonus`), Nível (selo + barra de XP; com subidas a barra enche/esvazia por nível, o selo pulsa com `ui_holo_level_ring`) e um aviso dourado "Slot N liberado" por item de `slots_unlocked` (aparece ao fim). Animação = função pura do tempo (`_apply(t)`), tween em tempo real (`set_ignore_time_scale`, decisão 59); toque na área pula; `reduced_effects` mostra o estado final direto; botões nunca ficam bloqueados. Gancho de VFX: `_play_level_up_fx(level)` (vazio, AG09). Moeda: ícone provisório desenhado até a T-162. Conteúdo rola em telas baixas. Botões: "Jogar de novo" (primário), "Voltar", "Enviar log". Capturas: `docs/img/resultado-recompensa-{vitoria,derrota}-375x{812,616}.png`. Testes: `tests/unit/ui/test_result_reward.gd`.
- **Resultado:** o botão "Logs" e o visualizador saíram (T-294, BRF-136). Abaixo de "Voltar ao título", **"Enviar log"** (T-269, 200×64; `LogUploader` em `src/debug/`, contrato em `docs/logs-api.md`): estados enviando / enviado ✔ (desabilitado) / falhou (tenta de novo), com aviso curto de privacidade abaixo. `LogUploader.ENABLED` desliga tudo no build final; textos em constantes `TXT_*` (trocar por chaves na T-240).
- **Título:** sem link de log (removido, BRF-099); logs só em Resultado e pausa. Gancho de subtítulo `TitleScreen.TXT_BUILD_TAG` (vazio no M2: nada é criado nem ocupa espaço; se preenchido, aparece em vermelho `danger`, maiúsculas, entre "ANIMA" e o botão; T-283 troca por `ALFA`). Capturas: `docs/img/titulo-375x616.png` e `-375x812.png`.
- **Pausa, "Voltar ao menu" (T-288, BRF-119):** botão secundário (mesmo estilo/tamanho de "Recomeçar"), `PauseScreen.menu_button`; despausa e emite `menu_requested` (o `SceneFlow` ouve e vai ao Menu; abandono sem recompensa). Captura: `docs/img/pausa-menu-375x812.png`.
- **Pausa holográfica (T-293, BRF-133):** véu `HOLO_BG` a 78%, painel `ui_holo_panel`, título "PAUSADO" (contorno `HOLO_BG`), Continuar primário (`ui_holo_btn_primary_*`), Recomeçar e Voltar ao menu secundários (`ui_holo_btn_secondary_*`); interruptores 228×88 com a mesma peça secundária (sem peça própria de interruptor: pendência AG08, ligado/desligado hoje só pelo texto). Sem mudança de sinais nem ordem. Capturas: `docs/img/pausa-holo-375x812.png` e `-1280x720.png`.
- **Pausa:** linha com dois interruptores 228×88: **"Efeitos reduzidos: sim/não"** (T-132, BRF-080) e **"Debug: ligado/desligado"**, que liga o overlay. O "Debug" (T-286, BRF-103) só existe na web com `?debug` na URL (qualquer valor; `DebugSettings.debug_ui_available()`), mesmo com o estado salvo; sem ele fica oculto e o "Efeitos reduzidos" centraliza. Fora da web, sempre visível. Os dois ficam em `user://debug.cfg` (`DebugSettings`; seções `[debug] overlay` e `[fx] reduced_effects`).
- **Efeitos reduzidos:** a pausa emite `reduced_effects_changed(on)`; o `SceneFlow` aplica na criação da partida e na hora (partida em curso) via `apply_reduced_effects(arena, director, on)`: `Arena.reduced_effects` (só se a propriedade existir) e `FxDirector.reduced_effects` (que repassa ao `FxPool`, de onde o `MatchRecorder` lê `reduced_effects` no log).
- **HUD:** sinal `ui_pressed(button, ok)` para o gravador.
- Detalhes, formato e como baixar no iPhone: [docs/debug.md](debug.md).

## 10. Pendências

| Item | Com quem |
|---|---|
| Paleta de projéteis inimigos sem ciano | AG01 |
| Arena encolhida (87%) para caber a bandeja de ~266 px sem cobrir inimigos | AG01 (T-144) |
| Leitura da safe area no Safari (`animaGetSafeArea()` já está no shell) | AG02 (T-005) |

## 10b. HUD (implementação, T-112)

- **Cena:** `src/ui/hud/hud.tscn` (`Hud`, CanvasLayer 10). O tema é aplicado na raiz `Root` até o tema global entrar no `project.godot` (T-121).
- **Ligação:** `hud.bind(arena)` **antes** de a arena entrar na árvore, porque os valores iniciais saem no `_ready` dela. O HUD só escuta sinais; os `boss_*` são ligados se existirem.
- **Skills:** o toque chama `Arena.use_skill(slot)` (com `SkillButton.inject_action = false`). Se a arena recusar, o botão treme. O teclado vai direto pelo Input Map ao `SkillController`.
- **Pausa:** o botão emite `pause_requested` **e** injeta a action `pause`. A tela de pausa (T-113) deve ouvir **um** dos dois, não os dois.
- **Fim da partida:** `match_ended` desativa as skills liberadas (as bloqueadas mantêm o cadeado) e o botão de pausa.
- **Safe area:** `apply_safe_area()` roda no `_ready` e a cada `size_changed`. Na web lê `animaGetSafeArea()`; no mobile nativo usa `DisplayServer.get_display_safe_area()`; no desktop, 0 + `margin_screen`.
- **Teste:** `src/ui/demo/hud_demo.tscn` (Arena + HUD).

## 10c. Telas (implementação, T-113)

Cenas independentes em `src/ui/screens/`, com o tema na raiz (via `ScreenKit`). O SceneFlow liga as telas na T-122.

| Tela | Cena | Contrato |
|---|---|---|
| Toque para começar | `title_screen.tscn` (`TitleScreen`) | sinal `start_requested`, emitido uma vez no primeiro toque, clique ou tecla. O gesto é tratado em `_input` (mesmo evento do navegador) para destravar o áudio. |
| Pausa | `pause_screen.tscn` (`PauseScreen`, CanvasLayer 20, `PROCESS_MODE_ALWAYS`) | `open()`, `close()`, `is_open()`, `bind(arena)` (desliga no `match_ended`); sinais `resumed` e `restart_requested`. Usa `get_tree().paused`. |
| Resultado | `result_screen.tscn` (`ResultScreen`) | `show_result(result: MatchResult)`, antes ou depois de entrar na árvore; sinal `play_again_requested`. |

- **Pausa — entrada única:** a tela ouve **só a action `pause`** (Esc + botão do HUD, que injeta a action). Ela **não** ouve `Hud.pause_requested`.
- **Perda de foco:** `NOTIFICATION_APPLICATION_FOCUS_OUT` / `WM_WINDOW_FOCUS_OUT` e, na web, `visibilitychange` abrem a pausa. A volta não retoma sozinha.
- **Recomeçar:** despausa e emite `restart_requested`. Quem ouve (SceneFlow) inicia uma partida nova.
- **Teste do fluxo:** `src/ui/demo/screens_demo.tscn` (Título → Partida → Pausa → Resultado → Jogar de novo).

### Menu principal (T-190, BRF-113)

`src/ui/screens/menu_screen.tscn` (`MenuScreen`), fiel a `assets/mockups/mockup_holo_menu.png`. Capturas: `docs/img/menu-375x616.png` e `menu-375x812.png`.
- **API:** `setup(view: Dictionary)` com `level`, `xp`, `xp_to_next`, `coins`, `is_max` (antes ou depois de entrar na árvore); sinal `play_pressed`. Não chama Backend nem SceneFlow (T-187 liga). Helpers estáticos: `format_number` (1.250) e `xp_ratio`.
- **Nível 30 (`is_max`):** texto `MAX` e barra cheia. XP no limite ou acima: barra cheia (clamp).
- **Layout:** fundo e animações da arte do título (`TitleScreen.build_art`); bloco único ancorado embaixo (logotipo, linha selo/barra/Moeda, Jogar), escala `largura / 375` (até 720) e menor em telas baixas para não cobrir o pedestal. Jogar >= 281x78 (1x). Peças `ui_holo_*` em `StyleBoxTexture` (Jogar com `expand_margin` 16 e texto 6 px abaixo ao pressionar; pílula; engrenagem) e `NinePatchRect` (barra).
- **Engrenagem (BRF-117):** ancorada ao canto superior direito da coluna do conteúdo (`MenuScreen.column_rect`: faixa da arte do título recortada à tela; em retrato é a tela toda), não da janela.
- **Engrenagem:** sem ação no M2 (nenhuma conexão em `pressed`). Sem Módulos, dicas de slot, ALFA nem versão.
- **Moeda provisória:** `MenuScreen.COIN_ICON` (único ponto de troca; T-162).

## 11. Exportação Web

- **Preset `Web`** (`export_presets.cfg`): sem threads, sem extensões, VRAM compression só desktop (o 2D usa textura sem compressão VRAM), resize policy *adaptive*, saída em `build/web/index.html`. Exclui `tests/`, `addons/gut/`, `docs/` e `build/`.
- **Shell** `web/shell.html`:
  - viewport sem zoom com `viewport-fit=cover`;
  - página `position: fixed`, `overscroll-behavior: none`, `touch-action: none`; fundo da página `#5A4A9A` (`UiTokens.BG_PANEL_ALT`, a bandeja do HUD), para que uma sobra no rodapé não mostre o lilás da splash; o degradê fica só em `#status`;
  - canvas `position: fixed` no canto (tamanho inline do Godot, policy *adaptive* + stretch `expand` = janela inteira). Altura pela regra do §9.1 (T-170, T-172);
  - **ordem das etapas: logo do estúdio → splash → título** (T-170, decisão 44). `#brand`: preto puro (`#000`, `100dvh`, safe areas) por cima da splash, logo `assets/branding/anima_games_logo.webp` em base64 (largura `min(60vw, 420px, 60vh)`); fade-in 200 ms, 1 s parado, fade-out 250 ms (≈1,5 s; corte seco com `prefers-reduced-motion`). O engine carrega em paralelo desde o início; se o jogo ficar pronto antes, o título só aparece quando o logo sai (`animaBrand.whenDone`); erro ou falta de WebGL 2 cortam o logo na hora (`animaBrand.stop`). `theme-color` e fundo da página seguem a etapa (§9.1);
  - bloqueio de pinça, duplo toque, rolagem e menu de contexto;
  - **splash tecnológica** (T-179, BRF-081, decisão 48): arte do dono `assets/splash/tech/tech_splash_clean.png` (768×1376, sem texto) → `web/splash/tech_splash_bg.webp` (q90, ~72 KB; `.gdignore`, fora do `.pck`), copiada para o build por `web/copy_pwa.sh` e pedida cedo com `<link rel="preload">`. Quadro `#status-art` ancorado no topo e centralizado, escala `--s = min(100dvh/1376, max(100vw/768, 0,88 × 100dvh/1376))` (1 u = 1 px da arte): cobre a altura e corta as laterais; em telas mais altas a arte ocupa ao menos 88% da altura e o resto é a cor da base `#021423`; laterais e base somem nessa cor em degradê (sem faixas). Enquanto a arte não carrega, fica só a cor (o logo preto cobre esse tempo);
  - por cima, em HTML/CSS (fonte do sistema): "PROJECT:"/"ANIMA" branco-ciano `#E6FFFF` com brilho (`text-shadow` ciano), topo em 895 u, 74 u e 132 u; **barra holográfica** (x 137 u, y 1194 u, 495×34 u, contorno ciano fino, preenchimento em degradê `#0E7F9C` → `#2FE6F2` → `#D8FFFF` com brilho e reflexo deslizando), progresso real do `onProgress` e modo indeterminado; "Carregando… N%" em `#9FF6FF` (1244 u);
  - animações CSS baratas: brilho do cristal pulsando (2,4 s), dois anéis tracejados achatados girando (60 s e 90 s), 8 partículas piscando; tudo parado com `prefers-reduced-motion` (a barra indeterminada só desacelera);
  - erro de carregamento e "sem WebGL 2" usam o mesmo fundo, com o aviso num painel holográfico no lugar da barra; ao iniciar o jogo, a splash sai com fade de 250 ms;
  - cor da página/`theme-color`: `#000` no logo, `#021423` na splash e no título, a bandeja `#5A4A9A` na partida. `index.html` ~47 KB (sem o logotipo base64 da splash B);
  - `window.animaGetSafeArea()` devolve um JSON com os insets em px CSS.
- **Teste local:** sirva `build/web/` por HTTP (ex.: `python -m http.server -d build/web 8000`); `file://` não funciona.

### 11.1 Tela "Toque para começar" (BRF-054, T-179)

`src/ui/screens/title_screen.gd` repete a splash tecnológica para a passagem parecer um único quadro:
- mesma escala do shell (`TitleScreen.art_scale(view)`, igual ao `--s`), com o quadro da arte ancorado no topo; fundo `assets/ui/title_bg_tech.webp` (import **Lossy 0,85**, ~60 KB no `.pck`) e cor da base `#021423` (raiz e página);
- "PROJECT:"/"ANIMA" em `LabelDisplay` com fonte proporcional à escala (74 u e 132 u), cor `#E6FFFF` e brilho pela sombra ciano sem deslocamento;
- animações em tweens (sem alocação por quadro): brilho do cristal (`GradientTexture2D` radial) pulsando, anéis tracejados (desenhados uma vez, só giram) e partículas piscando; com efeitos reduzidos (`DebugSettings.reduced_effects()`), anéis e partículas ficam parados;
- botão **"Toque para começar" holográfico** (StyleBoxFlat: fundo escuro translúcido, contorno ciano 3 px, sombra ciano; pressionado acende) no lugar da barra, 495×110 u (mín. 88 px), pulso de escala (0,8 s); em telas baixas sobe para não encostar no logo do estúdio;
- logo horizontal do estúdio (branco, 88%) na base, versão em ciano-claro no canto (o topo direito tem a bateria da arte);
- contrato mantido: qualquer toque, clique ou tecla emite `start_requested` uma vez e libera o áudio. No mesmo gesto, `TitleScreen.fade_from_dark()` põe um véu `#021423` (CanvasLayer 128 na raiz, ignora toque) que some em 0,3 s sobre a partida: sem corte seco do escuro para o cartoon claro;
- se a splash mudar no `web/shell.html`, ajuste as constantes do topo do script (px da arte).

## 11b. Áudio básico (T-182, BRF-123)
- Autoload `Audio` (`src/audio/audio_manager.gd`); barramentos `Music` e `SFX` em `default_bus_layout.tres`. Nada toca antes do 1º gesto: `TitleScreen` chama `Audio.unlock()`.
- Música (`mus_entrada.ogg`, loop) no Título e no Menu, com fade; para ao entrar na partida e no Resultado, volta ao Menu. Tiro do Anima: `Audio.play_shot()` (pool de 6 vozes, tom ±6%).
- Volumes 0-1 em `user://settings.cfg`, seção `audio` (`music`, `sfx`); `Audio.set_music_volume/set_sfx_volume`. Sem UI ainda. Fontes dos áudios: `assets/audio/_src/gen_audio.py`.

## 12. App na tela de início (T-175)

- **Arquivos:** `web/pwa/manifest.webmanifest` e ícones (cópia de `assets/app/`, AG08; atualizar com `bash web/copy_pwa.sh --sync-icons`). O export do Godot não copia extras: `bash web/copy_pwa.sh build/web` roda depois do `--export-release` (local e no workflow `deploy-web.yml`) e também sobrescreve `index.apple-touch-icon.png`/`index.icon.png`, que o preset (`html/export_icon`) injeta com o ícone do projeto. `web/pwa/.gdignore` mantém os PNGs fora do `.pck`.
- **Manifesto:** "Project: Anima"/"Anima", `start_url`/`scope` `./`, `display` standalone (`display_override` fullscreen → standalone), retrato, `background_color` e `theme_color` `#021423` (fundo da splash, T-179), ícones 192/512 `any`, 512 `maskable` e 180.
- **Sem service worker** (o PWA nativo do Godot gera um com cache offline; fica desligado): cada deploy aparece na próxima abertura.
- **Shell:** `<link rel="manifest">`, `apple-touch-icon` 180, favicons 32/48/ico, `apple-mobile-web-app-capable`, `mobile-web-app-capable`, `apple-mobile-web-app-title` "Anima", status bar `black-translucent`, `viewport-fit=cover`.
- **Standalone no iPhone:** sem barra do Safari; o web view vai da borda de cima (sob relógio/bateria) até a de baixo. O HUD já soma `safe-area-inset-top`. Altura do canvas pela regra do §9.1 (área visível real); se o canvas chega à borda, `covers_bottom = true` e a UI usa `max(12, 0,5 × inset)` embaixo. Conferir no log (`header.web.viewport`: `standalone`, `inner`, `vv`, `canvas`, `safe`).
- **Reinstalar no iPhone:** o iOS só relê manifesto, nome e ícone ao criar o atalho. Remova o atalho antigo (toque e segure › Remover App › Excluir da Tela de Início), abra o link no Safari e use Compartilhar › Adicionar à Tela de Início.
