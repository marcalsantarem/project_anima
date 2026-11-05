# Gameplay

> Dono: AG01. Escopo: M1 (protótipo do combate). Todos os números abaixo são **valores iniciais**: ficam em `data/` e mudam no playtest.
> Itens **[Proposta]** dependem de aprovação do AG00; **[A definir]** estão em aberto.

## Pilares

1. **Timing, não movimento.** O Anima não se move. A decisão do jogador é *quando* e *onde* usar cada skill.
2. **Legibilidade sob caos.** Muitos inimigos e projéteis, mas sempre dá para ler: o que me ameaça, o que é meu e quando a skill volta.
3. **Pressão em ondas.** Cada onda aperta e solta. O respiro entre ondas é parte do ritmo.
4. **Dados fora do código.** Nenhum número de balanceamento no script.

## Loop

| Escala | Duração | O jogador... |
|---|---|---|
| Decisão | ~10 s | vê a ameaça, escolhe a skill e a usa no momento certo |
| Onda | 30–60 s | sobrevive à composição; respiro de ~3 s antes da próxima |
| Fase | 3–10 min | ~10 ondas + chefe; vitória ao derrotar o chefe, derrota se o HP do Núcleo chegar a 0 |

## Arena e câmera

| Parâmetro | Valor |
|---|---|
| Resolução base | 720×1280, retrato, stretch `canvas_items` / `expand` |
| Arena (`arena_rect`) | **tela cheia acima da bandeja** (BRF-041): de y = 0 até `altura do viewport − arena_bottom_inset` (282 = `Hud.TRAY_HEIGHT`; quem monta a partida pode passar `Arena.set_bottom_inset(hud.tray_height())`, com safe area). O HUD de cima fica sobreposto ao fundo. Recalculada no `size_changed` do viewport (720 × 1280 a ~1560) |
| Área livre (`free_rect`) | entre o topo do HUD e a bandeja (T-169, decisão 43): de `arena_top_inset` (164 = `Hud.TOP_INSET`, **fixo**: a barra "Boss" não desloca o Anima) até o topo da bandeja (`altura − arena_bottom_inset`). Recalculada no `size_changed` e no `set_bottom_inset` |
| Anima | **centro da área livre**: `x = largura / 2`, `y = (top_inset + tray_top) / 2` (720×1280 com bandeja 282: y = 581; 720×1474: y = 678). Selo, pilares, alvo dos inimigos (inclusive os já em campo) e o alvo do meteoro seguem esse centro. Câmera fixa |
| Bordas de spawn | `top`, `bottom`, `left`, `right`, **fora da tela inteira** (`screen_rect`): `spawn_margin` 32 px + o desenho do inimigo (`Arena.spawn_margin_for`: laterais = meia largura do sprite/anel, base = altura acima da âncora, topo = raio). Nenhum inimigo nasce visível |
| Lógica | `_physics_process` a 60 Hz; o visual nunca decide a regra |

### Perspectiva 3/4 (T-144)

- **`position` = âncora = ponto de contato com o chão**, em coordenadas de tela. O corpo é desenhado acima dela.
- **Regra no plano do chão:** o Y da tela é o Y do chão encolhido por **0,75** (`GroundPlane.Y_SCALE`). Alcance, raios, distâncias e velocidades (px e px/s) valem **no chão**: 100 px no chão = 100 px na horizontal ou 75 px na vertical da tela. Use sempre `GroundPlane` (`distance`, `move_toward`, `to_ground`, `to_screen`), nunca `distance_to` direto.
- **Colisão:** `CircleShape2D` com o `CollisionShape2D` em escala `(1, 0,75)`, ou seja, círculo no chão = elipse na tela (testado no Godot 4.7.2, inclusive elipse × elipse).
- **Desenho:** decalques no chão (sombra, anel de skill, telegraph) são elipses 0,75 com `z_index = -1`, abaixo de todos os corpos. Cada entidade tem uma `GroundShadow` (115% do raio de colisão).
- **Y-sort:** `Arena`, `Enemies`, `Projectiles` e `EnemyProjectiles` com `y_sort_enabled`; Anima, inimigos e projéteis são ordenados juntos pela âncora. Projéteis voam `ProjectileData.height` px acima da sombra (só desenho).

### Arte na arena (T-137)

- Sprites de `assets/sprites/` via `SpriteArt` (`src/match/arena/sprite_art.gd`): PNG 2x, `scale` 0,5, `centered = false`, `offset = -âncora`, filtro Linear. Textura e âncora ficam nos dados: `EnemyData.sprite/sprite_anchor`, `ProjectileData.sprite/sprite_anchor`, `AnimaData` (grupo "Arte": base, cristal a `crystal_height` 110 px com bob de 5 px, 3 nós em elipse 29×12 px). Só visual: colisão, `GroundShadow` e `ground_plane` não mudaram.
- Projétil: sprite a `height` px acima da âncora, `rotation` = direção do tiro na tela. `ProjectileData.shape/color` seguem como identidade de leitura (testes), sem desenho.
- Fundo (BRF-041): nó `Floor` (`ArenaFloor`, `src/match/arena/arena_floor.gd`) com as peças de `assets/backgrounds/`: `floor_tile` repetido (Sprite2D com `region` + repeat) cobrindo a tela inteira, `floor_top_shade` no topo e `floor_ring` no Anima (escala `ArenaFloor.RING_SCALE` 0,35 = ~70% do tamanho anterior, decisão 43; todos `z_index = -10`); 4 `floor_pillar` nos cantos da área livre (`free_rect`; insets `pillar_inset_*`, topo 96 abaixo do HUD), com `GroundShadow` e Y-sort junto das entidades. Sem moldura. `ArenaFloor.layout()` só reposiciona (sem alocar por frame).
- Chefe: ogro (`boss_ogre.png`, âncora (256, 472), sem anel; `BossData.sprite_attack`/`sprite_stunned` para o wind-up e o atordoamento). Os campos `ring_*` do `EnemyData` continuam disponíveis.
- Fora: `pickup_particle.png` (ainda não há drop no chão) e `shadow_ground.png` (a sombra segue desenhada pelo jogo).

