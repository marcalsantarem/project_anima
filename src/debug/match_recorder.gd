class_name MatchRecorder
extends Node
## Gravador da partida (T-107, BRF-063; docs/debug.md). Criado pelo SceneFlow, sempre ligado.
## Só LÊ a Arena (sinais e API pública) e o HUD (`ui_pressed`). Nada sai do aparelho.
## Por quadro: só acumula o tempo do quadro (sem alocar). Amostras a cada 1 s (0,25 s com o chefe),
## eventos nos sinais, travadas > 50 ms, erros (Logger do Godot + gancho JS) e gravação em
## `user://logs/` a cada ~10 s e no fim. O resumo (LogReport) só é calculado no fim.

signal finished(doc: Dictionary)

const FORMAT := "anima_log/1"
const DEFAULT_DIR := "user://logs/"
const LAST_FILE := "last_match.json"
const PREV_FILE := "prev_match_%d.json"
const KEEP_PREVIOUS := 3
const SAMPLE_INTERVAL := 1.0
const SAMPLE_INTERVAL_BOSS := 0.25
const SAVE_INTERVAL := 10.0
const HITCH_MS := 50.0
const SLOW_MS := 33.0
const MAX_SAMPLES := 1500
const MAX_EVENTS := 3000
const MAX_HITCHES := 300
const MAX_ERRORS := 200
const MAX_BYTES := 1_000_000
const SAMPLE_COLS: Array[String] = [
	"t", "fps", "ms_avg", "ms_max", "n33", "n50", "proc_ms", "phys_ms", "draw_calls", "objects",
	"nodes", "orphans", "mem_static_mb", "mem_tex_mb", "mem_video_mb", "enemies", "enemies_by_type",
	"proj_player", "proj_enemy", "fx_live", "energy", "energy_max", "wave", "particles", "boss_hp",
	"boss_def", "paused",
]
const FX_TYPES: Array[StringName] = [
	&"fx_muzzle", &"fx_trail", &"fx_hit", &"fx_death", &"fx_pickup", &"fx_upgrade", &"fx_skill_cast",
	&"fx_telegraph", &"fx_core_pulse",
]
## Prefixos de linhas do console que o Logger do Godot já captura (evita duplicar na web).
const GODOT_CONSOLE_PREFIXES: Array[String] = [
	"ERROR:", "WARNING:", "USER ERROR:", "USER WARNING:", "SCRIPT ERROR:", "SHADER ERROR:", "   at:",
]
const JS_HOOK := """(function(){
if (window.__animaDbg) return;
var d = window.__animaDbg = {q: [], max: 200, dropped: 0};
function push(k, m){ if (d.q.length >= d.max) { d.dropped++; return; } d.q.push({k: k, m: String(m).slice(0, 400)}); }
['error','warn'].forEach(function(lv){ var orig = console[lv]; console[lv] = function(){
 try { push('console.' + lv, Array.prototype.map.call(arguments, String).join(' ')); } catch (e) {}
 return orig.apply(console, arguments); }; });
window.addEventListener('error', function(ev){ push('onerror', (ev.message || '') + ' @' + (ev.filename || '') + ':' + (ev.lineno || 0)); });
window.addEventListener('unhandledrejection', function(ev){ var r = ev.reason; push('unhandledrejection', r && (r.stack || r.message) || r); });
d.drain = function(){ var out = JSON.stringify({q: d.q, dropped: d.dropped}); d.q = []; d.dropped = 0; return out; };
})();"""
const JS_ENV := """JSON.stringify((function(){
var o = {ua: navigator.userAgent, dpr: window.devicePixelRatio, screen: [screen.width, screen.height],
 inner: [window.innerWidth, window.innerHeight], url: location.origin + location.pathname,
 orientation: (screen.orientation && screen.orientation.type) || (window.innerHeight >= window.innerWidth ? 'portrait' : 'landscape'),
 device_memory: navigator.deviceMemory || null, cores: navigator.hardwareConcurrency || null,
 build: window.ANIMA_BUILD || null,
 safe_area: window.animaGetSafeArea ? JSON.parse(animaGetSafeArea()) : null};
try { var c = document.createElement('canvas'); var gl = c.getContext('webgl2') || c.getContext('webgl');
 if (gl) { o.gl_version = gl.getParameter(gl.VERSION); var ext = gl.getExtension('WEBGL_debug_renderer_info');
  o.gl_vendor = gl.getParameter(ext ? ext.UNMASKED_VENDOR_WEBGL : gl.VENDOR);
  o.gl_renderer = gl.getParameter(ext ? ext.UNMASKED_RENDERER_WEBGL : gl.RENDERER);
  var lose = gl.getExtension('WEBGL_lose_context'); if (lose) lose.loseContext(); } } catch (e) { o.gl_error = String(e); }
return o; })())"""

