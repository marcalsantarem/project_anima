extends GutTest
## Partida montada como no jogo: Arena + HUD (bind antes de a arena entrar na árvore).
## Cobre ondas → dano → Partículas → cooldown → match_ended refletidos no HUD.

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const PULSE := preload("res://data/skills/skill_pulse.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const TWEEN_WAIT := UiTokens.ANIM_UI + 0.15

var arena: Arena
var hud: Hud


func after_each() -> void:
	Engine.time_scale = 1.0


func _stage(wave_counts: Array, wave_break := 0.5) -> StageData:
	var s := StageData.new()
	s.wave_break = wave_break
	for c in wave_counts:
		var e := WaveEntry.new()
		e.enemy = RUNNER
		e.count = c
		e.interval = 0.3
		e.spawn_edge = WaveEntry.SpawnEdge.TOP
		var w := WaveData.new()
		w.entries.append(e)
		s.waves.append(w)
	return s


## stage nulo = waves desligadas (spawn manual).
func _start(stage: StageData, attack := true) -> void:
	arena = ARENA_SCENE.instantiate()
	if stage:
		arena.stage = stage
	else:
		arena.waves_enabled = false
	hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	hud.bind(arena)
	watch_signals(arena)
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = attack


func _parked_enemy(data: EnemyData, offset := Vector2(0, -300)) -> Enemy:
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + offset
	e.target_position = e.position
	return e


func _result() -> MatchResult:
	return get_signal_parameters(arena, "match_ended")[0]


func test_hud_gets_initial_values() -> void:
	_start(_stage([1, 1, 1]), false)
	var max_hp := arena.anima.data.core_hp_max
	assert_eq(hud._core_bar.current, max_hp)
	assert_eq(hud._core_bar.maximum, max_hp)
	assert_eq(hud._wave_label.text, "ONDA 1/3")
	assert_eq(hud._coin_label.text, "0")


func test_hud_follows_core_damage() -> void:
	_start(null, false)
	var max_hp := arena.anima.data.core_hp_max
	arena.anima.core.take_damage(RUNNER.contact_damage)
	assert_eq(hud._core_bar.current, max_hp - RUNNER.contact_damage)
	await wait_physics_frames(1)
	var e := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -20) # encosta no Núcleo
	await wait_seconds(1.0)
	assert_eq(hud._core_bar.current, max_hp - 2 * RUNNER.contact_damage, "dano de contato chega ao HUD")
	assert_eq(arena.enemies_killed, 0, "morte por contato não conta abate")
	assert_eq(hud._coin_label.text, "0", "morte por contato não dá moeda")


func test_victory_reaches_hud_and_result() -> void:
	_start(_stage([2, 3]))
	await wait_for_signal(arena.match_ended, 30.0)
	assert_signal_emit_count(arena, "match_ended", 1)
	var r := _result()
	assert_eq(r.outcome, MatchResult.Outcome.VICTORY)
	assert_eq(r.enemies_killed, 5)
	assert_eq(r.coins, 5 * RUNNER.particle_drop)
	await wait_seconds(TWEEN_WAIT)
	assert_eq(hud._wave_label.text, "ONDA 2/2")
	assert_eq(hud._coin_label.text, UiTokens.format_int(r.coins))
	assert_eq(hud._core_bar.current, arena.anima.core.current)


func test_skill_touch_cooldown_cycle_in_hud() -> void:
	_start(null, false)
	await wait_physics_frames(1)
	_parked_enemy(TANK) # aguenta 2 pulsos
	var button := hud._skill(1)
	hud._on_skill_pressed(1) # toque no botão
	assert_signal_emitted_with_parameters(arena, "skill_used", [1])
	assert_eq(button.state, SkillButton.State.COOLDOWN)
	hud._on_skill_pressed(1) # em cooldown: rejeita
	assert_signal_emit_count(arena, "skill_used", 1)
	arena.skills.get_slot(1).remaining = 0.05
	await wait_physics_frames(6)
	assert_eq(button.state, SkillButton.State.READY)
	await wait_seconds(PULSE.windup + 0.1)
	hud._on_skill_pressed(1)
	assert_signal_emit_count(arena, "skill_used", 2, "pronta de novo após o cooldown")