## Anima e ataque automático

Arquivos de dados: `data/anima/anima_default.tres` (`AnimaData`) e `data/projectiles/projectile_anima_basic.tres` (`ProjectileData`).

| Campo | Valor | Notas |
|---|---|---|
| `AnimaData.core_hp_max` | 100 | HP do Núcleo |
| `AnimaData.hurtbox_radius` | 40 px | hurtbox circular |
| `AnimaData.fire_rate` | 2 tiros/s | |
| `AnimaData.attack_range` | 600 px | fora do alcance, não atira; também é a distância máxima do projétil |
| `AnimaData.target_scan_interval` | 0,1 s | busca de alvo por intervalo, não por frame |
| `AnimaData.projectile_pool_size` | 64 | pré-alocados; nada de `instantiate`/`queue_free` por tiro |
| `ProjectileData.speed` | 900 px/s | |
| `ProjectileData.damage` | 10 | |
| `ProjectileData.radius` | 6 px | |
| `ProjectileData.pierce` | 0 | número de alvos extras atravessados |
| `ProjectileData.color` | ciano | exclusivo do jogador; projéteis inimigos **sem ciano** |

**Mira:** maior `target_priority` primeiro (campo do inimigo); empate → mais próximo. Só considera inimigos dentro do alcance e visíveis.
**Projétil:** tiro em linha reta (sem teleguiado); acerta cada alvo uma vez; some ao passar do alcance ou ao esgotar o `pierce` e volta ao pool. Inativo, fica estacionado fora da arena (sem ligar e desligar a colisão). Pool esgotado = o tiro é pulado, o pool não cresce.

## Skills

3 slots no M1. O 4º slot (`skill_4` / `Espaço`) fica para **depois do M1**.

Cada skill é um `SkillData` (`data/skills/skill_<id>.tres`):
`id, type (AREA|CONTROL|DEFENSE), delivery (INSTANT|METEOR), cooldown, radius, damage, duration, windup, target_range, effect_params, fx_id, sfx_id, icon` + grupo Meteoro (`telegraph_time, fall_time, fall_height, crater_time, fizzle_cooldown_ratio, meteor_texture/anchor, crater_texture/anchor`).
O comportamento fica em um script por `type` (`SkillBehavior` → `AreaSkill`, ...), que só lê o Resource. Skill nova = dados novos; tipo novo = script novo + uma linha em `SkillController.behavior_for`.

**Implementação (T-108):** `SkillController` (nó `Skills` da arena) guarda os slots (1-based), o cooldown (`SkillSlot`, lógica pura) e escuta `skill_1..3` em `_unhandled_input`. A UI aciona por `Arena.use_skill(slot) -> bool`. As skills do slot vêm do export `skills` da cena até o `MatchConfig` trazê-las (AG04).

| Slot | Input Action | Skill (M1) | Tipo | Cooldown | Raio | Efeito |
|---|---|---|---|---|---|---|
| 1 | `skill_1` (`1`) | `skill_meteor` | area (METEOR) | 10 s | 160 px | 40 de dano no impacto, 0,6 s após o acionamento |
| 2 | `skill_2` (`2`) | `skill_stasis` | control | 15 s | 220 px | congela por 2,5 s; `effect_params.slow_after` = 0,5 por 1,5 s |
| 3 | `skill_3` (`3`) | `skill_aegis` | defense | 20 s | — | escudo no Núcleo por 4 s, absorve até 50 de dano |

- **Ao acionar:** valida o cooldown → aplica o efeito → emite `skill_used(slot)` e passa a emitir `cooldown_changed`. Acionar em cooldown não faz nada (a UI pode dar feedback de "indisponível").
- **Sem alvo:** se não há inimigo ao alcance, a skill de área não dispara e **não gasta o cooldown**.
- **Alvo da área e do controle:** automático, no ponto de maior densidade de inimigos dentro de `target_range` (calculado no acionamento; os centros candidatos são as posições dos inimigos).
- **Área:** dano por distância (raio da skill + raio do inimigo), sem usar a layer `skill_areas`. Mira manual: ver "Foco manual e mira dos Módulos" (decisão 46).
- **Feedback:** antecipação curta (~0,1 s) + impacto forte; tremor leve **desligável**.

### Meteoro de fogo (T-139, decisão 37)

