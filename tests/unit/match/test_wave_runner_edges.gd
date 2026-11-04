extends GutTest
## Lacunas de test_waves.gd: bordas do WaveRunner e validade dos dados de stage_01.

const RUNNER := preload("res://data/enemies/enemy_runner.tres")


func _entry(count: int, interval: float, delay := 0.0) -> WaveEntry:
	var e := WaveEntry.new()
	e.enemy = RUNNER
	e.count = count
	e.interval = interval
	e.start_delay = delay
	return e


func _stage(waves: Array, wave_break := 1.0) -> StageData:
	var s := StageData.new()
	s.wave_break = wave_break
	for entries in waves:
		var w := WaveData.new()
		for e in entries:
			w.entries.append(e)
		s.waves.append(w)
	return s


func test_idle_before_start() -> void:
	var r := WaveRunner.new(_stage([[_entry(1, 0.0)]]))
	watch_signals(r)
	assert_eq(r.current_wave(), 0)
	r.tick(5.0, 0)
	assert_eq(r.phase, WaveRunner.Phase.IDLE)
	assert_signal_not_emitted(r, "spawn_requested")


func test_empty_stage_clears_on_start() -> void:
	var r := WaveRunner.new(StageData.new())
	watch_signals(r)
	r.start()
	assert_eq(r.phase, WaveRunner.Phase.CLEARED)
	assert_signal_emit_count(r, "stage_cleared", 1)
	assert_signal_not_emitted(r, "wave_started")


func test_wave_with_several_entries_waits_for_all() -> void:
	var r := WaveRunner.new(_stage([[_entry(1, 0.0), _entry(2, 1.0, 2.0)]]))
	watch_signals(r)
	r.start()
	r.tick(0.1, 0) # 1º grupo nasceu e já morreu; 2º ainda não começou
	assert_signal_emit_count(r, "spawn_requested", 1)
	assert_eq(r.phase, WaveRunner.Phase.RUNNING, "não encerra com grupo pendente")
	r.tick(3.0, 0) # t = 3.1: os 2 do 2º grupo nasceram
	assert_signal_emit_count(r, "spawn_requested", 3)
	assert_signal_not_emitted(r, "stage_cleared", "não fecha no passo do último spawn")
	r.tick(0.1, 0) # morreram
	assert_signal_emitted(r, "stage_cleared")


func test_cleared_stage_ignores_ticks() -> void:
	var r := WaveRunner.new(_stage([[_entry(1, 0.0)]]))
	watch_signals(r)
	r.start()
	r.tick(0.1, 0)
	r.tick(0.1, 0)
	r.tick(10.0, 0)
	assert_signal_emit_count(r, "stage_cleared", 1)
	assert_signal_emit_count(r, "spawn_requested", 1)
	assert_eq(r.current_wave(), 1)


func test_zero_break_starts_next_wave_on_next_tick() -> void:
	var r := WaveRunner.new(_stage([[_entry(1, 0.0)], [_entry(1, 0.0)]], 0.0))
	watch_signals(r)
	r.start()
	r.tick(0.1, 0) # spawn
	r.tick(0.0, 0) # morto: respiro
	assert_eq(r.phase, WaveRunner.Phase.BREAK)
	r.tick(0.0, 0)
	assert_eq(r.current_wave(), 2)
	assert_signal_emitted_with_parameters(r, "wave_started", [2, 2])


## Regressão (T-150): a onda do chefe sozinho não pode fechar no mesmo passo em que ele nasce
## (alive_count é lido antes dos spawns do passo).
func test_last_spawn_does_not_close_wave_in_same_tick() -> void:
	var r := WaveRunner.new(_stage([[_entry(1, 0.0)]]))
	watch_signals(r)
	r.start()
	r.tick(0.1, 0)
	assert_signal_emit_count(r, "spawn_requested", 1)
	assert_signal_not_emitted(r, "stage_cleared")
	r.tick(0.1, 1) # vivo
	assert_signal_not_emitted(r, "stage_cleared")
	r.tick(0.1, 0)
	assert_signal_emitted(r, "stage_cleared")


func test_stage_01_data_is_valid() -> void:
	var s: StageData = load(StageData.path_for(&"stage_01"))
	assert_gte(s.wave_break, 0.0)
	for wi in s.waves.size():
		var w := s.waves[wi]
		assert_gt(w.entries.size(), 0, "onda %d sem grupos" % (wi + 1))
		for e in w.entries:
			assert_not_null(e.enemy, "onda %d: grupo sem inimigo" % (wi + 1))
			if e.enemy:
				var prefix := "boss_" if e.enemy is BossData else "enemy_"
				assert_true(String(e.enemy.id).begins_with(prefix), "id %s" % e.enemy.id)
			assert_gt(e.count, 0)
			assert_gte(e.interval, 0.0)
			assert_gte(e.start_delay, 0.0)
