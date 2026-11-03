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
| Anima | centro da arena, câmera fixa |
| Bordas de spawn | `top`, `bottom`, `left`, `right` (fora da tela, ~64 px além da borda) |
| Lógica | `_physics_process` a 60 Hz; o visual nunca decide a regra |

## Anima e ataque automático

Arquivo de dados: `data/anima/anima_default.tres` (`AnimaData`).

| Campo | Valor | Notas |
|---|---|---|
| `core_hp_max` | 100 | HP do Núcleo |
| `hurtbox_radius` | 40 px | hurtbox circular |
| `fire_rate` | 2 tiros/s | |
| `projectile_speed` | 900 px/s | |
| `projectile_damage` | 10 | |
| `attack_range` | 600 px | fora do alcance, não atira |
| `target_scan_interval` | 0,1 s | busca de alvo por intervalo, não por frame |
| `pierce` | 0 | número de alvos extras atravessados |
| `projectile_pool_size` | 64 | pré-alocados; nada de `instantiate`/`queue_free` por tiro |

**Mira:** maior `target_priority` primeiro (campo do inimigo); empate → mais próximo. Só considera inimigos dentro do alcance e visíveis.
**Projétil:** acerta cada alvo uma vez; some ao sair da tela, ao passar do alcance ou ao esgotar o `pierce`, e volta ao pool.

## Skills

3 slots no M1. O 4º slot (`skill_4` / `Espaço`) fica para **depois do M1**.

Cada skill é um `SkillData` (`data/skills/skill_<id>.tres`):
`id, type (area|control|defense), cooldown, radius, damage, duration, effect_params, fx_id, sfx_id`.
O comportamento fica em um script por `type`, que só lê o Resource. Skill nova = dados novos.

| Slot | Input Action | Skill (M1) | Tipo | Cooldown | Raio | Efeito |
|---|---|---|---|---|---|---|
| 1 | `skill_1` (`1`) | `skill_pulse` | area | 10 s | 180 px | 60 de dano instantâneo |
| 2 | `skill_2` (`2`) | `skill_stasis` | control | 15 s | 220 px | congela por 2,5 s; `effect_params.slow_after` = 0,5 por 1,5 s |
| 3 | `skill_3` (`3`) | `skill_aegis` | defense | 20 s | — | escudo no Núcleo por 4 s, absorve até 50 de dano |

- **Ao acionar:** valida o cooldown → aplica o efeito → emite `skill_used(slot)` e passa a emitir `cooldown_changed`. Acionar em cooldown não faz nada (a UI pode dar feedback de "indisponível").
- **Alvo da área e do controle:** automático, no ponto de maior densidade de inimigos dentro do alcance (amostragem por intervalo). **[A definir]**: mira manual por toque/clique como alternativa, a testar no playtest.
- **Feedback:** antecipação curta (~0,1 s) + impacto forte; tremor leve **desligável**.
- Cards e raridades (AG04, depois do M1) só alteram números e efeitos via `SkillData`. O gameplay não conhece cards.

## Inimigos

Arquivo de dados: `data/enemies/enemy_<id>.tres` (`EnemyData`). Campos: `id, hp, speed, contact_damage, attack_range, fire_rate, projectile_speed, projectile_damage, target_priority, coin_drop, radius`.

| Arquétipo | `id` | HP | Velocidade | Ataque | Moedas |
|---|---|---|---|---|---|
| Corredor | `enemy_runner` | 20 | 140 px/s | contato, 5 de dano | 1 |
| Tanque | `enemy_tank` | 120 | 50 px/s | contato, 20 de dano | 4 |
| Atirador | `enemy_shooter` | 35 | 80 px/s | para a ~380 px do centro; 1 tiro a cada 1,5 s, 6 de dano, 300 px/s | 2 |
| Enxame | `enemy_swarm` | 8 | 120 px/s | contato, 2 de dano; nasce em grupos de 5–8 | 1 cada |

- **Estados:** `SPAWN → AVANÇA → ATACA → MORRE`, mais `CONGELADO` e `LENTO` (das skills de controle).
- **Contato:** ao tocar a hurtbox do Anima, o inimigo causa `contact_damage` e morre (sem moedas).
- **Justiça:** projéteis inimigos com cor e forma distintas das do jogador (ex.: losango quente × círculo frio) e mais lentos que os do jogador.
- Inimigos em pool por arquétipo; fora da tela não fazem cálculos caros.

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
StageData: id, waves: Array[WaveData], boss_id, wave_break (s)
WaveData:  id, entries: Array[{enemy_id, count, interval, spawn_edge, start_delay}]
```

- `spawn_edge`: `top | bottom | left | right | random`.
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

- **Entrada:** `MatchConfig` (`stage_id`, `anima_data`, `skills: Array[SkillData]` com 3 itens). No M1 vem com valores padrão; depois, o AG04 preenche.
- **Saída:** `MatchResult` (`outcome: victory|defeat`, `wave_reached`, `waves_total`, `coins`, `enemies_killed`, `duration_s`).
- `src/match/` não conhece `meta/`, `backend/` nem nós de UI.
- **Pausa:** a UI pausa via `get_tree().paused`; a partida respeita o process mode e não decide a pausa.

## Sinais expostos à UI

Emitidos pelo nó raiz da partida (`Match`). Base: AG01 §9.

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
- Pools para projéteis e inimigos; nada de alocação por frame.
- Busca de alvo e de densidade por intervalo (0,1 s), não por frame.
- `CPUParticles2D` curtas; nada de partículas por projétil.

## Status dos sistemas

| Sistema | Status | Task |
|---|---|---|
| Arena, Anima, 1 inimigo | pendente | T-103 |
| Ataque automático com pool | pendente | T-104 |
| Ondas, HP do Núcleo, moedas, vitória/derrota | pendente | T-105 |
| Skill de área | pendente | T-108 |
| Skill de controle | pendente | T-109 |
| Skill de defesa | pendente | T-110 |
| Arquétipos (tanque, atirador, enxame) | pendente | T-111 |
| Chefe | pendente | T-115 |
