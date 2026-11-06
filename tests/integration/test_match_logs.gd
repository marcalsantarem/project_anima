extends GutTest
## Gravador com a Arena real e o botão "Logs" do Resultado (BRF-063).

const SAMPLE_LOG_DIR := "user://test_logs_ui/"

var _old_dir := ""


func before_all() -> void:
	_old_dir = MatchRecorder.log_dir
	MatchRecorder.log_dir = SAMPLE_LOG_DIR


func after_all() -> void:
	if DirAccess.dir_exists_absolute(SAMPLE_LOG_DIR):
		for f in DirAccess.get_files_at(SAMPLE_LOG_DIR):
			DirAccess.remove_absolute(SAMPLE_LOG_DIR.path_join(f))
		DirAccess.remove_absolute(SAMPLE_LOG_DIR)
	MatchRecorder.log_dir = _old_dir


## Partida real em passos fixos do gravador (um passo de 1/60 s por quadro de física).
func test_recorder_with_real_arena() -> void:
	var arena: Arena = load(MatchConfig.DEFAULT_MATCH_SCENE).instantiate()
	arena.setup(MatchConfig.new())
	var rec := MatchRecorder.new()
	rec.auto_process = false
	rec.save_enabled = false
	rec.attach(arena, null, null, 7)
	arena.set_seed(7)
	add_child_autofree(rec)
	add_child_autofree(arena)
	for i in 90:
		await wait_physics_frames(1)
		rec.step(1000.0 / 60.0)
	arena.anima.take_core_damage(arena.anima.core.max_hp)
	await wait_physics_frames(1)
	assert_true(rec.finished_ok, "match_ended fecha o log")
	var doc := rec.log_data
	assert_eq(doc.result.resultado, "derrota")
	assert_gt((doc.samples as Array).size(), 0)
	var types := (doc.events as Array).map(func(e: Dictionary) -> String: return e.e)
	assert_has(types, "inicio")
	assert_has(types, "onda")
	assert_has(types, "dano")
	assert_has(types, "fim")
	assert_string_contains(LogReport.to_text(doc), "Resultado: derrota")


func _sample_doc() -> Dictionary:
	var rec := MatchRecorder.new()
	rec.auto_process = false
	rec.save_enabled = false
	add_child(rec)
	for i in 200:
		rec.step(16.0 if i % 50 else 70.0)
	rec.event("dano", {"valor": 3, "fonte": "projetil_inimigo"})
	rec.finish(null)
	var doc := rec.log_data
	rec.free()
	return doc


func test_result_logs_button_opens_viewer_and_keeps_buttons() -> void:
	var screen: ResultScreen = load(SceneFlow.RESULT_SCENE).instantiate()
	var r := MatchResult.new()
	r.wave_reached = 3
	r.waves_total = 10
	screen.show_result(r)
	screen.set_log(_sample_doc())
	add_child_autofree(screen)
	await wait_process_frames(1)
	var logs := screen.find_child("Logs", true, false) as Button
	assert_not_null(logs, "botão Logs")
	if logs == null:
		return
	assert_gte(logs.custom_minimum_size.y, 44.0)
	logs.pressed.emit()
	assert_not_null(screen.viewer, "visualizador aberto")
	await wait_process_frames(1)
	var body := screen.viewer.body
	assert_gt(body.get_child_count(), 0)
	assert_string_contains((body.get_child(0) as Label).text, "RESUMO")
	assert_string_contains(screen.viewer.text, "LINHA DO TEMPO")
	assert_false(get_tree().paused, "não pausa")
	var paths := screen.viewer.save_files()
	assert_true(FileAccess.file_exists(paths[0]), ".json gravado fora da web")
	for p in paths:
		DirAccess.remove_absolute(p)
	screen.viewer.close()
	await wait_process_frames(1)
	assert_null(screen.viewer, "fechado")
	watch_signals(screen)
	(screen.find_child("PlayAgain", true, false) as Button).pressed.emit()
	(screen.find_child("BackToTitle", true, false) as Button).pressed.emit()
	assert_signal_emitted(screen, "play_again_requested")
	assert_signal_emitted(screen, "title_requested")