## Pasta dos logs (testes trocam).
static var log_dir := DEFAULT_DIR
## Ambiente web lido uma vez por página (o contexto WebGL extra é criado só uma vez).
static var _web_env_cache: Dictionary = {}

## Grava em disco (testes de unidade desligam).
var save_enabled := true
## `_process` mede e chama `step` sozinho; testes desligam e chamam `step(ms)` em passos fixos.
var auto_process := true

var header := {}
var finished_ok := false
var log_data: Dictionary = {}
## Tempo de partida (s): soma dos quadros sem pausa.
var match_time := 0.0
var frames := FrameStats.new()
var samples := DebugRing.new(MAX_SAMPLES)
var events := DebugRing.new(MAX_EVENTS)
var hitches := DebugRing.new(MAX_HITCHES)
var errors := DebugRing.new(MAX_ERRORS)
## Último estado amostrado + quadro atual (para o overlay).
var live := {}
var last_frame_ms := 0.0

var cost_us_total := 0
var cost_us_max := 0
var cost_frames := 0
var saves := 0
var save_ms_max := 0.0
var js_errors_dropped := 0

var _arena: Node
var _fx_pool: Node
var _seed := -1
var _result := {}
var _paused := false
var _last_tick_us := 0
var _sample_left := SAMPLE_INTERVAL
var _kills_left := 1.0
var _save_left := SAVE_INTERVAL
var _saved_this_frame := false
var _since_hitch := 0.0
var _win_count := 0
var _win_sum := 0.0
var _win_max := 0.0
var _win_33 := 0
var _win_50 := 0
var _kills := {} # id → mortes no segundo atual
var _contacts := {} # id → inimigos que tocaram o Núcleo no segundo atual
var _recent_kills: Array = [] # [frame, pos] das mortes do quadro de física atual (meteoro)
var _wave := 0
var _waves_total := 0
var _particles := 0
var _hp := -1
var _hp_max := 0
var _boss_active := false
var _boss_hp := -1
var _boss_def := -1
var _boss_def_max := 0
var _boss_def_mark := 4 # quartos da defesa ainda não registrados como marco
var _upgrade_level := {}
var _upgrade_cost := {}
var _hint := ""
var _hint_frame := -1
var _last_damage: Dictionary = {}
var _last_damage_frame := -1
var _logger: RecorderLogger
var _js_visibility_cb: JavaScriptObject


## Liga o gravador à partida. Chamar antes de a Arena entrar na árvore.
func attach(arena: Node, hud: Node = null, _pause: Node = null, match_seed: int = -1) -> void:
	_arena = arena
	_seed = match_seed
	_fx_pool = arena.get_node_or_null(^"FxPool")
	_link(arena, &"wave_changed", _on_wave_changed)
	_link(arena, &"core_hp_changed", _on_core_hp_changed)
	_link(arena, &"particles_changed", func(total: int) -> void: _particles = total)
	_link(arena, &"upgrade_changed", _on_upgrade_changed)
	_link(arena, &"skill_used", func(slot: int) -> void: event("skill", {"slot": slot}))
	_link(arena, &"skill_cast", _on_skill_cast)
	_link(arena, &"enemy_died", _on_enemy_died)
	_link(arena, &"projectile_hit", _on_projectile_hit)
	_link(arena, &"boss_spawned", _on_boss_spawned)
	_link(arena, &"boss_hp_changed", func(c: int, _m: int) -> void: _boss_hp = c)
	_link(arena, &"boss_defense_changed", _on_boss_defense_changed)
	_link(arena, &"boss_launched", func(from: Vector2, to: Vector2) -> void:
		event("chefe_lancado", {"de": _v(from), "para": _v(to)}))
	_link(arena, &"boss_defeated", func() -> void:
		_boss_active = false
		event("chefe_derrotado"))
	_link(arena, &"match_ended", finish)
	if hud != null:
		_link(hud, &"ui_pressed", _on_ui_pressed)


