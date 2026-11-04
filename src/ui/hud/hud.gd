class_name Hud
extends CanvasLayer
## HUD da partida (docs/ui.md §4–6). Só escuta os sinais da Arena; toques chamam Arena.use_skill(slot).
## Chame bind(arena) ANTES de a arena entrar na árvore: os valores iniciais saem no _ready dela.
## Layout cartoon (T-145): topo = pausa · pílula "ONDA x/y" · pílula de Partículas, barra de Energia;
## bandeja inferior = fileira de 5 upgrades (T-135) + 3 slots de skill (Ø 144, centros 150/360/570).

## Pedido de pausa (botão). O botão também injeta a action `pause`; a tela de pausa (T-113) ouve um dos dois.
signal pause_requested
## Toque num botão do HUD, para o gravador de debug (docs/debug.md): `skill_N`, id do upgrade ou `pause`;
## `ok` = a ação foi aceita (skill disparada, upgrade comprado). Sem posição do toque.
signal ui_pressed(button: StringName, ok: bool)

const THEME := preload("res://src/ui/theme/anima_theme.tres")
const SKILL_COUNT := 3
const SKILL_ICONS := [SkillButton.Icon.CIRCLE, SkillButton.Icon.DIAMOND, SkillButton.Icon.HEX]
const PARTICLES_ICON_SIZE := 36
const PAUSE_ICON_SIZE := 64
const CORE_ICON_SIZE := Vector2(36, 44)
const UPGRADE_BAND_PAD := 6
## Altura da bandeja inferior (upgrades + skills) sem safe area, em px da resolução base (docs/ui.md §4.4).
const TRAY_HEIGHT := 266
## Altura do HUD de cima (pausa/ONDA/Partículas + barra de Energia) sem safe area e sem a barra do chefe.
## O fundo da arena passa por trás do topo; o gameplay usa isto para não pôr alvos sob o HUD (docs/ui.md §4.4).
const TOP_INSET := 164
## Respiro entre a faixa de upgrades e os slots; embaixo dos slots, max(SPACE_XS, inset da UI) (T-172).
const SKILLS_TOP_PAD := UiTokens.SPACE_XS
## Altura extra do topo com a barra "Boss" visível (gap 16 + barra 36). top_inset() já soma quando ela aparece.
const BOSS_BAR_INSET := 52
## Trilho da barra "Boss": ~89% do trilho da Energia (36), decisão 39.
const BOSS_TRACK_HEIGHT := 32.0
const BOSS_BAR_HEIGHT := 36
const BOSS_FILL_TIME := 0.15
## Degradê escuro atrás do topo, só para leitura sobre o fundo da arena (alfa no alto da tela).
const TOP_SCRIM_ALPHA := 0.35
## Padrão do M1 (decisão 25): slot 1 liberado; 2 e 3 bloqueados até os níveis 7 e 12.
const M1_UNLOCK_LEVELS: Array[int] = [0, 7, 12]

## Ícone por slot (índice 0 = slot 1), caminho do PNG = `SkillData.icon` da skill do slot (decisão 37).
## Vazio ou inexistente = arte padrão do SkillButton (`ui_icon_skill_pulse` no slot 1). Troque em tempo
## de execução com set_slot_icon(slot, textura) — o HUD não lê src/match/.
@export var slot_icon_paths: Array[String] = [UiArt.SKILL_METEOR_PATH, "", ""]
## Nível de desbloqueio por slot (índice 0 = slot 1). 0 = liberado; > 0 = bloqueado com "NV x".
## No M2 o meta-jogo passa a lista conforme o nível da conta (set_slot_unlock_levels).
@export var slot_unlock_levels: Array[int] = M1_UNLOCK_LEVELS.duplicate()

