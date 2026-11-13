class_name ComingSoonScreen
extends Control
## Tela filha "Em breve" do hangar (T-200/T-201; docs/arte.md §11.9): topo com Voltar (pílula 104×56, alvo 64)
## e título, painel central com o ícone do conceito da aba. Recebe o título por `setup_title(text)` (a aba é
## deduzida do título, ou passada por `setup_tab(id)`) e emite `back_requested` no "Voltar".
## A barra do hangar fica por cima da base: `BarGap` reserva o espaço dela. Arte de `assets/ui/` (T-298).

signal back_requested

## Chaves de tradução (Loc.t).
const TXT_SOON := "SOON_TITLE"
const TXT_BACK := "COMMON_BACK"
const TXT_CAPTION := "SOON_CAPTION"
const BASE_W := 375.0
const HOLO_BG := Color("#021423")
const HOLO_LINE := Color("#3FE8F5")
const HOLO_TEXT := Color("#E6FFFF")
const HOLO_MUTED := Color("#7FA3B8")
const PILL_W := 104.0
const PILL_H := 56.0
const TOUCH := 64.0
const BAR_H := 110.0 ## itens 76 + faixa 34, a 1x
const CONCEPT_ICON := 54.0 ## a 1x (mockup)
const BACK_ICON := 18.0 ## a 1x (PNG 36)
const ASSET_DIR := "res://assets/ui/"
## Ícone do conceito por aba (glossário em 128; Ajustes usa o da barra).
const CONCEPT_FILES := {
	HangarNav.MODULES: "ui_icon_module", HangarNav.COMPONENTS: "ui_icon_component",
	HangarNav.CORES: "ui_icon_core", HangarNav.SETTINGS: "ui_icon_nav_settings", HangarNav.PLAY: "ui_icon_nav_play",
}

var title_text := ""
var tab_id: StringName = &""
@onready var _title: Label = %Title
@onready var _back: Button = %Back
@onready var _gap: Control = %BarGap
@onready var _column: Control = %Column
@onready var _top: Control = %TopBar


func setup_title(text: String) -> void:
	title_text = text
	for id: StringName in HangarNav.TITLES:
		if HangarNav.title_of(id) == text:
			tab_id = id
	if is_node_ready():
		_title.text = text
		_apply_icon()


func setup_tab(id: StringName) -> void:
	tab_id = id
	if is_node_ready():
		_apply_icon()


func _ready() -> void:
	_title.text = title_text
	%Soon.text = Loc.t(TXT_SOON)
	%Caption.text = Loc.t(TXT_CAPTION)
	_back.text = Loc.t(TXT_BACK)
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
	_back.icon = _tex("ui_icon_back")
	_back.add_theme_color_override("icon_normal_color", HOLO_TEXT)
	var pill := _tex("ui_holo_pill")
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb: StyleBox
		if pill:
			var t := _nine(pill, 20)
			if state == "pressed":
				t.modulate_color = Color(0.8, 0.9, 1.0)
			sb = t
		else:
			var f := StyleBoxFlat.new()
			f.bg_color = Color("#0B2A3F") if state != "pressed" else Color("#0A3347")
			f.border_color = HOLO_LINE
			f.set_border_width_all(1)
			f.set_corner_radius_all(28)
			sb = f
		_back.add_theme_stylebox_override(state, sb)
	var panel := _tex("ui_holo_panel")
	var psb: StyleBox
	if panel:
		psb = _nine(panel, 72)
	else:
		var f := StyleBoxFlat.new()
		f.bg_color = Color("#06182A")
		f.border_color = HOLO_LINE
		f.set_border_width_all(1)
		f.set_corner_radius_all(20)
		psb = f
	psb.set_content_margin_all(28)
	%Panel.add_theme_stylebox_override("panel", psb)
	_apply_icon()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _apply_icon() -> void:
	var icon: TextureRect = %ConceptIcon
	icon.texture = _tex(CONCEPT_FILES.get(tab_id, ""))
	icon.visible = icon.texture != null


static func _tex(file: String) -> Texture2D:
	var path := ASSET_DIR + file + ".png"
	return load(path) if file != "" and ResourceLoader.exists(path) else null


static func _nine(tex: Texture2D, m: float) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(m)
	return sb


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
	_back.add_theme_constant_override("icon_max_width", roundi(BACK_ICON * k))
	_back.add_theme_constant_override("h_separation", roundi(4.0 * k))
	%ConceptIcon.custom_minimum_size = Vector2.ONE * CONCEPT_ICON * k
	%Panel.get_theme_stylebox(&"panel").set_content_margin_all(28.0 * k)
	_title.add_theme_font_size_override("font_size", roundi(20.0 * k))
	%Soon.add_theme_font_size_override("font_size", roundi(30.0 * k))
	%Caption.add_theme_font_size_override("font_size", roundi(14.0 * k))