- `MeteorSkill` (estende `AreaSkill`), escolhido por `delivery = METEOR`. A `skill_pulse` saiu da partida; o `.tres` fica só para os testes do `AreaSkill` instantâneo.
- **Alvo:** o inimigo ao alcance (`target_range`) com mais vizinhos no `radius` (no chão); empate, inclusive todos sozinhos, = o mais próximo do Anima. O ponto é **adiantado**: posição prevista desse inimigo após `telegraph_time` (só se ele está avançando; atirador parado = posição atual). **T-173:** no início da queda (fim do aviso, `fall_time` antes do impacto) o alvo é **reavaliado** com a mesma regra, adiantado pelo tempo que falta; o telegraph pula para o novo ponto. Se nesse ponto **não há inimigo no raio** (mesma regra do dano: `radius` + raio do inimigo), o meteoro é **anulado**: sem queda, dano, cratera nem `skill_cast`; o cooldown restante cai para `fizzle_cooldown_ratio` (0,2) do total e sai `skill_fizzled(slot, at)`. **Com o chefe vivo nunca é anulado** (sempre cai, lança e atordoa).
- **Tempo:** telegraph no chão (elipse que enche) por `telegraph_time` = 0,6 s; o meteoro cai nos últimos `fall_time` = 0,35 s (de `fall_height` = 360 px acima, acelerando); no impacto, dano em área no chão e `skill_cast`; a cratera fica `crater_time` = 0,5 s. Nada é alocado na animação (nós criados no `_ready`).
- **Arte:** `assets/sprites/skill_meteor.png` (âncora 64,164) e `skill_meteor_crater.png` (âncora 128,96, escalada para largura 1x = 2 × raio × 1,07); sem textura, desenho provisório por código. `icon` = `assets/ui/ui_icon_skill_meteor.png` (o HUD ainda não lê esse campo: AG02).
- **Balanceamento:** 40 de dano mata enxame (8), corredor (20) e atirador (35); tanque (120) leva 1/3. Raio 160 cobre um grupo de enxame (espalhamento 48). Com 1 uso a cada 10 s, limpa grupos sem resolver as ondas 5+ (12–14 corredores vindos de bordas diferentes). Upgrades futuros: `radius`, `damage`, `cooldown` são campos separados; `upgrade_cooldown` já vale.
- Cards e raridades (AG04, depois do M1) só alteram números e efeitos via `SkillData`. O gameplay não conhece cards.

## Inimigos

Arquivo de dados: `data/enemies/enemy_<id>.tres` (`EnemyData`). Campos: `id, hp, speed, contact_damage, attack_range, fire_rate, projectile (ProjectileData), target_priority, particle_drop, radius, group_min, group_max, group_spread, color`.

| Arquétipo | `id` | HP | Velocidade | Ataque | Partículas |
|---|---|---|---|---|---|
| Corredor | `enemy_runner` | 20 | 140 px/s | contato, 4 de dano | 1 |
| Tanque | `enemy_tank` | 90 | 50 px/s | contato, 15 de dano | 4 |
| Atirador | `enemy_shooter` | 35 | 80 px/s | para a 380 px do centro; 1 tiro a cada 2 s (`projectile_enemy_bolt`: 3 de dano, 300 px/s, losango magenta) | 2 |
| Enxame | `enemy_swarm` | 8 | 120 px/s | contato, 1 de dano; nasce em grupos de 5–8, espalhados em 48 px | 1 cada |

- **Estados:** `SPAWN → AVANÇA → ATACA → MORRE`, mais `CONGELADO` e `LENTO` (das skills de controle).
- **Contato:** ao tocar a hurtbox do Anima, o inimigo causa `contact_damage` e morre (sem Partículas).
- **Justiça:** projéteis inimigos com cor e forma distintas das do jogador (ex.: losango quente × círculo frio) e mais lentos que os do jogador.
- **Atirador:** um só script (`Enemy`); com `attack_range > 0` ele para no alcance (estado `ATTACK`) e atira com o pool `EnemyProjectiles` da arena (128, layer `enemy_projectiles`). Quem reage ao acerto é o Anima (mask), que consome o projétil.
- **Grupo:** cada spawn de onda cria `group_min..group_max` inimigos (`Arena.spawn_group`). Só o enxame usa grupo > 1.
- Inimigos em pool por arquétipo (T-118); fora da tela não fazem cálculos caros.
- **Balanceamento:** valores do BRF-051 (ver "Balanceamento da fase 1").
- **Barra de vida (T-149, decisão 38):** `HealthBar` (`src/match/enemies/health_bar.gd`), filha do inimigo, 6 px de altura, largura `28 + raio` limitada a 40–56 px, 6 px acima do topo do sprite, z +1 (acima dos corpos), contorno `ink` `#3A2A55` 1,5 px e trilho `bar_track` `#5B4A7A`. Cor pela fração: **verde** `#3FD27F` com ≥ 60% (mais escuro que o `core_hp` para ler sobre o chão creme), **amarela** `#FFC93D` abaixo de 60%, **vermelha** `#FF5A6E` com ≤ 30%. Cheia ao nascer; só redesenha em `take_damage` (sem `_process`). `EnemyData.show_health_bar` (padrão true; o chefe usa false). Teste: `tests/unit/match/test_health_bar.gd` (faixas e 150 inimigos sem redesenho por quadro).

## Chefe

**Ogro (T-150, decisões 39 e 42).** Dados em `data/enemies/boss_warden.tres` (`BossData`; o id `boss_warden` foi mantido para não quebrar HUD/FX/fase; a arte é do ogro). Código em `src/match/enemies/boss/` (`Boss` herda `Enemy`). Entra sozinho na onda 10. **Uma fase**, **um golpe corpo a corpo**, **sem minions nem tiros**, **sem defesa** (T-166: a barra de defesa saiu; só a barra "Boss" do HUD, de vida).

