class_name MenuScreen
extends Control
## Menu principal holográfico (T-190, BRF-113; docs/arte.md §11, docs/ui.md "Menu principal").
## Recebe os dados por `setup(view)` e emite `play_pressed`; não chama Backend nem SceneFlow (T-187).
## `view`: {level: int, xp: int, xp_to_next: int, coins: int, is_max: bool}. A engrenagem não tem ação no M2.

signal play_pressed

const TXT_SUBTITLE := "PROJECT:"
const TXT_TITLE := "ANIMA"
const TXT_PLAY := "JOGAR"
const TXT_LEVEL := "NÍVEL %d"
const TXT_XP := "%s / %s XP"
const TXT_MAX := "MAX"

## Moeda provisória (T-162 troca): único ponto de troca do ícone.
const COIN_ICON := preload("res://assets/ui/ui_icon_particle.png")
const ICON_SETTINGS := preload("res://assets/ui/ui_icon_settings.png")
const PANEL_PILL := preload("res://assets/ui/ui_holo_pill.png")
const BTN_PRIMARY := preload("res://assets/ui/ui_holo_btn_primary_normal.png")
const BTN_PRIMARY_PRESSED := preload("res://assets/ui/ui_holo_btn_primary_pressed.png")
const BADGE := preload("res://assets/ui/ui_holo_level_badge.png")
const BAR_TRACK := preload("res://assets/ui/ui_holo_bar_track.png")
const BAR_FILL := preload("res://assets/ui/ui_holo_bar_fill.png")
const BAR_TIP := preload("res://assets/ui/ui_holo_bar_tip.png")

const BG_DEEP := Color("#021423")
const HOLO_TEXT := Color("#E6FFFF")
const HOLO_TEXT2 := Color("#9FF6FF")
const HOLO_MUTED := Color("#7FA3B8")
const HOLO_INK := Color("#03202E")
const COIN_TEXT := Color("#FFE08A")

# Medidas a 1x (mockup de 375 px); multiplicadas por `_k()` (largura / 375, no máximo 720 / 375).
const BASE_W := 375.0
const ROW_W := 288.0
const ROW_H := 58.0
const BADGE_SIZE := Vector2(52, 58)
const ROW_GAP := 5.0
const BAR_H := 12.0
const PILL_H := 38.0
const PLAY_SIZE := Vector2(281, 78)
const PLAY_ROW_GAP := 30.0 ## linha do nível → Jogar
const ROW_TITLE_GAP := 34.0 ## "ANIMA" → linha do nível (da base das letras ao topo da linha)
const SUB_GAP := 6.0
const TITLE_FONT := 60.0
const SUB_FONT := 25.0
const PLAY_FONT := 29.0
const GEAR_SIZE := 44.0
const GEAR_MARGIN := 16.0
const BOTTOM_GAP_MAX := 98.0
const BLOCK_H := 273.0 ## do topo de "PROJECT:" à base do Jogar, a 1x
const PEDESTAL_END := 0.55 ## fração da altura até a base do pedestal da arte
const PULSE_TIME := 0.8

var level_label: Label
var badge_label: Label
var xp_label: Label
var coins_label: Label
var play_button: Button
var settings_button: Button

