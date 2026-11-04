class_name DebugOverlay
extends CanvasLayer
## Overlay de debug (T-107; docs/debug.md §4): painel translúcido no canto superior esquerdo, abaixo do
## HUD, que ignora toques. Lê o MatchRecorder 4×/s. Liga por `?debug=1`, F3 (action `debug_toggle`) ou
## pelo interruptor "Debug" da pausa (DebugSettings, salvo em user://). Desligado por padrão.

const UPDATE_INTERVAL := 0.25
const FONT_SIZE := 18

var recorder: MatchRecorder
## Fornece o topo livre (abaixo do HUD de cima), em px da resolução base. Opcional.
var top_provider: Callable
var label: Label

var _panel: PanelContainer
var _left := 0.0


func setup(p_recorder: MatchRecorder, hud: Node = null) -> void:
	recorder = p_recorder
	if hud != null and hud.has_method(&"top_inset"):
		top_provider = Callable(hud, &"top_inset")


func _ready() -> void:
	layer = 15
	process_mode = PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.03, 0.1, 0.6)
	box.set_corner_radius_all(UiTokens.RADIUS_S)
	box.set_content_margin_all(UiTokens.SPACE_XS)
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	label.add_theme_constant_override("outline_size", 0)
	_panel.add_child(label)
	_apply_visibility()
	refresh()


func _process(delta: float) -> void:
	_apply_visibility()
	if not _panel.visible:
		return
	_left -= delta
	if _left <= 0.0:
		_left = UPDATE_INTERVAL
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle") and not event.is_echo():
		DebugSettings.toggle_overlay()
		_apply_visibility()
		refresh()


func _apply_visibility() -> void:
	var on := DebugSettings.overlay_enabled()
	if _panel.visible != on:
		_panel.visible = on


## Atualiza o texto e a posição (também chamado pelos testes).
func refresh() -> void:
	var top := UiTokens.SPACE_S * 1.0
	if top_provider.is_valid():
		top = float(top_provider.call()) + UiTokens.SPACE_XS
	_panel.position = Vector2(UiTokens.SPACE_XS, top)
	if recorder == null:
		label.text = "debug: sem gravador"
		return
	var s := recorder.live
	var lines := PackedStringArray()
	lines.append("FPS %s  ms %.1f / máx %.1f" % [s.get("fps", 0), recorder.last_frame_ms, float(s.get("ms_max", 0.0))])
	lines.append("ini %d  proj %d/%d  fx %d" % [int(s.get("enemies", 0)), int(s.get("proj_player", 0)),
		int(s.get("proj_enemy", 0)), int(s.get("fx_live", 0))])
	lines.append("draw %d  nós %d  mem %.1f MB" % [int(s.get("draw_calls", 0)), int(s.get("nodes", 0)),
		float(s.get("mem_static_mb", 0.0))])
	lines.append(">50ms %d  erros %d" % [recorder.frames.over_50, recorder.errors.size()])
	lines.append_array(MatchRecorder.viewport_lines(MatchRecorder.web_viewport()))
	for e in recorder.errors.tail(3):
		lines.append(str(e.get("msg", "")).left(48))
	label.text = "\n".join(lines)
