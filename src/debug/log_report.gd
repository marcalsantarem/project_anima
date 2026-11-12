class_name LogReport
extends RefCounted
## Resumo e texto legível do log da partida (docs/debug.md §3). Funções puras sobre o Dictionary do
## MatchRecorder (também o lido de JSON, com números como float). Só rodam no fim ou no visualizador.

const MAX_TIMELINE := 600 ## eventos no texto (os mais recentes)
const MAX_SAMPLE_ROWS := 400 ## linhas da tabela de amostras no texto
const TOP_HITCHES := 5
const FIRST_ERRORS := 20 ## mensagens de erro no resumo (BRF-136)
## Teto do log enviado (campo `log` do contrato; o corpo tem de caber em 200 KB, docs/logs-api.md).
const UPLOAD_MAX_BYTES := 150 * 1024


## Percentil por ordem (nearest-rank) de uma lista de números. p em 0–100.
static func percentile(values: Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var rank := clampi(ceili(clampf(p, 0.0, 100.0) / 100.0 * sorted.size()), 1, sorted.size())
	return float(sorted[rank - 1])


static func _col(doc: Dictionary, name: String) -> int:
	return (doc.get("samples_cols", []) as Array).find(name)


## Valores de uma coluna das amostras (opcionalmente só as não pausadas).
static func column(doc: Dictionary, name: String, skip_paused: bool = true) -> Array:
	var i := _col(doc, name)
	var p := _col(doc, "paused")
	var out := []
	if i < 0:
		return out
	for row in doc.get("samples", []):
		if skip_paused and p >= 0 and bool(row[p]):
			continue
		out.append(row[i])
	return out


static func _max(values: Array) -> float:
	var m := 0.0
	for v in values:
		if v is float or v is int:
			m = maxf(m, float(v))
	return m


static func _avg(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var s := 0.0
	for v in values:
		s += float(v)
	return s / values.size()


static func _first_last(doc: Dictionary, name: String) -> Array:
	var v := column(doc, name, false)
	return [0.0, 0.0] if v.is_empty() else [float(v[0]), float(v[-1])]


static func summarize(doc: Dictionary) -> Dictionary:
	var result: Dictionary = doc.get("result", {})
	var frames: Dictionary = doc.get("frames", {})
	var hist: Array = frames.get("hist_1ms", [])
	var count := int(frames.get("count", 0))
	var fps := column(doc, "fps")
	var events: Array = doc.get("events", [])
	var hitches: Array = doc.get("hitches", [])
	var errors: Array = doc.get("errors", [])

	var damage_total := 0
	var damage_hits := 0
	var damage_by := {}
	var upgrades := []
	var denied := 0
	var skills := {}
	var speed_changes := []
	var pauses := 0
	for e in events:
		match str(e.get("e", "")):
			"skill":
				var slot := str(int(e.get("slot", 0)))
				skills[slot] = int(skills.get(slot, 0)) + 1
			"velocidade":
				if e.get("de") != null: # de=null é a velocidade inicial (BRF-137), fora da lista de mudanças
					speed_changes.append([snappedf(float(e.get("t", 0)), 0.1), float(e.get("de", 1)), float(e.get("para", 1))])
			"pausa":
				pauses += 1
			"dano":
				var v := int(e.get("valor", 0))
				damage_total += v
				damage_hits += 1
				var src := str(e.get("fonte", "?"))
				damage_by[src] = int(damage_by.get(src, 0)) + v
			"dano_agg":
				var n := int(e.get("soma", 0))
				damage_total += n
				damage_hits += int(e.get("contagem", 0))
				var asrc := str(e.get("fonte", "?"))
				damage_by[asrc] = int(damage_by.get(asrc, 0)) + n
			"upgrade":
				upgrades.append("%s nv%d (%d)" % [e.get("id", ""), int(e.get("nivel", 0)), int(e.get("custo", 0))])
			"upgrade_negado":
				denied += 1

	var slow_seconds := []
	var t_i := _col(doc, "t")
	var n33_i := _col(doc, "n33")
	if t_i >= 0 and n33_i >= 0:
		for row in doc.get("samples", []):
			if float(row[n33_i]) > 0 and slow_seconds.size() < 40:
				slow_seconds.append(snappedf(float(row[t_i]), 0.1))
	var hitch_times := []
	for h in hitches:
		if hitch_times.size() < 40:
			hitch_times.append(snappedf(float(h.get("t", 0)), 0.1))
	var top := hitches.duplicate()
	top.sort_custom(func(a, b) -> bool: return float(a.get("ms", 0)) > float(b.get("ms", 0)))
	top = top.slice(0, TOP_HITCHES)

	var proj := []
	var pp := column(doc, "proj_player", false)
	var pe := column(doc, "proj_enemy", false)
	for i in mini(pp.size(), pe.size()):
		proj.append(float(pp[i]) + float(pe[i]))
	var mem := _first_last(doc, "mem_static_mb")
	var vmem := _first_last(doc, "mem_video_mb")
	var nodes := _first_last(doc, "nodes")
	var orphans := _first_last(doc, "orphans")
	var samples: Array = doc.get("samples", [])
	var duration := float(result.get("duration_s", 0.0))
	if duration <= 0.0 and not samples.is_empty() and t_i >= 0:
		duration = float(samples[-1][t_i])

	var err_by := {}
	for e in errors:
		var k := "%s/%s" % [e.get("fonte", ""), e.get("tipo", "")]
		err_by[k] = int(err_by.get(k, 0)) + 1
	var energy := column(doc, "energy", false)
	var hp_5s := []
	for i in range(0, energy.size(), 5):
		hp_5s.append(int(energy[i]))
	var out := {
		"duracao_s": snappedf(duration, 0.1),
		"resultado": str(result.get("resultado", "?")),
		"onda": int(result.get("onda", 0)),
		"ondas": int(result.get("ondas", 0)),
		"fps_medio": snappedf(_avg(fps), 0.1),
		"fps_min": snappedf(percentile(fps, 0.0), 0.1),
		"fps_p1": snappedf(percentile(fps, 1.0), 0.1),
		"fps_p5": snappedf(percentile(fps, 5.0), 0.1),
		"quadros": count,
		"quadro_ms_p50": FrameStats.hist_percentile(hist, count, 50.0),
		"quadro_ms_p95": FrameStats.hist_percentile(hist, count, 95.0),
		"quadro_ms_p99": FrameStats.hist_percentile(hist, count, 99.0),
		"quadro_ms_max": snappedf(float(frames.get("max_ms", 0.0)), 0.1),
		"travadas_33": int(frames.get("over_33", 0)),
		"travadas_50": int(frames.get("over_50", 0)),
		"travadas_100": int(frames.get("over_100", 0)),
		"segundos_com_33": slow_seconds,
		"travadas_50_em": hitch_times,
		"pico_inimigos": int(_max(column(doc, "enemies", false))),
		"pico_projeteis": int(_max(proj)),
		"pico_efeitos": int(_max(column(doc, "fx_live", false))),
		"pico_draw_calls": int(_max(column(doc, "draw_calls", false))),
		"memoria_mb": [snappedf(mem[0], 0.01), snappedf(mem[1], 0.01), snappedf(mem[1] - mem[0], 0.01)],
		"memoria_video_mb": [snappedf(vmem[0], 0.01), snappedf(vmem[1], 0.01), snappedf(vmem[1] - vmem[0], 0.01)],
		"nos": [int(nodes[0]), int(nodes[1]), int(nodes[1] - nodes[0])],
		"orfaos": [int(orphans[0]), int(orphans[1]), int(orphans[1] - orphans[0])],
		"dano_total": damage_total,
		"danos": damage_hits,
		"dano_por_fonte": damage_by,
		"upgrades": upgrades,
		"upgrades_negados": denied,
		"erros": errors.size(),
		"erros_por_tipo": err_by,
		"skills_usadas": skills,
		"mortes_por_tipo": result.get("mortes_por_tipo", {}),
		"velocidades": speed_changes,
		"velocidade_inicial": initial_speed(doc),
		"por_velocidade": by_speed(doc),
		"pausas": pauses,
		"energia_5s": hp_5s,
		"piores_quadros": doc.get("worst_frames", []),
		"erros_primeiros": errors.slice(0, FIRST_ERRORS).map(func(e) -> String: return "%s: %s" % [e.get("tipo", ""), e.get("msg", "")]),
		"maiores_travadas": top,
		"truncado": doc.get("truncated", {}),
	}
	var stress = doc.get("header", {}).get("stress")
	if stress is Array:
		out["estresse"] = _stress_summary(doc, stress, proj, fps, hist, count, frames)
	return out


## Velocidade (1 ou 2) com que a partida começou: evento inicial (de=null), senão `header.speed_initial`,
## senão a 1ª `time_scale` arredondada para 1/2 (log antigo), senão 1.
static func initial_speed(doc: Dictionary) -> int:
	for e in doc.get("events", []):
		if str(e.get("e", "")) == "velocidade" and e.get("de") == null:
			return 2 if float(e.get("para", 1)) >= 1.5 else 1
	var h: Dictionary = doc.get("header", {})
	if h.get("speed_initial") != null:
		return 2 if float(h.speed_initial) >= 1.5 else 1
	for v in column(doc, "time_scale", false):
		if is_equal_approx(float(v), 1.0) or is_equal_approx(float(v), 2.0):
			return int(roundf(float(v)))
	return 1


## fps por velocidade real (coluna `time_scale` de cada amostra; hit-stop e câmera lenta ficam de fora):
## {"1": {segundos, fps_medio, fps_min, quadro_p95_ms}, "2": {...}}. `quadro_p95_ms` = p95 dos ms médios por amostra.
static func by_speed(doc: Dictionary) -> Dictionary:
	var ts := _col(doc, "time_scale")
	var ti := _col(doc, "t")
	var fi := _col(doc, "fps")
	var mi := _col(doc, "ms_avg")
	var pi := _col(doc, "paused")
	var out := {}
	if ts < 0 or ti < 0 or fi < 0:
		return out
	var acc := {}
	var prev_t := 0.0
	for row in doc.get("samples", []):
		var t := float(row[ti])
		var dt := maxf(t - prev_t, 0.0)
		prev_t = t
		if pi >= 0 and bool(row[pi]):
			continue
		var sc := float(row[ts])
		var key := "1" if is_equal_approx(sc, 1.0) else ("2" if is_equal_approx(sc, 2.0) else "")
		if key == "":
			continue
		var a: Dictionary = acc.get(key, {"s": 0.0, "fps": [], "ms": []})
		a["s"] = float(a["s"]) + dt
		a["fps"].append(float(row[fi]))
		if mi >= 0:
			a["ms"].append(float(row[mi]))
		acc[key] = a
	for key in acc:
		var a: Dictionary = acc[key]
		out[key] = {"segundos": snappedf(float(a["s"]), 0.1), "fps_medio": snappedf(_avg(a["fps"]), 0.1),
			"fps_min": snappedf(percentile(a["fps"], 0.0), 0.1), "quadro_p95_ms": snappedf(percentile(a["ms"], 95.0), 0.1)}
	return out


## Métricas do período do modo de estresse (BRF-090). `params` = [inimigos, projéteis] pedidos.
static func _stress_summary(doc: Dictionary, params: Array, proj: Array, fps: Array, hist: Array,
		count: int, frames: Dictionary) -> Dictionary:
	var h: Dictionary = doc.get("header", {})
	var web: Dictionary = h.get("web", {})
	var vp: Dictionary = web.get("viewport", {})
	var draw := column(doc, "draw_calls", false)
	var nodes := column(doc, "nodes", false)
	var enemies := column(doc, "enemies", false)
	return {
		"parametros": "stress=%d,%d" % [int(params[0]), int(params[1])] + (" speed=%d" % int(h.get("speed")) if h.has("speed") and float(h.speed) > 1.0 else ""),
		"fps_medio": snappedf(_avg(fps), 0.1),
		"fps_min": snappedf(percentile(fps, 0.0), 0.1),
		"quadro_ms_p95": FrameStats.hist_percentile(hist, count, 95.0),
		"quadros_50ms": int(frames.get("over_50", 0)),
		"draw_calls": [snappedf(_avg(draw), 0.1), int(_max(draw))],
		"nos": [snappedf(_avg(nodes), 0.1), int(_max(nodes))],
		"inimigos": [snappedf(_avg(enemies), 0.1), int(_max(enemies))],
		"projeteis": [snappedf(_avg(proj), 0.1), int(_max(proj))],
		"dpr": web.get("dpr", null),
		"canvas": _canvas_size(vp, h),
	}


## [largura, altura] do canvas. O shell só informa [topo, base, altura]; a largura vem da janela.
static func _canvas_size(vp: Dictionary, h: Dictionary) -> Array:
	var c = vp.get("canvas")
	var inner = vp.get("inner")
	if c is Array and c.size() >= 3 and inner is Array and inner.size() >= 1 and float(inner[0]) > 0.0:
		return [float(inner[0]), float(c[2])]
	var w = h.get("window", [])
	return w if w is Array else []


## Resumo em 5 a 8 linhas para bater o olho no banco (BRF-136). Funciona com log antigo ou novo.
static func header_lines(doc: Dictionary) -> PackedStringArray:
	var s: Dictionary = doc.get("summary", {})
	if s.is_empty():
		s = summarize(doc)
	var h: Dictionary = doc.get("header", {})
	var run: Dictionary = h.get("run", {})
	var web: Dictionary = h.get("web", {})
	var env: Dictionary = h.get("env", {})
	var out := PackedStringArray()
	var tag := str(run.get("tag", ""))
	out.append("tag: %s · sessão %s · partida #%s · %s" % [tag if tag != "" else "(sem tag)", run.get("session_id", "?"),
		_i(run.get("run_index")), run.get("run_started_at", h.get("date", "?"))])
	var dev := str(h.get("os", ""))
	if web.is_empty():
		dev = "%s %s" % [h.get("platform", "?"), h.get("model", "")]
	elif dev.is_empty():
		dev = str(web.get("ua", "?")).left(60)
	out.append("aparelho: %s · %s núcleos · dpr %s · tela %s" % [dev, _s(env.get("cores", web.get("cores"))),
		_s(env.get("dpr", web.get("dpr"))), _s(env.get("inner", web.get("inner")))])
	var mode := str(env.get("display_mode", "")) if env.get("display_mode") != null else ("web" if not web.is_empty() else "nativo")
	out.append("modo: %s · v%s · %s" % [{"standalone": "PWA", "browser": "navegador"}.get(mode, mode), h.get("version", "?"),
		BuildInfo.label(BuildInfo.parse(h.get("build")))])
	var speeds: Array = s.get("velocidades", [])
	var stress = h.get("stress")
	out.append("velocidade: x%d inicial · %d mudanças · estresse: %s" % [int(s.get("velocidade_inicial", initial_speed(doc))),
		speeds.size(), "%d inimigos, %d proj" % [int(stress[0]), int(stress[1])] if stress is Array else "não"])
	var bs: Dictionary = s.get("por_velocidade", {})
	var per := []
	for k in ["1", "2"]:
		if bs.has(k):
			per.append("x%s %s fps (%ss)" % [k, bs[k].fps_medio, bs[k].segundos])
	out.append("fps médio %s%s · quadro p95 %s ms · p99 %s ms · >50 ms: %d" % [s.fps_medio,
		" (" + " · ".join(per) + ")" if per.size() > 1 or bs.has("2") else "", s.quadro_ms_p95, s.quadro_ms_p99, s.travadas_50])
	out.append("resultado: %s · onda %d/%d · %s · erros: %d · picos: %d inimigos, %d proj" % [s.resultado, s.onda,
		s.ondas, _time(float(s.duracao_s)), s.erros, s.pico_inimigos, s.pico_projeteis])
	var raf := _raf_line(h, doc.get("web_end", {}))
	if raf != "":
		out.append(raf)
	return out


## "cadência rAF: 30 Hz (possível Pouca Energia)" ou "60 Hz". Vazio fora da web. Usa início e fim da partida.
static func _raf_line(h: Dictionary, end: Dictionary) -> String:
	var env: Dictionary = h.get("env", {})
	if env.is_empty() and end.is_empty():
		return ""
	var a = env.get("raf_hz_inicio")
	var b = end.get("raf_hz_fim")
	var txt := "início %s · fim %s" % [("%d Hz" % roundi(a)) if a != null else "?", ("%d Hz" % roundi(b)) if b != null else "?"]
	if a != null and b != null and roundi(a) == roundi(b):
		txt = "%d Hz" % roundi(a)
	var suspect: bool = env.get("suspeita_30fps_cap") == true or end.get("suspeita_30fps_cap") == true
	return "cadência rAF: %s%s · tela %s Hz · max_fps %s" % [txt, " (possível Pouca Energia)" if suspect else "",
		_s(h.get("refresh_hz")), _s(h.get("max_fps"))]


static func _s(v: Variant) -> String:
	return "?" if v == null else str(v)


static func _i(v: Variant) -> String:
	return "?" if v == null else str(int(v))


## Conteúdo do campo `log` enviado: JSON `anima_log/1` com `resumo` (texto) em primeiro lugar, o
## mesmo documento do gravador e `upload` (o que foi cortado para caber). Nunca passa de `max_bytes`
## (UTF-8): corta amostras (1 a cada 2) e eventos (metade mais antiga) até caber. O doc original não muda.
static func upload_text(doc: Dictionary, max_bytes: int = UPLOAD_MAX_BYTES) -> String:
	var body := {"resumo": Array(header_lines(doc))} if not doc.is_empty() else {"resumo": ["sem log"]}
	body["format"] = doc.get("format", "anima_log/1")
	for k in doc:
		if k != "format":
			body[k] = doc[k]
	var info := {"samples_stride": 1, "events_dropped": 0, "limit_bytes": max_bytes}
	body["upload"] = info
	var text := JSON.stringify(body, "", false)
	var tries := 0
	while text.to_utf8_buffer().size() > max_bytes and tries < 12:
		tries += 1
		var samples: Array = body.get("samples", [])
		var events: Array = body.get("events", [])
		if samples.size() > 60 and tries % 2 == 1:
			var kept := []
			for i in range(0, samples.size(), 2):
				kept.append(samples[i])
			body["samples"] = kept
			info["samples_stride"] = int(info["samples_stride"]) * 2
		elif events.size() > 20:
			var half := events.size() / 2
			body["events"] = events.slice(half)
			info["events_dropped"] = int(info["events_dropped"]) + half
		else:
			body.erase("samples")
			info["samples_stride"] = 0
		text = JSON.stringify(body, "", false)
	return text


## Texto legível: RESUMO, linha do tempo e tabela compacta de amostras.
static func to_text(doc: Dictionary) -> String:
	var s: Dictionary = doc.get("summary", {})
	if s.is_empty():
		s = summarize(doc)
	var h: Dictionary = doc.get("header", {})
	var lines := PackedStringArray()
	lines.append("=== RESUMO DA PARTIDA ===")
	lines.append("Data: %s  ·  Godot %s  ·  versão %s" % [h.get("date", "?"), h.get("godot", "?"), h.get("version", "")])
	lines.append(BuildInfo.summary_line(BuildInfo.parse(h.get("build"))))
	var web: Dictionary = h.get("web", {})
	if not web.is_empty():
		lines.append("Navegador: %s" % web.get("ua", "?"))
		lines.append("GPU: %s / %s  ·  dpr %s  ·  tela %s  ·  %s" % [web.get("gl_vendor", "?"),
			web.get("gl_renderer", "?"), web.get("dpr", "?"), web.get("inner", "?"), web.get("orientation", "?")])
	else:
		lines.append("Plataforma: %s %s  ·  GPU %s" % [h.get("platform", "?"), h.get("model", ""), h.get("adapter", "?")])
	lines.append("Seed: %s  ·  efeitos reduzidos: %s" % [h.get("seed", "?"), "sim" if h.get("reduced_effects", false) else "não"])
	lines.append("")
	lines.append("Resultado: %s  ·  onda %d/%d  ·  duração %s" % [s.resultado, s.onda, s.ondas, _time(s.duracao_s)])
	lines.append("FPS: médio %s  ·  mín %s  ·  p1 %s  ·  p5 %s" % [s.fps_medio, s.fps_min, s.fps_p1, s.fps_p5])
	lines.append("Quadro (ms): p50 %s  ·  p95 %s  ·  p99 %s  ·  máx %s  (%d quadros)" % [s.quadro_ms_p50,
		s.quadro_ms_p95, s.quadro_ms_p99, s.quadro_ms_max, s.quadros])
	lines.append("Travadas: >33 ms %d  ·  >50 ms %d  ·  >100 ms %d" % [s.travadas_33, s.travadas_50, s.travadas_100])
	if not (s.travadas_50_em as Array).is_empty():
		lines.append("  >50 ms em (s): %s" % ", ".join((s.travadas_50_em as Array).map(str)))
	if not (s.segundos_com_33 as Array).is_empty():
		lines.append("  segundos com >33 ms: %s" % ", ".join((s.segundos_com_33 as Array).map(str)))
	lines.append("Picos: inimigos %d  ·  projéteis %d  ·  efeitos %d  ·  draw calls %d" % [s.pico_inimigos,
		s.pico_projeteis, s.pico_efeitos, s.pico_draw_calls])
	lines.append("Memória (MB): %s → %s (%+.2f)  ·  vídeo %s → %s (%+.2f)" % [s.memoria_mb[0], s.memoria_mb[1],
		s.memoria_mb[2], s.memoria_video_mb[0], s.memoria_video_mb[1], s.memoria_video_mb[2]])
	lines.append("Nós: %d → %d (%+d)  ·  órfãos %d → %d (%+d)" % [s.nos[0], s.nos[1], s.nos[2], s.orfaos[0],
		s.orfaos[1], s.orfaos[2]])
	for k in (s.get("por_velocidade", {}) as Dictionary):
		var v: Dictionary = s.por_velocidade[k]
		lines.append("Velocidade x%s: %s s · fps médio %s · mín %s · quadro p95 %s ms" % [k, v.segundos, v.fps_medio, v.fps_min, v.quadro_p95_ms])
	if s.has("estresse"):
		var e: Dictionary = s.estresse
		lines.append("ESTRESSE %s: fps médio %s · mín %s · p95 %s ms · quadros >50 ms %d · draw [méd,máx] %s · nós %s · inimigos %s · proj %s · dpr %s · canvas %s" % [
			e.parametros, e.fps_medio, e.fps_min, e.quadro_ms_p95, e.quadros_50ms, e.draw_calls, e.nos,
			e.inimigos, e.projeteis, e.dpr, e.canvas])
	lines.append("Dano recebido: %d em %d golpes  ·  por fonte: %s" % [s.dano_total, s.danos, JSON.stringify(s.dano_por_fonte)])
	lines.append("Upgrades: %s  ·  negados: %d" % [", ".join(s.upgrades) if not (s.upgrades as Array).is_empty() else "nenhum", s.upgrades_negados])
	lines.append("Erros capturados: %d" % s.erros)
	for e in s.erros_primeiros:
		lines.append("  · %s" % e)
	lines.append("Maiores travadas:")
	if (s.maiores_travadas as Array).is_empty():
		lines.append("  nenhuma > 50 ms")
	for t in s.maiores_travadas:
		lines.append("  %s ms em %s  ·  inimigos %d · proj %d/%d · efeitos %d · onda %d%s%s" % [t.get("ms"),
			_time(float(t.get("t", 0))), int(t.get("inimigos", 0)), int(t.get("proj_jogador", 0)),
			int(t.get("proj_inimigo", 0)), int(t.get("efeitos", 0)), int(t.get("onda", 0)),
			" · chefe" if t.get("chefe", false) else "", " · após gravação" if t.get("apos_gravacao", false) else ""])
	var trunc: Dictionary = s.get("truncado", {})
	var cut := []
	for k in trunc:
		if (trunc[k] is bool and trunc[k]) or ((trunc[k] is int or trunc[k] is float) and float(trunc[k]) > 0):
			cut.append("%s=%s" % [k, trunc[k]])
	if not cut.is_empty():
		lines.append("TRUNCADO (buffers cheios): %s" % ", ".join(cut))
	var rec: Dictionary = doc.get("recorder", {})
	lines.append("Gravador: %s µs/quadro (máx %s)  ·  %s gravações (máx %s ms)" % [rec.get("cost_us_avg", "?"),
		rec.get("cost_us_max", "?"), rec.get("saves", "?"), rec.get("save_ms_max", "?")])

	lines.append("")
	lines.append("=== LINHA DO TEMPO ===")
	var events: Array = doc.get("events", [])
	if events.size() > MAX_TIMELINE:
		lines.append("(mostrando os %d eventos mais recentes de %d; todos estão no .json)" % [MAX_TIMELINE, events.size()])
		events = events.slice(events.size() - MAX_TIMELINE)
	for e in events:
		lines.append(_event_line(e))
	var hitches: Array = doc.get("hitches", [])
	if not hitches.is_empty():
		lines.append("")
		lines.append("=== TRAVADAS > 50 ms ===")
		for t in hitches:
			lines.append("%s  %s ms  (desde a anterior %s s)" % [_time(float(t.get("t", 0))), t.get("ms"), t.get("desde_anterior_s")])
	var errors: Array = doc.get("errors", [])
	if not errors.is_empty():
		lines.append("")
		lines.append("=== ERROS ===")
		for e in errors:
			lines.append("%s  [%s/%s] %s %s" % [_time(float(e.get("t", 0))), e.get("fonte", ""), e.get("tipo", ""),
				e.get("msg", ""), e.get("onde", "")])

	lines.append("")
	lines.append("=== AMOSTRAS ===")
	lines.append("   t     fps  ms_med  ms_max >33 >50 draw  nós ini proj fx  mem  E    onda P     chefe")
	var rows: Array = doc.get("samples", [])
	if rows.size() > MAX_SAMPLE_ROWS:
		lines.append("(mostrando as %d amostras mais recentes de %d)" % [MAX_SAMPLE_ROWS, rows.size()])
		rows = rows.slice(rows.size() - MAX_SAMPLE_ROWS)
	var c := {}
	for name in ["t", "fps", "ms_avg", "ms_max", "n33", "n50", "draw_calls", "nodes", "enemies", "proj_player",
			"proj_enemy", "fx_live", "mem_static_mb", "energy", "wave", "particles", "boss_hp", "boss_def", "paused"]:
		c[name] = _col(doc, name)
	for r in rows:
		lines.append("%6.1f %5.1f %6.1f %7.1f %3d %3d %4d %5d %3d %4d %3d %5.1f %4d %3d %5d %s%s" % [
			_n(r, c.t), _n(r, c.fps), _n(r, c.ms_avg), _n(r, c.ms_max), int(_n(r, c.n33)), int(_n(r, c.n50)),
			int(_n(r, c.draw_calls)), int(_n(r, c.nodes)), int(_n(r, c.enemies)),
			int(_n(r, c.proj_player) + _n(r, c.proj_enemy)), int(_n(r, c.fx_live)), _n(r, c.mem_static_mb),
			int(_n(r, c.energy)), int(_n(r, c.wave)), int(_n(r, c.particles)),
			"" if _n(r, c.boss_hp) < 0 else "%d/%d" % [int(_n(r, c.boss_hp)), int(_n(r, c.boss_def))],
			" P" if c.paused >= 0 and bool(r[c.paused]) else ""])
	return "\n".join(lines)


static func _n(row: Array, i: int) -> float:
	if i < 0 or i >= row.size() or not (row[i] is float or row[i] is int):
		return 0.0
	return float(row[i])


static func _event_line(e: Dictionary) -> String:
	var rest := e.duplicate()
	rest.erase("t")
	rest.erase("e")
	return "%s  %-14s %s" % [_time(float(e.get("t", 0))), e.get("e", ""), JSON.stringify(rest) if not rest.is_empty() else ""]


static func _time(seconds: float) -> String:
	var tenths := int(round(seconds * 10.0)) ## arredonda o tempo todo (45.96 -> 46.0, não 45.0)
	var s := tenths / 10
	return "%02d:%02d.%d" % [s / 60, s % 60, tenths % 10]


## Nome base do arquivo: anima_log_AAAAMMDD_HHMMSS.
static func file_base(doc: Dictionary) -> String:
	var date := str(doc.get("header", {}).get("date", ""))
	if date.length() < 19:
		date = Time.get_datetime_string_from_system(false, true)
	# "AAAA-MM-DD HH:MM:SS" (hora local do aparelho)
	return "anima_log_%s_%s" % [date.substr(0, 10).replace("-", ""), date.substr(11, 8).replace(":", "")]
