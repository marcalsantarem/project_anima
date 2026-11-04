@tool
class_name SkillButton
extends Control
## Botão circular de skill. docs/ui.md §5.1.
## Não chama a skill: toque/clique emitem `activated(slot)` e, se `inject_action`, a Input Action `skill_<slot>`.
## O estado vem do gameplay: on_used() ← skill_used, set_cooldown() ← cooldown_changed, set_ready() ← skill_ready.
## Arte da T-128 (T-138): molduras por estado, ícone (`icon_texture`; Icon.CIRCLE usa `ui_icon_skill_pulse`),
## cadeado e véu de recarga radial (`ui_skill_cooldown_mask`). O badge da tecla continua desenhado.
## `locked` (T-136): slot ainda não liberado. Cadeado + "NV x", ignora toque, clique, a action `skill_<slot>` e os sinais de gameplay.

signal activated(slot: int)

enum State { READY, COOLDOWN, DISABLED, LOCKED }
enum Icon { CIRCLE, DIAMOND, HEX }

const DIAMETER := float(UiTokens.SKILL_DIAMETER)
const PRESS_SCALE := 0.92
const READY_POP := 1.08
const SHAKE_PX := 6.0
const GLOW_PERIOD := 1.5
const BADGE_SIZE := 36.0
const ICON_SIZE := 88.0
const LOCK_SIZE := 64.0
const DIM_ALPHA := 0.55

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
## Vazio = arte padrão do `icon` (só Icon.CIRCLE tem arte; os outros são desenhados).
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		queue_redraw()
## Desligue quando quem ouve `activated` já aciona a skill (ex.: HUD → Arena.use_skill).
@export var inject_action := true

var action := &"skill_1"
## Nível de conta que libera o slot (só exibição; quem decide é o meta-jogo).
var unlock_level := 0
var state := State.READY
var _remaining := 0.0
var _total := 0.0
var _flash := 0.0
var _glow_t := 0.0
var _shortcut := ""
var _touch_index := -1
var _anim: Tween
var _badge_box := _make_badge_box()
var _veil_pts := PackedVector2Array()
var _veil_uvs := PackedVector2Array()


func _init() -> void:
	custom_minimum_size = Vector2(DIAMETER, DIAMETER + UiTokens.SHADOW_BASE)
	mouse_filter = MOUSE_FILTER_STOP
	focus_mode = FOCUS_NONE


func _ready() -> void:
	_shortcut = _shortcut_label()
	_update_accessibility()
	resized.connect(_update_pivot)
	_update_pivot()


func set_cooldown(remaining: float, total: float) -> void:
	if state == State.DISABLED or state == State.LOCKED:
		return
	_remaining = maxf(remaining, 0.0)
	_total = maxf(total, 0.001)
	state = State.COOLDOWN if _remaining > 0.0 else State.READY
	queue_redraw()


func set_ready() -> void:
	if state == State.LOCKED:
		return
	var was_cooldown := state == State.COOLDOWN
	state = State.READY
	_remaining = 0.0
	if was_cooldown:
		_pop(READY_POP)
	queue_redraw()


func on_used() -> void:
	if state == State.LOCKED:
		return
	_flash = 1.0
	queue_redraw()


func set_disabled(disabled: bool) -> void:
	if state == State.LOCKED:
		return
	if disabled:
		state = State.DISABLED
	else:
		state = State.COOLDOWN if _remaining > 0.0 else State.READY
	queue_redraw()


## Bloqueia (level > 0 aparece como "NV x") ou libera o slot. Liberado volta a `ready`.
func set_locked(locked: bool, level := 0) -> void:
	unlock_level = level if locked else 0
	if locked:
		state = State.LOCKED
		_remaining = 0.0
		_flash = 0.0
		_touch_index = -1
		mouse_default_cursor_shape = CURSOR_FORBIDDEN
	elif state == State.LOCKED:
		state = State.READY
		mouse_default_cursor_shape = CURSOR_ARROW
	_update_accessibility()
	queue_redraw()


func is_locked() -> bool:
	return state == State.LOCKED


func _update_accessibility() -> void:
	var text := "Skill %d" % slot
	if state == State.LOCKED:
		text += ", bloqueada" + (" até o nível %d" % unlock_level if unlock_level > 0 else "")
	accessibility_name = text


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
	if state == State.LOCKED:
		# Consome o toque/clique sem acionar nada (não vaza para a arena).
		if (event is InputEventScreenTouch or event is InputEventMouseButton) and _hit(event.position):
			accept_event()
		return
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