var _data := {"level": 1, "xp": 0, "xp_to_next": 1, "coins": 0, "is_max": false}
var _art: Control
var _sub_title: Label
var _title: Label
var _row: HBoxContainer
var _badge: Control
var _badge_tex: TextureRect
var _text_col: VBoxContainer
var _bar: Control
var _track: NinePatchRect
var _fill: NinePatchRect
var _tip: TextureRect
var _pill: PanelContainer
var _coin_icon: TextureRect
var _bold: Font
var _built := false


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self, BG_DEEP)
	ScreenKit.set_page_color(BG_DEEP)
	_bold = ScreenKit.THEME.get_font(&"font", &"LabelDisplay")
	_art = TitleScreen.build_art(DebugSettings.reduced_effects())
	root.add_child(_art)

	_sub_title = TitleScreen.title_label(TXT_SUBTITLE)
	_sub_title.name = "Subtitle"
	_sub_title.add_theme_font_override("font", _spaced(6.0))
	root.add_child(_sub_title)
	_title = TitleScreen.title_label(TXT_TITLE)
	_title.name = "Title"
	root.add_child(_title)

	_build_row(root)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = TXT_PLAY
	play_button.focus_mode = FOCUS_NONE
	_style_play(play_button)
	play_button.pressed.connect(func() -> void: play_pressed.emit())
	root.add_child(play_button)

	settings_button = Button.new() # sem ação no M2 (configurações no M8)
	settings_button.name = "SettingsButton"
	settings_button.focus_mode = FOCUS_NONE
	settings_button.icon = ICON_SETTINGS
	settings_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_button.expand_icon = false
	_style_texture_all(settings_button, PANEL_PILL, 20, 0.0)
	root.add_child(settings_button)

	_built = true
	_apply()
	_layout()
	get_viewport().size_changed.connect(_layout)
	var pulse := play_button.create_tween().set_loops()
	pulse.tween_property(play_button, "scale", Vector2.ONE * 1.03, PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(play_button, "scale", Vector2.ONE, PULSE_TIME).set_trans(Tween.TRANS_SINE)


## Dados da conta (ver cabeçalho). Pode ser chamada antes ou depois de entrar na árvore.
func setup(view: Dictionary) -> void:
	_data.merge(view, true)
	if _built:
		_apply()
		_layout()


## 1.250 (milhar com ponto, pt-BR).
static func format_number(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if n < 0 else "") + out


## Fração do trilho preenchida: 1 no nível máximo, 0 sem XP, sempre em [0, 1].
static func xp_ratio(xp: int, xp_to_next: int, is_max: bool) -> float:
	if is_max:
		return 1.0
	if xp_to_next <= 0:
		return 0.0
	return clampf(float(xp) / float(xp_to_next), 0.0, 1.0)


func _build_row(root: Control) -> void:
	_row = HBoxContainer.new()
	_row.name = "LevelRow"
	_row.mouse_filter = MOUSE_FILTER_IGNORE
	root.add_child(_row)

	_badge = Control.new()
	_badge.name = "Badge"
	_badge.mouse_filter = MOUSE_FILTER_IGNORE
	_row.add_child(_badge)
	_badge_tex = TextureRect.new()
	_badge_tex.texture = BADGE
	_badge_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_badge_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_badge_tex.mouse_filter = MOUSE_FILTER_IGNORE
	_badge_tex.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_badge.add_child(_badge_tex)
	badge_label = _text("", HOLO_TEXT, true)
	badge_label.name = "BadgeNumber"
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_badge.add_child(badge_label)

	_text_col = VBoxContainer.new()
	_text_col.name = "LevelText"
	_text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	_text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_col.mouse_filter = MOUSE_FILTER_IGNORE
	_row.add_child(_text_col)
	level_label = _text("", HOLO_TEXT2, true)
	level_label.name = "LevelLabel"
	level_label.add_theme_font_override("font", _spaced(3.0))
	_text_col.add_child(level_label)
	_bar = Control.new()
	_bar.name = "XpBar"
	_bar.mouse_filter = MOUSE_FILTER_IGNORE
	_bar.resized.connect(_update_bar)
	_text_col.add_child(_bar)
	_track = _nine(BAR_TRACK, 8)
	_track.name = "Track"
	_track.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bar.add_child(_track)
	_fill = _nine(BAR_FILL, 6)
	_fill.name = "Fill"
	_bar.add_child(_fill)
	_tip = TextureRect.new()
	_tip.name = "Tip"
	_tip.texture = BAR_TIP
	_tip.mouse_filter = MOUSE_FILTER_IGNORE
	_bar.add_child(_tip)
	xp_label = _text("", HOLO_MUTED, false)
	xp_label.name = "XpLabel"
	_text_col.add_child(xp_label)

	_pill = PanelContainer.new()
	_pill.name = "CoinPill"
	_pill.mouse_filter = MOUSE_FILTER_IGNORE
	_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_texture_all(_pill, PANEL_PILL, 20, 0.0, true)
	_row.add_child(_pill)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = MOUSE_FILTER_IGNORE
	_pill.add_child(box)
	_coin_icon = TextureRect.new()
	_coin_icon.name = "CoinIcon"
	_coin_icon.texture = COIN_ICON
	_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_coin_icon.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(_coin_icon)
	coins_label = _text("", COIN_TEXT, true)
	coins_label.name = "CoinsLabel"
	box.add_child(coins_label)


func _apply() -> void:
	var is_max := bool(_data.is_max)
	var lvl := int(_data.level)
	badge_label.text = str(lvl)
	level_label.text = TXT_LEVEL % lvl
	if is_max:
		xp_label.text = TXT_MAX
	else:
		xp_label.text = TXT_XP % [format_number(int(_data.xp)), format_number(int(_data.xp_to_next))]
	coins_label.text = format_number(int(_data.coins))
	_update_bar()


func _update_bar() -> void:
	if _fill == null or _bar == null:
		return
	var ratio := xp_ratio(int(_data.xp), int(_data.xp_to_next), bool(_data.is_max))
	var inset := 4.0
	var inner := maxf(0.0, _bar.size.x - 2.0 * inset)
	var w := inner * ratio
	_fill.visible = ratio > 0.0
	_tip.visible = ratio > 0.0
	if ratio <= 0.0:
		return
	w = maxf(w, 12.0) # abaixo disso o 9-patch (6 + 6) se deforma
	_fill.position = Vector2(inset, inset)
	_fill.size = Vector2(w, maxf(0.0, _bar.size.y - 2.0 * inset))
	_tip.position = Vector2(inset + w - _tip.size.x / 2.0, (_bar.size.y - _tip.size.y) / 2.0)


## Escala do bloco: largura / 375 (até 720); em telas baixas encolhe para o logotipo não cobrir o pedestal da arte.
func _k(view: Vector2) -> float:
	var k := minf(view.x, 720.0) / BASE_W
	var gap := minf(view.y * 0.12, BOTTOM_GAP_MAX * k)
	return minf(k, (view.y * (1.0 - PEDESTAL_END) - gap) / BLOCK_H)


func _layout() -> void:
	var view := get_viewport_rect().size
	var safe := ScreenKit.safe_area(get_viewport())
	var k := _k(view)
	var s := TitleScreen.art_scale(view)
	_art.scale = Vector2.ONE * s
	_art.position = Vector2((view.x - TitleScreen.ART.x * s) / 2.0, 0)

	# Bloco único ancorado embaixo: Jogar → linha do nível → logotipo.
	var gap := clampf(view.y * 0.12, UiTokens.SPACE_L, BOTTOM_GAP_MAX * k)
	var bottom := view.y - float(safe.bottom) - gap
	var play_w := minf(PLAY_SIZE.x * k, view.x - 2.0 * UiTokens.MARGIN_SCREEN)
	var play_size := Vector2(play_w, maxf(PLAY_SIZE.y * k, UiTokens.TOUCH_MIN))
	play_button.size = play_size
	play_button.position = Vector2((view.x - play_size.x) / 2.0, bottom - play_size.y)
	play_button.pivot_offset = play_size / 2.0
	play_button.add_theme_font_size_override("font_size", roundi(PLAY_FONT * k))

	var row_w := minf(ROW_W * k, view.x - 2.0 * UiTokens.MARGIN_SCREEN)
	var row_h := ROW_H * k
	_row.add_theme_constant_override("separation", roundi(5.0 * k))
	_row.size = Vector2(row_w, row_h)
	_row.position = Vector2((view.x - row_w) / 2.0, play_button.position.y - PLAY_ROW_GAP * k - row_h)
	_badge.custom_minimum_size = BADGE_SIZE * k
	badge_label.add_theme_font_size_override("font_size", roundi(25.0 * k))
	_text_col.add_theme_constant_override("separation", roundi(3.0 * k))
	level_label.add_theme_font_size_override("font_size", roundi(13.0 * k))
	xp_label.add_theme_font_size_override("font_size", maxi(UiTokens.FONT_CAPTION - 2, roundi(11.0 * k)))
	_bar.custom_minimum_size = Vector2(0, BAR_H * k)
	_pill.custom_minimum_size = Vector2(92.0 * k, PILL_H * k)
	_coin_icon.custom_minimum_size = Vector2.ONE * 23.0 * k
	coins_label.add_theme_font_size_override("font_size", roundi(17.0 * k))
	for sb: StyleBoxTexture in [_pill.get_theme_stylebox("panel")]:
		sb.content_margin_left = 9.0 * k
		sb.content_margin_right = 9.0 * k
	_row.reset_size()
	_row.size = Vector2(row_w, row_h)

	# Logotipo: base das letras de "ANIMA" a ROW_TITLE_GAP acima da linha do nível.
	var title_font := roundi(TITLE_FONT * k)
	var sub_font := roundi(SUB_FONT * k)
	var title_base := _row.position.y - ROW_TITLE_GAP * k
	_place_label(_title, title_font, title_base - title_font * 0.7, view.x)
	var sub_base := title_base - title_font * 0.7 - 6.0 * k
	_place_label(_sub_title, sub_font, sub_base - sub_font * 0.7, view.x)

	var gear := maxf(GEAR_SIZE * k, UiTokens.TOUCH_MIN)
	settings_button.size = Vector2.ONE * gear
	settings_button.position = Vector2(view.x - float(safe.right) - GEAR_MARGIN * k - gear, float(safe.top) + UiTokens.SPACE_M)
	_update_bar()


## Rótulo de largura total; `cap_top` é o topo das maiúsculas (compensa o espaço acima delas, como o título).
func _place_label(l: Label, font: int, cap_top: float, width: float) -> void:
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_constant_override("shadow_outline_size", maxi(4, roundi(font * 0.09)))
	l.size = Vector2(width, 0)
	l.position = Vector2(0, cap_top - font * 0.18)


func _text(text: String, color: Color, bold: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	if bold:
		l.add_theme_font_override("font", _bold)
	return l


func _spaced(px: float) -> Font:
	var fv := FontVariation.new()
	if _bold is FontVariation: # mantém o peso 800 do tema (um FontVariation sobre outro perde a variação)
		fv.base_font = _bold.base_font
		fv.variation_opentype = _bold.variation_opentype
	else:
		fv.base_font = _bold
	fv.spacing_glyph = roundi(px)
	return fv


func _nine(tex: Texture2D, margin: int) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	n.mouse_filter = MOUSE_FILTER_IGNORE
	return n


func _tex_box(tex: Texture2D, m_h: float, m_v: float, expand: float) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = m_h
	sb.texture_margin_right = m_h
	sb.texture_margin_top = m_v
	sb.texture_margin_bottom = m_v
	sb.expand_margin_left = expand
	sb.expand_margin_right = expand
	sb.expand_margin_top = expand
	sb.expand_margin_bottom = expand
	return sb


func _style_texture_all(c: Control, tex: Texture2D, margin: float, expand: float, panel := false) -> void:
	var sb := _tex_box(tex, margin, margin, expand)
	if panel:
		c.add_theme_stylebox_override("panel", sb)
		return
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		c.add_theme_stylebox_override(state, sb)


## Jogar: brilho pintado fora do corpo (expand 16); pressionado troca a textura e baixa o texto 6 px.
func _style_play(b: Button) -> void:
	var normal := _tex_box(BTN_PRIMARY, 48.0, 56.0, 16.0)
	var pressed := _tex_box(BTN_PRIMARY_PRESSED, 48.0, 56.0, 16.0)
	normal.content_margin_bottom = 12.0 # a base escura do corpo não entra no centro do texto
	pressed.content_margin_bottom = 12.0
	pressed.content_margin_top = 6.0
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_font_override("font", _spaced(4.0))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(state, HOLO_INK)
	b.add_theme_constant_override("outline_size", 0)
