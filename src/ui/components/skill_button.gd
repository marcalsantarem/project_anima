@tool
class_name SkillButton
extends Control
## Botão circular de skill. docs/ui.md §5.1.
## Não chama a skill: toque/clique emitem `activated(slot)` e, se `inject_action`, a Input Action `skill_<slot>`.
## O estado vem do gameplay: on_used() ← skill_used, set_cooldown() ← cooldown_changed, set_ready() ← skill_ready.
## Arte holográfica (T-290, ui_hud_skill_*, 1:1): moldura por estado (pronto, recarga, bloqueado, vazio), anel de
## progresso e véu radial da recarga, ícone (`icon_texture`; Icon.CIRCLE usa `UiArt.SKILL_METEOR_PATH`), cadeado
## e badge da tecla (`ui_hud_key_badge`). `empty` = liberado sem Módulo (anel tracejado, sem ícone).
## `locked` (T-136): slot ainda não liberado. Cadeado + "NV x", ignora toque, clique, a action `skill_<slot>` e os sinais de gameplay.
## `drag_aim` (T-178, decisão 46): pronto, o toque vira "toque simples" (activated ao soltar) ou, passado
## AIM_THRESHOLD, mira (aim_started/aim_moved/aim_ended, `at` em coordenadas do viewport). Quem fala com a arena é o HUD.

signal activated(slot: int)
## Arrasto passou do limiar: modo mira.
signal aim_started(slot: int)
## Dedo/mouse em modo mira; `at` em coordenadas do viewport.
signal aim_moved(slot: int, at: Vector2)
## Fim da mira. `cancelled` = soltou sobre o próprio botão ou a mira foi abortada (recarga, bloqueio, fim).
signal aim_ended(slot: int, at: Vector2, cancelled: bool)

enum State { READY, COOLDOWN, DISABLED, LOCKED }
enum Icon { CIRCLE, DIAMOND, HEX }

const DIAMETER := float(UiTokens.SKILL_DIAMETER)
const PRESS_SCALE := 0.92
## Pulso de "pronto" (T-117): 1 → READY_POP → 1 em READY_PULSE_TIME, com o anel mais claro.
const READY_POP := 1.12
const READY_PULSE_TIME := 0.3
## "Afundar" curto no uso (T-117), junto com o flash do anel.
const USE_SINK := 0.88
const SHAKE_PX := 6.0
const GLOW_PERIOD := 1.5
const ICON_SIZE := 88.0
const LOCK_SIZE := 64.0
const LOCK_TEXT_SIZE := 30
const DIM_ALPHA := 0.55
## Distância (px da resolução base) que separa toque simples de arrasto para mirar.
const AIM_THRESHOLD := 24.0

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
## Arrastar a partir do botão pronto para mirar (T-178). Desligado = acionamento ao apertar, como antes.
@export var drag_aim := false

var action := &"skill_1"
## Nível de conta que libera o slot (só exibição; quem decide é o meta-jogo).
var unlock_level := 0
var state := State.READY
## Liberado sem Módulo equipado: só visual (moldura `empty`, sem ícone). Não muda toque nem sinais.
var empty := false
var _remaining := 0.0
var _total := 0.0
var _flash := 0.0
## 1 → 0 durante o pulso de "pronto" (brilho extra do anel).
var ready_glow := 0.0
## Houve recarga desde o último "pronto" (o cooldown_changed com 0 pode chegar antes do skill_ready).
var _cooling := false
var _glow_t := 0.0
var _shortcut := ""
var _touch_index := -1
var _anim: Tween
var _veil_pts := PackedVector2Array()
var _veil_uvs := PackedVector2Array()
## Em modo mira (por arrasto ou pela tecla segurada, ver set_aiming).
var aiming := false
## Mira em área inválida: anel `danger` em vez de `accent`.
var aim_valid := true
var _pending := false # pressionado pronto, ainda sem decidir entre toque e arrasto
var _mouse_down := false
var _press_at := Vector2.ZERO
var _aim_at := Vector2.ZERO


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
	if state != State.READY:
		_cooling = true
		cancel_aim()
	queue_redraw()


func set_ready() -> void:
	if state == State.LOCKED:
		return
	var was_cooldown := _cooling or state == State.COOLDOWN
	_cooling = false
	state = State.READY
	_remaining = 0.0
	if was_cooldown:
		_ready_pulse()
	queue_redraw()


func on_used() -> void:
	if state == State.LOCKED:
		return
	_flash = 1.0
	_pending = false
	_pop(USE_SINK)
	queue_redraw()


func set_disabled(disabled: bool) -> void:
	if state == State.LOCKED:
		return
	if disabled:
		state = State.DISABLED
		cancel_aim()
		_pending = false
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
		_cooling = false
		cancel_aim()
		_pending = false
		_touch_index = -1
		_mouse_down = false
		mouse_default_cursor_shape = CURSOR_FORBIDDEN
	elif state == State.LOCKED:
		state = State.READY
		mouse_default_cursor_shape = CURSOR_ARROW
	_update_accessibility()
	queue_redraw()