func _link(source: Node, sig: StringName, cb: Callable) -> void:
	if source.has_signal(sig):
		source.connect(sig, cb)


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	set_process(auto_process)
	header = build_header()
	if save_enabled:
		MatchRecorder.rotate_files()
	_install_error_hooks()
	event("inicio", {"seed": _seed})


func _exit_tree() -> void:
	if not finished_ok:
		finish(null)
	_remove_error_hooks()


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	var ms := delta * 1000.0 if _last_tick_us == 0 else (t0 - _last_tick_us) / 1000.0
	_last_tick_us = t0
	step(ms, get_tree().paused)
	var cost := Time.get_ticks_usec() - t0
	cost_us_total += cost
	cost_frames += 1
	if cost > cost_us_max:
		cost_us_max = cost


## Um quadro de `ms` milissegundos. Quadros pausados não contam no tempo nem nas estatísticas.
func step(ms: float, paused: bool = false) -> void:
	if finished_ok:
		return
	if paused != _paused:
		_paused = paused
		event("pausa" if paused else "retomada")
	if paused:
		return
	var dt := ms / 1000.0
	match_time += dt
	_since_hitch += dt
	last_frame_ms = ms
	frames.add(ms)
	_win_count += 1
	_win_sum += ms
	_win_max = maxf(_win_max, ms)
	if ms > SLOW_MS:
		_win_33 += 1
		if ms > HITCH_MS:
			_win_50 += 1
			_hitch(ms)
	_saved_this_frame = false
	if not header.has("stress"):
		_detect_stress()
	_kills_left -= dt
	if _kills_left <= 0.0:
		_kills_left = maxf(_kills_left + 1.0, 0.0)
		_flush_kills()
	_sample_left -= dt
	if _sample_left <= 0.0:
		_sample()
		var interval := SAMPLE_INTERVAL_BOSS if _boss_active else SAMPLE_INTERVAL
		_sample_left = maxf(_sample_left + interval, 0.0)
	_save_left -= dt
	if _save_left <= 0.0:
		_save_left = SAVE_INTERVAL
		save_now()


## Evento com tempo de partida. `data` vira campos do evento.
func event(type: String, data: Dictionary = {}) -> void:
	var e := {"t": snappedf(match_time, 0.001), "e": type}
	e.merge(data)
	events.push(e)


# --- Sinais ---

func _on_wave_changed(current: int, total: int) -> void:
	_wave = current
	_waves_total = total
	event("onda", {"onda": current, "total": total})


func _on_core_hp_changed(current: int, max_hp: int) -> void:
	if _hp >= 0 and current < _hp:
		var frame := Engine.get_physics_frames()
		var source := _hint if _hint_frame == frame else "?"
		_last_damage = {"t": snappedf(match_time, 0.001), "e": "dano", "valor": _hp - current,
			"fonte": source, "energia": current, "energia_max": max_hp}
		_last_damage_frame = frame
		events.push(_last_damage)
	elif max_hp != _hp_max and _hp >= 0:
		event("energia_max", {"energia": current, "energia_max": max_hp})
	_hp = current
	_hp_max = max_hp


## Fonte do dano: o sinal pode vir antes ou depois da queda de Energia no mesmo quadro de física.
func _damage_hint(source: String) -> void:
	var frame := Engine.get_physics_frames()
	_hint = source
	_hint_frame = frame
	if _last_damage_frame == frame and _last_damage.get("fonte") == "?":
		_last_damage["fonte"] = source


func _on_projectile_hit(_at: Vector2, target_kind: StringName) -> void:
	if target_kind == &"core":
		_damage_hint("projetil_inimigo")


func _on_enemy_died(at: Vector2, archetype_id: StringName, cause: int) -> void:
	var id := String(archetype_id)
	if cause == 1: # Enemy.DeathCause.CONTACT
		_contacts[id] = int(_contacts.get(id, 0)) + 1
		_damage_hint("contato:" + id)
		return
	_kills[id] = int(_kills.get(id, 0)) + 1
	var frame := Engine.get_physics_frames()
	if not _recent_kills.is_empty() and _recent_kills[0][0] != frame:
		_recent_kills.clear()
	_recent_kills.append([frame, at])


func _on_upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int) -> void:
	var prev := int(_upgrade_level.get(id, level))
	if level > prev:
		event("upgrade", {"id": String(id), "nivel": level, "max": max_level,
			"custo": int(_upgrade_cost.get(id, -1)), "particulas_restantes": _arena_int(&"particles", _particles)})
	_upgrade_level[id] = level
	_upgrade_cost[id] = next_cost