| Parâmetro | Valor |
|---|---|
| HP | 1100 (`hp`; T-173: era 1200); defesa `defense_max = 0` (arquivada, ver abaixo) |
| Movimento | 140 px/s (T-173: era 160) até `attack_range` 100 px (no chão) do centro do Núcleo: encosta sem tocar a hurtbox (40 + raio 48) |
| Golpe | a cada `attack_interval` 1,8 s (T-173: era 1,5); `attack_windup` 0,5 s de aviso (sprite `boss_ogre_attack.png`, cresce até +12% e puxa para vermelho) e `attack_damage` 20 (T-173: era 30) no Núcleo (passa pela defesa do upgrade) |
| Meteoro | **sempre** causa o dano (40) na vida **e** lança o chefe (`Boss.take_skill_damage`; vale qualquer meteoro cujo raio o toque). Se o meteoro o mata, não há lançamento |
| Lançamento | `launch_distance` 600 px no chão para longe do Núcleo, **limitado a 85% do alcance do Anima** (decisão 47: `Arena.boss_launch_reach_ratio` 0,85 × `attack_range` 600 = 510 px do Núcleo, no chão; `Boss.launch_max_reach`), preso na área visível acima da bandeja (`Arena.boss_launch_bounds`: arena menos o raio nas laterais e na base e a altura do sprite no topo); voo `launch_time` 0,6 s (tween de física, ease-out) |
| Atordoado | `stun_time` 2 s (sprite `boss_ogre_stunned.png`), não bate; no fim anda de volta |
| Imunidade | `relaunch_immunity` 1 s depois de acordar: o meteoro fere, mas não relança. Em voo ou atordoado também não relança. Evita prender o chefe longe com dois meteoros seguidos (o cooldown do meteoro com upgrade fica perto do ciclo voo + atordoamento + volta) |
| Passos (T-167) | `WalkAnimator` (`src/match/enemies/walk_animator.gd`), só visual: `walk_bob` 7 px, inclinação ±`walk_tilt_deg` 5°, squash `walk_squash` 6% no apoio do pé e sombra encolhendo até 12% no alto do passo; ritmo = distância andada / `walk_step_length` 70 px (a 140 px/s = 2 passos/s). Parado, atacando, em voo ou atordoado: pose neutra. `walk_frames` (opcional, um quadro por quarto de ciclo) alterna os quadros `boss_ogre_walk_1..4` (AG08; mesma âncora do `boss_ogre`). `walk_full = true` liga a pose completa; com `false` (inimigos comuns) só o balanço. **Inimigos comuns: desligado** (`walk_bob = 0`): medido com 150 inimigos andando, só o balanço de 3 px custa +0,7 ms/quadro de física no PC (0,6 → 1,3 ms; a pose completa, +1,6 ms) |
| Partículas | 50 ao morrer; vitória imediata |

- **Modos:** `ADVANCE → ATTACK (espera → wind-up → golpe) → LAUNCHED → STUNNED → ADVANCE`. Durante `LAUNCHED`/`STUNNED`, `Enemy.state = ATTACK` (parado para a mira e o meteoro).

### Defesa do chefe (arquivada)

Código e testes mantidos e funcionais (`Boss.has_defense()`), desligados no `boss_warden` (decisão 42). **Como ligar** em outro chefe: `defense_max > 0` no `.tres`. Com ela:
- **Escudo:** todo dano tira primeiro da defesa e, enquanto ela é > 0, a vida não muda (o excedente do golpe que zera a defesa não passa para a vida). Ao zerar, o chefe é lançado; ao acordar, a defesa volta cheia.
- **Meteoro com defesa > 0:** zera a defesa e lança na hora, sem dano na vida.
- **Barra:** `HealthBar` aço `#7F93AD`, 96 px, sobre o chefe; o sinal `boss_defense_changed` só existe nesse caso.
- Testes: `test_archived_*` em `tests/unit/match/test_boss.gd` e `test_boss_telegraph_defense_and_launch` (cópia do `boss_warden` com `defense_max = 500`).


## Ondas

Arquivo de dados: `data/waves/stage_01.tres` (`StageData`), com uma lista de `WaveData`.

```
StageData: id, waves: Array[WaveData], wave_break (s), boss_id
WaveData:  id, entries: Array[WaveEntry]
WaveEntry: enemy (EnemyData), count, interval (s), spawn_edge, start_delay (s)
```

- `spawn_edge`: `TOP | BOTTOM | LEFT | RIGHT | RANDOM` (enum `WaveEntry.SpawnEdge`).
- `WaveEntry.enemy` aponta direto para o `.tres` do inimigo (sem tabela de `enemy_id`).
- O i-ésimo inimigo de um grupo nasce em `start_delay + i × interval`.
- A fase vem de `data/waves/<config.stage_id>.tres`.
- Uma onda termina quando todos os inimigos dela nasceram **e** morreram. Depois vem o respiro `wave_break` (3 s).
- **Chefe na onda 10, sozinho** (T-150; antes vinha com 4 corredores + 1 atirador): o "Onda 10/10" bate com o fim da fase. Uma onda só fecha num passo sem spawn (correção da T-150: antes, a onda com só o chefe terminava no passo em que ele nascia). `StageData.boss_id = boss_warden` (informativo).
- **Vitória ao derrotar o chefe** (`Arena._on_enemy_died`). Derrota: HP do Núcleo = 0.

**Curva da fase 1 (`stage_01`, T-116).** Balanceada para **1 skill (slot 1, hoje `skill_meteor`; antes `skill_pulse`) + upgrades da partida**, independente do tipo da skill de área (T-139). Um arquétipo novo a cada 2–3 ondas. Partículas pela média do enxame (5–8 por grupo, média 6,5); "tempo" = último spawn + tempo de limpeza estimado (sem simulação de combate).

| Onda | Composição | Inimigos | Partículas | Acumulado | Tempo est. |
|---|---|---|---|---|---|
| 1 | 5 corredores | 5 | 5 | 5 | ~15 s |
| 2 | 10 corredores (cima e baixo) | 10 | 10 | 15 | ~17 s |
| 3 | 9 corredores + 1 enxame (**novo**) | ~15,5 | ~15,5 | ~30 | ~16 s |
| 4 | 10 corredores + 2 enxames | ~23 | ~23 | ~53 | ~18 s |
| 5 | 10 corredores + 2 enxames + 1 tanque (**novo**) | ~24 | ~27 | ~80 | ~21 s |
| 6 | 10 corredores + 2 enxames + 2 tanques | ~25 | ~31 | ~111 | ~20 s |
| 7 | 10 corredores + 2 enxames + 2 tanques + 2 atiradores (**novo**) | ~27 | ~35 | ~146 | ~22 s |
| 8 | 14 corredores + 3 enxames + 2 tanques + 2 atiradores | ~37,5 | ~45,5 | ~191,5 | ~26 s |
| 9 | 14 corredores + 3 enxames + 3 tanques + 3 atiradores | ~39,5 | ~51,5 | **~243** | ~27 s |
| 10 | **chefe ogro sozinho** | 1 | 50 do chefe | — | ~50 s |

