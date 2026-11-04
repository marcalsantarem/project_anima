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
| `surface` | `#FFFFFF` | botão secundário, pílula de moedas, botão de pausa |
| `text_primary` | `#FFFFFF` + contorno `ink` | texto sobre painéis e arena |
| `text_secondary` | `#E2DAFF` | rótulos, legendas |
| `text_on_light` | `#3A2A55` | texto de botão claro/ciano |
| `accent` | `#2FE6D2` (ciano) | foco, skill pronta, botão principal, cristal do Núcleo |
| `skill_fill` / `badge` / `locked` | `#957CE6` / `#CDF1FF` / `#9D98AE` | slot de skill, badge da tecla, bloqueado/desabilitado |
| `bar_track` | `#5B4A7A` | trilho das barras |
| `core_hp` | `#6CF0A4` → `#FFC93D` → `#FF5A6E` | HP do Núcleo: > 50% / 25–50% / < 25% |
| `boss_hp` | `#C056F0` | barra do chefe |
| `danger` | `#FF5A6E` | dano, derrota |
| `coin` | `#FFC93D` | estrela de moedas/Partículas, "Vitória" |
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
| `font_hud` | 32 | 800 | "ONDA X/Y", moedas |
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
       │ ◆ [NÚCLEO 1.170 / 1.500 ███] │  linha 2: 44 px
       │ [barra do chefe — só c/ boss]│  linha 3 (oculta sem chefe)
       ├──────────────────────────────┤ ← ~y 180 + safe_top
       │       ZONA DE COMBATE        │  Anima no centro; a arena encolhe (AG01)
       ├──────────────────────────────┤ ← bandeja, ~y 1000 − safe_bottom
       │ [up][up][up][up][up]         │  fileira de upgrades 5 × 128×80 (T-135)
       ├──────────────────────────────┤
       │   (1)      (2)      (3)      │  skills Ø 144, cy ≈ 1194
       │  safe area base (home bar)   │