func _on_ui_pressed(button: StringName, ok: bool) -> void:
	event("toque", {"botao": String(button), "ok": ok})
	if not ok and _upgrade_cost.has(button):
		event("upgrade_negado", {"id": String(button), "custo": int(_upgrade_cost[button]),
			"particulas": _arena_int(&"particles", _particles)})


func _on_skill_cast(slot: int, at: Vector2, radius: float) -> void:
	var hits := 0
	var boss_hit := false
	var enemies = _arena_prop(&"active_enemies")
	if enemies is Array:
		for enemy in enemies:
			if is_instance_valid(enemy) and GroundPlane.distance(enemy.position, at) <= radius + 1.0:
				hits += 1
				if enemy is Boss:
					boss_hit = true
	var frame := Engine.get_physics_frames()
	for k in _recent_kills:
		if k[0] == frame and GroundPlane.distance(k[1], at) <= radius + 1.0:
			hits += 1
	var skill_id := ""
	var skills = _arena_prop(&"skills")
	if skills is SkillController and skills.get_slot(slot) != null:
		skill_id = String(skills.get_slot(slot).data.id)
	event("meteoro" if skill_id.contains("meteor") else "skill_impacto", {"slot": slot, "skill": skill_id,
		"alvo": _v(at), "raio": snappedf(radius, 0.1), "atingidos": hits, "chefe": boss_hit})


func _on_boss_spawned(id: StringName) -> void:
	_boss_active = true
	_sample_left = minf(_sample_left, SAMPLE_INTERVAL_BOSS)
	event("chefe", {"id": String(id)})
	var enemies = _arena_prop(&"active_enemies")
	if enemies is Array:
		for enemy in enemies:
			if enemy is Boss and not enemy.attack_landed.is_connected(_on_boss_attack):
				enemy.attack_landed.connect(_on_boss_attack)


func _on_boss_attack(_damage: int) -> void:
	_damage_hint("chefe")


## Marcos da defesa do chefe: início, cada quarto perdido, zero e recarga.
func _on_boss_defense_changed(current: int, max_defense: int) -> void:
	var first := _boss_def < 0
	var refill := not first and current > _boss_def
	_boss_def = current
	_boss_def_max = max_defense
	var quarter := ceili(4.0 * current / maxf(max_defense, 1.0))
	if first or refill:
		_boss_def_mark = quarter
		event("chefe_defesa", {"defesa": current, "max": max_defense})
	elif quarter < _boss_def_mark:
		_boss_def_mark = quarter
		event("chefe_defesa", {"defesa": current, "max": max_defense})


# --- Quadro, amostras e travadas ---

func _hitch(ms: float) -> void:
	hitches.push({"t": snappedf(match_time, 0.001), "ms": snappedf(ms, 0.1),
		"desde_anterior_s": snappedf(_since_hitch, 0.01), "inimigos": _enemy_count(),
		"proj_jogador": _pool_count(&"projectiles"), "proj_inimigo": _pool_count(&"enemy_projectiles"),
		"efeitos": _fx_live(), "onda": _wave, "chefe": _boss_active, "apos_gravacao": _saved_this_frame})
	_since_hitch = 0.0


func _flush_kills() -> void:
	if not _kills.is_empty():
		event("mortes", {"por_tipo": _kills})
		_kills = {}
	if not _contacts.is_empty():
		event("contatos", {"por_tipo": _contacts})
		_contacts = {}


func _sample() -> void:
	var by_type := {}
	var enemies = _arena_prop(&"active_enemies")
	if enemies is Array:
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.get(&"data") != null:
				var id := String(enemy.data.id)
				by_type[id] = int(by_type.get(id, 0)) + 1
	var avg := _win_sum / _win_count if _win_count > 0 else 0.0
	var mb := 1.0 / 1048576.0
	var row := [
		# FPS medido na janela (quadros / tempo real deles): vale também em passos fixos.
		snappedf(match_time, 0.01), snappedf(1000.0 / avg if avg > 0.0 else 0.0, 0.1), snappedf(avg, 0.01),
		snappedf(_win_max, 0.01), _win_33, _win_50,
		snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
		snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) * mb, 0.01),
		snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) * mb, 0.01),
		snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) * mb, 0.01),
		_enemy_count(), by_type, _pool_count(&"projectiles"), _pool_count(&"enemy_projectiles"), _fx_live(),
		_hp, _hp_max, _wave, _arena_int(&"particles", _particles), _boss_hp if _boss_active else -1,
		_boss_def if _boss_active else -1, _paused,
	]
	samples.push(row)
	for i in SAMPLE_COLS.size():
		live[SAMPLE_COLS[i]] = row[i]
	_win_count = 0
	_win_sum = 0.0
	_win_max = 0.0
	_win_33 = 0
	_win_50 = 0
	_drain_errors()


