class_name SessionInfo
extends RefCounted
## Identificação do ensaio e ambiente do navegador para o log (T-294, BRF-136; docs/debug.md §1).
## Tudo é opcional: fora da web (PC, editor, headless) os campos do navegador ficam ausentes/null.
## Nada aqui roda por quadro: leituras só no início e no fim da partida.

const TAG_MAX := 64
const JS_TAG := "(new URLSearchParams(location.search)).get('tag') || ''"
const JS_NOW := "performance.now()"
## Navegador, tela, hardware, conexão, carga e áudio. Campo que o navegador não expõe vira null.
const JS_ENV := """JSON.stringify((function(){
var n = function(v){ return v === undefined ? null : v; };
var o = {};
var mq = null; try { mq = window.matchMedia('(display-mode: standalone)').matches; } catch (e) {}
o.standalone_mq = n(mq); o.standalone_nav = n(navigator.standalone);
o.dpr = n(window.devicePixelRatio);
o.screen = [screen.width, screen.height]; o.inner = [window.innerWidth, window.innerHeight];
o.orientation = (screen.orientation && screen.orientation.type) || (window.innerHeight >= window.innerWidth ? 'portrait' : 'landscape');
o.cores = n(navigator.hardwareConcurrency); o.device_memory = n(navigator.deviceMemory);
var c = navigator.connection; o.connection = c ? {type: n(c.effectiveType), downlink: n(c.downlink), rtt: n(c.rtt), save_data: n(c.saveData)} : null;
o.language = n(navigator.language); o.online = n(navigator.onLine);
o.perf_now_ms = Math.round(performance.now());
try { var nav = performance.getEntriesByType('navigation')[0];
 o.nav = nav ? {response_end: Math.round(nav.responseEnd), dcl: Math.round(nav.domContentLoadedEventEnd), load: Math.round(nav.loadEventEnd)} : null; } catch (e) { o.nav = null; }
try { var rs = performance.getEntriesByType('resource'), tr = 0, en = 0, de = 0;
 for (var i = 0; i < rs.length; i++) { tr += rs[i].transferSize || 0; en += rs[i].encodedBodySize || 0; de += rs[i].decodedBodySize || 0; }
 o.resources = {count: rs.length, transfer_bytes: tr, encoded_bytes: en, decoded_bytes: de}; } catch (e) { o.resources = null; }
var ac = null, au = null; try { var A = window.__anima_audio || []; var c0 = A.length ? A[A.length - 1] : (window.GodotAudio && GodotAudio.ctx) || null;
 if (c0) { ac = c0.state; au = {count: A.length, state: c0.state, sample_rate: c0.sampleRate, base_latency: n(c0.baseLatency), output_latency: n(c0.outputLatency)}; } } catch (e) {}
o.audio_state = ac; o.audio_ctx = au;
o.raf_hz = window.__animaRaf ? window.__animaRaf.hz(1500) : null;
var L = window.__animaDbg && window.__animaDbg.life;
o.life = L ? {hidden_count: L.hidden_count, hidden_ms: Math.round(L.hidden_ms + (L.hidden_since === null ? 0 : performance.now() - L.hidden_since)),
 longest_hidden_ms: Math.round(L.longest), pagehide: L.pagehide, pageshow: L.pageshow, freeze: L.freeze, resume: L.resume,
 gl_lost: L.gl_lost, gl_restored: L.gl_restored, hooked_at_ms: Math.round(L.since)} : null;
return o; })())"""

static var _session_id := ""
static var _run_index := 0
static var _title_ms := -1.0
static var _tag_cache := ""
static var _tag_read := false


## Id aleatório por abertura do app (8 hex). Estável durante a sessão.
static func session_id() -> String:
	if _session_id.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		_session_id = "%08x" % (rng.randi() & 0x7fffffff)
	return _session_id


## Conta uma partida na sessão e devolve o número dela (1 = primeira).
static func next_run() -> int:
	_run_index += 1
	return _run_index


static func run_index() -> int:
	return _run_index


## Marca o início da cena de título (ms desde o início da página na web; do motor fora dela).
static func mark_title() -> void:
	if _title_ms < 0.0:
		_title_ms = now_ms()


static func title_ms() -> float:
	return _title_ms


## ms desde o início da página (`performance.now()`); fora da web, ms desde o início do motor.
static func now_ms() -> float:
	if OS.has_feature("web"):
		return float(JavaScriptBridge.eval(JS_NOW, true))
	return float(Time.get_ticks_msec())


