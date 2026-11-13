class_name ComingSoonScreen
extends Control
## Tela filha "Em breve" do hangar (T-200/T-201; docs/arte.md §11.9): topo com Voltar (pílula 104×56, alvo 64)
## e título, painel central. Recebe o título por `setup_title(text)` e emite `back_requested` no "Voltar".
## A barra do hangar fica por cima da base: `BarGap` reserva o espaço dela.

signal back_requested

const TXT_SOON := "Em breve"
const TXT_BACK := "Voltar"
const TXT_CAPTION := "Esta área chega numa próxima versão."
const BASE_W := 375.0
const HOLO_BG := Color("#021423")
const HOLO_LINE := Color("#3FE8F5")
const HOLO_TEXT := Color("#E6FFFF")
const HOLO_MUTED := Color("#7FA3B8")
const PILL_W := 104.0
const PILL_H := 56.0
const TOUCH := 64.0
const BAR_H := 110.0 ## itens 76 + faixa 34, a 1x

var title_text := ""
@onready var _title: Label = %Title
@onready var _back: Button = %Back
@onready var _gap: Control = %BarGap
@onready var _column: Control = %Column
@onready var _top: Control = %TopBar


func setup_title(text: String) -> void:
	title_text = text
	if is_node_ready():
		_title.text = text


func _ready() -> void:
	_title.text = title_text
	%Soon.text = TXT_SOON
	%Caption.text = TXT_CAPTION
	_back.text = TXT_BACK
	_back.pressed.connect(back_requested.emit)
	var bold := ScreenKit.THEME.get_font(&"font", &"LabelDisplay")
	_title.add_theme_font_override("font", bold)
	_title.add_theme_color_override("font_color", HOLO_TEXT)
	%Soon.add_theme_font_override("font", bold)
	%Soon.add_theme_color_override("font_color", HOLO_TEXT)
	%Caption.add_theme_color_override("font_color", HOLO_MUTED)
	_back.add_theme_font_override("font", bold)
	_back.add_theme_color_override("font_color", HOLO_TEXT)
	_back.add_theme_color_override("font_pressed_color", HOLO_TEXT)
	_back.add_theme_color_override("font_hover_color", HOLO_TEXT)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#0B2A3F") if state != "pressed" else Color("#0A3347")
		sb.border_color = HOLO_LINE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(28)
		_back.add_theme_stylebox_override(state, sb)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("#06182A")
	psb.border_color = HOLO_LINE
	psb.set_border_width_all(1)
	psb.set_corner_radius_all(20)
	psb.set_content_margin_all(28)
	%Panel.add_theme_stylebox_override("panel", psb)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var view := get_viewport_rect().size
	var k := minf(view.x, 720.0) / BASE_W
	var safe := ScreenKit.safe_area(get_viewport())
	var col_w := minf(view.x, 720.0)
	var x0 := (view.x - col_w) / 2.0
	_column.offset_left = x0 + 16.0 * k
	_column.offset_right = -(x0 + 16.0 * k)
	_column.offset_top = float(safe.top) + 8.0 * k
	_back.custom_minimum_size = Vector2(PILL_W * k, maxf(TOUCH, PILL_H * k))
	%Spacer.custom_minimum_size = Vector2(PILL_W * k, 0)
	_top.add_theme_constant_override("separation", roundi(8.0 * k))
	_gap.custom_minimum_size = Vector2(0, maxf(BAR_H * k, 34.0 * k + float(safe.bottom) + 76.0 * k))
	_back.add_theme_font_size_override("font_size", roundi(16.0 * k))
	_title.add_theme_font_size_override("font_size", roundi(20.0 * k))
	%Soon.add_theme_font_size_override("font_size", roundi(30.0 * k))
	%Caption.add_theme_font_size_override("font_size", roundi(14.0 * k))