func _enemy_count() -> int:
	var enemies = _arena_prop(&"active_enemies")
	return enemies.size() if enemies is Array else 0


func _pool_count(prop: StringName) -> int:
	var pool = _arena_prop(prop)
	return pool.active_count() if pool != null and pool.has_method(&"active_count") else 0


func _fx_live() -> int:
	if _fx_pool == null or not is_instance_valid(_fx_pool):
		return 0
	var n := 0
	for type in FX_TYPES:
		n += _fx_pool.active_count(type)
	return n


func _arena_int(prop: StringName, fallback: int) -> int:
	var v = _arena_prop(prop)
	return int(v) if v != null else fallback


## Propriedade pública da Arena, ou null (Arena ausente ou já liberada).
func _arena_prop(prop: StringName) -> Variant:
	if _arena == null or not is_instance_valid(_arena):
		return null
	return _arena.get(prop)


static func _v(p: Vector2) -> Array:
	return [roundi(p.x), roundi(p.y)]


# --- Erros ---

func _install_error_hooks() -> void:
	if OS.has_method(&"add_logger") and ClassDB.class_exists(&"Logger"):
		_logger = RecorderLogger.new()
		OS.add_logger(_logger)
		header["godot_logger"] = true
	else:
		header["godot_logger"] = false
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_HOOK, true)
		_js_visibility_cb = JavaScriptBridge.create_callback(_on_web_visibility)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _js_visibility_cb)


func _remove_error_hooks() -> void:
	if _logger != null:
		OS.remove_logger(_logger)
		_logger = null
	if _js_visibility_cb != null:
		JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange", _js_visibility_cb)
		_js_visibility_cb = null


func _on_web_visibility(_args: Array) -> void:
	event("aba_oculta" if JavaScriptBridge.eval("document.hidden", true) else "aba_visivel")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		event("foco_perdido")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		event("foco_voltou")


## Junta os erros pendentes (Logger, de qualquer thread, e console da página).
func _drain_errors() -> void:
	if _logger != null:
		for e in _logger.drain():
			e["t"] = snappedf(match_time, 0.001)
			errors.push(e)
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("window.__animaDbg ? __animaDbg.drain() : ''", true)
		var data = JSON.parse_string(str(raw)) if raw else null
		if data is Dictionary:
			js_errors_dropped += int(data.get("dropped", 0))
			for item in data.get("q", []):
				var msg := str(item.get("m", ""))
				if _logger != null and _is_godot_line(msg):
					continue
				errors.push({"t": snappedf(match_time, 0.001), "fonte": "js", "tipo": str(item.get("k", "")), "msg": msg})


static func _is_godot_line(msg: String) -> bool:
	for p in GODOT_CONSOLE_PREFIXES:
		if msg.begins_with(p):
			return true
	return false


# --- Fim, cabeçalho e arquivo ---

## Fecha o log (idempotente). `result` = MatchResult, ou null se a partida foi interrompida.
func finish(result = null) -> void:
	if finished_ok:
		return
	_detect_stress()
	_flush_kills()
	_sample()
	if result != null:
		_result = {
			"resultado": "estresse" if header.has("stress") else (
				"vitoria" if result.outcome == MatchResult.Outcome.VICTORY else "derrota"),
			"onda": result.wave_reached, "ondas": result.waves_total, "particulas": result.particles,
			"inimigos": result.enemies_killed, "duracao_s": snappedf(result.duration_s, 0.01),
		}
	else:
		_result = {"resultado": "interrompida", "onda": _wave, "ondas": _waves_total,
			"duracao_s": snappedf(match_time, 0.01)}
	event("fim", _result.duplicate())
	finished_ok = true
	log_data = build_log(true)
	if save_enabled:
		_write(log_data)
	_remove_error_hooks()
	finished.emit(log_data)


