class_name BuildInfo
extends RefCounted
## Versão e build do jogo (T-165; docs/debug.md §7). O deploy injeta `window.ANIMA_BUILD` no index.html
## (web/inject_build.sh); fora dele (export local, editor) não há objeto e o build vale "dev local".

## Versão usada quando `application/config/version` não existe no project.godot. Guardada e enviada
## sem o `v` (ex. `0.2.1`, contrato de docs/logs-api.md); o `v` só entra na exibição (pause_text).
const DEFAULT_VERSION := "0.2.1"
const LOCAL_LABEL := "dev local"
const KEYS := ["sha", "sha_full", "branch", "built_at", "run"]
const JS_READ := "JSON.stringify(window.ANIMA_BUILD || null)"

static var _cache: Dictionary = {}


## Versão do jogo: a do project.godot, se houver; senão DEFAULT_VERSION.
static func version() -> String:
	var v := str(ProjectSettings.get_setting("application/config/version", ""))
	return v if not v.is_empty() else DEFAULT_VERSION


## Normaliza o objeto injetado (ou null/lixo) em {sha, sha_full, branch, built_at, run, local}.
static func parse(data) -> Dictionary:
	var out := {"sha": "", "sha_full": "", "branch": "", "built_at": "", "run": "", "local": true}
	if not (data is Dictionary):
		return out
	for k in KEYS:
		var v = data.get(k)
		out[k] = "" if v == null else str(v).strip_edges()
	if out.run.ends_with(".0"):
		out.run = out.run.trim_suffix(".0")
	if out.sha.is_empty() and out.sha_full.length() >= 7:
		out.sha = out.sha_full.left(7)
	out.local = out.sha.is_empty()
	return out


## Build atual (lido uma vez por página na web; fora dela, sempre local).
static func current() -> Dictionary:
	if _cache.is_empty():
		var data = null
		if OS.has_feature("web"):
			data = JSON.parse_string(str(JavaScriptBridge.eval(JS_READ, true)))
		_cache = parse(data)
	return _cache


## Rótulo curto: o SHA curto ou "dev local".
static func label(b: Dictionary) -> String:
	return LOCAL_LABEL if b.get("local", true) else str(b.get("sha", ""))


## Linha do resumo: `Build: <sha> (<branch>) · <data> · exec #<n>` ou `Build: dev local`.
static func summary_line(b: Dictionary) -> String:
	if b.get("local", true):
		return "Build: %s" % LOCAL_LABEL
	return "Build: %s (%s) · %s · exec #%s" % [b.get("sha", ""), b.get("branch", "?"), b.get("built_at", "?"),
		b.get("run", "?")]


## Texto da tela inicial e da pausa: `v0.2.1 · <sha>` (ou `v0.2.1 · dev local`).
static func pause_text(b: Dictionary, ver: String) -> String:
	return "v%s · %s" % [ver, label(b)]