func test_cooldown_updates_are_throttled_and_decreasing() -> void:
	_start(null, false)
	await wait_physics_frames(1)
	_parked_enemy(TANK)
	assert_true(arena.use_skill(1))
	await wait_seconds(1.0)
	var n: int = get_signal_emit_count(arena, "cooldown_changed")
	# 1 no uso + ~10/s (SkillController.COOLDOWN_EMIT_INTERVAL)
	assert_between(n, 8, 13, "emissões em 1 s: %d" % n)
	var last: Array = get_signal_parameters(arena, "cooldown_changed")
	assert_almost_eq(last[1], PULSE.cooldown - 1.0, 0.2)
	assert_almost_eq(hud._skill(1)._remaining, last[1], 0.2, "HUD recebe o restante (interpola entre emissões)")


func test_skill_without_target_keeps_button_ready() -> void:
	_start(null, false)
	await wait_physics_frames(1)
	hud._on_skill_pressed(1)
	assert_signal_not_emitted(arena, "skill_used")
	assert_eq(hud._skill(1).state, SkillButton.State.READY)
	assert_true(arena.skills.get_slot(1).is_ready())


func test_defeat_locks_hud_and_freezes_match() -> void:
	_start(_stage([25], 0.5), false) # 25 × 5 de contato > 100 HP
	await wait_for_signal(arena.match_ended, 30.0)
	var r := _result()
	assert_eq(r.outcome, MatchResult.Outcome.DEFEAT)
	assert_eq(r.wave_reached, 1)
	assert_eq(hud._core_bar.current, 0)
	for b in hud._skills:
		# Slots bloqueados (T-136) continuam com cadeado; os liberados ficam desativados.
		var expected := SkillButton.State.LOCKED if b.slot > 1 else SkillButton.State.DISABLED
		assert_eq(b.state, expected)
	assert_true(hud._pause_button.disabled)
	assert_false(arena.use_skill(1), "skills travadas após o fim")

	await wait_physics_frames(2) # process_mode diferido
	var alive := arena.active_enemies.duplicate()
	var positions := alive.map(func(e: Enemy) -> Vector2: return e.position)
	var hp_emits: int = get_signal_emit_count(arena, "core_hp_changed")
	var particle_emits: int = get_signal_emit_count(arena, "particles_changed")
	await wait_seconds(1.0)
	assert_eq(alive.map(func(e: Enemy) -> Vector2: return e.position), positions, "inimigos congelados")
	assert_eq(get_signal_emit_count(arena, "core_hp_changed"), hp_emits)
	if alive.size() > 0:
		alive[0].take_damage(9999) # abate após o fim não pontua
	assert_eq(get_signal_emit_count(arena, "particles_changed"), particle_emits)
	assert_eq(arena.particles, r.coins)
	assert_signal_emit_count(arena, "match_ended", 1)


func test_stage_01_full_match_is_consistent() -> void:
	# Fase real, sem intervenção do jogador, acelerada 4×.
	_start(load(StageData.path_for(&"stage_01")))
	Engine.time_scale = 4.0
	await wait_for_signal(arena.match_ended, 60.0)
	Engine.time_scale = 1.0
	assert_signal_emit_count(arena, "match_ended", 1, "partida termina")
	if get_signal_emit_count(arena, "match_ended") == 0:
		return
	var r := _result()
	gut.p("stage_01 sem skills: %s, onda %d/%d, %d abates, %d Partículas, %.1f s" % [
		MatchResult.Outcome.keys()[r.outcome], r.wave_reached, r.waves_total,
		r.enemies_killed, r.coins, r.duration_s])
	assert_eq(r.waves_total, 3)
	assert_between(r.wave_reached, 1, 3)
	if r.outcome == MatchResult.Outcome.VICTORY:
		assert_eq(r.wave_reached, 3)
		assert_gt(arena.anima.core.current, 0)
	else:
		assert_eq(arena.anima.core.current, 0)
	await wait_seconds(TWEEN_WAIT)
	assert_eq(hud._wave_label.text, "ONDA %d/3" % r.wave_reached)
	assert_eq(hud._coin_label.text, UiTokens.format_int(r.coins))
	assert_eq(hud._core_bar.current, arena.anima.core.current)