var _arena: Node
var _root: Control
var _top: MarginContainer
var _top_scrim: TextureRect
var _tray: PanelContainer
var _upgrade_margin: MarginContainer
var _skills_margin: MarginContainer
## Contêiner da fileira de 5 upgrades (UpgradeButton, T-135).
var upgrade_row: HBoxContainer
var _core_bar: UiBar
var _boss_bar: UiBar
var _boss_row: Control
var _boss_tween: Tween
var _boss_hiding := false
var _wave_label: Label
var _particles_label: Label
var _pause_button: Button
var _skills: Array[SkillButton] = []
var _upgrades: Array[UpgradeButton] = []
var _particles_shown := 0
var _particles_tween: Tween
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
	_connect(&"particles_changed", _on_particles_changed)
	_connect(&"upgrade_changed", _on_upgrade_changed)
	_connect(&"skill_used", _on_skill_used)
	_connect(&"cooldown_changed", _on_cooldown_changed)
	_connect(&"skill_ready", _on_skill_ready)
	_connect(&"boss_spawned", _on_boss_spawned)
	_connect(&"boss_hp_changed", _on_boss_hp_changed)
	_connect(&"boss_defeated", _on_boss_defeated)
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
	_build_top_scrim()
	_build_top()
	_build_tray()


## Topo sem faixa de fundo (BRF-039): só um degradê escuro suave, que some até a altura do HUD de cima.
func _build_top_scrim() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(UiTokens.INK, TOP_SCRIM_ALPHA))
	grad.set_color(1, Color(UiTokens.INK, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	_top_scrim = TextureRect.new()
	_top_scrim.name = "TopScrim"
	_top_scrim.texture = tex
	_top_scrim.stretch_mode = TextureRect.STRETCH_SCALE
	_top_scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_top_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_scrim.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_scrim.offset_bottom = TOP_INSET
	_root.add_child(_top_scrim)


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

	# Linha 1: pausa · ONDA x/y (centralizada) · Partículas. Os lados têm a mesma largura.
	var row1 := _hbox(UiTokens.SPACE_XS)
	top_col.add_child(row1)
	var left := _hbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(left)
	_pause_button = Button.new()
	_pause_button.name = "Pause"
	_pause_button.accessibility_name = "Pausa"
	# Arte ui_icon_pause (o botão inteiro, 64 px) no canto; o alvo de toque continua com 88 px.
	_pause_button.icon = UiArt.PAUSE
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		_pause_button.add_theme_stylebox_override(st, empty)
	_pause_button.expand_icon = true
	_pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_pause_button.add_theme_constant_override("icon_max_width", PAUSE_ICON_SIZE)
	_pause_button.add_theme_color_override("icon_pressed_color", Color(0.82, 0.8, 0.9))
	_pause_button.add_theme_color_override("icon_hover_pressed_color", Color(0.82, 0.8, 0.9))
	_pause_button.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.55))
	_pause_button.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
	_pause_button.focus_mode = Control.FOCUS_NONE
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
	var particles_pill := _panel(&"PanelPillLight")
	particles_pill.name = "ParticlesPill"
	particles_pill.accessibility_name = "Partículas"
	particles_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(particles_pill)
	var particles_row := _hbox(UiTokens.SPACE_XS)
	particles_pill.add_child(particles_row)
	particles_row.add_child(StarIcon.new(PARTICLES_ICON_SIZE))
	_particles_label = _label(&"LabelHud")
	_particles_label.text = "0"
	_particles_label.add_theme_color_override("font_color", UiTokens.PARTICLES)
	_particles_label.add_theme_color_override("font_outline_color", UiTokens.INK)
	_particles_label.add_theme_constant_override("outline_size", UiTokens.TEXT_OUTLINE)
	_particles_label.custom_minimum_size.x = 72
	_particles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	particles_row.add_child(_particles_label)

	# Linha 2: cristal + barra de Energia
	var row2 := _hbox(UiTokens.SPACE_XS)
	top_col.add_child(row2)
	row2.add_child(_icon(CORE_ICON_SIZE, _draw_crystal))
	_core_bar = UiBar.new()
	_core_bar.color_mode = UiBar.ColorMode.CORE_HP
	_core_bar.label_prefix = "ENERGIA "
	_core_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_core_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row2.add_child(_core_bar)

	# Linha 3: barra "Boss" (decisão 39), mesma largura útil da de Energia; aparece com o chefe.
	var row3 := _hbox(UiTokens.SPACE_XS)
	row3.name = "BossRow"
	row3.visible = false
	top_col.add_child(row3)
	_boss_row = row3
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(CORE_ICON_SIZE.x, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row3.add_child(spacer)
	_boss_bar = UiBar.new()
	_boss_bar.name = "BossBar"
	_boss_bar.color_mode = UiBar.ColorMode.FIXED
	_boss_bar.fill_color = UiTokens.BOSS_HP
	_boss_bar.title = "Boss"
	_boss_bar.track_height = BOSS_TRACK_HEIGHT
	_boss_bar.fill_time = BOSS_FILL_TIME
	_boss_bar.custom_minimum_size.y = BOSS_BAR_HEIGHT
	_boss_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row3.add_child(_boss_bar)


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

	# Faixa da fileira de upgrades (decisão 35, T-135).
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
	for id in UpgradeButton.IDS:
		var ub := UpgradeButton.new()
		ub.upgrade_id = id
		ub.name = String(id)
		ub.buy_requested.connect(_on_upgrade_buy)
		upgrade_row.add_child(ub)
		_upgrades.append(ub)

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
		sb.icon_texture = UiArt.load_icon(slot_icon_paths[i] if i < slot_icon_paths.size() else "")
		sb.inject_action = false
		sb.activated.connect(_on_skill_pressed)
		skills_row.add_child(sb)
		_skills.append(sb)
	_apply_slot_locks()


## Troca os níveis de desbloqueio em tempo de execução (ver slot_unlock_levels).
func set_slot_unlock_levels(levels: Array[int]) -> void:
	slot_unlock_levels = levels.duplicate()
	_apply_slot_locks()


## Ícone do slot (ex.: `SkillData.icon`). null volta à arte padrão do botão.
func set_slot_icon(slot: int, texture: Texture2D) -> void:
	var sb := _skill(slot)
	if sb:
		sb.icon_texture = texture


func _apply_slot_locks() -> void:
	for i in _skills.size():
		var level := slot_unlock_levels[i] if i < slot_unlock_levels.size() else 0
		_skills[i].set_locked(level > 0, level)


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


## Cristal da barra de Energia, ciano com contorno.
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
	return ScreenKit.safe_area(get_viewport())


func apply_safe_area() -> void:
	var s := safe_insets()
	var m := UiTokens.MARGIN_SCREEN
	for box in [_top, _upgrade_margin, _skills_margin]:
		box.add_theme_constant_override("margin_left", m + int(s.left))
		box.add_theme_constant_override("margin_right", m + int(s.right))
	_top.add_theme_constant_override("margin_top", m + int(s.top))
	_upgrade_margin.add_theme_constant_override("margin_top", UPGRADE_BAND_PAD)
	_upgrade_margin.add_theme_constant_override("margin_bottom", UPGRADE_BAND_PAD)
	_skills_margin.add_theme_constant_override("margin_top", SKILLS_TOP_PAD)
	_skills_margin.add_theme_constant_override("margin_bottom", int(_bottom_pad(s)))
	_top_scrim.offset_bottom = top_inset()


## Altura ocupada pelo HUD de cima, com a safe area (px da resolução base). Soma a barra "Boss" se visível.
func top_inset() -> float:
	var boss := BOSS_BAR_INSET if _boss_row and _boss_row.visible and not _boss_hiding else 0
	return TOP_INSET + boss + safe_insets().top


## Altura ocupada pela bandeja inferior, com a safe area (px da resolução base).
func tray_height() -> float:
	return TRAY_HEIGHT - UiTokens.SPACE_XS + _bottom_pad(safe_insets())


## Folga entre a base dos slots e a borda inferior (T-172): SPACE_XS sem safe area; com ela, a inset da UI
## (ScreenKit.ui_bottom_inset, já reduzida), sem somar as duas. O fundo da bandeja segue até a borda.
func _bottom_pad(s: Dictionary) -> float:
	return maxf(UiTokens.SPACE_XS, roundf(float(s.bottom)))


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


func _on_particles_changed(total: int) -> void:
	# total é o acumulado da partida.
	if _particles_tween:
		_particles_tween.kill()
	_particles_tween = create_tween()
	_particles_tween.tween_method(_set_particles_shown, _particles_shown, total, UiTokens.ANIM_UI)
	for ub in _upgrades:
		ub.set_particles(total) # habilitação imediata; só o número anima


func _on_upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int) -> void:
	var ub := upgrade_button(id)
	if ub:
		ub.set_upgrade(level, max_level, next_cost)