## Modo de estresse ativo (nó StressMode na Arena): guarda `stress=N,M` no cabeçalho (BRF-090).
func _detect_stress() -> void:
	if header.has("stress") or _arena == null:
		return
	var node := _arena.get_node_or_null(^"StressMode")
	if node != null:
		header["stress"] = [int(node.get("enemy_target")), int(node.get("projectile_target"))]


func build_log(with_summary: bool) -> Dictionary:
	var doc := {
		"format": FORMAT,
		"header": header,
		"result": _result,
		"frames": frames.to_dict(),
		"samples_cols": SAMPLE_COLS,
		"samples": samples.to_array(),
		"events": events.to_array(),
		"hitches": hitches.to_array(),
		"errors": errors.to_array(),
		"truncated": {"samples": samples.dropped, "events": events.dropped, "hitches": hitches.dropped,
			"errors": errors.dropped, "js_errors": js_errors_dropped, "size_limit": false},
		"recorder": {
			"cost_us_avg": snappedf(float(cost_us_total) / cost_frames, 0.1) if cost_frames > 0 else 0.0,
			"cost_us_max": cost_us_max, "saves": saves, "save_ms_max": snappedf(save_ms_max, 0.01),
		},
	}
	if with_summary:
		doc["summary"] = LogReport.summarize(doc)
	return doc


## Grava o estado atual em `last_match.json` (a cada ~10 s; no fim vai com o resumo).
func save_now() -> void:
	if not save_enabled:
		return
	_write(build_log(false))


