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
- Chefe: `EnemyData.ring_sprite/ring_anchor/ring_height/ring_spin_speed` já desenham o anel atrás do corpo; a T-115 só preenche os dados (`boss_warden.png`, âncora (256, 472); anel (256, 128) a 70 px).
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
| Corredor | `enemy_runner` | 20 | 140 px/s | contato, 5 de dano | 1 |
| Tanque | `enemy_tank` | 120 | 50 px/s | contato, 20 de dano | 4 |
| Atirador | `enemy_shooter` | 35 | 80 px/s | para a 380 px do centro; 1 tiro a cada 1,5 s (`projectile_enemy_bolt`: 6 de dano, 300 px/s, losango magenta) | 2 |
| Enxame | `enemy_swarm` | 8 | 120 px/s | contato, 2 de dano; nasce em grupos de 5–8, espalhados em 48 px | 1 cada |

- **Estados:** `SPAWN → AVANÇA → ATACA → MORRE`, mais `CONGELADO` e `LENTO` (das skills de controle).
- **Contato:** ao tocar a hurtbox do Anima, o inimigo causa `contact_damage` e morre (sem Partículas).
- **Justiça:** projéteis inimigos com cor e forma distintas das do jogador (ex.: losango quente × círculo frio) e mais lentos que os do jogador.
- **Atirador:** um só script (`Enemy`); com `attack_range > 0` ele para no alcance (estado `ATTACK`) e atira com o pool `EnemyProjectiles` da arena (128, layer `enemy_projectiles`). Quem reage ao acerto é o Anima (mask), que consome o projétil.
- **Grupo:** cada spawn de onda cria `group_min..group_max` inimigos (`Arena.spawn_group`). Só o enxame usa grupo > 1.
- Inimigos em pool por arquétipo (T-118); fora da tela não fazem cálculos caros.
- **Balanceamento:** só com o ataque automático, 2 tanques + 2 atiradores juntos já derrotam o Núcleo. A curva da T-116 deve contar com as skills.

## Chefe

Arquivo de dados: `data/enemies/boss_<id>.tres` (`BossData`, herda `EnemyData`; padrões como `BossPattern` embutidos). Código em `src/match/enemies/boss/` (`Boss` herda `Enemy`; cena `boss.tscn`). Um chefe no M1: `boss_warden` (nome provisório). Entra numa onda como qualquer inimigo (`WaveEntry.enemy = boss_warden.tres`, `count` 1): a `Arena.spawn` usa a cena do chefe quando os dados são `BossData`.

| Parâmetro | Valor |
|---|---|
| HP | 1200 |
| Posição | entra pela borda, a 60 px/s, e para a 420 px do centro (`attack_range`) |
| Fases | `phase_thresholds` [0,6, 0,3]: 100–60%, 60–30%, abaixo de 30% |
| Espera entre padrões | `pattern_interval` 3,0 / 2,4 / 1,8 s por fase |
| Padrões (peso por fase) | `pattern_fan` leque de 5 `projectile_enemy_bolt` em 40°, mirado no Núcleo (3/2/2); `pattern_ring` anel de 12 com ângulo inicial aleatório (0/2/3); `pattern_summon` 4 `enemy_swarm` a 70 px do chefe (1/1/2) |
| Aviso | antes de cada padrão, 1,0–1,2 s (≥ 0,8 s). `BossTelegraph` desenhado por código: cone (leque) ou círculo (anel, invocação) que se preenche até o efeito. VFX final: AG09 |
| Projéteis | pool inimigo da arena (128), alcance `projectile_range` 700 px |
| Partículas | 50 ao morrer |

- Ciclo: `ADVANCE` → `ATTACK` (espera → aviso → efeito → espera…). Sorteio por peso da fase com `Boss.rng` (semente vinda da arena).
- Ao derrotá-lo: Partículas, `boss_defeated` e **vitória imediata** (mesmo com invocados vivos).
- **Balanceamento (estimativa, calibrar na T-116):** com DPS base 20, ~60 s; com ~250 Partículas distribuídas (DPS ~37) + `skill_pulse`, ~30 s. Só o projétil central do leque acerta o Núcleo (6 de dano); o anel acerta no máximo 1; o enxame invocado, 2 por contato.

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
- **Chefe na onda 10, com acompanhantes** (T-116), e não numa onda 11 só dele: o "Onda 10/10" bate com o fim da fase e os acompanhantes mantêm pressão enquanto o jogador foca o chefe. `StageData.boss_id = boss_warden` (informativo).
- **Vitória ao derrotar o chefe** (`Arena._on_enemy_died`), mesmo com acompanhantes vivos. Derrota: HP do Núcleo = 0.

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
| 10 | **chefe** + 4 corredores + 1 atirador (+ enxames invocados) | 6+ | 6 + 50 do chefe | — | ~48 s |

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
| Chefe: HP / tiro (novo `projectile_boss_bolt`) | 1200 / 6 (tiro comum) | **2500 / 14** (tiro próprio, para o chefe seguir perigoso) |

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
| `boss_hp_changed(current: int, max: int)` | entrada e a cada dano no chefe (`current` nunca negativo; 0 na morte, antes de `match_ended`) |
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
| `boss_telegraph_started(pattern_id: StringName, duration: float, at: Vector2, radius: float)` | início do aviso de um padrão; `at` = posição do chefe, `radius` = `telegraph_radius` |
| `boss_phase_changed(phase: int)` | troca de fase do chefe (0-based) |

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
| Chefe | protótipo | T-115 |
| Upgrades da partida | protótipo | T-134 |
