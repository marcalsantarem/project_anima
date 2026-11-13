class_name HangarBar
extends Control
## Barra inferior do hangar (T-201, BRF-146; docs/arte.md §11.9, opção A). 5 itens: Módulos · Componentes ·
## Jogar (centro) · Núcleos · Ajustes. Lê o nível por `setup(level, progression)` (ou do `SceneFlow` ao entrar
## na árvore) e emite `tab_pressed(id)`; no hangar real chama `SceneFlow.open_hangar_tab`. Item bloqueado só
## mostra um aviso. Peças de `assets/ui/` carregadas por caminho: faltando, usa StyleBoxFlat/ícone simples.

signal tab_pressed(id: StringName)
signal locked_pressed(id: StringName)

const ASSET_DIR := "res://assets/ui/"
const BASE_W := 375.0
const ITEM_H := 76.0
const SAFE_STRIP := 34.0
const ICON := 28.0
const ICON_ACTIVE := 32.0
const FONT_LABEL := 11.5
const FONT_CHIP := 11.0
const FONT_HINT := 11.0
const HINT_TIME := 1.6
## 9-slice das peças (px do PNG 2x ≈ px de tela no viewport 720; assets/ui/README.md, barra do hangar).
const BAR_SLICE := [48, 48, 16, 8] # esq/dir/topo/base
const BAR_GLOW := 8.0 # expand_margin do topo (brilho para cima)
const CHIP_SLICE := [38, 12, 12, 12]
const CHIP_H := 20.0 ## a 1x (40 no PNG)
const CHIP_TEXT_L := 21.0 ## content_margin esq a 1x (38 no PNG + folga de 2), texto à direita do cadeado
const CHIP_TEXT_R := 6.0
const LOCK_SHIFT := 12.0 ## ícone bloqueado desloca para a esquerda; o selo fica à direita
const HINT_GAP := 2.0 ## aviso entre o JOGAR e a barra (o menu deixa ~22 px a 1x)

const HOLO_BG := Color("#06182A")
const HOLO_LINE := Color("#3FE8F5")
const HOLO_TEXT := Color("#E6FFFF")
const LABEL_NORMAL := Color("#9FC4D6")
const LABEL_LOCKED := Color("#6F8BA3")
const ICON_FALLBACK := {
	HangarNav.MODULES: Color("#B58CFF"), HangarNav.COMPONENTS: Color("#FFC95A"), HangarNav.PLAY: Color("#3FE8F5"),
	HangarNav.CORES: Color("#6DF2A8"), HangarNav.SETTINGS: Color("#9FC4D6"),
}
const ICON_FILES := {
	HangarNav.MODULES: "ui_icon_nav_modules", HangarNav.COMPONENTS: "ui_icon_nav_components",
	HangarNav.PLAY: "ui_icon_nav_play", HangarNav.CORES: "ui_icon_nav_cores", HangarNav.SETTINGS: "ui_icon_nav_settings",
}
const LOCKED_ICON_FILES := {
	HangarNav.MODULES: "ui_icon_module_locked", HangarNav.COMPONENTS: "ui_icon_component_locked",
	HangarNav.CORES: "ui_icon_core_locked",
}

var level := 1
var progression: ProgressionData
var current: StringName = HangarNav.PLAY
var items: Dictionary = {}  # StringName -> Button
var hint_label: Label

var _bg: Panel
var _mark: ColorRect
var _parts: Dictionary = {}  # id -> {icon: TextureRect, fb: Panel, label: Label, chip: Label}
var _bold: Font
var _hint_tween: Tween
var _built := false


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bold = ScreenKit.THEME.get_font(&"font", &"LabelDisplay")
	_build()
	var flow := get_node_or_null("/root/SceneFlow")
	if flow != null:
		if progression == null:
			progression = flow.progression
			if flow.profile != null:
				level = flow.profile.level
		if not tab_pressed.is_connected(flow.open_hangar_tab):
			tab_pressed.connect(flow.open_hangar_tab)
		if not flow.hangar_tab_changed.is_connected(set_current):
			flow.hangar_tab_changed.connect(set_current)
		current = flow.current_tab
	get_viewport().size_changed.connect(_layout)
	refresh()


## Dados da conta (nível e tabela de progressão). Pode ser chamada a qualquer momento.
func setup(account_level: int, prog: ProgressionData) -> void:
	level = account_level
	progression = prog
	if _built:
		refresh()


func set_current(id: StringName) -> void:
	current = id
	if _built:
		refresh()


## Aperta o item `id` (toque ou teste): bloqueado só avisa; livre emite `tab_pressed`.
func press(id: StringName) -> void:
	if HangarBarLogic.is_locked(id, level, progression):
		locked_pressed.emit(id)
		show_hint(HangarBarLogic.lock_hint(id, progression))
	else:
		tab_pressed.emit(id)