func _write(doc: Dictionary) -> void:
	var t0 := Time.get_ticks_usec()
	var text := MatchRecorder.to_json_limited(doc)
	DirAccess.make_dir_recursive_absolute(log_dir)
	var f := FileAccess.open(log_dir.path_join(LAST_FILE), FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	saves += 1
	_saved_this_frame = true
	save_ms_max = maxf(save_ms_max, (Time.get_ticks_usec() - t0) / 1000.0)


## JSON com no máximo MAX_BYTES: se passar, descarta a metade mais antiga de amostras e eventos e anota.
static func to_json_limited(doc: Dictionary, max_bytes: int = MAX_BYTES) -> String:
	var text := JSON.stringify(doc)
	var tries := 0
	while text.length() > max_bytes and tries < 6:
		tries += 1
		for key in ["samples", "events"]:
			var arr: Array = doc[key]
			doc[key] = arr.slice(arr.size() / 2)
			doc["truncated"][key] = int(doc["truncated"].get(key, 0)) + arr.size() - doc[key].size()
		doc["truncated"]["size_limit"] = true
		text = JSON.stringify(doc)
	return text


func build_header() -> Dictionary:
	var vp := get_viewport()
	var h := {
		"game": ProjectSettings.get_setting("application/config/name", ""),
		"version": BuildInfo.version(),
		"godot": Engine.get_version_info().string,
		"date": Time.get_datetime_string_from_system(false, true),
		"unix": Time.get_unix_time_from_system(),
		"platform": OS.get_name(),
		"model": OS.get_model_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"screen": _v(Vector2(DisplayServer.screen_get_size())),
		"window": _v(Vector2(DisplayServer.window_get_size())),
		"viewport": _v(vp.get_visible_rect().size) if vp else [],
		"safe_area": _rect(Rect2(DisplayServer.get_display_safe_area())),
		"cores": OS.get_processor_count(),
		"reduced_effects": bool(_fx_pool.get(&"reduced_effects")) if _fx_pool else false,
		"seed": _seed,
		"build": BuildInfo.current().duplicate(),
	}
	if vp:
		var ui := ScreenKit.safe_area(vp)
		h["ui_insets"] = {"top": roundi(ui.top), "bottom": roundi(ui.bottom), "bottom_raw": roundi(ui.bottom_raw),
			"left": roundi(ui.left), "right": roundi(ui.right), "css_k": snappedf(ui.css_k, 0.001),
			"covers_bottom": ui.covers_bottom}
	if OS.has_feature("web"):
		h["web"] = MatchRecorder.web_env().duplicate()
		h["web"]["viewport"] = MatchRecorder.web_viewport()
	return h


static func _rect(r: Rect2) -> Array:
	return [roundi(r.position.x), roundi(r.position.y), roundi(r.size.x), roundi(r.size.y)]


## Ambiente do navegador (user agent, tela, WebGL…). Lido uma vez por página.
static func web_env() -> Dictionary:
	if _web_env_cache.is_empty() and OS.has_feature("web"):
		var data = JSON.parse_string(str(JavaScriptBridge.eval(JS_ENV, true)))
		_web_env_cache = data if data is Dictionary else {"error": "sem dados"}
	return _web_env_cache


## Medidas do viewport do shell (animaViewportInfo, T-172), lidas na hora (mudam com a barra do Safari).
static func web_viewport() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var raw = JavaScriptBridge.eval("window.animaViewportInfo ? animaViewportInfo() : ''", true)
	var data = JSON.parse_string(str(raw)) if raw else null
	return data if data is Dictionary else {}


## Linhas curtas do viewport para o overlay ?debug=1 (mesmos números do cabeçalho). Vazio fora da web.
static func viewport_lines(v: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if v.is_empty():
		return out
	var vv: Array = v.get("vv") if v.get("vv") is Array else [0, 0, 0, 1]
	var c: Array = v.get("canvas", [0, 0, 0])
	var sa: Dictionary = v.get("safe", {})
	var inner: Array = v.get("inner", [0, 0])
	var scr: Array = v.get("screen", [0, 0])
	out.append("in %sx%s app %s out %s cli %s" % [_n(inner[0]), _n(inner[1]), _n(v.get("app_h")),
		_n(v.get("outer_h")), _n(v.get("client_h"))])
	out.append("vv %sx%s +%s s%s scr %sx%s" % [_n(vv[0]), _n(vv[1]), _n(vv[2]), _n(vv[3]), _n(scr[0]), _n(scr[1])])
	out.append("svh %s dvh %s lvh %s %s" % [_n(v.get("svh")), _n(v.get("dvh")), _n(v.get("lvh")),
		"standalone" if v.get("standalone") else "aba"])
	out.append("cv %s..%s h%s safe %s/%s cobre %s" % [_n(c[0]), _n(c[1]), _n(c[2]), _n(sa.get("top", 0)),
		_n(sa.get("bottom", 0)), "sim" if sa.get("covers_bottom", false) else "não"])
	return out


static func _n(v: Variant) -> String:
	if v == null:
		return "-"
	var f := float(v)
	return str(int(f)) if is_equal_approx(f, roundf(f)) else str(snappedf(f, 0.1))


## Antes de cada partida: last → prev_1 → prev_2 → prev_3 (o mais antigo sai).
static func rotate_files() -> void:
	var dir := log_dir
	if not FileAccess.file_exists(dir.path_join(LAST_FILE)):
		return
	var oldest := dir.path_join(PREV_FILE % KEEP_PREVIOUS)
	if FileAccess.file_exists(oldest):
		DirAccess.remove_absolute(oldest)
	for i in range(KEEP_PREVIOUS - 1, 0, -1):
		var from := dir.path_join(PREV_FILE % i)
		if FileAccess.file_exists(from):
			DirAccess.rename_absolute(from, dir.path_join(PREV_FILE % (i + 1)))
	DirAccess.rename_absolute(dir.path_join(LAST_FILE), dir.path_join(PREV_FILE % 1))


static func has_last_log() -> bool:
	return FileAccess.file_exists(log_dir.path_join(LAST_FILE))


## Log salvo da última partida (com resumo calculado se faltar), ou {}.
static func load_last() -> Dictionary:
	var path := log_dir.path_join(LAST_FILE)
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return {}
	if not data.has("summary"):
		data["summary"] = LogReport.summarize(data)
	return data


## Logger do Godot (4.5+): chamado de qualquer thread, por isso a fila com Mutex.
class RecorderLogger:
	extends Logger
	const MAX_PENDING := 200
	const TYPES := ["error", "warning", "script", "shader"]
	var _mutex := Mutex.new()
	var _pending: Array = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		if _pending.size() < MAX_PENDING:
			_pending.append({"fonte": "godot", "tipo": TYPES[clampi(error_type, 0, 3)],
				"msg": (rationale if rationale != "" else code).left(400),
				"onde": "%s:%d %s" % [file.get_file(), line, function]})
		_mutex.unlock()

	func _log_message(message: String, error: bool) -> void:
		if not error:
			return
		_mutex.lock()
		if _pending.size() < MAX_PENDING:
			_pending.append({"fonte": "godot", "tipo": "stderr", "msg": message.strip_edges().left(400)})
		_mutex.unlock()

	func drain() -> Array:
		_mutex.lock()
		var out := _pending
		_pending = []
		_mutex.unlock()
		return out
