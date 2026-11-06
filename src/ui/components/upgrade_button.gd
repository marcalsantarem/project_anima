class_name UpgradeButton
extends Control
## Botão de upgrade da partida (T-135, decisão 35). docs/ui.md §5.4.
## Não compra nada: toque/clique/ui_accept emitem `buy_requested(id)` só no estado `affordable`.
## O estado vem do gameplay: set_upgrade() ← upgrade_changed, set_particles() ← particles_changed.
## Arte da T-128 (T-138): moldura por estado, ícone do upgrade (UiArt.UPGRADE_ICONS ou `icon_texture`), pílula de custo.

signal buy_requested(id: StringName)
## Primeira vez na partida em que o botão fica `affordable` (T-117: pulso discreto no HUD).
signal first_affordable(id: StringName)

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
## Ações de gameplay que nunca acionam o botão pelo teclado (Espaço = skill_4 e também ui_accept).
const GAME_ACTIONS: Array[StringName] = [&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"pause"]

const COST_POOR := Color("#FF9AA6")
const RADIUS := 18 ## cantos do corpo da arte
const DIM_ALPHA := 0.55 ## ícone sem Partículas
## Layout interno (assets/ui/README.md, relativo ao corpo 128×80).
const ICON_R := 20.0
const ICON_C := Vector2(31, 28)
const PILL := Rect2(9, 52, 112, 25)
const PILL_STAR := 20.0
const LEVEL_SIZE := 26
const COST_SIZE := 20
const MAX_OUTLINE := 6 ## contorno total do "MAX" (assets/ui/README.md)
const PLUS_RISE := 28.0
const SHAKE_PX := 5.0
const AFFORDABLE_POP := 1.06
const PRESS_SCALE := 0.94

@export var upgrade_id: StringName = &"upgrade_atk_power":
	set(v):
		upgrade_id = v
		_update_accessibility()
		queue_redraw()
## Vazio = ícone padrão do upgrade_id (UiArt.upgrade_icon).
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
var _was_affordable := false ## já ficou `affordable` alguma vez (pulso só na primeira)
var _disabled := false
var _plus := 0.0 ## 0..1: progresso do "+1" (0 = invisível)
var _touch_index := -1
var _anim: Tween
var _plus_tween: Tween
var _focus_box: StyleBoxFlat


func _init() -> void:
	custom_minimum_size = UiTokens.UPGRADE_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_ALL
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
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
		if s == State.AFFORDABLE and not _was_affordable:
			_was_affordable = true
			_affordable_pop()
			first_affordable.emit(upgrade_id)
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


## Pop discreto na primeira vez que fica comprável (T-117).
func _affordable_pop() -> void:
	if not is_inside_tree():
		return
	if _anim:
		_anim.kill()
	scale = Vector2.ONE
	_anim = create_tween()
	_anim.tween_property(self, "scale", Vector2.ONE * AFFORDABLE_POP, UiTokens.ANIM_FAST)
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
	var frame := UiArt.UPGRADE_BTN_MAX if state == State.MAX else (UiArt.UPGRADE_BTN_DISABLED if poor else UiArt.UPGRADE_BTN_NORMAL)
	draw_texture_rect(frame, UiArt.UPGRADE_FRAME_RECT, false)
	if has_focus():
		draw_style_box(_focus_box, body.grow(6))

	var font := get_theme_font("font_bold", "SkillButton") # mesma fonte encorpada do SkillButton
	var icon := icon_texture if icon_texture else UiArt.upgrade_icon(upgrade_id)
	if icon:
		draw_texture_rect(icon, Rect2(ICON_C - Vector2(ICON_R, ICON_R), Vector2(ICON_R, ICON_R) * 2.0), false, Color(1, 1, 1, DIM_ALPHA) if poor else Color.WHITE)

	# "Nv N" (centro em x = 90, alinhado ao ícone)
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
		draw_texture_rect(UiArt.UPGRADE_COST_PILL_MAX, PILL, false)
		# Branco com contorno ink de 6 px (T-154; a arte não tem texto).
		draw_string_outline(font, Vector2(PILL.position.x, cy), "MAX", HORIZONTAL_ALIGNMENT_CENTER, PILL.size.x, COST_SIZE,
			MAX_OUTLINE, UiTokens.INK)
		draw_string(font, Vector2(PILL.position.x, cy), "MAX", HORIZONTAL_ALIGNMENT_CENTER, PILL.size.x, COST_SIZE, UiTokens.TEXT_PRIMARY)
	else:
		draw_texture_rect(UiArt.UPGRADE_COST_PILL, PILL, false)
		var star := Rect2(PILL.position + Vector2(4.0, (PILL.size.y - PILL_STAR) * 0.5), Vector2(PILL_STAR, PILL_STAR))
		draw_texture_rect(UiArt.PARTICLE_OFF if state == State.DISABLED else UiArt.PARTICLE, star, false)
		var cost := UiTokens.format_int(next_cost) if _known and next_cost >= 0 else "—"
		var color := COST_POOR if state == State.POOR else (UiTokens.TEXT_SECONDARY if state == State.DISABLED else UiTokens.TEXT_PRIMARY)
		draw_string(font, Vector2(PILL.position.x + 26.0, cy), cost, HORIZONTAL_ALIGNMENT_RIGHT, PILL.size.x - 34.0, COST_SIZE, color)

	# "+1" subindo acima do canto superior esquerdo
	if _plus > 0.0:
		var a := 1.0 - maxf(_plus - 0.5, 0.0) * 2.0
		var p := Vector2(ICON_C.x - 18.0, -6.0 - PLUS_RISE * _plus)
		draw_string_outline(font, p, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, LEVEL_SIZE, UiTokens.TEXT_OUTLINE, Color(UiTokens.INK, a))
		draw_string(font, p, "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, LEVEL_SIZE, Color(UiTokens.GOLD, a))