func set_empty(on: bool) -> void:
	if empty != on:
		empty = on
		queue_redraw()


func is_locked() -> bool:
	return state == State.LOCKED


func _update_accessibility() -> void:
	var key := "SKILL_A11Y"
	if state == State.LOCKED:
		key = "SKILL_A11Y_LOCKED_LEVEL" if unlock_level > 0 else "SKILL_A11Y_LOCKED"
	accessibility_name = Loc.t(key, {"slot": slot, "level": unlock_level})


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
	if ready_glow > 0.0:
		ready_glow = maxf(ready_glow - delta / READY_PULSE_TIME, 0.0)
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
		if event.pressed:
			if _touch_index != -1 or not _hit(event.position):
				return
			_touch_index = event.index
			_down(event.position)
		elif event.index == _touch_index:
			# O release vem para quem recebeu o toque, mesmo fora do círculo.
			_touch_index = -1
			_up(event.position)
		else:
			return
		accept_event()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_drag(event.position)
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Toque já foi tratado acima; ignora o mouse emulado.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed:
			if not _hit(event.position):
				return
			_mouse_down = true
			_down(event.position)
		elif _mouse_down:
			_mouse_down = false
			_up(event.position)
		else:
			return
		accept_event()
	elif event is InputEventMouseMotion and _mouse_down and event.device != InputEvent.DEVICE_ID_EMULATION:
		_drag(event.position)
		accept_event()


func _down(local: Vector2) -> void:
	if drag_aim and state == State.READY:
		_pending = true
		_press_at = _to_viewport(local)
		_pop(PRESS_SCALE)
	else:
		_press()


func _drag(local: Vector2) -> void:
	if not _pending:
		return
	var at := _to_viewport(local)
	if not aiming:
		if at.distance_to(_press_at) < AIM_THRESHOLD:
			return
		set_aiming(true)
		aim_started.emit(slot)
	_aim_at = at
	aim_moved.emit(slot, at)


func _up(local: Vector2) -> void:
	if not _pending:
		_release()
		return
	_pending = false
	if aiming:
		set_aiming(false)
		aim_ended.emit(slot, _to_viewport(local), _hit(local))
		return
	# Toque simples: acionamento automático, como antes do arrasto existir.
	activated.emit(slot)
	if inject_action:
		_send_action(true)
		_send_action(false)


## Estado visual "mirando" (também usado pelo HUD com a tecla segurada). Não emite sinais.
func set_aiming(on: bool) -> void:
	if aiming == on:
		return
	aiming = on
	aim_valid = true
	queue_redraw()


func set_aim_valid(valid: bool) -> void:
	if aim_valid != valid:
		aim_valid = valid
		queue_redraw()


## Aborta a mira por arrasto em curso (sem acionar): emite aim_ended(..., true).
func cancel_aim() -> void:
	if not _pending:
		return
	_pending = false
	if aiming:
		set_aiming(false)
		aim_ended.emit(slot, _aim_at, true)