- **Partículas antes do chefe:** ~243 depois do BRF-051 (antes ~255; faixa ~222–264 conforme o tamanho dos enxames), alinhado aos ~250 de `docs/meta.md`. Nenhum `particle_drop` mudou.
- **Duração estimada (antes do BRF-051):** ~235 s de ondas + 27 s de respiros ≈ **4,5 min** jogando bem (alvo ~5 min; limite 3–10 min). Sem skill nem upgrades, a simulação do teste de integração perde na onda 4–5 (~80 s), como esperado.
- Teste: `tests/unit/match/test_stage_01_curve.gd` percorre as ondas pelos dados (chefe só na última, Partículas ~250 ± 15 %, ondas crescentes, todos os spawns emitidos).

### Balanceamento da fase 1 (BRF-051) e simulação

O dono achou a fase 1 difícil demais no iPhone. Mudanças **só em dados** (antes → depois):

| Dado | Antes | Depois |
|---|---|---|
| HP do Núcleo (`anima_default`) | 100 | **160** |
| Dano do tiro do atirador (`projectile_enemy_bolt`) / cadência do atirador | 6 / 0,667 tiro/s | **3 / 0,5 tiro/s** |
| Tanque: HP / contato | 120 / 20 | **90 / 15** |
| Contato: corredor / enxame | 5 / 2 | **4 / 1** |
| Corredores nas ondas 5–7 | 12 | **10** |
| Atiradores nas ondas 7 / 8 / 9 | 3 / 3 / 4 | **2 / 2 / 3** |
| Respiro entre ondas (`wave_break`) | 3 s | **5 s** |
| Custo dos upgrades (`docs/meta.md`) | 5, 7, 10 … 104 | **4, 6, 8 … 83** |
| Chefe (substituído pelo ogro na T-150, ver abaixo) | 1200 / tiro 6 | 2500 / tiro próprio 14 |

Meteoro e Partículas por inimigo não mudaram (o custo menor já faz os upgrades chegarem cedo: o 1º sai na onda 1).

**Bot de simulação** (`tests/tools/sim_bot.gd` + `tests/tools/run_sim.gd`, ferramenta manual, fora do GUT): sem mira nem posicionamento (o jogo é automático); usa o meteoro sempre que pronto; compra upgrades em **round-robin** dano → cadência → vida → defesa → cooldown, esperando ter Partículas para o próximo da fila (pula o que está no máximo). A seed vai em `Arena.set_seed()` (T-123: mesma seed = mesmos spawns e sorteios do chefe).

```bash
godot --headless --path . --fixed-fps 60 -s tests/tools/run_sim.gd -- --seeds=20 --start=1
```

`--fixed-fps 60` faz cada quadro valer 1/60 s sem esperar o relógio (~1–2 s reais por partida). Teste rápido no GUT: `tests/unit/match/test_sim_seed.gd` (seed + 10 s do bot).

| Bot médio | Chega ao chefe | Vence | HP do Núcleo ao chegar ao chefe | Chefe entra | Partida | Partículas |
|---|---|---|---|---|---|---|
| Antes (40 seeds) | **0 %** (cai nas ondas 7–8) | 0 % | — | — | ~2,4 min | ~135 |
| Depois (seeds 1–40) | **100 %** | **58 %** | 53 % | ~214 s | ~4,6 min | ~275 |
| Depois (seeds 1001–1100) | **100 %** | **62 %** | 55 % | ~214 s | ~4,6 min | ~279 |

**T-150 (chefe ogro), seeds 1–100 e 1001–1100:** chega ao chefe **100%**, vence **63% / 56%**, HP do Núcleo ao chegar **56% / 55%**, chefe entra aos ~204 s, partida ~4,2 min (luta ~50 s). Calibrado só nos dados do chefe: HP 600, defesa 500, 110 px/s, golpe 21 a cada 1,5 s. O meteoro (cooldown ~8–10 s) lança o chefe quase a cada uso; a velocidade decide se ele volta a tempo de bater (70–80 px/s: nunca bate; 130: o bot perde sempre), por isso o ajuste fino é no dano do golpe. O `run_sim.gd` agora fixa a janela em retrato (405×720 → base 720×1280); antes a janela headless saía quadrada e a arena tinha 1280 px de largura (os números do BRF-051 acima foram medidos assim; refeitos em retrato, a chegada ao chefe e o HP continuam iguais).

**T-166 (chefe sem defesa; meteoro sempre lança), seeds 1–100** (`run_sim.gd` agora imprime a luta e a Energia restante de quem vence; `--boss-hp/--boss-dmg/--boss-interval/--boss-speed` sobrescrevem o chefe só na execução):

| Chefe | Chega | Vence | Luta (vitórias) | Energia restante de quem vence | Energia ao chegar |
|---|---|---|---|---|---|
| Antes: HP 600 + defesa 500, 110 px/s, golpe 21 / 1,5 s | 100% | 63% | 49 s (53 s) | 13% | 56% |
| Sem defesa, HP 1000, resto igual | 100% | 100% | 25 s | 48% | 58% |
| HP 1200, 150 px/s, golpe 28 | 100% | 94% | 28 s | 27% | 58% |
| HP 1200, 165 px/s, golpe 28 | 100% | 70% | 27 s (28 s) | 21% | — |
| HP 1200, 180 px/s, golpe 30 | 100% | 54% | 26 s (28 s) | 19% | — |
| **Escolhido: HP 1200, 160 px/s, golpe 30 / 1,5 s** | **100%** | **73%** | **27 s (28 s)** | **22%** | 57% |