## Texto livre de `?tag=` (web) ou `--tag=` (linha de comando); sem caracteres de controle, até 64.
static func tag() -> String:
	if not _tag_read:
		_tag_read = true
		var raw := ""
		if OS.has_feature("web"):
			raw = str(JavaScriptBridge.eval(JS_TAG, true))
		else:
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--tag="):
					raw = a.trim_prefix("--tag=")
		_tag_cache = clean_tag(raw)
	return _tag_cache


static func clean_tag(raw: String) -> String:
	var out := ""
	for i in raw.length():
		var c := raw.unicode_at(i)
		out += raw[i] if c >= 32 and c != 127 else " "
	return out.strip_edges().left(TAG_MAX)


## `2026-11-10T14:03:22Z` (UTC).
static func utc_now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"


## Dados do navegador agora. `{}` fora da web. Campos que o navegador não expõe vêm null.
static func web_snapshot() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var data = JSON.parse_string(str(JavaScriptBridge.eval(JS_ENV, true)))
	if not data is Dictionary:
		return {}
	var d: Dictionary = data
	var mq = d.get("standalone_mq")
	var nav = d.get("standalone_nav")
	d["display_mode"] = null if mq == null and nav == null else ("standalone" if (mq == true or nav == true) else "browser")
	return d


## Cadência atual do requestAnimationFrame (Hz, janela de 1,5 s), ou null (fora da web, sem gancho ou aba parada).
static func raf_hz() -> Variant:
	if not OS.has_feature("web"):
		return null
	var v = JavaScriptBridge.eval("window.__animaRaf ? __animaRaf.hz(1500) : null", true)
	return float(v) if v != null else null


## Cadência ~30 Hz (±4) com `Engine.max_fps == 0`: o navegador está limitando a 30 (Modo de Pouca Energia do iOS?).
static func suspect_30fps_cap(hz: Variant, max_fps: int) -> Variant:
	if hz == null:
		return null
	return max_fps == 0 and absf(float(hz) - 30.0) <= 4.0


## Estado do áudio do lado do Godot: desbloqueado, música tocando, vozes de SFX ativas, volumes e taxa de mixagem.
static func audio_info() -> Dictionary:
	var node := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Audio") if Engine.get_main_loop() is SceneTree else null
	if node == null:
		return {}
	return {"unlocked": node.get("unlocked"), "music_playing": node.call("is_music_playing"),
		"voices_playing": node.call("voices_playing"), "music_volume": node.get("music_volume"),
		"sfx_volume": node.get("sfx_volume"), "mix_rate": AudioServer.get_mix_rate()}


## Cabeçalho da identificação do ensaio (`header.run`).
static func run_info(started_at: String) -> Dictionary:
	return {"tag": tag(), "session_id": session_id(), "run_index": _run_index, "run_started_at": started_at}


## SO e navegador curtos a partir do user agent. Ex.: `iOS 17.2 · Safari 17.2`. Vazio se não souber.
static func ua_short(ua: String) -> String:
	if ua.is_empty():
		return ""
	return " · ".join(PackedStringArray([os_from_ua(ua), browser_from_ua(ua)].filter(func(s) -> bool: return s != "")))


static func os_from_ua(ua: String) -> String:
	var m := _rx(r"(?:iPhone OS|CPU OS|iPad.*? OS) (\d+)[_.](\d+)(?:[_.](\d+))?").search(ua)
	if m != null:
		return "iOS %s.%s" % [m.get_string(1), m.get_string(2)]
	m = _rx(r"Android (\d+(?:\.\d+)?)").search(ua)
	if m != null:
		return "Android " + m.get_string(1)
	m = _rx(r"Windows NT (\d+\.\d+)").search(ua)
	if m != null:
		return "Windows " + m.get_string(1)
	m = _rx(r"Mac OS X (\d+)[_.](\d+)").search(ua)
	if m != null:
		return "macOS %s.%s" % [m.get_string(1), m.get_string(2)]
	if ua.contains("Linux"):
		return "Linux"
	return ""


static func browser_from_ua(ua: String) -> String:
	for pair in [[r"(?:EdgiOS|Edg)/(\d+)", "Edge"], [r"(?:CriOS|Chrome)/(\d+)", "Chrome"], [r"(?:FxiOS|Firefox)/(\d+)", "Firefox"]]:
		var m := _rx(pair[0]).search(ua)
		if m != null:
			return "%s %s" % [pair[1], m.get_string(1)]
	var s := _rx(r"Version/(\d+(?:\.\d+)?).*Safari").search(ua)
	if s != null:
		return "Safari " + s.get_string(1)
	return "Safari" if ua.contains("Safari") else ""


static func _rx(pattern: String) -> RegEx:
	var r := RegEx.new()
	r.compile(pattern)
	return r
