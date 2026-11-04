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
| Arena | faixa da tela de y = 164 a 987 (base 720×1280, mockup A); o resto é HUD. Insets `arena_top_inset` / `arena_bottom_inset` na cena; com `expand` a arena cresce junto |
| Anima | centro da **arena** (não da tela), câmera fixa |
| Bordas de spawn | `top`, `bottom`, `left`, `right` (fora da arena, 32 px além da borda) |
| Lógica | `_physics_process` a 60 Hz; o visual nunca decide a regra |

### Perspectiva 3/4 (T-144)

- **`position` = âncora = ponto de contato com o chão**, em coordenadas de tela. O corpo é desenhado acima dela.
- **Regra no plano do chão:** o Y da tela é o Y do chão encolhido por **0,75** (`GroundPlane.Y_SCALE`). Alcance, raios, distâncias e velocidades (px e px/s) valem **no chão**: 100 px no chão = 100 px na horizontal ou 75 px na vertical da tela. Use sempre `GroundPlane` (`distance`, `move_toward`, `to_ground`, `to_screen`), nunca `distance_to` direto.
- **Colisão:** `CircleShape2D` com o `CollisionShape2D` em escala `(1, 0,75)`, ou seja, círculo no chão = elipse na tela (testado no Godot 4.7.2, inclusive elipse × elipse).
- **Desenho:** decalques no chão (sombra, anel de skill, telegraph) são elipses 0,75 com `z_index = -1`, abaixo de todos os corpos. Cada entidade tem uma `GroundShadow` (115% do raio de colisão).
- **Y-sort:** `Arena`, `Enemies`, `Projectiles` e `EnemyProjectiles` com `y_sort_enabled`; Anima, inimigos e projéteis são ordenados juntos pela âncora. Projéteis voam `ProjectileData.height` px acima da sombra (só desenho).

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
`id, type (AREA|CONTROL|DEFENSE), cooldown, radius, damage, duration, windup, target_range, effect_params, fx_id, sfx_id`.
O comportamento fica em um script por `type` (`SkillBehavior` → `AreaSkill`, ...), que só lê o Resource. Skill nova = dados novos; tipo novo = script novo + uma linha em `SkillController.behavior_for`.

**Implementação (T-108):** `SkillController` (nó `Skills` da arena) guarda os slots (1-based), o cooldown (`SkillSlot`, lógica pura) e escuta `skill_1..3` em `_unhandled_input`. A UI aciona por `Arena.use_skill(slot) -> bool`. As skills do slot vêm do export `skills` da cena até o `MatchConfig` trazê-las (AG04).

| Slot | Input Action | Skill (M1) | Tipo | Cooldown | Raio | Efeito |
|---|---|---|---|---|---|---|
| 1 | `skill_1` (`1`) | `skill_pulse` | area | 10 s | 180 px | 60 de dano instantâneo |
| 2 | `skill_2` (`2`) | `skill_stasis` | control | 15 s | 220 px | congela por 2,5 s; `effect_params.slow_after` = 0,5 por 1,5 s |
| 3 | `skill_3` (`3`) | `skill_aegis` | defense | 20 s | — | escudo no Núcleo por 4 s, absorve até 50 de dano |

- **Ao acionar:** valida o cooldown → aplica o efeito → emite `skill_used(slot)` e passa a emitir `cooldown_changed`. Acionar em cooldown não faz nada (a UI pode dar feedback de "indisponível").
- **Sem alvo:** se não há inimigo ao alcance, a skill de área não dispara e **não gasta o cooldown**.
- **Alvo da área e do controle:** automático, no ponto de maior densidade de inimigos dentro de `target_range` (calculado no acionamento; os centros candidatos são as posições dos inimigos).
- **Área:** dano por distância (raio da skill + raio do inimigo), sem usar a layer `skill_areas`. **[A definir]**: mira manual por toque/clique como alternativa, a testar no playtest.
- **Feedback:** antecipação curta (~0,1 s) + impacto forte; tremor leve **desligável**.
- Cards e raridades (AG04, depois do M1) só alteram números e efeitos via `SkillData`. O gameplay não conhece cards.

## Inimigos

Arquivo de dados: `data/enemies/enemy_<id>.tres` (`EnemyData`). Campos: `id, hp, speed, contact_damage, attack_range, fire_rate, projectile (ProjectileData), target_priority, coin_drop, radius, group_min, group_max, group_spread, color`.

| Arquétipo | `id` | HP | Velocidade | Ataque | Moedas |
|---|---|---|---|---|---|
| Corredor | `enemy_runner` | 20 | 140 px/s | contato, 5 de dano | 1 |
| Tanque | `enemy_tank` | 120 | 50 px/s | contato, 20 de dano | 4 |
| Atirador | `enemy_shooter` | 35 | 80 px/s | para a 380 px do centro; 1 tiro a cada 1,5 s (`projectile_enemy_bolt`: 6 de dano, 300 px/s, losango magenta) | 2 |
| Enxame | `enemy_swarm` | 8 | 120 px/s | contato, 2 de dano; nasce em grupos de 5–8, espalhados em 48 px | 1 cada |

