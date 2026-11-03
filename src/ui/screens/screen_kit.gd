class_name ScreenKit
## Peças comuns das telas (docs/ui.md §8): raiz com tema, rótulos, botões e fade.

const THEME := preload("res://src/ui/theme/anima_theme.tres")


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
	b.custom_minimum_size = Vector2(320, UiTokens.TOUCH_MIN)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	return b


static func fade_in(node: CanvasItem) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, UiTokens.ANIM_UI)


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]
