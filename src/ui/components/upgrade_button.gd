class_name UpgradeButton
extends Control
## Botão de upgrade da partida (T-135, decisão 35). docs/ui.md §5.4.
## Não compra nada: toque/clique/ui_accept emitem `buy_requested(id)` só no estado `affordable`.
## O estado vem do gameplay: set_upgrade() ← upgrade_changed, set_particles() ← particles_changed.
## Ícone provisório desenhado à mão até a T-128: defina `icon_texture` para trocar pela arte.

signal buy_requested(id: StringName)

enum State { AFFORDABLE, POOR, MAX, DISABLED }

## Ordem e nomes da fileira (contrato em docs/gameplay.md, `Arena.UPGRADE_IDS`).
const IDS: Array[StringName] = [
	&"upgrade_atk_power", &"upgrade_atk_spd", &"upgrade_defense", &"upgrade_max_hp", &"upgrade_cooldown",
]
const NAMES := {
	&"upgrade_atk_power": "Atk power",
	&"upgrade_atk_spd": "Atk spd",
	&"upgrade_defense": "Defesa",
	&"upgrade_max_hp": "Vida máxima",
	&"upgrade_cooldown": "Cooldown",
}
const ICON_COLORS := {
	&"upgrade_atk_power": Color("#FF6B4A"),
	&"upgrade_atk_spd": Color("#FFA43D"),
	&"upgrade_defense": Color("#8FA3C8"),
	&"upgrade_max_hp": Color("#FF6FA0"),
	&"upgrade_cooldown": Color("#2FC6B4"),
}
## Ações de gameplay que nunca acionam o botão pelo teclado (Espaço = skill_4 e também ui_accept).
const GAME_ACTIONS: Array[StringName] = [&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"pause"]

const FILL := Color("#3D8BF5")
const FILL_POOR := Color("#A7A3B8")
const COST_POOR := Color("#FF9AA6")
const MAX_GOLD := Color("#F5B83D")
const RADIUS := 14
const ICON_R := 22.0
const ICON_C := Vector2(32, 30)
const PILL := Rect2(8, 46, 112, 24)
const LEVEL_SIZE := 26
const COST_SIZE := 20
const PLUS_RISE := 28.0
const SHAKE_PX := 5.0
const PRESS_SCALE := 0.94

@export var upgrade_id: StringName = &"upgrade_atk_power":
	set(v):
		upgrade_id = v
		_update_accessibility()
		queue_redraw()
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		queue_redraw()

var level := 0
var max_level := 0
var next_cost := -1
var particles := 0
var state := State.DISABLED
var _known := false ## recebeu ao menos um set_upgrade
var _disabled := false
var _plus := 0.0 ## 0..1: progresso do "+1" (0 = invisível)
var _touch_index := -1
var _anim: Tween
var _plus_tween: Tween
var _box: StyleBoxFlat
var _box_poor: StyleBoxFlat
var _pill: StyleBoxFlat
var _pill_max: StyleBoxFlat
var _focus_box: StyleBoxFlat


func _init() -> void:
	custom_minimum_size = UiTokens.UPGRADE_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	_box = UiTokens.cartoon_box(FILL, RADIUS, UiTokens.SHADOW_BASE)
	_box_poor = UiTokens.cartoon_box(FILL_POOR, RADIUS, UiTokens.SHADOW_BASE)
	_pill = UiTokens.cartoon_box(UiTokens.INK, 10, 0)
	_pill.set_border_width_all(0)
	_pill_max = UiTokens.cartoon_box(MAX_GOLD, 10, 0)
	_pill_max.set_border_width_all(2)
	_focus_box = StyleBoxFlat.new()
	_focus_box.draw_center = false
	_focus_box.border_color = UiTokens.ACCENT
	_focus_box.set_border_width_all(UiTokens.BORDER_FOCUS)
	_focus_box.set_corner_radius_all(RADIUS + 4)
	_focus_box.anti_aliasing = true
	set_process(false)


func _ready() -> void:
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	pivot_offset = size * 0.5
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	_update_accessibility()


## upgrade_changed(id, level, max_level, next_cost). next_cost = -1 = nível máximo.
func set_upgrade(new_level: int, new_max: int, new_cost: int) -> void:
	var gained := _known and new_level > level
	level = new_level
	max_level = new_max
	next_cost = new_cost
	_known = true
	_refresh_state()
	if gained:
		_show_plus_one()


## particles_changed(total): o botão se habilita pelo total atual.
func set_particles(total: int) -> void:
	particles = total
	_refresh_state()


func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	_touch_index = -1
	_refresh_state()


## Feedback de "não deu" (sem Partículas, MAX ou o gameplay recusou).
func reject() -> void:
	if _anim:
		_anim.kill()
	scale = Vector2.ONE
	var origin := position
	_anim = create_tween()
	var step := UiTokens.ANIM_FAST / 4.0
	for dx in [SHAKE_PX, -SHAKE_PX, SHAKE_PX * 0.5, 0.0]:
		_anim.tween_property(self, "position:x", origin.x + dx, step)


