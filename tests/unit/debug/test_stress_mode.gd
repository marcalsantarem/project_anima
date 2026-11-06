extends GutTest
## Temporizador do modo de estresse (tempo simulado) e métricas no resumo do log (BRF-090).

var _fired := 0


func _on_up() -> void:
	_fired += 1


func _stress() -> StressMode:
	var s := StressMode.new()
	add_child_autofree(s)
	s.time_up.connect(_on_up)
	return s


func test_ends_after_60s_once() -> void:
	_fired = 0
	var s := _stress()
	for i in 59:
		s.tick(1.0)
	assert_eq(_fired, 0)
	s.tick(1.0)
	assert_eq(_fired, 1)
	s.tick(5.0)
	assert_eq(_fired, 1)


func test_paused_does_not_count() -> void:
	_fired = 0
	var s := _stress()
	get_tree().paused = true
	s.tick(100.0)
	get_tree().paused = false
	assert_eq(_fired, 0)
	assert_almost_eq(s.time_left, StressMode.DURATION_S, 0.001)


func test_summary_has_stress_block_only_when_stressed() -> void:
	var rec := MatchRecorder.new()
	rec.save_enabled = false
	rec.auto_process = false
	add_child_autofree(rec)
	for i in 120:
		rec.step(16.7)
	rec.finish(null)
	assert_false(rec.log_data.summary.has("estresse"))
	var rec2 := MatchRecorder.new()
	rec2.save_enabled = false
	rec2.auto_process = false
	add_child_autofree(rec2)
	rec2.header["stress"] = [150, 300]
	for i in 120:
		rec2.step(16.7)
	rec2.finish(null)
	var e: Dictionary = rec2.log_data.summary.estresse
	assert_eq(e.parametros, "stress=150,300")
	for k in ["fps_medio", "fps_min", "quadro_ms_p95", "quadros_50ms", "draw_calls", "nos", "inimigos", "projeteis", "dpr", "canvas"]:
		assert_true(e.has(k), k)
	assert_string_contains(LogReport.to_text(rec2.log_data), "ESTRESSE stress=150,300")
