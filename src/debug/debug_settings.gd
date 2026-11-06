class_name DebugSettings
extends RefCounted
## Estado do overlay de debug (docs/debug.md §4): desligado por padrão, salvo em `user://debug.cfg`.
## `?debug=1` na URL liga (e `?debug=0` desliga) e salva. Sem autoload: estado estático.
## Também guarda a opção "Efeitos reduzidos" (T-132, BRF-080; seção `[fx]`), desligada por padrão.

const DEFAULT_PATH := "user://debug.cfg"

static var path := DEFAULT_PATH
static var _loaded := false
static var _overlay := false
static var _reduced_effects := false


static func overlay_enabled() -> bool:
	_load()
	return _overlay


static func set_overlay_enabled(on: bool) -> void:
	_load()
	_overlay = on
	_save()


static func reduced_effects() -> bool:
	_load()
	return _reduced_effects


static func set_reduced_effects(on: bool) -> void:
	_load()
	_reduced_effects = on
	_save()


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("debug", "overlay", _overlay)
	cfg.set_value("fx", "reduced_effects", _reduced_effects)
	cfg.save(path)


static func toggle_overlay() -> void:
	set_overlay_enabled(not overlay_enabled())


## Esquece o estado carregado (testes ou troca de `path`).
static func reset() -> void:
	_loaded = false
	_overlay = false
	_reduced_effects = false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		_overlay = bool(cfg.get_value("debug", "overlay", false))
		_reduced_effects = bool(cfg.get_value("fx", "reduced_effects", false))
	var param := url_param()
	if param == "1" or param == "0":
		set_overlay_enabled(param == "1")


## Teste: null = usa a URL real; true/false simula a query com/sem `debug`.
static var query_has_debug_override = null


## Se a UI de debug (interruptor da pausa) deve aparecer: fora da web sempre; na web só com `?debug` (qualquer valor).
static func debug_ui_available() -> bool:
	if query_has_debug_override != null:
		return bool(query_has_debug_override)
	if not OS.has_feature("web"):
		return true
	return bool(JavaScriptBridge.eval("(new URLSearchParams(location.search)).has('debug')", true))


## Valor de `debug` na query string (só na web), ou "".
static func url_param() -> String:
	if not OS.has_feature("web"):
		return ""
	var v = JavaScriptBridge.eval("(new URLSearchParams(location.search)).get('debug') || ''", true)
	return str(v) if v != null else ""