func display_name() -> String:
	return NAMES.get(upgrade_id, String(upgrade_id))


func _refresh_state() -> void:
	var s := State.AFFORDABLE
	if _disabled or not _known:
		s = State.DISABLED
	elif next_cost < 0:
		s = State.MAX
	elif particles < next_cost:
		s = State.POOR
	if s != state:
		state = s
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if s == State.AFFORDABLE else CURSOR_ARROW
	_update_accessibility()
	queue_redraw()


func _update_accessibility() -> void:
	var text := "%s, nível %d" % [display_name(), level]
	match state:
		State.MAX:
			text += ", máximo"
		State.AFFORDABLE:
			text += ", custa %s Partículas" % UiTokens.format_int(next_cost)
		State.POOR:
			text += ", faltam Partículas (%s)" % UiTokens.format_int(next_cost)
	accessibility_name = text


# --- Entrada ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_release_pointer_focus()
			_activate()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Toque já foi tratado acima; ignora o mouse emulado.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			accept_event()
			return
		if event.pressed:
			_release_pointer_focus()
			_activate()
		accept_event()
	elif event.is_action_pressed(&"ui_accept") and not event.is_echo() and not _is_game_action(event):
		_activate()
		accept_event()


## Foco visível só pelo teclado: clique/toque não deixa o anel de foco nem "prende" o Espaço.
func _release_pointer_focus() -> void:
	if has_focus():
		release_focus()


func _is_game_action(event: InputEvent) -> bool:
	for a in GAME_ACTIONS:
		if InputMap.has_action(a) and event.is_action(a):
			return true
	return false


func _activate() -> void:
	if state == State.AFFORDABLE:
		_press_pop()
		buy_requested.emit(upgrade_id)
	elif state != State.DISABLED:
		reject()


func _press_pop() -> void:
	if _anim:
		_anim.kill()
	scale = Vector2.ONE
	_anim = create_tween()
	_anim.tween_property(self, "scale", Vector2.ONE * PRESS_SCALE, UiTokens.ANIM_FAST * 0.5)
	_anim.tween_property(self, "scale", Vector2.ONE, UiTokens.ANIM_FAST)


## "+1" sobe (ANIM_UI) e some (ANIM_UI) acima do canto do botão.
func _show_plus_one() -> void:
	if _plus_tween:
		_plus_tween.kill()
	_plus_tween = create_tween()
	_plus_tween.tween_method(_set_plus, 0.01, 1.0, UiTokens.ANIM_UI * 2.0)
	_plus_tween.tween_callback(_set_plus.bind(0.0))


func _set_plus(v: float) -> void:
	_plus = v
	queue_redraw()


# --- Desenho (só quando algo muda; nada por frame) ---

func _draw() -> void:
	var body := Rect2(Vector2.ZERO, size)
	var poor := state == State.POOR or state == State.DISABLED
	draw_style_box(_box_poor if poor else _box, body)
	# Anel interno: ciano (comprável) ou dourado (MAX)
	var inner := Rect2(body.position + Vector2(5, 5), body.size - Vector2(10, 10 + UiTokens.SHADOW_BASE))
	if state == State.AFFORDABLE:
		draw_rect(inner, Color(UiTokens.ACCENT, 0.9), false, 3.0, true)
	elif state == State.MAX:
		draw_rect(Rect2(body.position + Vector2(2, 2), body.size - Vector2(4, 4 + UiTokens.SHADOW_BASE)), MAX_GOLD, false, 5.0, true)
	if has_focus():
		draw_style_box(_focus_box, body.grow(6))

	var font := get_theme_font("font_bold", "SkillButton") # mesma fonte encorpada do SkillButton
	_draw_icon(poor)

	# "Nv N"
	var lv_x := ICON_C.x + ICON_R + 4.0
	var lv_w := size.x - lv_x - 4.0
	var lv := "Nv %d" % level
	var lv_fs := LEVEL_SIZE
	while lv_fs > 14 and font.get_string_size(lv, HORIZONTAL_ALIGNMENT_LEFT, -1, lv_fs).x > lv_w - 2.0:
		lv_fs -= 2 # "Nv 10" encolhe para caber
	var lv_y := ICON_C.y + (font.get_ascent(lv_fs) - font.get_descent(lv_fs)) * 0.5
	draw_string_outline(font, Vector2(lv_x, lv_y), lv, HORIZONTAL_ALIGNMENT_CENTER, lv_w, lv_fs, UiTokens.TEXT_OUTLINE, UiTokens.INK)
	draw_string(font, Vector2(lv_x, lv_y), lv, HORIZONTAL_ALIGNMENT_CENTER, lv_w, lv_fs, UiTokens.TEXT_PRIMARY)

	# Pílula de custo (estrela + número) ou "MAX"
	var cy := PILL.get_center().y + (font.get_ascent(COST_SIZE) - font.get_descent(COST_SIZE)) * 0.5
	if state == State.MAX:
		draw_style_box(_pill_max, PILL)
		draw_string(font, Vector2(PILL.position.x, cy), "MAX", HORIZONTAL_ALIGNMENT_CENTER, PILL.size.x, COST_SIZE, UiTokens.INK)
	else:
		draw_style_box(_pill, PILL)
		_draw_star(Vector2(PILL.position.x + 13.0, PILL.get_center().y), 9.0)
		var cost := UiTokens.format_int(next_cost) if _known and next_cost >= 0 else "—"
		var color := COST_POOR if state == State.POOR else (UiTokens.TEXT_SECONDARY if state == State.DISABLED else UiTokens.TEXT_PRIMARY)
		draw_string(font, Vector2(PILL.position.x + 26.0, cy), cost, HORIZONTAL_ALIGNMENT_RIGHT, PILL.size.x - 34.0, COST_SIZE, color)

	# "+1" subindo acima do canto superior esquerdo
	if _plus > 0.0:
		var a := 1.0 - maxf(_plus - 0.5, 0.0) * 2.0
		var p := Vector2(ICON_C.x - 18.0, -6.0 - PLUS_RISE * _plus)
		draw_string_outline(font, p, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, LEVEL_SIZE, UiTokens.TEXT_OUTLINE, Color(UiTokens.INK, a))
		draw_string(font, p, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, LEVEL_SIZE, Color(UiTokens.PARTICLES, a))


