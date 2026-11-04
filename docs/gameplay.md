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
| Anima | centro da **arena** (não da tela), câmera fixa |
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
- Fundo (BRF-041): nó `Floor` (`ArenaFloor`, `src/match/arena/arena_floor.gd`) com as peças de `assets/backgrounds/`: `floor_tile` repetido (Sprite2D com `region` + repeat) cobrindo a tela inteira, `floor_top_shade` no topo e `floor_ring` no Anima (todos `z_index = -10`); 4 `floor_pillar` nos cantos da `arena_rect` (insets `pillar_inset_*`), com `GroundShadow` e Y-sort junto das entidades. Sem moldura. `ArenaFloor.layout()` só reposiciona (sem alocar por frame).
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
`id, type (AREA|CONTROL|DEFENSE), delivery (INSTANT|METEOR), cooldown, radius, damage, duration, windup, target_range, effect_params, fx_id, sfx_id, icon` + grupo Meteoro (`telegraph_time, fall_time, fall_height, crater_time, meteor_texture/anchor, crater_texture/anchor`).
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
- **Área:** dano por distância (raio da skill + raio do inimigo), sem usar a layer `skill_areas`. **[A definir]**: mira manual por toque/clique como alternativa, a testar no playtest.
- **Feedback:** antecipação curta (~0,1 s) + impacto forte; tremor leve **desligável**.

### Meteoro de fogo (T-139, decisão 37)

- `MeteorSkill` (estende `AreaSkill`), escolhido por `delivery = METEOR`. A `skill_pulse` saiu da partida; o `.tres` fica só para os testes do `AreaSkill` instantâneo.
- **Alvo:** o inimigo ao alcance (`target_range`) com mais vizinhos no `radius` (no chão); empate, inclusive todos sozinhos, = o mais próximo do Anima. O ponto é **adiantado**: posição prevista desse inimigo após `telegraph_time` (só se ele está avançando; atirador parado = posição atual). O ponto fica fixo depois do acionamento.
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

**Ogro (T-150, decisão 39).** Dados em `data/enemies/boss_warden.tres` (`BossData`; o id `boss_warden` foi mantido para não quebrar HUD/FX/fase; a arte é do ogro). Código em `src/match/enemies/boss/` (`Boss` herda `Enemy`). Entra sozinho na onda 10. **Uma fase**, **um golpe corpo a corpo**, **sem minions nem tiros** (os padrões leque/anel/invocação, as fases por vida, `BossPattern` e `BossTelegraph` foram removidos).

| Parâmetro | Valor |
|---|---|
| HP / defesa | 600 / 500 (`hp`, `defense_max`) |
| Movimento | 110 px/s até `attack_range` 100 px (no chão) do centro do Núcleo: encosta sem tocar a hurtbox (40 + raio 48) |
| Golpe | a cada `attack_interval` 1,5 s; `attack_windup` 0,5 s de aviso (sprite `boss_ogre_attack.png`, cresce até +12% e puxa para vermelho) e `attack_damage` 21 no Núcleo (passa pela defesa do upgrade) |
| Lançamento | `launch_distance` 600 px no chão para longe do Núcleo, preso na área visível acima da bandeja (`Arena.boss_launch_bounds`: arena menos o raio nas laterais e na base e a altura do sprite no topo); voo `launch_time` 0,6 s (tween de física, ease-out) |
| Atordoado | `stun_time` 2 s (sprite `boss_ogre_stunned.png`), não bate; no fim a defesa volta cheia e ele anda de volta |
| Partículas | 50 ao morrer; vitória imediata |

- **Defesa = escudo:** todo dano tira primeiro da defesa e, enquanto ela é > 0, a vida não muda (o excedente do golpe que zera a defesa não passa para a vida). Ao zerar, o chefe é lançado. Durante o voo e o atordoamento (defesa 0), o dano vai para a vida.
- **Meteoro:** com defesa > 0, zera a defesa e lança na hora, sem dano na vida (vale qualquer meteoro cujo raio toque o chefe). Com defesa 0, causa o dano normal (40) na vida. Vem de `Enemy.take_skill_damage` (o `AreaSkill` chama esse método).
- **Barra de defesa:** `HealthBar` com cor fixa aço `#7F93AD`, 96 px, sobre o chefe. A barra grande "Boss" (vida) é do HUD (AG02, T-152).
- **Modos:** `ADVANCE → ATTACK (espera → wind-up → golpe) → LAUNCHED → STUNNED → ADVANCE`. Durante `LAUNCHED`/`STUNNED`, `Enemy.state = ATTACK` (parado para a mira e o meteoro).

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
| `boss_hp_changed(current: int, max: int)` | entrada e a cada dano **na vida** do chefe (a defesa absorve antes; `current` nunca negativo; 0 na morte, antes de `match_ended`) |
| `boss_defense_changed(current: int, max: int)` | entrada (cheia) e a cada mudança da defesa (dano, meteoro, volta cheia no fim do atordoamento) |
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
| `boss_telegraph_started(pattern_id: StringName, duration: float, at: Vector2, radius: float)` | início do wind-up do golpe: `pattern_id` = `attack_id` (`&"boss_slam"`), `duration` = `attack_windup`, `at` = posição do chefe, `radius` = `telegraph_radius` |
| `boss_launched(from: Vector2, to: Vector2)` | chefe lançado (defesa esgotada ou meteoro); `to` = fim do voo |

`boss_phase_changed` **deixou de existir** (uma fase; T-150).

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
| Chefe (ogro) | protótipo | T-115, T-150 |
| Barra de vida dos inimigos | protótipo | T-149 |
| Upgrades da partida | protótipo | T-134 |