func show_hint(text: String) -> void:
	hint_label.text = text
	hint_label.modulate.a = 1.0
	hint_label.visible = true
	_layout()
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_interval(HINT_TIME)
	_hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.2)
	_hint_tween.tween_callback(hint_label.hide)


## Altura total ocupada (itens + faixa segura), em px de tela.
func bar_height() -> float:
	var view := _view()
	return ITEM_H * _k(view) + _strip(_k(view))


func refresh() -> void:
	for id: StringName in HangarBarLogic.ORDER:
		var st := HangarBarLogic.state_of(id, current, level, progression)
		var locked := st == HangarBarLogic.State.LOCKED
		var active := st == HangarBarLogic.State.ACTIVE
		var b: Button = items[id]
		var p: Dictionary = _parts[id]
		_style_item(b, active)
		var tex := _tex(LOCKED_ICON_FILES.get(id, "") if locked else ICON_FILES[id])
		if tex == null and locked:
			tex = _tex(ICON_FILES[id])
		var icon: TextureRect = p.icon
		var fb: Panel = p.fb
		icon.texture = tex
		icon.visible = tex != null
		fb.visible = tex == null
		fb.self_modulate = Color(0.45, 0.5, 0.55, 0.6) if locked else Color.WHITE
		icon.modulate = Color.WHITE # a arte do bloqueado já vem a 45% (README); sem alfa extra
		var label: Label = p.label
		label.add_theme_color_override("font_color",
			HOLO_TEXT if active else (LABEL_LOCKED if locked else LABEL_NORMAL))
		var chip: Label = p.chip
		chip.visible = locked
		chip.text = HangarBarLogic.lock_text(id, progression)
	_layout()


func _build() -> void:
	_bg = Panel.new()
	_bg.name = "Background"
	_bg.mouse_filter = MOUSE_FILTER_STOP # a barra não deixa o toque passar para a tela
	var bg_tex := _tex("ui_nav_bar")
	if bg_tex:
		var sb := _nine(bg_tex, BAR_SLICE)
		sb.expand_margin_top = BAR_GLOW
		_bg.add_theme_stylebox_override("panel", sb)
	else:
		var sbf := StyleBoxFlat.new()
		sbf.bg_color = HOLO_BG
		sbf.border_color = HOLO_LINE
		sbf.border_width_top = 2
		_bg.add_theme_stylebox_override("panel", sbf)
	add_child(_bg)

	for id: StringName in HangarBarLogic.ORDER:
		var b := Button.new()
		b.name = String(id).to_pascal_case()
		b.focus_mode = FOCUS_NONE
		b.pressed.connect(press.bind(id))
		add_child(b)
		items[id] = b
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = MOUSE_FILTER_IGNORE
		b.add_child(icon)
		var fb := Panel.new() # ícone simples enquanto a arte não existe
		fb.mouse_filter = MOUSE_FILTER_IGNORE
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = ICON_FALLBACK[id]
		fsb.set_corner_radius_all(8)
		fb.add_theme_stylebox_override("panel", fsb)
		b.add_child(fb)
		var label := _label(HangarBarLogic.label_of(id))
		b.add_child(label)
		var chip := _label("")
		chip.add_theme_color_override("font_color", Color("#9FB8CC"))
		var chip_tex := _tex("ui_nav_lock_chip")
		var csb: StyleBox
		if chip_tex:
			csb = _nine(chip_tex, CHIP_SLICE)
		else:
			var f := StyleBoxFlat.new()
			f.bg_color = Color("#0B2A3F")
			f.border_color = HOLO_LINE
			f.set_border_width_all(1)
			f.set_corner_radius_all(6)
			csb = f
		chip.add_theme_stylebox_override("normal", csb)
		b.add_child(chip)
		_parts[id] = {"icon": icon, "fb": fb, "label": label, "chip": chip}

	_mark = ColorRect.new()
	_mark.name = "ActiveMark"
	_mark.color = HOLO_LINE
	_mark.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_mark)

	hint_label = _label("")
	hint_label.name = "Hint"
	hint_label.visible = false
	hint_label.add_theme_color_override("font_color", HOLO_TEXT)
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color("#021423E6")
	hsb.border_color = HOLO_LINE
	hsb.set_border_width_all(1)
	hsb.set_corner_radius_all(8)
	hint_label.add_theme_stylebox_override("normal", hsb)
	add_child(hint_label)
	_built = true


static func _nine(tex: Texture2D, m: Array) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = m[0]
	sb.texture_margin_right = m[1]
	sb.texture_margin_top = m[2]
	sb.texture_margin_bottom = m[3]
	return sb


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _bold)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _style_item(b: Button, active: bool) -> void:
	var empty := StyleBoxEmpty.new()
	var act := _item_box("ui_nav_tab_active", Color("#0E4A5E"))
	var pr := _item_box("ui_nav_tab_pressed", Color("#0A3347"))
	b.add_theme_stylebox_override("normal", act if active else empty)
	b.add_theme_stylebox_override("hover", act if active else empty)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("focus", empty)
	b.add_theme_stylebox_override("disabled", empty)