func _set_particles_shown(v: int) -> void:
	_particles_shown = v
	_particles_label.text = UiTokens.format_int(v)


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


func _on_boss_spawned(_id: StringName) -> void:
	_show_boss(true)


func _on_boss_hp_changed(current: int, max_hp: int) -> void:
	if current > 0 and not _boss_row.visible:
		_show_boss(true)
	_boss_bar.set_value(current, max_hp)
	if current <= 0:
		_show_boss(false)


func _on_boss_defeated() -> void:
	_show_boss(false)


## Fade curto (ANIM_UI) ao entrar e ao sair; o topo e o degradê crescem/encolhem com a barra.
func _show_boss(on: bool) -> void:
	if on == (_boss_row.visible and not _boss_hiding):
		return
	if _boss_tween:
		_boss_tween.kill()
	_boss_hiding = not on
	_boss_tween = _boss_row.create_tween()
	if on:
		_boss_row.visible = true
		_top_scrim.offset_bottom = top_inset()
		_boss_tween.tween_property(_boss_row, "modulate:a", 1.0, UiTokens.ANIM_UI).from(0.0)
	else:
		_boss_tween.tween_property(_boss_row, "modulate:a", 0.0, UiTokens.ANIM_UI)
		_boss_tween.tween_callback(_hide_boss_row)


