@tool
class_name SkillButton
extends Control
## Botão circular de skill. docs/ui.md §5.1.
## Não chama a skill: toque/clique emitem `activated(slot)` e, se `inject_action`, a Input Action `skill_<slot>`.
## O estado vem do gameplay: on_used() ← skill_used, set_cooldown() ← cooldown_changed, set_ready() ← skill_ready.

signal activated(slot: int)

enum State { READY, COOLDOWN, DISABLED }
enum Icon { CIRCLE, DIAMOND, HEX }

const DIAMETER := 128.0
const PRESS_SCALE := 0.92
const READY_POP := 1.08
const SHAKE_PX := 6.0
const GLOW_PERIOD := 1.5

## 1-based (1 a 3), casa com `skill_1`..`skill_3`.
@export_range(1, 4) var slot := 1:
	set(v):
		slot = v
		action = StringName("skill_%d" % slot)
		queue_redraw()
@export var icon := Icon.CIRCLE:
	set(v):
		icon = v
		queue_redraw()
## Desligue quando quem ouve `activated` já aciona a skill (ex.: HUD → Arena.use_skill).
@export var inject_action := true

var action := &"skill_1"
var state := State.READY
var _remaining := 0.0
var _total := 0.0
var _flash := 0.0
var _glow_t := 0.0
var _shortcut := ""
var _show_shortcut := true
var _touch_index := -1
var _anim: Tween


func _init() -> void:
	custom_minimum_size = Vector2(DIAMETER, DIAMETER + UiTokens.FONT_CAPTION + UiTokens.SPACE_XS)
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_NONE


func _ready() -> void:
	_show_shortcut = not DisplayServer.is_touchscreen_available() or Engine.is_editor_hint()
	_shortcut = _shortcut_label()
	resized.connect(_update_pivot)
	_update_pivot()


func set_cooldown(remaining: float, total: float) -> void:
	if state == State.DISABLED:
		return
	_remaining = maxf(remaining, 0.0)
	_total = maxf(total, 0.001)
	state = State.COOLDOWN if _remaining > 0.0 else State.READY
	queue_redraw()


func set_ready() -> void:
	var was_cooldown := state == State.COOLDOWN
	state = State.READY
	_remaining = 0.0
	if was_cooldown:
		_pop(READY_POP)
	queue_redraw()


func on_used() -> void:
	_flash = 1.0
	queue_redraw()


func set_disabled(disabled: bool) -> void:
	if disabled:
		state = State.DISABLED
	else:
		state = State.COOLDOWN if _remaining > 0.0 else State.READY
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var dirty := false
	# Interpolação local entre sinais (≤ ~10×/s). O próximo cooldown_changed corrige.
	if state == State.COOLDOWN and _remaining > 0.0:
		_remaining = maxf(_remaining - delta, 0.0)
		dirty = true
	if state == State.READY:
		_glow_t = fmod(_glow_t + delta, GLOW_PERIOD)
		dirty = true
	if _flash > 0.0:
		_flash = maxf(_flash - delta / UiTokens.ANIM_UI, 0.0)
		dirty = true
	if dirty:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not _hit(event.position):
			return
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_press()
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_release()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Toque já foi tratado acima; ignora o mouse emulado.
		if event.device == InputEvent.DEVICE_ID_EMULATION or not _hit(event.position):
			return
		if event.pressed:
			_press()
		else:
			_release()
		accept_event()


## Atalho de teclado: o Input Map já leva a ação ao gameplay; aqui é só o feedback visual.
func _unhandled_input(event: InputEvent) -> void:
	# Só teclado: a ação injetada pelo próprio toque também passa por aqui.
	if event is InputEventKey and event.is_action_pressed(action) and not event.is_echo():
		_feedback_press()


## Feedback de "indisponível" (ex.: o gameplay recusou o acionamento).
func reject() -> void:
	_shake()


func _press() -> void:
	_feedback_press()
	if state != State.DISABLED:
		activated.emit(slot)
	if inject_action:
		_send_action(true)


func _release() -> void:
	if inject_action:
		_send_action(false)


func _feedback_press() -> void:
	match state:
		State.READY:
			_pop(PRESS_SCALE)
		State.COOLDOWN:
			_shake()


func _send_action(pressed: bool) -> void:
	if state == State.DISABLED and pressed:
		return
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _hit(pos: Vector2) -> bool:
	return pos.distance_to(_center()) <= DIAMETER * 0.5