func _item_box(file: String, fallback: Color) -> StyleBox:
	var t := _tex(file)
	if t:
		var sb := StyleBoxTexture.new()
		sb.texture = t
		return sb
	var f := StyleBoxFlat.new()
	f.bg_color = fallback
	f.set_corner_radius_all(14)
	f.border_color = HOLO_LINE
	f.set_border_width_all(1)
	return f


static func _tex(file: String) -> Texture2D:
	if file == "":
		return null
	var path := ASSET_DIR + file + ".png"
	return load(path) if ResourceLoader.exists(path) else null


func _view() -> Vector2:
	return get_viewport_rect().size if is_inside_tree() else Vector2(BASE_W, 812)


func _k(view: Vector2) -> float:
	return minf(view.x, 720.0) / BASE_W


## Faixa segura embaixo: 34 px da arte ou a safe area do aparelho, o que for maior.
func _strip(k: float) -> float:
	var safe_bottom := float(ScreenKit.safe_area(get_viewport()).bottom) if is_inside_tree() else 0.0
	return maxf(SAFE_STRIP * k, safe_bottom)


func _layout() -> void:
	if not _built:
		return
	var view := _view()
	var k := _k(view)
	var ih := ITEM_H * k
	var h := ih + _strip(k)
	var col_w := minf(view.x, 720.0)
	var x0 := (view.x - col_w) / 2.0
	var top := view.y - h
	_bg.position = Vector2(0, top)
	_bg.size = Vector2(view.x, h)
	var n := HangarBarLogic.ORDER.size()
	var item_w := col_w / float(n)
	for i in n:
		var id: StringName = HangarBarLogic.ORDER[i]
		var b: Button = items[id]
		b.position = Vector2(x0 + i * item_w, top)
		b.size = Vector2(item_w, ih)
		var p: Dictionary = _parts[id]
		var active := id == current and not HangarBarLogic.is_locked(id, level, progression)
		var isz := (ICON_ACTIVE if active else ICON) * k
		var locked := HangarBarLogic.is_locked(id, level, progression)
		var ipos := Vector2((item_w - isz) / 2.0 - (LOCK_SHIFT * k if locked else 0.0), 10.0 * k)
		for c: Control in [p.icon, p.fb]:
			c.position = ipos
			c.size = Vector2(isz, isz)
		var lab: Label = p.label
		lab.add_theme_font_size_override("font_size", roundi(FONT_LABEL * k))
		lab.position = Vector2(0, ipos.y + isz + 3.0 * k)
		lab.size = Vector2(item_w, 16.0 * k)
		var chip: Label = p.chip
		chip.add_theme_font_size_override("font_size", roundi(FONT_CHIP * k))
		var csb := chip.get_theme_stylebox(&"normal")
		csb.content_margin_left = CHIP_TEXT_L * k # texto à direita do cadeado da arte
		csb.content_margin_right = CHIP_TEXT_R * k
		csb.content_margin_top = 0
		csb.content_margin_bottom = 0
		chip.custom_minimum_size = Vector2(0, CHIP_H * k)
		chip.reset_size()
		chip.position = Vector2(item_w / 2.0 - LOCK_SHIFT * k, ipos.y + 14.0 * k)
	var ai := HangarBarLogic.ORDER.find(current)
	_mark.visible = ai >= 0 and not HangarBarLogic.is_locked(current, level, progression)
	if _mark.visible:
		_mark.size = Vector2(40.0 * k, 4.0 * k)
		_mark.position = Vector2(x0 + ai * item_w + (item_w - _mark.size.x) / 2.0, top)
	# Aviso compacto na faixa entre o JOGAR e a barra (não cobre o botão; T-298).
	var hsb := hint_label.get_theme_stylebox(&"normal")
	hsb.content_margin_left = 8.0 * k
	hsb.content_margin_right = 8.0 * k
	hsb.content_margin_top = 1.0 * k
	hsb.content_margin_bottom = 1.0 * k
	hint_label.add_theme_font_size_override("font_size", roundi(FONT_HINT * k))
	hint_label.reset_size()
	hint_label.position = Vector2((view.x - hint_label.size.x) / 2.0, top - hint_label.size.y - HINT_GAP * k)
	# Se a faixa não couber (tela baixa), o aviso sobe para logo acima do JOGAR, sem cobri-lo.
	var play := _play_button()
	if play != null:
		var pr := play.get_global_rect().grow(play.size.y * 0.03) # margem do pulso (1,03)
		var hr := Rect2(hint_label.global_position, hint_label.size)
		if hr.intersects(pr):
			hint_label.global_position.y = pr.position.y - hint_label.size.y - HINT_GAP * k


## Botão JOGAR visível na tela atual do hangar (o aviso desvia dele). Nulo fora do hangar.
func _play_button() -> Control:
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene == null:
		return null
	var b := scene.find_child("PlayButton", true, false) as Control
	return b if b != null and b.is_visible_in_tree() else null
