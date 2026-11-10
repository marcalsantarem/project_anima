class_name DebugMetaPanel
extends VBoxContainer
## Seção "Meta" do overlay de debug (T-193; docs/debug.md §4.1): linha com nível, XP e Moeda e botões
## de ação (`DebugMeta`). Recolhida por padrão. Toque >= 64 px, estilo holográfico (tokens HOLO_*).

signal action_done(action_name: String, before: Dictionary, after: Dictionary)

const BTN_H := 64
const BTN_W := 200
const CONFIRM_S := 3.0

var line: Label
var toggle: Button
var reset_button: Button
var _grid: GridContainer
var _confirm_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle = _button("Meta ▸", _on_toggle)
	add_child(toggle)
	line = Label.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_font_size_override("font_size", 18)
	line.add_theme_color_override("font_color", UiTokens.HOLO_TEXT2)
	line.visible = false
	add_child(line)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.visible = false
	add_child(_grid)
	_grid.add_child(_button("+100 XP", _act.bind(DebugMeta.Action.XP_SMALL)))
	_grid.add_child(_button("+1000 XP", _act.bind(DebugMeta.Action.XP_BIG)))
	_grid.add_child(_button("+500 Moeda", _act.bind(DebugMeta.Action.COINS)))
	_grid.add_child(_button("Nível −", _act.bind(DebugMeta.Action.LEVEL_DOWN)))
	_grid.add_child(_button("Nível +", _act.bind(DebugMeta.Action.LEVEL_UP)))
	reset_button = _button("Zerar save", _on_reset)
	_grid.add_child(reset_button)
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh()


func _process(delta: float) -> void:
	if _confirm_left > 0.0:
		_confirm_left -= delta
		if _confirm_left <= 0.0:
			_cancel_confirm()


func is_open() -> bool:
	return _grid != null and _grid.visible


func refresh() -> void:
	if line != null and SceneFlow.profile != null:
		line.text = DebugMeta.line(SceneFlow.profile)


func _on_toggle() -> void:
	set_open(not is_open())


func set_open(open: bool) -> void:
	_grid.visible = open
	line.visible = open
	toggle.text = "Meta ▾" if open else "Meta ▸"
	_cancel_confirm()
	refresh()


func _act(a: DebugMeta.Action) -> void:
	var before := _snap()
	var after := DebugMeta.run(a)
	refresh()
	action_done.emit(DebugMeta.action_name(a), before, after)


func _snap() -> Dictionary:
	return DebugMeta.snapshot(SceneFlow.profile) if SceneFlow.profile != null else {}


## Confirmação em 2 toques: o 1º arma ("Confirmar?"), o 2º dentro de 3 s zera.
func _on_reset() -> void:
	if _confirm_left > 0.0:
		_cancel_confirm()
		_act(DebugMeta.Action.RESET)
		return
	_confirm_left = CONFIRM_S
	reset_button.text = "Confirmar?"


func _cancel_confirm() -> void:
	_confirm_left = 0.0
	if reset_button != null:
		reset_button.text = "Zerar save"


static func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(BTN_W, BTN_H)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	var normal := _box(Color(UiTokens.HOLO_TRAY, 0.9))
	var down := _box(Color(UiTokens.HOLO_LINE, 0.35))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("pressed", down)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, UiTokens.HOLO_TEXT)
	b.pressed.connect(cb)
	return b


static func _box(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = UiTokens.HOLO_LINE
	s.set_border_width_all(2)
	s.set_corner_radius_all(UiTokens.RADIUS_S)
	s.set_content_margin_all(UiTokens.SPACE_XS)
	return s
