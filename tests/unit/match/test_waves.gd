extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func _entry(count: int, interval: float, delay := 0.0) -> WaveEntry:
	var e := WaveEntry.new()
	e.enemy = RUNNER
	e.count = count
	e.interval = interval
	e.start_delay = delay
	e.spawn_edge = WaveEntry.SpawnEdge.TOP
	return e


func _stage(wave_counts: Array, wave_break := 1.0) -> StageData:
	var s := StageData.new()
	s.wave_break = wave_break
	for c in wave_counts:
		var w := WaveData.new()
		w.entries.append(_entry(c, 0.5))
		s.waves.append(w)
	return s


func test_stage_01_has_three_waves() -> void:
	var s: StageData = load(StageData.path_for(&"stage_01"))
	assert_eq(s.waves.size(), 3)


func test_spawns_follow_delay_and_interval() -> void:
	var s := StageData.new()
	var w := WaveData.new()
	w.entries.append(_entry(3, 1.0, 0.5))
	s.waves.append(w)
	var r := WaveRunner.new(s)
	watch_signals(r)
	r.start()
	r.tick(0.4, 0)
	assert_signal_emit_count(r, "spawn_requested", 0)
	r.tick(0.2, 1) # t = 0.6
	assert_signal_emit_count(r, "spawn_requested", 1)
	r.tick(2.0, 3) # t = 2.6: os 3 nasceram
	assert_signal_emit_count(r, "spawn_requested", 3)


func test_wave_waits_for_kills_then_break_then_next() -> void:
	var r := WaveRunner.new(_stage([1, 1], 1.0))
	watch_signals(r)
	r.start()
	assert_signal_emitted_with_parameters(r, "wave_started", [1, 2])
	r.tick(0.1, 1) # nasceu, ainda vivo
	assert_eq(r.phase, WaveRunner.Phase.RUNNING)
	r.tick(0.1, 0) # morreu
	assert_eq(r.phase, WaveRunner.Phase.BREAK)
	r.tick(0.5, 0)
	assert_eq(r.current_wave(), 1)
	r.tick(0.6, 0)
	assert_signal_emitted_with_parameters(r, "wave_started", [2, 2])


func test_last_wave_clears_stage() -> void:
	var r := WaveRunner.new(_stage([1]))
	watch_signals(r)
	r.start()
	r.tick(0.1, 1)
	r.tick(0.1, 0)
	assert_signal_emitted(r, "stage_cleared")
	assert_eq(r.phase, WaveRunner.Phase.CLEARED)


func _run_arena(stage: StageData, attack: bool) -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.stage = stage
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = attack
	watch_signals(arena)
	return arena


func test_victory_after_last_wave_with_particles() -> void:
	var arena := _run_arena(_stage([2, 2], 0.5), true)
	await wait_for_signal(arena.match_ended, 30.0)
	assert_signal_emit_count(arena, "match_ended", 1)
	var result: MatchResult = get_signal_parameters(arena, "match_ended")[0]
	assert_eq(result.outcome, MatchResult.Outcome.VICTORY)
	assert_eq(result.wave_reached, 2)
	assert_eq(result.waves_total, 2)
	assert_eq(result.enemies_killed, 4)
	assert_eq(result.coins, 4 * RUNNER.particle_drop)
	assert_signal_emitted_with_parameters(arena, "particles_changed", [result.coins])
	assert_gt(result.duration_s, 0.0)


func test_defeat_when_core_hp_reaches_zero() -> void:
	# 100 HP / 5 de contato = 20 corredores; 25 garantem a derrota.
	var arena := _run_arena(_stage([25]), false)
	await wait_for_signal(arena.match_ended, 30.0)
	assert_signal_emit_count(arena, "match_ended", 1)
	var result: MatchResult = get_signal_parameters(arena, "match_ended")[0]
	assert_eq(result.outcome, MatchResult.Outcome.DEFEAT)
	assert_eq(arena.anima.core.current, 0)
	assert_eq(result.coins, 0)
	await wait_physics_frames(5)
	assert_signal_emit_count(arena, "match_ended", 1, "emitido uma vez só")
