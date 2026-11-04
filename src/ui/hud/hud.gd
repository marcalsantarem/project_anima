class_name Hud
extends CanvasLayer
## HUD da partida (docs/ui.md §4–6). Só escuta os sinais da Arena; toques chamam Arena.use_skill(slot).
## Chame bind(arena) ANTES de a arena entrar na árvore: os valores iniciais saem no _ready dela.
## Layout cartoon (T-145): topo = pausa · pílula "ONDA x/y" · pílula de moedas, barra do Núcleo;
## bandeja inferior = fileira de upgrades (reservada, T-135) + 3 slots de skill (Ø 144, centros 150/360/570).

## Pedido de pausa (botão). O botão também injeta a action `pause`; a tela de pausa (T-113) ouve um dos dois.
signal pause_requested

const THEME := preload("res://src/ui/theme/anima_theme.tres")
const SKILL_COUNT := 3
const SKILL_ICONS := [SkillButton.Icon.CIRCLE, SkillButton.Icon.DIAMOND, SkillButton.Icon.HEX]
const COIN_SIZE := 36
const CORE_ICON_SIZE := Vector2(36, 44)
const UPGRADE_BAND_PAD := 10

var _arena: Node
var _root: Control
var _top: MarginContainer
var _tray: PanelContainer
var _upgrade_margin: MarginContainer
var _skills_margin: MarginContainer
## Contêiner da fileira de 5 upgrades (vazio até a T-135).
var upgrade_row: HBoxContainer
var _core_bar: UiBar
var _boss_bar: UiBar
var _boss_row: Control
var _boss_label: Label
var _wave_label: Label
var _coin_label: Label
var _pause_button: Button
var _skills: Array[SkillButton] = []
var _coins_shown := 0
var _coin_tween: Tween
var _wave_tween: Tween


func _ready() -> void:
	layer = 10
	_build()
	get_viewport().size_changed.connect(apply_safe_area)
	apply_safe_area()


func bind(arena: Node) -> void:
	_arena = arena
	_connect(&"core_hp_changed", _on_core_hp_changed)
	_connect(&"wave_changed", _on_wave_changed)
	_connect(&"coins_changed", _on_coins_changed)
	_connect(&"skill_used", _on_skill_used)
	_connect(&"cooldown_changed", _on_cooldown_changed)
	_connect(&"skill_ready", _on_skill_ready)
	_connect(&"boss_spawned", _on_boss_spawned)
	_connect(&"boss_hp_changed", _on_boss_hp_changed)
	_connect(&"match_ended", _on_match_ended)


func _connect(sig: StringName, cb: Callable) -> void:
	# boss_* ainda não existem na Arena (T-111); liga quando existirem.
	if _arena.has_signal(sig) and not _arena.is_connected(sig, cb):
		_arena.connect(sig, cb)


# --- Construção ---

func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.theme = THEME
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_top()
	_build_tray()


func _build_top() -> void:
	_top = MarginContainer.new()
	_top.name = "Top"
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.grow_vertical = Control.GROW_DIRECTION_END
	_root.add_child(_top)
	var top_col := VBoxContainer.new()
	top_col.add_theme_constant_override("separation", UiTokens.SPACE_S)
	top_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(top_col)

	# Linha 1: pausa · ONDA x/y (centralizada) · moedas. Os lados têm a mesma largura.
	var row1 := _hbox(UiTokens.SPACE_XS)
	top_col.add_child(row1)
	var left := _hbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(left)
	_pause_button = Button.new()
	_pause_button.name = "Pause"
	_pause_button.text = "II"
	_pause_button.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.add_theme_font_size_override("font_size", UiTokens.FONT_HUD)
	_pause_button.pressed.connect(_on_pause_pressed)
	left.add_child(_pause_button)

	var wave_pill := _panel(&"PanelPill")
	wave_pill.custom_minimum_size.x = 220
	wave_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row1.add_child(wave_pill)
	_wave_label = _label(&"LabelHud")
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_pill.add_child(_wave_label)

	var right := _hbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	row1.add_child(right)
	var coin_pill := _panel(&"PanelPillLight")
	coin_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(coin_pill)
	var coin_row := _hbox(UiTokens.SPACE_XS)
	coin_pill.add_child(coin_row)
	coin_row.add_child(_icon(Vector2(COIN_SIZE, COIN_SIZE), _draw_star))
	_coin_label = _label(&"LabelHud")
	_coin_label.text = "0"
	_coin_label.add_theme_color_override("font_color", UiTokens.COIN)
	_coin_label.custom_minimum_size.x = 72
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_row.add_child(_coin_label)

	# Linha 2: cristal + barra do Núcleo
	var row2 := _hbox(UiTokens.SPACE_XS)
	top_col.add_child(row2)
	row2.add_child(_icon(CORE_ICON_SIZE, _draw_crystal))
	_core_bar = UiBar.new()
	_core_bar.color_mode = UiBar.ColorMode.CORE_HP
	_core_bar.label_prefix = "NÚCLEO "
	_core_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_core_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row2.add_child(_core_bar)

	# Chefe (aparece com boss_spawned)
	var boss_col := VBoxContainer.new()
	boss_col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	boss_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_col.visible = false
	top_col.add_child(boss_col)
	_boss_row = boss_col
	_boss_label = _label(&"LabelCaption")
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_col.add_child(_boss_label)
	_boss_bar = UiBar.new()
	_boss_bar.color_mode = UiBar.ColorMode.FIXED
	_boss_bar.fill_color = UiTokens.BOSS_HP
	_boss_bar.show_numbers = false
	_boss_bar.custom_minimum_size.y = 28
	boss_col.add_child(_boss_bar)


