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

### 3.1 Cores (Cyber-Mystic Minimal)

| Token | Hex | Uso |
|---|---|---|
| `bg_void` | `#07090F` | fundo da arena, pillarbox |
| `bg_panel` | `#111726` (opacidade 85%) | painéis, barra do topo, overlays |
| `bg_panel_alt` | `#1A2236` | botões em repouso, trilhas de barra |
| `line` | `#2A3550` | bordas e divisores (1–2 px) |
| `text_primary` | `#E8EEF8` | texto principal |
| `text_secondary` | `#8A96B0` | rótulos, atalhos de teclado |
| `accent` | `#3DF5E0` (ciano) | foco, skill pronta, destaque |
| `core_hp` | `#3DF58A` → `#F5C53D` → `#F5455C` | HP do Núcleo: > 50% / 25–50% / < 25% |
| `boss_hp` | `#C040F5` | barra do chefe |
| `danger` | `#F5455C` | dano, derrota, alertas |
| `coin` | `#F5C53D` | moedas |
| `cooldown_dim` | preto com opacidade 55% | véu sobre a skill em recarga |

**Raridade** (reservado para depois do M1): comum `#9AA4B8` · raro `#3D8BF5` · épico `#A04DF5` · lendário `#F5B83D`.

**Regras:**
- Contraste do texto sobre `bg_panel` ≥ 4.5:1.
- **Projéteis inimigos não usam `accent`** (ciano). Isso evita confundir ameaça com UI. A paleta dos projéteis é com o AG01; peço `danger` e magenta.

### 3.2 Tipografia

- **Fonte [Proposta]:** *Outfit* (sans-serif geométrica, OFL), em `assets/fonts/`. Alternativa: *Exo 2* (OFL).
- **Pesos:** só 2 (Regular e Bold), para reduzir o tamanho do build.
- **Números do HUD:** algarismos tabulares (largura fixa), para não "tremerem" na contagem.

| Token | Tamanho (px base) | Peso | Uso |
|---|---|---|---|
| `font_display` | 72 | Bold | "Vitória" / "Derrota" |
| `font_title` | 48 | Bold | títulos de tela |
| `font_hud` | 32 | Bold | `Wave X/Y`, moedas, segundos do cooldown |
| `font_body` | 28 | Regular | textos de tela, botões |
| `font_caption` | 22 | Regular | atalhos de teclado, rótulos |

Mínimo absoluto: **22 px** na base (~11 pt no iPhone).

### 3.3 Espaçamento e forma

| Token | Valor |
|---|---|
| `space_xs / s / m / l / xl` | 8 / 16 / 24 / 32 / 48 px |
| `margin_screen` | 24 px (além da safe area) |
| `radius_s / m` | 8 / 16 px; botões de skill são círculos |
| `touch_min` | 88 px |
| `border` | 2 px (`line`); 3 px no foco (`accent`) |
| `anim_fast / anim_ui` | 100 / 200 ms, ease-out |

## 4. Layout da partida (retrato)

```
y=0    ┌──────────────────────────────┐
       │  safe area topo (notch)      │
       ├──────────────────────────────┤ ← topo do HUD = safe_top + 24
       │ [HP Núcleo ███████░░] [⏸]    │  linha 1: 64 px
       │ Wave 3/10          ● 125     │  linha 2: 48 px
       │ [barra do chefe — só c/ boss]│  linha 3: 32 px (oculta sem chefe)
       ├──────────────────────────────┤ ← ~y 200 + safe_top
       │                              │
       │       ZONA DE COMBATE        │
       │             ◆ Anima          │  centro da tela (360, 640)
       │      (nenhuma UI fixa)       │
       │                              │
       ├──────────────────────────────┤ ← ~y 1060 − safe_bottom
       │   (1)      (2)      (3)      │  botões de skill Ø 128 px
       ├──────────────────────────────┤ ← base do HUD = 1280 − safe_bottom − 24
       │  safe area base (home bar)   │
y=1280 └──────────────────────────────┘
```

### 4.1 Topo (`HudTop`)

| Elemento | Posição | Tamanho | Notas |
|---|---|---|---|
| HP do Núcleo | linha 1, esquerda → até o botão de pausa | altura 32 px | barra com interpolação suave (~150 ms), número `atual/máx` dentro dela, cor por faixa (`core_hp`), flash `danger` ao levar dano |
| Pausa | linha 1, à direita | **88×88** | ícone ⏸; também `Esc` |
| `Wave X/Y` | linha 2, à esquerda | `font_hud` | pulso de escala (200 ms) ao trocar de onda |
| Moedas | linha 2, à direita | `font_hud`, ícone `coin` | só a contagem da partida |
| Barra do chefe | linha 3, largura total | altura 24 px | aparece em `boss_spawned`, some com o chefe; cor `boss_hp`, nome do chefe à esquerda **[Proposta]** |

### 4.2 Zona de combate

- Vai do fim do HUD do topo ao início da barra de skills. **Nenhuma UI fixa entra aqui.**
- Textos flutuantes (dano, "Onda 3!") são permitidos, curtos (≤ 1 s) e **fora** do círculo central de raio ~160 px em volta do Anima **[Proposta]**.
- O Anima fica sempre no centro geométrico da tela (360, 640 na base). Em telas altas, o espaço extra é distribuído acima e abaixo dele.

### 4.3 Barra de skills (`HudSkills`)

