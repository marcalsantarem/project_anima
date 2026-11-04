class_name ScreenKit
## Peças comuns das telas (docs/ui.md §8): raiz com tema, cartão com moldura, rótulos, botões e fade.

const THEME := preload("res://src/ui/theme/anima_theme.tres")
const CARD_WIDTH := 520.0

## Safe area simulada (px da resolução base, ex.: {"bottom": 65.0}) para renders e testes fora do iPhone.
## Vazio = safe area real do navegador/dispositivo.
static var simulated_safe_area: Dictionary = {}


## Raiz em tela cheia com o tema aplicado (até o tema global, T-121).
static func root(parent: Node, bg: Color = UiTokens.BG_VOID) -> Control:
	var r := Control.new()
	r.name = "Root"
	r.theme = THEME
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(r)
	var fill := ColorRect.new()
	fill.color = bg
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(fill)
	return r


## Coluna centralizada com margem de tela.
static func column(parent: Control, separation: int = UiTokens.SPACE_M) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, UiTokens.SPACE_XL)
	parent.add_child(m)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", separation)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	return col


## Cartão com moldura (painel cartoon) centralizado na tela, com uma coluna dentro.
static func card(parent: Control, separation: int = UiTokens.SPACE_M) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)
	# 520 px, mas nunca mais largo que a tela menos as margens (telas estreitas).
	var fit := func() -> void:
		panel.custom_minimum_size.x = clampf(center.size.x - 2 * UiTokens.MARGIN_SCREEN, 0.0, CARD_WIDTH)
	center.resized.connect(fit)
	fit.call()
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, UiTokens.SPACE_M)
	panel.add_child(pad)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", separation)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(col)
	return col


static func label(text: String, variation: StringName, color: Color = UiTokens.TEXT_PRIMARY) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if color != UiTokens.TEXT_PRIMARY:
		l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, primary: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = &"ButtonPrimary" if primary else &""
	b.custom_minimum_size = Vector2(360, UiTokens.TOUCH_MIN)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b


static func fade_in(node: CanvasItem) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, UiTokens.ANIM_UI)


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]


## Inset inferior usado pela UI quando o canvas cobre a borda (T-172, docs/ui.md §9.1): o indicador de
## início é uma linha fina, então basta max(SAFE_BOTTOM_MIN, SAFE_BOTTOM_FACTOR × inset).
const SAFE_BOTTOM_MIN := 12.0
const SAFE_BOTTOM_FACTOR := 0.5


## Regra da inset inferior (px da resolução base): 0 sem inset; 0 se o canvas não cobre a borda inferior
## (a faixa fora do canvas já é a zona do indicador); senão max(12, 0,5 × inset).
static func ui_bottom_inset(raw: float, covers_bottom: bool) -> float:
	if raw <= 0.0 or not covers_bottom:
		return 0.0
	return maxf(SAFE_BOTTOM_MIN, SAFE_BOTTOM_FACTOR * raw)


## Safe area (docs/ui.md §9). Insets em px da resolução base: {top, bottom, left, right}, mais
## `css_k` (px da resolução base por px CSS; fora da web, por px da janela) para medir como o shell.
## `bottom` já é o valor para a UI (ui_bottom_inset); `bottom_raw` é a inset informada e `covers_bottom`
## diz se o canvas chega à borda inferior. A simulação recebe a inset bruta em "bottom" (e, opcional,
## "covers_bottom", padrão true).
static func safe_area(vp: Viewport) -> Dictionary:
	var out := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0, "css_k": 1.0, "covers_bottom": true}
	if not simulated_safe_area.is_empty():
		out.merge(simulated_safe_area, true)
		return _finish_bottom(out)
	var visible_size := vp.get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	if win.y > 0.0:
		out.css_k = visible_size.y / win.y
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("window.animaGetSafeArea ? animaGetSafeArea() : ''", true)
		var data = JSON.parse_string(str(raw)) if raw else null
		if data is Dictionary and float(data.get("height", 0)) > 0.0:
			var k := visible_size.y / float(data["height"])
			out.css_k = k
			for side in ["top", "bottom", "left", "right"]:
				out[side] = float(data.get(side, 0.0)) * k
			out.covers_bottom = bool(data.get("covers_bottom", true))
	elif OS.has_feature("mobile"):
		var screen := Rect2(Vector2.ZERO, DisplayServer.screen_get_size())
		var safe := Rect2(DisplayServer.get_display_safe_area())
		var k := visible_size.y / screen.size.y
		out.top = safe.position.y * k
		out.bottom = (screen.end.y - safe.end.y) * k
		out.left = safe.position.x * k
		out.right = (screen.end.x - safe.end.x) * k
	return _finish_bottom(out)


static func _finish_bottom(out: Dictionary) -> Dictionary:
	out.bottom_raw = float(out.bottom)
	out.bottom = ui_bottom_inset(out.bottom_raw, bool(out.covers_bottom))
	return out