func _center() -> Vector2:
	return Vector2(size.x * 0.5, DIAMETER * 0.5)


func _update_pivot() -> void:
	pivot_offset = _center()


func _pop(peak: float) -> void:
	if _anim:
		_anim.kill()
	scale = Vector2.ONE
	_anim = create_tween()
	_anim.tween_property(self, "scale", Vector2.ONE * peak, UiTokens.ANIM_FAST).set_ease(Tween.EASE_OUT)
	_anim.tween_property(self, "scale", Vector2.ONE, UiTokens.ANIM_FAST).set_ease(Tween.EASE_IN)


func _shake() -> void:
	if _anim:
		_anim.kill()
	scale = Vector2.ONE
	var origin := position
	_anim = create_tween()
	var step := UiTokens.ANIM_FAST / 4.0
	for dx in [SHAKE_PX, -SHAKE_PX, SHAKE_PX * 0.5, 0.0]:
		_anim.tween_property(self, "position:x", origin.x + dx, step)


func _shortcut_label() -> String:
	if not InputMap.has_action(action):
		return ""
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return ev.as_text_physical_keycode() if ev.physical_keycode != KEY_NONE else ev.as_text_keycode()
	return ""


func _draw() -> void:
	var c := _center()
	var r := DIAMETER * 0.5
	var is_ready := state == State.READY
	var disabled := state == State.DISABLED

	# Fundo e brilho
	if is_ready and not Engine.is_editor_hint():
		var pulse := 0.5 - 0.5 * cos(TAU * _glow_t / GLOW_PERIOD)
		draw_circle(c, r + 6.0, Color(UiTokens.ACCENT, 0.12 + 0.18 * pulse))
	draw_circle(c, r, UiTokens.BG_PANEL_ALT)

	# Ícone
	var icon_color := UiTokens.TEXT_SECONDARY if disabled else UiTokens.TEXT_PRIMARY
	_draw_icon(c, r * 0.42, icon_color)

	# Véu e setor de recarga (sentido horário a partir do topo)
	if state == State.COOLDOWN and _total > 0.0:
		var frac := clampf(_remaining / _total, 0.0, 1.0)
		_draw_sector(c, r, frac, UiTokens.COOLDOWN_DIM)

	# Anel
	var ring := UiTokens.LINE
	if is_ready:
		ring = UiTokens.ACCENT
	if _flash > 0.0:
		ring = ring.lerp(Color.WHITE, _flash)
	if not disabled:
		draw_arc(c, r - 2.0, 0.0, TAU, 64, ring, 4.0 if is_ready or _flash > 0.0 else 2.0, true)

	var font := get_theme_font("font_bold", "SkillButton")
	# Segundos restantes
	if state == State.COOLDOWN and _remaining > 0.0:
		var fs := get_theme_font_size("font_size", "SkillButton")
		var text := "%.1f" % _remaining if _remaining < 1.0 else str(ceili(_remaining))
		var y := c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 6, UiTokens.BG_VOID)
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_PRIMARY)

	# Atalho de teclado (só desktop)
	if _show_shortcut and _shortcut != "":
		var cs := get_theme_font_size("caption_size", "SkillButton")
		draw_string(font, Vector2(0, DIAMETER + UiTokens.SPACE_XS + font.get_ascent(cs)), _shortcut, HORIZONTAL_ALIGNMENT_CENTER, size.x, cs, UiTokens.TEXT_SECONDARY)


func _draw_icon(c: Vector2, s: float, color: Color) -> void:
	match icon:
		Icon.CIRCLE:
			draw_arc(c, s, 0.0, TAU, 48, color, 5.0, true)
			draw_circle(c, s * 0.35, color)
		Icon.DIAMOND:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), color)
		Icon.HEX:
			var pts := PackedVector2Array()
			for i in 7:
				var a := TAU * i / 6.0 - PI * 0.5
				pts.append(c + Vector2(cos(a), sin(a)) * s)
			draw_polyline(pts, color, 5.0, true)


func _draw_sector(c: Vector2, r: float, frac: float, color: Color) -> void:
	if frac <= 0.0:
		return
	var steps := maxi(int(64 * frac), 2)
	var pts := PackedVector2Array([c])
	var start := -PI * 0.5
	for i in steps + 1:
		var a := start + TAU * frac * float(i) / steps
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, color)