- **Estados:** `SPAWN → AVANÇA → ATACA → MORRE`, mais `CONGELADO` e `LENTO` (das skills de controle).
- **Contato:** ao tocar a hurtbox do Anima, o inimigo causa `contact_damage` e morre (sem moedas).
- **Justiça:** projéteis inimigos com cor e forma distintas das do jogador (ex.: losango quente × círculo frio) e mais lentos que os do jogador.
- **Atirador:** um só script (`Enemy`); com `attack_range > 0` ele para no alcance (estado `ATTACK`) e atira com o pool `EnemyProjectiles` da arena (128, layer `enemy_projectiles`). Quem reage ao acerto é o Anima (mask), que consome o projétil.
- **Grupo:** cada spawn de onda cria `group_min..group_max` inimigos (`Arena.spawn_group`). Só o enxame usa grupo > 1.
- Inimigos em pool por arquétipo (T-118); fora da tela não fazem cálculos caros.
- **Balanceamento:** só com o ataque automático, 2 tanques + 2 atiradores juntos já derrotam o Núcleo. A curva da T-116 deve contar com as skills.

## Chefe

Arquivo de dados: `data/enemies/boss_<id>.tres` (`BossData`). Um chefe no M1: `boss_warden` (nome provisório).

| Parâmetro | Valor |
|---|---|
| HP | 1500 |
| Posição | entra pelo topo e para a ~420 px do centro |
| Fases | 100–60%, 60–25%, 25–0% (cada fase muda o peso dos padrões e a cadência) |
| Padrões | leque de projéteis, anel de projéteis, invocar enxame (com pesos por fase) |
| Aviso | ≥ 0,8 s de telegraph antes de cada padrão forte |
| Moedas | 50 |

As ondas normais param enquanto o chefe está vivo. Ao derrotá-lo: vitória.

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
- A fase vem de `data/waves/<config.stage_id>.tres`. Hoje `stage_01` tem **3 ondas de teste** (corredores; a 3ª inclui 1 tanque, 1 atirador e 1 grupo de enxame); a curva abaixo entra na T-116.
- Uma onda termina quando todos os inimigos dela nasceram **e** morreram. Depois vem o respiro `wave_break` (3 s).
- A última onda é a do chefe.

**Curva de dificuldade (fase 1, ~10 ondas):**

| Ondas | Composição | Objetivo |
|---|---|---|
| 1–2 | corredores | aprender o ataque automático |
| 3–4 | corredores + enxame | usar a skill de área |
| 5–6 | + tanques | usar o controle |
| 7–8 | + atiradores | usar a defesa |
| 9 | tudo junto, densidade máxima | teste final |
| 10 | chefe | |

Alvo de duração: ~5–7 min.

## Contrato de partida

- **Raiz:** `Arena` (`src/match/arena/arena.tscn`). `setup(config)` antes de entrar na árvore; sem config, usa `MatchConfig.new()`.
- **Entrada:** `MatchConfig` (`src/core/`, do AG07). Hoje só `stage_id` é lido; `anima_data` e `skills` entram depois (AG04).
- **Saída:** `MatchResult` (`src/core/`; `outcome: VICTORY|DEFEAT`, `wave_reached`, `waves_total`, `coins`, `enemies_killed`, `duration_s`).
- `src/match/` não conhece `meta/`, `backend/` nem nós de UI.
- **Pausa:** a UI pausa via `get_tree().paused`; a partida respeita o process mode e não decide a pausa.

## Sinais expostos à UI

Emitidos pelo nó raiz da partida (`Arena`). Na T-105 já existem `core_hp_changed`, `wave_changed`, `coins_changed` e `match_ended`. Base: AG01 §9.

| Sinal | Quando |
|---|---|
| `core_hp_changed(current: int, max: int)` | início da partida e a cada dano ou cura no Núcleo |
| `wave_changed(current: int, total: int)` | início de cada onda (a onda do chefe conta no `total`) |
| `cooldown_changed(slot: int, remaining: float, total: float)` | ao usar a skill e durante o cooldown, no máximo ~10×/s |
| `skill_ready(slot: int)` | quando o cooldown chega a 0 |
| `coins_changed(amount: int)` | `amount` = **total** de moedas na partida (não o incremento) |
| `boss_spawned(id: StringName)` | entrada do chefe |
| `boss_hp_changed(current: int, max: int)` | a cada dano no chefe |
| `match_ended(result: MatchResult)` | vitória ou derrota (uma vez) |

**Mudanças em relação ao §9 do AG01 (precisam de aprovação):**
1. **Novo:** `skill_used(slot: int)`, já citado no §7 do AG01 mas ausente do §9. Serve ao feedback de acionamento no HUD.
2. **Esclarecido:** `coins_changed` envia o total, não o delta.
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
| Ondas, HP do Núcleo, moedas, vitória/derrota | protótipo | T-105 |
| Skill de área | protótipo | T-108 |
| Skill de controle | pendente | T-109 |
| Skill de defesa | pendente | T-110 |
| Arquétipos (tanque, atirador, enxame) | protótipo | T-111 |
| Chefe | pendente | T-115 |
