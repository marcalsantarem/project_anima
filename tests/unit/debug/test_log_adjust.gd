extends GutTest
## Ajustes do log (T-295, BRF-137): velocidade real, fps por velocidade, dano agregado, result do estresse,
## cadência rAF, query e áudio. Só conteúdo do campo `log`; o contrato da API não muda.

class FakeEnemy:
	extends Node
	var data := {"id": "enemy_swarm"}


class FakeArena:
	extends Node
	signal match_ended(result: MatchResult)
	signal core_hp_changed(current: int, max_hp: int)
	var active_enemies: Array = []
	var particles := 0


class FakeSpeed:
	extends Node
	signal speed_changed(speed: float)
	var chosen := 1.0


func _recorder(speed: Node = null, enemies: int = 0) -> MatchRecorder:
	var arena := FakeArena.new()
	add_child_autofree(arena)
	for i in enemies:
		var e := FakeEnemy.new()
		e.data = {"id": ["enemy_runner", "enemy_swarm", "enemy_tank", "enemy_shooter"][i % 4]}
		arena.add_child(e)
		arena.active_enemies.append(e)
	var rec := MatchRecorder.new()
	rec.save_enabled = false
	rec.auto_process = false
	rec.speed_source = speed
	rec.attach(arena, null, null, 7)
	add_child_autofree(rec)
	return rec


func _run(rec: MatchRecorder, seconds: float, ms: float = 16.7) -> void:
	for i in roundi(seconds * 1000.0 / ms):
		rec.step(ms)


func _stress_log(hits_per_s: int) -> MatchRecorder:
	var rec := _recorder(null, 150)
	rec.header["stress"] = [150, 300]
	var hp := 1000000000
	rec._on_core_hp_changed(hp, hp)
	var steps := 60 * hits_per_s
	var per_step := 1.0 / hits_per_s
	for i in steps:
		rec.step(per_step * 1000.0)
		rec._on_projectile_hit(Vector2.ZERO, &"core")
		hp -= 1
		rec._on_core_hp_changed(hp, 1000000000)
	rec.finish(null)
	return rec


func test_stress_60s_log_size() -> void:
	var rec := _stress_log(30)
	var n := LogReport.upload_text(rec.log_data).to_utf8_buffer().size()
	gut.p("log de estresse de 60 s: %d bytes, eventos %d" % [n, rec.log_data.events.size()])
	assert_lt(n, 60 * 1024)
	assert_eq(int(rec.log_data.summary.dano_total), 60 * 30, "agregar não perde dano")
	assert_eq(int(rec.log_data.summary.danos), 60 * 30)


func test_rare_damage_stays_individual_and_big_too() -> void:
	var rec := _recorder()
	rec._on_core_hp_changed(100, 100)
	rec.step(16.7)
	rec._on_core_hp_changed(99, 100)
	rec._on_core_hp_changed(80, 100) # >= 10% de energia_max: individual na hora
	_run(rec, 2.0)
	var kinds := {}
	for e in rec.events.to_array():
		kinds[e.e] = int(kinds.get(e.e, 0)) + 1
	assert_eq(int(kinds.get("dano", 0)), 2)
	assert_false(kinds.has("dano_agg"))


func test_dano_agg_fields_and_threshold() -> void:
	var rec := _recorder()
	rec._on_core_hp_changed(1000, 1000)
	rec.step(16.7)
	for i in 8: # 8 golpes na mesma janela de 1 s: passa de 5, vira agregado
		rec._on_projectile_hit(Vector2.ZERO, &"core")
		rec._on_core_hp_changed(1000 - (i + 1), 1000)
	_run(rec, 1.5)
	var agg := rec.events.to_array().filter(func(e) -> bool: return e.e == "dano_agg")
	assert_eq(agg.size(), 1)
	assert_eq(agg[0].fonte, "projetil_inimigo")
	assert_eq(agg[0].soma, 8)
	assert_eq(agg[0].contagem, 8)
	assert_true(agg[0].has("t"))


func test_real_speed_initial_event_and_summary_agree() -> void:
	var sp := FakeSpeed.new()
	sp.chosen = 2.0
	add_child_autofree(sp)
	var rec := _recorder(sp)
	Engine.time_scale = 2.0
	_run(rec, 3.0)
	rec.finish(null)
	Engine.time_scale = 1.0
	var first: Dictionary = rec.events.to_array().filter(func(e) -> bool: return e.e == "velocidade")[0]
	assert_null(first.de)
	assert_eq(first.para, 2.0)
	var s: Dictionary = rec.log_data.summary
	assert_eq(rec.log_data.header.speed_initial, 2.0)
	assert_eq(s.velocidade_inicial, 2)
	assert_eq(s.velocidades.size(), 0, "sem mudanças")
	assert_true(s.por_velocidade.has("2"))
	assert_false(s.por_velocidade.has("1"))
	var tsi := (rec.log_data.samples_cols as Array).find("time_scale")
	assert_eq(float(rec.log_data.samples[0][tsi]), 2.0)
	var lines := LogReport.header_lines(rec.log_data)
	assert_string_contains("\n".join(lines), "velocidade: x2 inicial · 0 mudanças")