- **3 botões circulares de Ø 128 px** (acima do mínimo de 88), com centros em x = 180 / 360 / 540 e espaço de 52 px entre eles.
- Centro vertical: `1280 − safe_bottom − 24 − 64` (≈ y 1192 sem safe area).
- **Ordem:** 1 = área, 2 = controle, 3 = defesa. A defesa fica à direita, mais perto do polegar direito **[Proposta]**.
- **4º slot (`Espaço`):** o [gameplay.md](gameplay.md) o deixa para depois do M1. Se entrar, os 4 botões ficam em x = 108 / 276 / 444 / 612 com Ø 120 px, ou o 4º vai acima do centro em Ø 104 px. Decisão do AG00.
- **Área de toque = o círculo inteiro.** Toques entre os botões não fazem nada (sem "dedo gordo" acionando o vizinho).

## 5. Componentes

### 5.1 `SkillButton`

| Estado | Visual |
|---|---|
| `ready` | ícone cheio, anel `accent`, brilho pulsando de leve (1 vez a cada 1,5 s) |
| `cooldown` | véu `cooldown_dim` com setor radial regressivo, segundos em `font_hud` (inteiros; com 1 decimal abaixo de 1 s), anel `line` |
| `disabled` | ícone em `text_secondary`, sem anel (ex.: pausa, fim da partida) |
| `pressed` | escala 0,92 por 100 ms; volta em 100 ms |

- **Uso confirmado** (`skill_used`): flash curto `accent` no anel, e o botão entra em `cooldown`.
- **Toque em recarga:** sem `skill_used`, o botão só treme de leve (100 ms), para mostrar que a skill está indisponível.
- **Cooldown com no máximo ~10 sinais/s:** o setor radial é interpolado localmente entre um sinal e outro, porque é só visual. O valor de verdade é sempre o último `remaining` recebido. Os segundos são arredondados para cima.
- Na transição `cooldown → ready` (`skill_ready`): flash `accent` + escala 1,08 → 1,0 em 200 ms.
- **Atalho:** no desktop, mostra a tecla (`1`, `2`, `3`) em `font_caption` abaixo do botão. No toque, fica oculto.
- **Toque e clique** disparam a mesma Input Action (§7). O botão não chama a skill diretamente.
- Ícones: placeholders geométricos (círculo, losango, escudo hexagonal), sem copiar ícones de jogos existentes.

### 5.2 `Bar` (HP do Núcleo / chefe)

- Trilha `bg_panel_alt`, preenchimento na cor do token, borda `line`.
- **Interpolação:** o preenchimento principal vai direto ao novo valor, e uma "barra fantasma" clara vai atrás em ~300 ms, mostrando quanto foi perdido.

### 5.3 `Button` (telas)

- Altura mínima de 88 px, largura ≥ 320 px nos botões principais, `radius_m`.
- Principal: fundo `accent`, texto `bg_void`. Secundário: fundo `bg_panel_alt`, borda `line`.
- Foco por teclado visível (borda `accent` 3 px); `Enter`/`Espaço` ativam.

## 6. Ligação com o gameplay (contrato em [docs/gameplay.md](gameplay.md))

Os sinais são emitidos pelo nó raiz `Match`.

| Sinal | Consumidor | Efeito |
|---|---|---|
| `core_hp_changed(current, max)` | Bar HP do Núcleo | valor, cor por faixa, flash de dano |
| `wave_changed(current, total)` | rótulo `Wave X/Y` | texto + pulso |
| `skill_used(slot)` | SkillButton[slot] | flash de acionamento (§5.1) |
| `cooldown_changed(slot, remaining, total)` | SkillButton[slot] | estado `cooldown`, setor e segundos (≤ ~10×/s, interpolado) |
| `skill_ready(slot)` | SkillButton[slot] | estado `ready` + flash |
| `coins_changed(amount)` | rótulo de moedas | `amount` é o **total** da partida: o rótulo anima do valor exibido até ele (≤ 200 ms), sem somar nada |
| `boss_spawned(id)` | Bar do chefe | mostrar a barra + nome |
| `boss_hp_changed(current, max)` | Bar do chefe | valor; ocultar ao chegar a 0 |
| `match_ended(result)` | fluxo de telas | abrir Resultado com `result` |

- A UI **só ouve** esses sinais. Ela não lê nós da arena nem faz cálculos de jogo.
- `MatchResult`: `outcome` (`victory`|`defeat`), `wave_reached`, `waves_total`, `coins`, `enemies_killed`, `duration_s`.
- **Pendência com o AG01:** confirmar se `slot` começa em 1 (como na tabela de skills do gameplay.md) ou em 0.

## 7. Entrada

| Ação (Input Map) | Toque / mouse | Teclado |
|---|---|---|
| `skill_1`..`skill_3` | botão de skill | `1` `2` `3` |
| `skill_4` | [A definir] | `Espaço` |
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
| **Resultado** | "Vitória" (`accent`) ou "Derrota" (`danger`) em `font_display`; `Wave wave_reached/waves_total`, moedas, inimigos derrotados, tempo (mm:ss); botão **Jogar de novo** | Jogar de novo → nova Partida |

- **Perda de foco** (troca de aba ou app, `NOTIFICATION_APPLICATION_FOCUS_OUT` / `visibilitychange`): abre a Pausa automaticamente. A volta **não** retoma sozinha; o jogador toca em Continuar.
- **Sem menu/hangar no M1** (meta-jogo fora do escopo). "Jogar de novo" volta direto à partida.
- Transições entre telas: fade de 200 ms.
- Textos em pt-BR, guardados em um s