As linhas intermediárias usaram 50 seeds. Sem a defesa, o meteoro (cooldown 8–10 s) lança o chefe a cada uso e ele passa ~7 s fora (voo, 2 s atordoado e a volta), por isso a **velocidade** decide quanto ele bate. As metas "vitória ~60%" e "Energia de quem vence ≥ 25%" puxam em sentidos opostos (o dano do chefe é quase o mesmo em toda seed; quem vence é quem chega com mais Energia): 94% de vitória dá 27% de Energia, 54% dá 19%. Ficou no meio (73% / 22%), com a luta no limite de baixo da faixa de 25–45 s. Referência do log real no iPhone: o jogador tinha ~38 de DPS no chefe; com 1200 de vida, ~32 s de luta.

**T-173 (chefe mais fácil; meteoro reavalia o alvo), seeds 1–100** (meta: vitória ≥ 85%, Energia de quem vence ≥ 35%, luta 25–45 s; log real no iPhone: o jogador terminou com 2% onde o bot dava 22%, por isso a mira ficou acima da meta). Defesa continua arquivada. `run_sim.gd` agora imprime os meteoros contra a horda (lançados, com 0 acertos e anulados).

| Chefe | Chega | Vence | Luta (vitórias) | Energia restante de quem vence |
|---|---|---|---|---|
| Antes (T-166): HP 1200, 160 px/s, golpe 30 / 1,5 s | 100% | 73% | 27 s (28 s) | 22% |
| Só o meteoro novo, chefe igual | 100% | 76% | 27 s (28 s) | 25% |
| HP 1200, 140 px/s, golpe 22 / 1,8 s | 100% | 100% | 29 s | 35% |
| HP 1000, 140 px/s, golpe 22 / 1,8 s | 100% | 100% | 24 s | 43% |
| HP 1100, 140 px/s, golpe 22 / 1,8 s | 100% | 100% | 27 s | 38% |
| HP 1200, 140 px/s, golpe 20 / 1,8 s | 100% | 100% | 29 s | 38% |
| **Escolhido: HP 1100, 140 px/s, golpe 20 / 1,8 s** | **100%** | **100%** | **27 s** | **40%** (seeds 1001–1100: 100% / 27 s / 41%) |

Meteoros contra a horda com **0 acertos** (bot, seeds 1–100): **13,6% → 7,9%** (267 → 154 de ~1950), e 25 anulados (1,3%) com o cooldown devolvido. Os 0 acertos que sobram são inimigos sozinhos (corredor/enxame com 5–8 de vida) que o ataque automático mata durante a queda (0,35 s); a reavaliação não prevê isso.

Limite: o bot reage na hora (compra e usa a skill no mesmo quadro); um jogador real tende a ser um pouco pior. Confirmar no playtest no iPhone.

## Contrato de partida

- **Raiz:** `Arena` (`src/match/arena/arena.tscn`). `setup(config)` antes de entrar na árvore; sem config, usa `MatchConfig.new()`.
- **Entrada:** `MatchConfig` (`src/core/`, do AG07). Hoje só `stage_id` é lido; `anima_data` e `skills` entram depois (AG04).
- **Saída:** `MatchResult` (`src/core/`; `outcome: VICTORY|DEFEAT`, `wave_reached`, `waves_total`, `coins` (= Partículas; nome mantido em `src/core/` até decisão do AG00), `enemies_killed`, `duration_s`).
- `src/match/` não conhece `meta/`, `backend/` nem nós de UI.
- **Pausa:** a UI pausa via `get_tree().paused`; a partida respeita o process mode e não decide a pausa.

## Sinais expostos à UI

Emitidos pelo nó raiz da partida (`Arena`). Na T-105 já existem `core_hp_changed`, `wave_changed`, `particles_changed` e `match_ended`. Base: AG01 §9.

| Sinal | Quando |
|---|---|
| `core_hp_changed(current: int, max: int)` | início da partida e a cada dano ou cura no Núcleo |
| `wave_changed(current: int, total: int)` | início de cada onda (a onda do chefe conta no `total`) |
| `cooldown_changed(slot: int, remaining: float, total: float)` | ao usar a skill e durante o cooldown, no máximo ~10×/s |
| `skill_ready(slot: int)` | quando o cooldown chega a 0 |
| `particles_changed(total: int)` | `total` = **total** de Partículas na partida (não o incremento). Partículas começam em 0 e zeram a cada partida (decisão 29). `coins_changed(amount)` é um alias temporário, emitido junto, até a T-141 migrar o HUD |
| `boss_spawned(id: StringName)` | entrada do chefe (logo depois vem `boss_hp_changed` com a vida cheia) |
| `boss_hp_changed(current: int, max: int)` | entrada e a cada dano **na vida** do chefe (com a defesa arquivada ligada, ela absorve antes; `current` nunca negativo; 0 na morte, antes de `match_ended`) |
| `boss_defense_changed(current: int, max: int)` | **arquivado:** só para chefes com `defense_max > 0` (o `boss_warden` não emite). Entrada (cheia) e a cada mudança da defesa |
| `boss_defeated` | chefe abatido (antes do `match_ended` de vitória) |
| `upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int)` | ver "Upgrades da partida (T-134)" abaixo |
| `match_ended(result: MatchResult)` | vitória ou derrota (uma vez) |

### Sinais para VFX (T-148)

Também na `Arena`, só em eventos (nenhum por quadro; as ligações são feitas uma vez no `_ready`/spawn). **Posições** = âncora no chão em coordenadas de tela da Arena (regra do `GroundPlane`); **raios** em px no chão. Consumidos pelo `FxDirector` (AG09, `docs/vfx.md`).