func test_speed_change_without_signal_is_recorded() -> void:
	var sp := FakeSpeed.new()
	add_child_autofree(sp)
	var rec := _recorder(sp)
	_run(rec, 0.5)
	sp.chosen = 2.0 # como StressMode.apply_speed: muda `chosen` sem emitir o sinal
	_run(rec, 0.5)
	rec.finish(null)
	var s: Dictionary = rec.log_data.summary
	assert_eq(s.velocidade_inicial, 1)
	assert_eq(s.velocidades.size(), 1)
	assert_eq(s.velocidades[0][2], 2.0)


func test_fps_by_speed_in_summary_and_line() -> void:
	var rec := _recorder()
	Engine.time_scale = 1.0
	_run(rec, 3.0, 16.7)
	Engine.time_scale = 2.0
	_run(rec, 3.0, 33.3)
	rec.finish(null)
	Engine.time_scale = 1.0
	var bs: Dictionary = rec.log_data.summary.por_velocidade
	assert_true(bs.has("1") and bs.has("2"))
	for k in ["segundos", "fps_medio", "fps_min", "quadro_p95_ms"]:
		assert_true(bs["2"].has(k), k)
	assert_gt(bs["1"].fps_medio, bs["2"].fps_medio)
	assert_string_contains("\n".join(LogReport.header_lines(rec.log_data)), "x2 ")


func test_resumo_line_count_and_raf_line() -> void:
	var rec := _recorder()
	_run(rec, 2.0)
	rec.finish(null)
	var doc := rec.log_data.duplicate(true)
	var n := LogReport.header_lines(doc).size()
	assert_between(n, 5, 8)
	doc.header["env"] = {"raf_hz_inicio": 30.1, "suspeita_30fps_cap": true}
	doc["web_end"] = {"raf_hz_fim": 29.8, "suspeita_30fps_cap": true}
	var txt := "\n".join(LogReport.header_lines(doc))
	assert_string_contains(txt, "cadência rAF: 30 Hz")
	assert_string_contains(txt, "possível Pouca Energia")
	assert_between(LogReport.header_lines(doc).size(), 5, 8)
	doc.header["env"] = {"raf_hz_inicio": 60.0, "suspeita_30fps_cap": false}
	doc["web_end"] = {"raf_hz_fim": 60.0, "suspeita_30fps_cap": false}
	assert_string_contains("\n".join(LogReport.header_lines(doc)), "cadência rAF: 60 Hz")


func test_suspect_30fps_cap_rule() -> void:
	assert_true(SessionInfo.suspect_30fps_cap(30.0, 0))
	assert_true(SessionInfo.suspect_30fps_cap(33.5, 0))
	assert_false(SessionInfo.suspect_30fps_cap(60.0, 0))
	assert_false(SessionInfo.suspect_30fps_cap(30.0, 30), "max_fps explícito não é suspeita")
	assert_null(SessionInfo.suspect_30fps_cap(null, 0))


func test_header_has_refresh_max_fps_audio_off_web() -> void:
	var rec := _recorder()
	assert_true(rec.header.has("refresh_hz"))
	assert_true(rec.header.has("max_fps"))
	assert_true(rec.header.has("audio"))
	rec.finish(null)
	assert_true(rec.log_data.has("audio_end"))


func test_stress_result_is_quit_in_payload_and_resultado_stays_in_log() -> void:
	var rec := _recorder()
	rec.header["stress"] = [150, 300]
	rec.finish(null)
	var res := MatchResult.new()
	res.outcome = MatchResult.Outcome.VICTORY
	res.wave_reached = 3
	res.duration_s = 60.0
	var doc := rec.log_data.duplicate()
	doc["result"] = {"resultado": "estresse"}
	var p := LogUploader.build_payload(res, doc, "ua")
	assert_eq(p.result, "quit")
	assert_eq(p.wave, 3)
	assert_eq(p.duration_s, 60.0)
	assert_eq(JSON.parse_string(p.log).result.resultado, "estresse")
	assert_eq(LogUploader.build_payload(res, {}, "ua").result, "victory")
	var body := LogUploader.build_body(res, doc, "ua")
	assert_lte(body.to_utf8_buffer().size(), LogUploader.MAX_BYTES)