func _hide_boss_row() -> void:
	_boss_row.visible = false
	_top_scrim.offset_bottom = top_inset()


func _on_match_ended(_result) -> void:
	_show_boss(false)
	for sb in _skills:
		sb.set_disabled(true)
	_pause_button.disabled = true
	for ub in _upgrades:
		ub.set_disabled(true)


# --- Entrada ---

func _on_skill_pressed(slot: int) -> void:
	var sb := _skill(slot)
	if sb and sb.is_locked():
		ui_pressed.emit(StringName("skill_%d" % slot), false)
		return
	if _arena == null or not _arena.has_method(&"use_skill"):
		return
	var ok: bool = _arena.use_skill(slot)
	ui_pressed.emit(StringName("skill_%d" % slot), ok)
	if not ok:
		_skill(slot).reject()


func _on_upgrade_buy(id: StringName) -> void:
	if _arena == null or not _arena.has_method(&"buy_upgrade"):
		return
	var ok: bool = _arena.buy_upgrade(id)
	ui_pressed.emit(id, ok)
	if not ok:
		var ub := upgrade_button(id)
		if ub:
			ub.reject()


func _on_pause_pressed() -> void:
	ui_pressed.emit(&"pause", true)
	pause_requested.emit()
	var ev := InputEventAction.new()
	ev.action = &"pause"
	ev.pressed = true
	Input.parse_input_event(ev)


func _skill(slot: int) -> SkillButton:
	return _skills[slot - 1] if slot >= 1 and slot <= _skills.size() else null


func upgrade_button(id: StringName) -> UpgradeButton:
	for ub in _upgrades:
		if ub.upgrade_id == id:
			return ub
	return null
