extends GutTest
## Lógica pura do debug (BRF-063): buffer circular, histograma de quadros, percentis, resumo e JSON.


func test_ring_keeps_order_and_counts_dropped() -> void:
	var r := DebugRing.new(3)
	for i in 5:
		r.push(i)
	assert_eq(r.size(), 3)
	assert_eq(r.dropped, 2, "2 itens sobrescritos")
	assert_eq(r.to_array(), [2, 3, 4], "do mais antigo ao mais novo")
	assert_eq(r.tail(2), [3, 4])
	assert_eq(r.last(), 4)
	r.clear()
	assert_eq(r.size(), 0)
	assert_null(r.last())


func test_frame_stats_histogram_and_percentiles() -> void:
	var f := FrameStats.new()
	for i in 98:
		f.add(16.4)
	f.add(40.0)
	f.add(120.0)
	assert_eq(f.count, 100)
	assert_eq(f.over_33, 2)
	assert_eq(f.over_50, 1)
	assert_eq(f.over_100, 1)
	assert_eq(f.percentile(50.0), 17.0, "balde de 16 ms → limite 17")
	assert_eq(f.percentile(99.0), 41.0)
	assert_eq(f.percentile(100.0), 121.0)
	assert_almost_eq(f.max_ms, 120.0, 0.001)
	var d := f.to_dict()
	assert_eq((d.hist_1ms as Array).size(), 121, "histograma cortado no último balde usado")


func test_frame_stats_clamps_huge_frames() -> void:
	var f := FrameStats.new()
	f.add(5000.0)
	assert_eq(f.hist[FrameStats.BUCKETS - 1], 1)


func test_percentile_nearest_rank() -> void:
	var v := [10, 50, 20, 40, 30]
	assert_eq(LogReport.percentile(v, 0.0), 10.0)
	assert_eq(LogReport.percentile(v, 50.0), 30.0)
	assert_eq(LogReport.percentile(v, 100.0), 50.0)
	assert_eq(LogReport.percentile([], 50.0), 0.0)


func _synthetic() -> Dictionary:
	var cols := MatchRecorder.SAMPLE_COLS
	var samples := []
	for i in 10:
		var row := []
		row.resize(cols.size())
		row.fill(0)
		row[cols.find("t")] = float(i + 1)
		row[cols.find("fps")] = 60.0 if i != 4 else 20.0
		row[cols.find("enemies")] = i
		row[cols.find("proj_player")] = 3
		row[cols.find("proj_enemy")] = i * 2
		row[cols.find("nodes")] = 100 + i * 5
		row[cols.find("mem_static_mb")] = 50.0 + i
		row[cols.find("n33")] = 1 if i == 4 else 0
		row[cols.find("enemies_by_type")] = {}
		row[cols.find("paused")] = false
		samples.append(row)
	var f := FrameStats.new()
	for i in 590:
		f.add(16.0)
	for i in 10:
		f.add(60.0)
	return {
		"format": MatchRecorder.FORMAT,
		"header": {"date": "2026-11-04 10:20:30", "godot": "4.7.2"},
		"result": {"resultado": "derrota", "onda": 3, "ondas": 10, "duracao_s": 10.0},
		"frames": f.to_dict(),
		"samples_cols": cols,
		"samples": samples,
		"events": [
			{"t": 1.0, "e": "dano", "valor": 5, "fonte": "projetil_inimigo"},
			{"t": 2.0, "e": "dano", "valor": 7, "fonte": "contato:enemy_swarm"},
			{"t": 3.0, "e": "upgrade", "id": "upgrade_atk_power", "nivel": 1, "custo": 20},
			{"t": 4.0, "e": "upgrade_negado", "id": "upgrade_atk_power"},
		],
		"hitches": [{"t": 5.0, "ms": 60.0}, {"t": 6.0, "ms": 90.0}],
		"errors": [{"t": 1.0, "tipo": "error", "msg": "falha"}],
		"truncated": {"samples": 0, "events": 0},
	}