| Sinal | Quando |
|---|---|
| `projectile_fired(from: Vector2, dir: Vector2)` | tiro do Anima (`dir` em tela, normalizada). Tiros inimigos não emitem |
| `projectile_hit(at: Vector2, target_kind: StringName)` | acerto de projétil: `&"enemy"`, `&"boss"` (tiro do Anima) ou `&"core"` (tiro inimigo no Núcleo) |
| `enemy_died(at: Vector2, archetype_id: StringName, cause: int)` | toda morte; `cause` = `Enemy.DeathCause` (KILLED 0, CONTACT 1) |
| `particles_gained(at: Vector2, amount: int)` | abate com `particle_drop > 0` (depois de `particles_changed`) |
| `skill_cast(slot: int, at: Vector2, radius: float)` | impacto da skill de área (meteoro), não no acionamento |
| `skill_fizzled(slot: int, at: Vector2)` | T-173: meteoro anulado no início da queda (nenhum inimigo no raio, sem chefe vivo); sem `skill_cast` nem cratera; `at` = ponto onde cairia; o cooldown já veio reduzido em `cooldown_changed`. Para um aviso discreto na UI (AG02) |
| `boss_telegraph_started(pattern_id: StringName, duration: float, at: Vector2, radius: float)` | início do wind-up do golpe: `pattern_id` = `attack_id` (`&"boss_slam"`), `duration` = `attack_windup`, `at` = posição do chefe, `radius` = `telegraph_radius` |
| `boss_launched(from: Vector2, to: Vector2)` | chefe lançado (meteoro; ou defesa arquivada esgotada); `to` = fim do voo |
| `enemy_damaged(at: Vector2, amount: int, by_skill: bool)` | T-117: cada dano na vida de inimigo/chefe (antes de `enemy_died`); `by_skill` = meteoro. Dano na defesa arquivada não emite |
| `skill_fall_started(slot: int, at: Vector2, fall_time: float)` | meteoro começa a cair (uma vez por uso, só se não foi anulado): `at` = ponto de impacto, `fall_time` = s até o impacto (≈ `fall_time` dos dados) |
| `boss_attack_landed(at: Vector2)` | golpe do ogro acerta o Núcleo (antes do dano); `at` = âncora do Núcleo |

`skill_used(slot)` e `skill_ready(slot)` já são repassados pela `Arena` (seção acima).

### Game feel (T-117, BRF-079)

Valores em `data/feel/game_feel.tres` (`GameFeelData`); `Arena.feel` nulo = esse arquivo.
- **Tremor** (`ScreenShake`): deslocamento do nó raiz da `Arena` (o HUD é um `CanvasLayer` à parte, não treme). Um por vez; o novo só vale se for mais forte que o que resta; decai em k². Meteoro no impacto 14 px/0,25 s, golpe do ogro 9/0,2, morte do chefe 16/0,4, dano no Núcleo ≥ 10% do máximo 5/0,15. RNG próprio (não muda a seed dos spawns).
- **Hit-stop** (`HitStop`): `Engine.time_scale` = 0 por 60 ms (meteoro), 50 ms (chefe lançado), 80 ms (morte do chefe), em tempo real; nunca empilha (1 ativo, os outros pedidos são ignorados); restaura o `time_scale` anterior, também ao sair da árvore. Efeitos de `_process` do HUD também param nesses ms (aceito: são 30–80 ms; tweens do HUD podem usar `ignore_time_scale`). `Arena.hit_stop_enabled` é falso no headless (testes, bot).
- **Números de dano** (`DamageNumbers`): um nó, pool fixo de 48, desenhado com `draw_string` (Outfit peso 800). Branco 26 px no tiro, laranja 40 px no meteoro; sobem 56 px e somem em 0,6 s. Mesmo alvo no mesmo quadro de física = um número somado; até 12 números novos por quadro; pool cheio reusa o mais velho.
- **Flash de acerto**: todo dano na vida de inimigo/chefe deixa o corpo em `self_modulate` = `hit_flash_color` (3,3,3: estoura para branco) por 70 ms (`hit_flash_time`; 0 = desligado). Não conflita com o tom do wind-up do chefe (`modulate`). Igual no modo reduzido.
- **`Arena.reduced_effects`** (o `SceneFlow` define; pode mudar no meio da partida): tremor a 30%, sem hit-stop (encerra um ativo), números só do meteoro e do chefe.

`boss_phase_changed` **deixou de existir** (uma fase; T-150).

### Foco manual e mira dos Módulos (BRF-076; decisões 45 e 46)

API da `Arena` para a UI (AG02, T-178). `at` em coordenadas da Arena = as do viewport que o HUD usa (âncora no chão).

| Membro | Contrato |
|---|---|
| `use_skill(slot: int, at: Vector2 = Vector2.INF) -> bool` | `Vector2.INF` = alvo automático (como antes). `at` finito = mira manual: só para Módulos de área; exige `can_aim_at(at)` (senão devolve `false` e não gasta o cooldown); **não** exige inimigo ao alcance. Módulo sem mira (não área) ignora `at` |
| `show_skill_aim(slot: int, at: Vector2) -> void` | prévia **no chão** do raio do Módulo do slot (elipse 0,75, contorno claro + preenchimento translúcido, `accent` ciano do jogador), centro preso à área de mira; um nó criado no `_ready`, só move e redesenha. Slot sem Módulo de área = esconde |
| `hide_skill_aim() -> void` | esconde a prévia |
| `can_aim_at(at: Vector2) -> bool` | `at` dentro de `free_rect()` (entre o HUD de cima e a bandeja) |
| `aim_rect() -> Rect2` | a área de mira (= `free_rect()`) |
| sinal `focus_changed(enemy: Node)` | foco manual definido (o inimigo) ou desfeito (`null`: morte, toque no chão vazio ou no mesmo inimigo) |
| `focused_enemy() -> Enemy` / `set_focus(enemy)` | foco atual (ou `null`) / define por código (testes, bot) |