func _build_tray() -> void:
	_tray = _panel(&"PanelTray")
	_tray.name = "Tray"
	_tray.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_tray.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_root.add_child(_tray)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tray.add_child(col)

	# Faixa da fileira de upgrades (decisão 35). Os botões vêm na T-135.
	var band := _panel(&"")
	var band_sb := StyleBoxFlat.new()
	band_sb.bg_color = UiTokens.TRAY_BAND
	band_sb.border_color = UiTokens.INK
	band_sb.border_width_bottom = UiTokens.BORDER
	band.add_theme_stylebox_override("panel", band_sb)
	col.add_child(band)
	_upgrade_margin = _margin_box()
	band.add_child(_upgrade_margin)
	upgrade_row = _hbox(UiTokens.UPGRADE_GAP)
	upgrade_row.name = "UpgradeRow"
	upgrade_row.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_row.custom_minimum_size.y = UiTokens.UPGRADE_SIZE.y
	_upgrade_margin.add_child(upgrade_row)

	# Slots de skill
	_skills_margin = _margin_box()
	col.add_child(_skills_margin)
	var skills_row := _hbox(UiTokens.SKILL_GAP)
	skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_skills_margin.add_child(skills_row)
	for i in SKILL_COUNT:
		var sb := SkillButton.new()
		sb.slot = i + 1
		sb.icon = SKILL_ICONS[i]
		sb.inject_action = false
		sb.activated.connect(_on_skill_pressed)
		skills_row.add_child(sb)
		_skills.append(sb)