func _draw_icon(dim: bool) -> void:
	if icon_texture:
		var r := Rect2(ICON_C - Vector2(ICON_R, ICON_R), Vector2(ICON_R, ICON_R) * 2.0)
		draw_texture_rect(icon_texture, r, false, Color(1, 1, 1, 0.55) if dim else Color.WHITE)
		return
	var base: Color = ICON_COLORS.get(upgrade_id, UiTokens.ACCENT)
	draw_circle(ICON_C, ICON_R + 3.0, UiTokens.INK)
	draw_circle(ICON_C, ICON_R, UiTokens.LOCKED if dim else base)
	var fg := UiTokens.TEXT_SECONDARY if dim else UiTokens.TEXT_PRIMARY
	var c := ICON_C
	var s := ICON_R * 0.6
	match upgrade_id:
		&"upgrade_atk_power": # espada
			_glyph(PackedVector2Array([c + Vector2(-2.5, s * 0.35), c + Vector2(-2.5, -s), c + Vector2(0, -s - 4), c + Vector2(2.5, -s), c + Vector2(2.5, s * 0.35)]), fg)
			draw_line(c + Vector2(-s * 0.6, s * 0.4), c + Vector2(s * 0.6, s * 0.4), UiTokens.INK, 7.0)
			draw_line(c + Vector2(-s * 0.6, s * 0.4), c + Vector2(s * 0.6, s * 0.4), fg, 3.0)
			draw_line(c + Vector2(0, s * 0.45), c + Vector2(0, s), UiTokens.INK, 5.0)
		&"upgrade_atk_spd": # dupla seta
			for dx in [-5.0, 5.0]:
				var o := c + Vector2(dx, 0)
				var pts := PackedVector2Array([o + Vector2(-s * 0.4, -s * 0.7), o + Vector2(s * 0.4, 0), o + Vector2(-s * 0.4, s * 0.7)])
				draw_polyline(pts, UiTokens.INK, 8.0, true)
				draw_polyline(pts, fg, 4.0, true)
		&"upgrade_defense": # escudo hexagonal
			var hex := PackedVector2Array()
			for i in 6:
				var ang := TAU * i / 6.0 - PI * 0.5
				hex.append(c + Vector2(cos(ang), sin(ang)) * s)
			_glyph(hex, fg)
			draw_circle(c, s * 0.38, UiTokens.INK)
		&"upgrade_max_hp": # coração com +
			var heart := PackedVector2Array()
			for i in 24:
				var t := TAU * i / 24.0
				heart.append(c + Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * (s / 17.0))
			_glyph(heart, fg)
			draw_line(c + Vector2(-s * 0.35, 0), c + Vector2(s * 0.35, 0), base, 3.0)
			draw_line(c + Vector2(0, -s * 0.35), c + Vector2(0, s * 0.35), base, 3.0)
		_: # ampulheta (cooldown)
			_glyph(PackedVector2Array([c + Vector2(-s * 0.6, -s), c + Vector2(s * 0.6, -s), c + Vector2(0, 0)]), fg)
			_glyph(PackedVector2Array([c + Vector2(0, 0), c + Vector2(s * 0.6, s), c + Vector2(-s * 0.6, s)]), fg)


func _glyph(pts: PackedVector2Array, fill: Color) -> void:
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, UiTokens.INK, 5.0, true)
	draw_colored_polygon(pts, fill)


func _draw_star(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI * 0.5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.4))
	draw_colored_polygon(pts, UiTokens.PARTICLES)