**Foco manual (T-176):** `Arena._unhandled_input` (toque `InputEventScreenTouch` ou clique esquerdo `InputEventMouseButton`, só eventos não consumidos pelo HUD; sem teclas) escolhe o inimigo vivo mais próximo do ponto num raio de `focus_pick_radius` (padrão 44 px) além do raio do inimigo e da altura do sprite (o toque vale do pé ao topo do desenho). Toque no mesmo inimigo ou no chão vazio (dentro da área de mira) desfaz. No navegador o toque também chega como clique emulado (`InputEventMouseButton` com `device == InputEvent.DEVICE_ID_EMULATION`); a Arena **ignora o emulado**, senão o par toque + clique no mesmo inimigo focava e desfazia (bug do iPhone). Mouse real (PC) segue valendo. O Anima mira no focado enquanto ele está no alcance; fora dele, usa a regra automática e volta ao focado quando ele entra. Marcador: anel pulsante ciano no chão sob o focado (`FocusMarker`, desenhado por código, sem alocar). Vale para o chefe.

**Mira do meteoro (T-177):** com `at` manual, o meteoro cai **exatamente** em `at` (sem previsão, sem a reavaliação da T-173 e **sem anular**, mesmo sem inimigo); aviso, queda, dano, cratera e lançamento do chefe iguais. Automático = igual a antes.

**Bot (100 seeds) antes → depois do chefe dentro do alcance:** vitória 100% → 100%; Energia de quem vence 40% → 40%; luta 27 s → 26 s. O lançamento de 600 px já era cortado pela borda visível na maioria dos casos; vida e dano do chefe mantidos. O bot não usa foco nem mira manual.
Testes: `tests/unit/match/test_focus_and_aim.gd`.

### Upgrades da partida (T-134)

Valores e curva de custo em [meta.md](meta.md). Lógica em `src/match/upgrades/`, dados em `data/upgrades/<id>.tres` (`UpgradeData`).

- **IDs, nesta ordem** (`Arena.UPGRADE_IDS`): `upgrade_atk_power`, `upgrade_atk_spd`, `upgrade_defense`, `upgrade_max_hp`, `upgrade_cooldown`.
- **`Arena.buy_upgrade(id: StringName) -> bool`**: compra 1 nível se `particles ≥ custo` e `nível < max_level`; desconta as Partículas (emite `particles_changed`) e aplica o efeito. Não pausa a partida. Devolve `false` sem efeito se não puder comprar, se o id for desconhecido ou se a partida acabou.
- **Sinal `upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int)`**: emitido para os 5 upgrades no início da partida (no `_ready` da Arena, em `UPGRADE_IDS`) e para o upgrade comprado após cada compra. `next_cost = -1` quando o nível está no máximo.
- Consulta síncrona (opcional): `Arena.upgrades.level(id)`, `.next_cost(id)`, `.max_level(id)`.
- A UI decide "indisponível" comparando `next_cost` com o total do último `particles_changed`.
- Reset: os níveis vivem na `Arena`; cada partida nova começa com todos no nível 0.

**Mudanças em relação ao §9 do AG01 (precisam de aprovação):**
1. **Novo:** `skill_used(slot: int)`, já citado no §7 do AG01 mas ausente do §9. Serve ao feedback de acionamento no HUD.
2. **Esclarecido:** `particles_changed` (antigo `coins_changed`) envia o total, não o delta.
3. **Esclarecido:** `cooldown_changed` usa 3 argumentos (o §7 do AG01 cita só 2).

## Camadas de colisão [Proposta → AG07]

O `project.godot` é do AG07. Layers sugeridas:

| Layer | Nome | Colide com (mask) |
|---|---|---|
| 1 | `anima` | `enemies`, `enemy_projectiles` |
| 2 | `enemies` | `anima`, `player_projectiles`, `skill_areas` |
| 3 | `player_projectiles` | `enemies` |
| 4 | `enemy_projectiles` | `anima`, `shield` |
| 5 | `skill_areas` | `enemies` |
| 6 | `shield` | `enemy_projectiles`, `enemies` |

## Debug

`debug_toggle` (`F3`): FPS, contagem de inimigos e projéteis, alvo atual, áreas das skills e câmera lenta (0,25×).

## Limites de desempenho

- Metas: 60 fps no PC; ≥ 50 fps no iPhone com ~150 inimigos e ~300 projéteis (a confirmar no M0).
- Pools para projéteis (feito) e inimigos (T-118, depois dos arquétipos da T-111 e de medir); nada de alocação por frame.
- Busca de alvo e de densidade por intervalo (0,1 s), não por frame.
- `CPUParticles2D` curtas; nada de partículas por projétil.

## Status dos sistemas

| Sistema | Status | Task |
|---|---|---|
| Arena, Anima, 1 inimigo | protótipo | T-103 |
| Ataque automático com pool | protótipo | T-104 |
| Ondas, HP do Núcleo, Partículas, vitória/derrota | protótipo | T-105 |
| Skill de área (meteoro) | protótipo | T-108, T-139 |
| Sinais para VFX | protótipo | T-148 |
| Skill de controle | pendente | T-109 |
| Skill de defesa | pendente | T-110 |
| Arquétipos (tanque, atirador, enxame) | protótipo | T-111 |
| Chefe (ogro) | protótipo | T-115, T-150, T-166, T-167, BRF-076 (lançamento no alcance) |
| Barra de vida dos inimigos | protótipo | T-149 |
| Upgrades da partida | protótipo | T-134 |
| Foco manual do ataque, mira manual do meteoro (API) | protótipo | T-176, T-177 |
| Game feel: tremor, hit-stop, números de dano, efeitos reduzidos | protótipo | T-117 |