y=1280 └──────────────────────────────┘
```

### 4.1 Topo (`Hud/Top`)

| Elemento | Posição | Tamanho | Notas |
|---|---|---|---|
| Pausa | linha 1, à esquerda | **88×88**, botão claro | "II"; também `Esc` |
| "ONDA X/Y" | linha 1, centro | pílula `bg_panel`, `font_hud` | pulso de escala (200 ms) ao trocar de onda |
| Moedas | linha 1, à direita | pílula `surface`, estrela `coin` + número `coin` | contagem da partida, com milhar |
| HP do Núcleo | linha 2, largura total | altura 40 px, cristal `accent` à esquerda | texto "NÚCLEO atual / máx", cor por faixa, flash `danger` e barra fantasma |
| Barra do chefe | linha 3, largura total | altura 28 px | aparece em `boss_spawned`; cor `boss_hp`, nome do chefe em cima |

### 4.2 Zona de combate

- Vai do fim do HUD do topo ao início da bandeja. **Nenhuma UI fixa entra aqui.**
- Textos flutuantes (dano, "Onda 3!") são permitidos, curtos (≤ 1 s) e **fora** do círculo central de raio ~160 px em volta do Anima **[Proposta]**.
- O Anima fica no centro da tela; o encolhimento da arena para caber a bandeja (87%) é do AG01 (T-144).

### 4.3 Bandeja inferior (`Hud/Tray`)

- Painel `bg_panel_alt` de largura total com contorno superior `ink`; vai até a borda inferior (a safe area entra como margem interna).
- **Fileira de upgrades** (`Hud.upgrade_row`, decisão 35): faixa `tray_band` com 80 px úteis (padding 10), 5 botões de 128×80 com gap 12 e margem 16. **O contêiner fica vazio até a T-135.**
- **3 slots de skill de Ø 144 px**, gap 66, centros em x = 150 / 360 / 570, cy ≈ 1194 sem safe area.
- Slots 2 e 3 bloqueados com cadeado e "NV 7"/"NV 12": **T-136**.
- **Área de toque = o círculo inteiro.** Toques entre os botões não fazem nada.

## 5. Componentes

### 5.1 `SkillButton`

| Estado | Visual |
|---|---|
| `ready` | círculo `skill_fill` com contorno e sombra de base `ink`, anel `accent` grosso, halo pulsando (1 vez a cada 1,5 s) |
| `cooldown` | véu `cooldown_dim` com setor radial regressivo, segundos em `font_title` com contorno (inteiros; 1 decimal abaixo de 1 s), anel fino escuro |
| `disabled` | fundo `locked`, ícone `text_secondary`, sem anel (ex.: fim da partida) |
| `pressed` | escala 0,92 por 100 ms; volta em 100 ms |

- **Uso confirmado** (`skill_used`): flash curto `accent` no anel, e o botão entra em `cooldown`.
- **Toque em recarga:** sem `skill_used`, o botão só treme de leve (100 ms), para mostrar que a skill está indisponível.
- **Cooldown com no máximo ~10 sinais/s:** o setor radial é interpolado localmente entre um sinal e outro, porque é só visual. O valor de verdade é sempre o último `remaining` recebido. Os segundos são arredondados para cima.
- Na transição `cooldown → ready` (`skill_ready`): flash `accent` + escala 1,08 → 1,0 em 200 ms.
- **Badge da tecla:** quadradinho `badge` no canto superior direito com a tecla do Input Map (ou o número do slot), sempre visível (mockup aprovado).
- **Toque e clique** disparam a mesma Input Action (§7). O botão não chama a skill diretamente.
- Ícones: placeholders geométricos brancos com contorno (explosão de 8 pontas, losango, hexágono) até a T-128.

### 5.2 `Bar` (HP do Núcleo / chefe)

- Pílula: trilho `bar_track` com contorno `ink` 4 px, preenchimento na cor do token com faixa `highlight`, texto `label_prefix` + "atual / máx" com contorno.
- **Interpolação:** o preenchimento principal vai direto ao novo valor, e uma "barra fantasma" clara vai atrás em ~300 ms, mostrando quanto foi perdido.

### 5.3 `Button` (telas)

- Altura mínima de 88 px, largura ≥ 360 px nos botões principais, `radius_m`, contorno `ink` 4 px e sombra de base de 6 px (pressionado = afunda).
- Principal: fundo `accent`, texto `text_on_light`. Secundário: fundo `surface`, texto `text_on_light`. Desabilitado: `locked`.
- Painéis (`PanelContainer`): `bg_panel` com moldura; variações `PanelPill`, `PanelPillLight` e `PanelTray`. Pausa e resultado usam um cartão central (`ScreenKit.card`).
- Foco por teclado visível (borda `accent` 4 px por fora); `Enter`/`Espaço` ativam.

## 6. Ligação com o gameplay (contrato em [docs/gameplay.md](gameplay.md))

Os sinais são emitidos pelo nó raiz `Match`.

| Sinal | Consumidor | Efeito |
|---|---|---|
| `core_hp_changed(current, max)` | Bar HP do Núcleo | valor, cor por faixa, flash de dano |
| `wave_changed(current, total)` | rótulo "ONDA X/Y" | texto + pulso |
| `skill_used(slot)` | SkillButton[slot] | flash de acionamento (§5.1) |
| `cooldown_changed(slot, remaining, total)` | SkillButton[slot] | estado `cooldown`, setor e segundos (≤ ~10×/s, interpolado) |
| `skill_ready(slot)` | SkillButton[slot] | estado `ready` + flash |
| `coins_changed(amount)` | rótulo de moedas | `amount` é o **total** da partida: o rótulo anima do valor exibido até ele (≤ 200 ms), sem somar nada |
| `boss_spawned(id)` | Bar do chefe | mostrar a barra + nome |
| `boss_hp_changed(current, max)` | Bar do chefe | valor; ocultar ao chegar a 0 |
| `match_ended(result)` | fluxo de telas | abrir Resultado com `result` |

- A UI **só ouve** esses sinais. Ela não lê nós da arena nem faz cálculos de jogo.
- `MatchResult`: `outcome` (`victory`|`defeat`), `wave_reached`, `waves_total`, `coins`, `enemies_killed`, `duration_s`.
- **`slot` é 1-based** (1 a 3) e casa com `skill_1`..`skill_3`.

## 7. Entrada

| Ação (Input Map) | Toque / mouse | Teclado |
|---|---|---|
| `skill_1`..`skill_3` | botão de skill | `1` `2` `3` |
| `skill_4` | Depois (fora do M1) | `Espaço` |
| `pause` | botão ⏸ | `Esc` |
| `ui_accept` (telas) | botão | `Enter` / `Espaço` |

- Nada de teclas fixas no código: tudo via Input Actions. Alterar o Input Map exige autorização do AG00.
- Durante a partida, `Espaço` é `skill_4`. A UI não usa `ui_accept` enquanto o HUD estiver ativo.
- **Multitoque:** é possível tocar duas skills ao mesmo tempo (cada botão trata o próprio toque).

## 8. Fluxo de telas do M1

```
Boot/Loading (HTML shell) → Toque para começar → Partida ⇄ Pausa → Resultado → (Jogar de novo) → Partida
```

| Tela | Conteúdo | Saídas |
|---|---|---|
| **Loading** (HTML, em `web/`) | logo/nome em texto, barra de progresso `accent` sobre `bg_void` | automática → Toque para começar |
| **Toque para começar** | nome do jogo (`font_title`), "Toque para começar" pulsando (`font_body`) | qualquer toque, clique ou tecla → **libera o áudio** → Partida |
| **Partida** | HUD (§4) | ⏸ / `Esc` → Pausa; `match_ended` → Resultado |
| **Pausa** (overlay) | véu `bg_panel` sobre o jogo, título "Pausado", botões **Continuar** e **Recomeçar** | Continuar / `Esc` → Partida; Recomeçar → nova Partida |
| **Resultado** | "Vitória" (`coin`) ou "Derrota" (`danger`) em `font_display`, num cartão com moldura; "Onda wave_reached/waves_total", moedas, inimigos derrotados, tempo (mm:ss); botão **Jogar de novo** | Jogar de novo → nova Partida |

- **Perda de foco** (troca de aba ou app, `NOTIFICATION_APPLICATION_FOCUS_OUT` / `visibilitychange`): abre a Pausa automaticamente. A volta **não** retoma sozinha; o jogador toca em Continuar.
- **Sem menu/hangar no M1** (meta-jogo fora do escopo). "Jogar de novo" volta direto à partida.
- Transições entre telas: fade de 200 ms.
- Textos em pt-BR, guardados em um só lugar (prontos para `tr()` no futuro) **[Proposta]**.

## 9. Safe area

- **Fonte do valor [Proposta]:** o HTML shell lê `env(safe-area-inset-*)` via CSS (com `viewport-fit=cover`) e o Godot recebe os valores por `JavaScriptBridge`. Fora da web, ou se falhar, usa `DisplayServer.get_display_safe_area()`; se nada vier, aplica a margem fixa de 24 px.
- Os insets são convertidos de px CSS para px da resolução base e aplicados como margem nos contêineres `HudTop` e `HudSkills` (e nas telas). A zona de combate não muda.
- A confirmar no iPhone (T-005): se o Safari reporta os insets em tela cheia e em modo navegador.

## 10. Pendências

| Item | Com quem |
|---|---|
| Paleta de projéteis inimigos sem ciano | AG01 |
| Arena encolhida (87%) para caber a bandeja de ~280 px sem cobrir inimigos | AG01 (T-144) |
| Botões de upgrade no `Hud.upgrade_row` / slots bloqueados | AG02 (T-135 / T-136) |
| Leitura da safe area no Safari (`animaGetSafeArea()` já está no shell) | AG02 (T-005) |

## 10b. HUD (implementação, T-112)

- **Cena:** `src/ui/hud/hud.tscn` (`Hud`, CanvasLayer 10). O tema é aplicado na raiz `Root` até o tema global entrar no `project.godot` (T-121).
- **Ligação:** `hud.bind(arena)` **antes** de a arena entrar na árvore, porque os valores iniciais saem no `_ready` dela. O HUD só escuta sinais; os `boss_*` são ligados se existirem.
- **Skills:** o toque chama `Arena.use_skill(slot)` (com `SkillButton.inject_action = false`). Se a arena recusar, o botão treme. O teclado vai direto pelo Input Map ao `SkillController`.
- **Pausa:** o botão emite `pause_requested` **e** injeta a action `pause`. A tela de pausa (T-113) deve ouvir **um** dos dois, não os dois.
- **Fim da partida:** `match_ended` desativa as skills e o botão de pausa.
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

## 11. Exportação Web

- **Preset `Web`** (`export_presets.cfg`): sem threads, sem extensões, VRAM compression só desktop (o 2D usa textura sem compressão VRAM), resize policy *adaptive*, saída em `build/web/index.html`. Exclui `tests/`, `addons/gut/`, `docs/` e `build/`.
- **Shell** `web/shell.html`:
  - viewport sem zoom com `viewport-fit=cover`;
  - página `position: fixed`, `overscroll-behavior: none`, `touch-action: none`;
  - bloqueio de pinça, duplo toque, rolagem e menu de contexto;
  - tela de carregamento com os tokens do tema;
  - `window.animaGetSafeArea()` devolve um JSON com os insets em px CSS.
- **Teste local:** sirva `build/web/` por HTTP (ex.: `python -m http.server -d build/web 8000`); `file://` não funciona.
