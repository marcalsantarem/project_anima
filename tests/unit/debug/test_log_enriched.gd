extends GutTest
## Log enriquecido (T-294, BRF-136): identificação do ensaio, ambiente, velocidade, piores quadros,
## resumo em texto, limite de tamanho do envio e compatibilidade com logs antigos.

class FakeArena:
	extends Node
	signal match_ended(result: MatchResult)
	signal core_hp_changed(current: int, max_hp: int)
	var active_enemies: Array = []
	var particles := 0


func _recorder() -> MatchRecorder:
	var arena := FakeArena.new()
	add_child_autofree(arena)
	var rec := MatchRecorder.new()
	rec.save_enabled = false
	rec.auto_process = false
	rec.attach(arena, null, null, 7)
	add_child_autofree(rec)
	return rec


func _run(rec: MatchRecorder, seconds: float, ms: float = 16.0) -> void:
	for i in roundi(seconds * 1000.0 / ms):
		rec.step(ms)


func test_header_run_info_and_optional_fields_off_web() -> void:
	var rec := _recorder()
	var run: Dictionary = rec.header.run
	for k in ["tag", "session_id", "run_index", "run_started_at"]:
		assert_true(run.has(k), k)
	assert_eq(str(run.session_id).length(), 8)
	assert_gte(int(run.run_index), 1)
	assert_true(str(run.run_started_at).ends_with("Z"))
	assert_false(rec.header.has("env"), "sem ambiente do navegador fora da web")
	assert_true(rec.header.has("load"))
	assert_eq(SessionInfo.web_snapshot(), {})


func test_run_index_increments_and_session_is_stable() -> void:
	var a := _recorder()
	var b := _recorder()
	assert_eq(int(b.header.run.run_index), int(a.header.run.run_index) + 1)
	assert_eq(a.header.run.session_id, b.header.run.session_id)


func test_tag_is_cleaned_and_limited() -> void:
	assert_eq(SessionInfo.clean_tag("iphone11-x2\nstress150"), "iphone11-x2 stress150")
	assert_eq(SessionInfo.clean_tag("a".repeat(200)).length(), SessionInfo.TAG_MAX)
	assert_eq(SessionInfo.clean_tag("  "), "")


func test_ua_parsing() -> void:
	var ios := "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
	assert_eq(SessionInfo.ua_short(ios), "iOS 17.2 · Safari 17.2")
	var chrome := "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
	assert_eq(SessionInfo.ua_short(chrome), "Windows 10.0 · Chrome 130")
	assert_eq(SessionInfo.ua_short(""), "")


func test_worst_frames_top5_sorted() -> void:
	var rec := _recorder()
	for ms in [10.0, 80.0, 20.0, 60.0, 15.0, 90.0, 40.0, 70.0, 12.0]:
		rec.step(ms)
	var w: Array = rec.build_log(false).worst_frames
	assert_eq(w.size(), MatchRecorder.WORST_FRAMES)
	assert_eq(w[0][1], 90.0)
	assert_eq(w[4][1], 40.0)
	for i in range(1, w.size()):
		assert_gte(w[i - 1][1], w[i][1])


func test_sample_has_new_columns() -> void:
	var rec := _recorder()
	_run(rec, 1.1)
	var cols := MatchRecorder.SAMPLE_COLS
	assert_has(cols, "render_objects")
	assert_has(cols, "time_scale")
	assert_eq(rec.samples.to_array()[0].size(), cols.size())


func test_speed_change_event_timeline() -> void:
	var rec := _recorder()
	_run(rec, 0.5)
	rec._on_speed_changed(2.0)
	_run(rec, 0.5)
	rec._on_speed_changed(1.0)
	rec.finish(null)
	var s: Dictionary = rec.log_data.summary
	assert_eq(s.velocidades.size(), 2)
	assert_eq(s.velocidades[0][2], 2.0)
	assert_eq(s.velocidades[1][1], 2.0)


func test_summary_text_lines_5_to_8() -> void:
	var rec := _recorder()
	_run(rec, 3.0)
	rec.finish(null)
	var lines := LogReport.header_lines(rec.log_data)
	assert_between(lines.size(), 5, 8)
	assert_string_contains(lines[0], "tag:")
	assert_string_contains("\n".join(lines), "fps médio")


func test_upload_text_is_json_with_summary_first_and_old_doc_still_valid() -> void:
	var rec := _recorder()
	_run(rec, 3.0)
	rec.finish(null)
	var txt := LogReport.upload_text(rec.log_data)
	var parsed = JSON.parse_string(txt)
	assert_true(parsed is Dictionary)
	assert_eq(parsed.format, "anima_log/1")
	assert_true(txt.begins_with("{\"resumo\":"), "resumo em primeiro")
	assert_eq(parsed.header.run.run_index, rec.header.run.run_index)
	# Log antigo (sem os campos novos) continua válido.
	var old := {"format": "anima_log/1", "header": {"version": "0.1.0"}, "result": {"resultado": "derrota", "onda": 2, "ondas": 5},
		"frames": {"count": 0, "hist_1ms": []}, "samples_cols": ["t", "fps"], "samples": [[1.0, 60.0]], "events": [], "hitches": [], "errors": []}
	var old_parsed = JSON.parse_string(LogReport.upload_text(old))
	assert_true(old_parsed is Dictionary)
	assert_eq(old_parsed.format, "anima_log/1")
	assert_between(old_parsed.resumo.size(), 5, 8)


func test_empty_doc_gives_valid_json() -> void:
	var parsed = JSON.parse_string(LogReport.upload_text({}))
	assert_true(parsed is Dictionary)
	assert_false(str(parsed.resumo).is_empty())


func test_big_log_respects_contract_limits() -> void:
	var rec := _recorder()
	rec.finish(null)
	var doc := rec.log_data.duplicate()
	var cols: Array = doc.samples_cols
	var rows := []
	for i in 1500:
		var row := []
		for c in cols:
			row.append({} if c == "enemies_by_type" else float(i) + 0.123)
		rows.append(row)
	doc["samples"] = rows
	var ev := []
	for i in 3000:
		ev.append({"t": float(i), "e": "mortes", "por_tipo": {"enemy_swarm": 3, "enemy_tank": 1}})
	doc["events"] = ev
	var body := LogUploader.build_body(null, doc, "ua")
	assert_lte(body.to_utf8_buffer().size(), LogUploader.MAX_BYTES, "corpo <= 200 KB")
	var p = JSON.parse_string(body)
	assert_true(p is Dictionary)
	for k in ["version", "build", "platform", "user_agent", "result", "wave", "duration_s", "log"]:
		assert_true(p.has(k), k)
	assert_lte(str(p.log).to_utf8_buffer().size(), LogReport.UPLOAD_MAX_BYTES)
	assert_true(JSON.parse_string(p.log) is Dictionary, "log continua JSON")
	assert_gt(int(JSON.parse_string(p.log).upload.samples_stride), 1, "anota o corte")


func test_normal_match_log_is_small() -> void:
	var rec := _recorder()
	_run(rec, 60.0)
	rec.finish(null)
	var n := LogReport.upload_text(rec.log_data).to_utf8_buffer().size()
	gut.p("tamanho do log de 60 s: %d bytes" % n)
	assert_lt(n, LogReport.UPLOAD_MAX_BYTES)