## Slot bloqueado: engole `skill_<slot>` (teclado ou injetada) antes do `_unhandled_input` do gameplay.
func _input(event: InputEvent) -> void:
	if state == State.LOCKED and event.is_action(action):
		get_viewport().set_input_as_handled()


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
	var locked := state == State.LOCKED
	var disabled := state == State.DISABLED or locked

	# Halo extra que pulsa (a moldura "pronta" já tem o halo fixo) e moldura do estado
	if is_ready and not Engine.is_editor_hint():
		var pulse := 0.5 - 0.5 * cos(TAU * _glow_t / GLOW_PERIOD)
		draw_circle(c, r + 8.0, Color(UiTokens.ACCENT, 0.25 * pulse))
	var frame := UiArt.SKILL_FRAME_LOCKED if disabled else (UiArt.SKILL_FRAME_READY if is_ready else UiArt.SKILL_FRAME_COOLDOWN)
	draw_texture_rect(frame, Rect2(c - UiArt.SKILL_FRAME_CENTER, UiArt.SKILL_FRAME_SIZE), false)
	if _flash > 0.0:
		draw_arc(c, r - 8.0, 0.0, TAU, 64, Color(1, 1, 1, _flash), 8.0, true)

	var font := get_theme_font("font_bold", "SkillButton")
	if locked:
		_draw_lock(c, r, font)
	else:
		var tex := _icon_texture()
		if tex:
			var half := ICON_SIZE * 0.5
			draw_texture_rect(tex, Rect2(c - Vector2(half, half), Vector2(ICON_SIZE, ICON_SIZE)), false, Color(1, 1, 1, DIM_ALPHA) if disabled else Color.WHITE)
		else:
			_draw_icon(c, r * 0.4, UiTokens.TEXT_SECONDARY if disabled else UiTokens.TEXT_PRIMARY)

	# Véu de recarga (sentido horário a partir do topo)
	if state == State.COOLDOWN and _total > 0.0:
		_draw_veil(c, clampf(_remaining / _total, 0.0, 1.0))

	# Segundos restantes
	if state == State.COOLDOWN and _remaining > 0.0:
		var fs := get_theme_font_size("font_size", "SkillButton")
		var text := "%.1f" % _remaining if _remaining < 1.0 else str(ceili(_remaining))
		var y := c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_OUTLINE + 2, UiTokens.INK)
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_PRIMARY)

	# Badge da tecla / slot (canto superior direito)
	var bc := c + Vector2(r, -r) * 0.72
	var half_b := BADGE_SIZE * 0.5
	draw_style_box(_badge_box, Rect2(bc - Vector2(half_b, half_b), Vector2(BADGE_SIZE, BADGE_SIZE + 3)))
	var cs := get_theme_font_size("caption_size", "SkillButton")
	var label := _shortcut if _shortcut != "" else str(slot)
	var by := bc.y + (font.get_ascent(cs) - font.get_descent(cs)) * 0.5
	draw_string(font, Vector2(bc.x - half_b, by), label, HORIZONTAL_ALIGNMENT_CENTER, BADGE_SIZE, cs, UiTokens.INK)


static func _make_badge_box() -> StyleBoxFlat:
	var badge := UiTokens.cartoon_box(UiTokens.BADGE, 10, 3)
	badge.set_border_width_all(3)
	badge.border_width_bottom = 6
	return badge


func _icon_texture() -> Texture2D:
	if icon_texture:
		return icon_texture
	return UiArt.SKILL_PULSE if icon == Icon.CIRCLE else null


## Cadeado (acima do centro) + "NV x" (abaixo), como no mockup aprovado.
func _draw_lock(c: Vector2, r: float, font: Font) -> void:
	var has_level := unlock_level > 0
	var lc := c + Vector2(0, -r * 0.22 if has_level else 0.0)
	var half := LOCK_SIZE * 0.5
	draw_texture_rect(UiArt.LOCK, Rect2(lc - Vector2(half, half), Vector2(LOCK_SIZE, LOCK_SIZE)), false)
	if not has_level:
		return
	var fs := UiTokens.FONT_HUD
	var text := "NV %d" % unlock_level
	var y := c.y + r * 0.62
	draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_OUTLINE, UiTokens.INK)
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.TEXT_PRIMARY)


func _icon_points(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match icon:
		Icon.CIRCLE: # explosão de 8 pontas
			for i in 16:
				var a := TAU * i / 16.0 - PI * 0.5
				pts.append(c + Vector2(cos(a), sin(a)) * (s if i % 2 == 0 else s * 0.5))
		Icon.DIAMOND:
			pts = PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.8, 0), c + Vector2(0, s), c + Vector2(-s * 0.8, 0)])
		Icon.HEX:
			for i in 6:
				var a := TAU * i / 6.0 - PI * 0.5
				pts.append(c + Vector2(cos(a), sin(a)) * s)
	return pts


func _draw_icon(c: Vector2, s: float, color: Color) -> void:
	var pts := _icon_points(c, s)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, UiTokens.INK, 10.0, true)
	draw_colored_polygon(pts, color)
	if icon == Icon.CIRCLE:
		draw_circle(c, s * 0.28, UiTokens.ACCENT)


## Setor da máscara radial (textura em UV); buffers reaproveitados entre desenhos.
func _draw_veil(c: Vector2, frac: float) -> void:
	if frac <= 0.0:
		return
	var mr := UiArt.SKILL_MASK_RADIUS
	if frac >= 0.999:
		draw_texture_rect(UiArt.SKILL_COOLDOWN_MASK, Rect2(c - Vector2(mr, mr), Vector2(mr, mr) * 2.0), false)
		return
	var steps := maxi(int(64 * frac), 2)
	_veil_pts.resize(steps + 2)
	_veil_uvs.resize(steps + 2)
	_veil_pts[0] = c
	_veil_uvs[0] = Vector2(0.5, 0.5)
	for i in steps + 1:
		var a := -PI * 0.5 + TAU * frac * float(i) / steps
		var d := Vector2(cos(a), sin(a))
		_veil_pts[i + 1] = c + d * mr
		_veil_uvs[i + 1] = Vector2(0.5, 0.5) + d * 0.5
	draw_colored_polygon(_veil_pts, Color.WHITE, _veil_uvs, UiArt.SKILL_COOLDOWN_MASK)