func test_summary_from_synthetic_log() -> void:
	var s := LogReport.summarize(_synthetic())
	assert_eq(s.resultado, "derrota")
	assert_eq(s.fps_min, 20.0)
	assert_eq(s.fps_p5, 20.0)
	assert_almost_eq(float(s.fps_medio), 56.0, 0.01)
	assert_eq(s.quadro_ms_p50, 17.0)
	assert_eq(s.quadro_ms_p99, 61.0)
	assert_eq(s.travadas_50, 10)
	assert_eq(s.pico_inimigos, 9)
	assert_eq(s.pico_projeteis, 21, "jogador + inimigos")
	assert_eq(s.nos, [100, 145, 45], "crescimento de nós")
	assert_eq(s.dano_total, 12)
	assert_eq(s.dano_por_fonte["projetil_inimigo"], 5)
	assert_eq(s.upgrades_negados, 1)
	assert_eq((s.upgrades as Array).size(), 1)
	assert_eq(s.erros, 1)
	assert_eq(s.maiores_travadas[0].ms, 90.0, "maior travada primeiro")
	assert_eq(s.segundos_com_33, [5.0])


func test_json_round_trip_keeps_summary_and_text() -> void:
	var doc := _synthetic()
	doc["summary"] = LogReport.summarize(doc)
	var back = JSON.parse_string(JSON.stringify(doc))
	assert_true(back is Dictionary)
	var s2 := LogReport.summarize(back)
	assert_eq(int(s2.dano_total), 12)
	assert_eq(float(s2.fps_min), 20.0)
	var text := LogReport.to_text(back)
	assert_string_contains(text, "RESUMO")
	assert_string_contains(text, "LINHA DO TEMPO")
	assert_string_contains(text, "AMOSTRAS")
	assert_eq(LogReport.file_base(back), "anima_log_20261104_102030")


func test_json_size_limit_truncates_and_notes() -> void:
	var doc := _synthetic()
	var big := []
	for i in 400:
		big.append({"t": float(i), "e": "x", "pad": "0123456789012345678901234567890123456789"})
	doc["events"] = big
	var text := MatchRecorder.to_json_limited(doc, 8000)
	assert_true(text.length() <= 8000)
	var back = JSON.parse_string(text)
	assert_true(back.truncated.size_limit, "nota de truncamento")
	assert_gt(int(back.truncated.events), 0)


func test_settings_persist_overlay_state() -> void:
	var old := DebugSettings.path
	DebugSettings.path = "user://test_debug.cfg"
	DebugSettings.reset()
	assert_false(DebugSettings.overlay_enabled(), "desligado por padrão")
	DebugSettings.set_overlay_enabled(true)
	DebugSettings.reset()
	assert_true(DebugSettings.overlay_enabled(), "estado salvo")
	DebugSettings.toggle_overlay()
	assert_false(DebugSettings.overlay_enabled())
	DirAccess.remove_absolute(DebugSettings.path)
	DebugSettings.path = old
	DebugSettings.reset()


## T-172: linhas do viewport no overlay ?debug=1 (mesmos números de header.web.viewport).
func test_viewport_lines() -> void:
	assert_eq(MatchRecorder.viewport_lines({}).size(), 0, "fora da web: nada")
	var v := {"inner": [375.0, 768.0], "app_h": 812.0, "outer_h": 812.0, "client_h": 768.0,
		"vv": [375.0, 768.0, 0.0, 1.0], "screen": [375.0, 812.0], "svh": 768.0, "dvh": 768.0, "lvh": 812.0,
		"canvas": [0.0, 812.0, 812.0], "standalone": false,
		"safe": {"top": 44.0, "bottom": 34.0, "covers_bottom": true}}
	var lines := MatchRecorder.viewport_lines(v)
	assert_eq(lines.size(), 4)
	assert_eq(lines[0], "in 375x768 app 812 out 812 cli 768")
	assert_eq(lines[3], "cv 0..812 h812 safe 44/34 cobre sim")