func _to_viewport(local: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * local


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


## Pulso ao ficar pronto (T-117): escala 1 → 1,12 → 1 e brilho do anel, ~0,3 s.
func _ready_pulse() -> void:
	if _anim:
		_anim.kill()
	scale = Vector2.ONE
	ready_glow = 1.0
	var half := READY_PULSE_TIME * 0.5
	_anim = create_tween()
	_anim.tween_property(self, "scale", Vector2.ONE * READY_POP, half).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim.tween_property(self, "scale", Vector2.ONE, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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

	# Halo extra que pulsa (a moldura "pronta" já tem o brilho fixo) e moldura do estado
	if is_ready and not Engine.is_editor_hint():
		var pulse := 0.5 - 0.5 * cos(TAU * _glow_t / GLOW_PERIOD)
		draw_circle(c, r + 8.0, Color(UiTokens.HOLO_LINE, 0.2 * pulse))
	var frame := UiArt.HUD_SKILL_LOCKED if locked else (UiArt.HUD_SKILL_EMPTY if empty else (UiArt.HUD_SKILL_READY if is_ready else UiArt.HUD_SKILL_COOLDOWN))
	draw_texture_rect(frame, Rect2(c - UiArt.SKILL_FRAME_CENTER, UiArt.SKILL_FRAME_SIZE), false)
	if ready_glow > 0.0:
		draw_circle(c, r + 10.0, Color(UiTokens.HOLO_LINE, 0.45 * ready_glow))
		draw_arc(c, r - 2.0, 0.0, TAU, 64, Color(1, 1, 1, 0.8 * ready_glow), 6.0, true)
	if _flash > 0.0:
		draw_arc(c, r - 8.0, 0.0, TAU, 64, Color(1, 1, 1, _flash), 8.0, true)
	if aiming:
		draw_arc(c, r + 6.0, 0.0, TAU, 64, UiTokens.HOLO_LINE if aim_valid else UiTokens.DANGER, 8.0, true)

	var font := get_theme_font("font_bold", "SkillButton")
	if locked:
		_draw_lock(c, r, font)
	elif not empty:
		var tex := _icon_texture()
		if tex:
			var half := ICON_SIZE * 0.5
			draw_texture_rect(tex, Rect2(c - Vector2(half, half), Vector2(ICON_SIZE, ICON_SIZE)), false, Color(1, 1, 1, DIM_ALPHA) if disabled or aiming else Color.WHITE)
		else:
			_draw_icon(c, r * 0.4, UiTokens.HOLO_MUTED if disabled else UiTokens.HOLO_TEXT)

	# Recarga: véu do setor restante, anel de progresso (enche conforme a recarga passa) e segundos
	if state == State.COOLDOWN and _total > 0.0:
		var left := clampf(_remaining / _total, 0.0, 1.0)
		_draw_sector(UiArt.HUD_SKILL_MASK, Rect2(c - Vector2(UiArt.SKILL_MASK_RADIUS, UiArt.SKILL_MASK_RADIUS), Vector2(UiArt.SKILL_MASK_RADIUS, UiArt.SKILL_MASK_RADIUS) * 2.0), c, UiArt.SKILL_MASK_RADIUS, left)
		_draw_sector(UiArt.HUD_SKILL_RING, Rect2(c - UiArt.SKILL_FRAME_CENTER, UiArt.SKILL_FRAME_SIZE), c, UiArt.SKILL_RING_RADIUS, 1.0 - left)
	if state == State.COOLDOWN and _remaining > 0.0:
		var fs := get_theme_font_size("font_size", "SkillButton")
		var text := "%.1f" % _remaining if _remaining < 1.0 else str(ceili(_remaining))
		var y := c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.HOLO_OUTLINE, UiTokens.HOLO_BG)
		draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, UiTokens.HOLO_TEXT)

	# Badge da tecla / slot (canto superior direito); apagado no bloqueado
	var bc := c + UiArt.KEY_BADGE_OFFSET
	var half_b := UiArt.KEY_BADGE_SIZE * 0.5
	draw_texture_rect(UiArt.HUD_KEY_BADGE_OFF if locked else UiArt.HUD_KEY_BADGE, Rect2(bc - Vector2(half_b, half_b), Vector2(UiArt.KEY_BADGE_SIZE, UiArt.KEY_BADGE_SIZE)), false)
	var cs := get_theme_font_size("caption_size", "SkillButton")
	var label := _shortcut if _shortcut != "" else str(slot)
	var by := bc.y + (font.get_ascent(cs) - font.get_descent(cs)) * 0.5
	draw_string(font, Vector2(bc.x - half_b, by), label, HORIZONTAL_ALIGNMENT_CENTER, UiArt.KEY_BADGE_SIZE, cs, UiTokens.HOLO_DIS_TEXT if locked else UiTokens.HOLO_TEXT)


func _icon_texture() -> Texture2D:
	if icon_texture:
		return icon_texture
	return UiArt.load_icon(UiArt.SKILL_METEOR_PATH) if icon == Icon.CIRCLE else null


## Cadeado holográfico (acima do centro) + "NV x" (abaixo) em `holo_muted`.
func _draw_lock(c: Vector2, r: float, font: Font) -> void:
	var has_level := unlock_level > 0
	var lc := c + Vector2(0, -r * 0.22 if has_level else 0.0)
	var half := LOCK_SIZE * 0.5
	draw_texture_rect(UiArt.LOCK_HOLO, Rect2(lc - Vector2(half, half), Vector2(LOCK_SIZE, LOCK_SIZE)), false)
	if not has_level:
		return
	var text := Loc.t("COMMON_LOCK_LEVEL", {"level": unlock_level})
	var y := c.y + r * 0.62
	draw_string_outline(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, LOCK_TEXT_SIZE, UiTokens.HOLO_OUTLINE, UiTokens.HOLO_BG)
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, LOCK_TEXT_SIZE, UiTokens.HOLO_MUTED)


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
	draw_polyline(closed, UiTokens.HOLO_BG, 10.0, true)
	draw_colored_polygon(pts, color)
	if icon == Icon.CIRCLE:
		draw_circle(c, s * 0.28, UiTokens.HOLO_LINE)


## Setor horário (a partir do topo) de `frac` da volta, preenchido com a textura em `tex_rect`; buffers reaproveitados.
func _draw_sector(tex: Texture2D, tex_rect: Rect2, c: Vector2, radius: float, frac: float) -> void:
	if frac <= 0.0:
		return
	if frac >= 0.999:
		draw_texture_rect(tex, tex_rect, false)
		return
	var steps := maxi(int(64 * frac), 2)
	_veil_pts.resize(steps + 2)
	_veil_uvs.resize(steps + 2)
	_veil_pts[0] = c
	_veil_uvs[0] = (c - tex_rect.position) / tex_rect.size
	for i in steps + 1:
		var a := -PI * 0.5 + TAU * frac * float(i) / steps
		var p := c + Vector2(cos(a), sin(a)) * radius
		_veil_pts[i + 1] = p
		_veil_uvs[i + 1] = (p - tex_rect.position) / tex_rect.size
	draw_colored_polygon(_veil_pts, Color.WHITE, _veil_uvs, tex)