func _margin_box() -> MarginContainer:
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func _panel(variation: StringName) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _hbox(separation: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _label(variation: StringName) -> Label:
	var l := Label.new()
	l.theme_type_variation = variation
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _icon(min_size: Vector2, painter: Callable) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(painter.bind(c))
	return c


## Estrela de 4 pontas (moedas/Partículas), dourada com contorno.
func _draw_star(c: Control) -> void:
	var ctr := c.size * 0.5
	var s := minf(c.size.x, c.size.y) * 0.5
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI * 0.5
		pts.append(ctr + Vector2(cos(a), sin(a)) * (s if i % 2 == 0 else s * 0.38))
	_outlined(c, pts, UiTokens.COIN)


## Cristal do Núcleo, ciano com contorno.
func _draw_crystal(c: Control) -> void:
	var w := c.size.x * 0.5
	var h := c.size.y * 0.5
	var ctr := c.size * 0.5
	var pts := PackedVector2Array([ctr + Vector2(0, -h), ctr + Vector2(w, 0), ctr + Vector2(0, h), ctr + Vector2(-w, 0)])
	_outlined(c, pts, UiTokens.ACCENT)


func _outlined(c: Control, pts: PackedVector2Array, fill: Color) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	c.draw_polyline(closed, UiTokens.INK, 6.0, true)
	c.draw_colored_polygon(pts, fill)


# --- Safe area (docs/ui.md §9) ---

## Insets em px da resolução base: {top, bottom, left, right}.
func safe_insets() -> Dictionary:
	var out := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var visible_size := get_viewport().get_visible_rect().size
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("window.animaGetSafeArea ? animaGetSafeArea() : ''", true)
		var data = JSON.parse_string(str(raw)) if raw else null
		if data is Dictionary and float(data.get("height", 0)) > 0.0:
			var k := visible_size.y / float(data["height"])
			for side in out:
				out[side] = float(data.get(side, 0.0)) * k
	elif OS.has_feature("mobile"):
		var screen := Rect2(Vector2.ZERO, DisplayServer.screen_get_size())
		var safe := Rect2(DisplayServer.get_display_safe_area())
		var k := visible_size.y / screen.size.y
		out.top = safe.position.y * k
		out.bottom = (screen.end.y - safe.end.y) * k
		out.left = safe.position.x * k
		out.right = (screen.end.x - safe.end.x) * k
	return out


func apply_safe_area() -> void:
	var s := safe_insets()
	var m := UiTokens.MARGIN_SCREEN
	for box in [_top, _upgrade_margin, _skills_margin]:
		box.add_theme_constant_override("margin_left", m + int(s.left))
		box.add_theme_constant_override("margin_right", m + int(s.right))
	_top.add_theme_constant_override("margin_top", m + int(s.top))
	_upgrade_margin.add_theme_constant_override("margin_top", UPGRADE_BAND_PAD)
	_upgrade_margin.add_theme_constant_override("margin_bottom", UPGRADE_BAND_PAD)
	_skills_margin.add_theme_constant_override("margin_top", m)
	_skills_margin.add_theme_constant_override("margin_bottom", UiTokens.SPACE_XS + int(s.bottom))


# --- Sinais da Arena ---

func _on_core_hp_changed(current: int, max_hp: int) -> void:
	_core_bar.set_value(current, max_hp)


func _on_wave_changed(current: int, total: int) -> void:
	_wave_label.text = "ONDA %d/%d" % [current, total]
	_wave_label.pivot_offset = _wave_label.size * 0.5
	if _wave_tween:
		_wave_tween.kill()
	_wave_tween = create_tween()
	_wave_tween.tween_property(_wave_label, "scale", Vector2.ONE * 1.15, UiTokens.ANIM_FAST)
	_wave_tween.tween_property(_wave_label, "scale", Vector2.ONE, UiTokens.ANIM_FAST)


func _on_coins_changed(amount: int) -> void:
	# amount é o total da partida.
	if _coin_tween:
		_coin_tween.kill()
	_coin_tween = create_tween()
	_coin_tween.tween_method(_set_coins_shown, _coins_shown, amount, UiTokens.ANIM_UI)


func _set_coins_shown(v: int) -> void:
	_coins_shown = v
	_coin_label.text = UiTokens.format_int(v)


func _on_skill_used(slot: int) -> void:
	var sb := _skill(slot)
	if sb:
		sb.on_used()


func _on_cooldown_changed(slot: int, remaining: float, total: float) -> void:
	var sb := _skill(slot)
	if sb:
		sb.set_cooldown(remaining, total)


func _on_skill_ready(slot: int) -> void:
	var sb := _skill(slot)
	if sb:
		sb.set_ready()


func _on_boss_spawned(id: StringName) -> void:
	_boss_label.text = String(id).trim_prefix("boss_").capitalize()
	_boss_row.visible = true


func _on_boss_hp_changed(current: int, max_hp: int) -> void:
	_boss_bar.set_value(current, max_hp)
	if current <= 0:
		_boss_row.visible = false


func _on_match_ended(_result) -> void:
	for sb in _skills:
		sb.set_disabled(true)
	_pause_button.disabled = true


# --- Entrada ---

func _on_skill_pressed(slot: int) -> void:
	if _arena == null or not _arena.has_method(&"use_skill"):
		return
	if not _arena.use_skill(slot):
		_skill(slot).reject()


func _on_pause_pressed() -> void:
	pause_requested.emit()
	var ev := InputEventAction.new()
	ev.action = &"pause"
	ev.pressed = true
	Input.parse_input_event(ev)


func _skill(slot: int) -> SkillButton:
	return _skills[slot - 1] if slot >= 1 and slot <= _skills.size() else null
