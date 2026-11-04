class_name DebugSettings
extends RefCounted
## Estado do overlay de debug (docs/debug.md §4): desligado por padrão, salvo em `user://debug.cfg`.
## `?debug=1` na URL liga (e `?debug=0` desliga) e salva. Sem autoload: estado estático.

const DEFAULT_PATH := "user://debug.cfg"

static var path := DEFAULT_PATH
static var _loaded := false
static var _overlay := false


static func overlay_enabled() -> bool:
	_load()
	return _overlay


static func set_overlay_enabled(on: bool) -> void:
	_load()
	_overlay = on
	var cfg := ConfigFile.new()
	cfg.set_value("debug", "overlay", on)
	cfg.save(path)


static func toggle_overlay() -> void:
	set_overlay_enabled(not overlay_enabled())


## Esquece o estado carregado (testes ou troca de `path`).
static func reset() -> void:
	_loaded = false
	_overlay = false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		_overlay = bool(cfg.get_value("debug", "overlay", false))
	var param := url_param()
	if param == "1" or param == "0":
		set_overlay_enabled(param == "1")


## Valor de `debug` na query string (só na web), ou "".
static func url_param() -> String:
	if not OS.has_feature("web"):
		return ""
	var v = JavaScriptBridge.eval("(new URLSearchParams(location.search)).get('debug') || ''", true)
	return str(v) if v != null else ""
