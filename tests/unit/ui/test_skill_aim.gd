extends GutTest
## T-178 (decisão 46): toque simples, arrastar para mirar, cancelar e tecla segurada, com uma Arena falsa.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const VALID_MAX_Y := 900.0 ## FakeArena: abaixo disso é a bandeja (inválido)


class FakeArena:
	extends Node
	var used: Array = [] # [slot, at]
	var shown := 0
	var hidden := 0
	var last_aim := Vector2.INF
	func use_skill(slot: int, at: Vector2 = Vector2.INF) -> bool:
		used.append([slot, at])
		return true
	func show_skill_aim(_slot: int, at: Vector2) -> void:
		shown += 1
		last_aim = at
	func hide_skill_aim() -> void:
		hidden += 1
	func can_aim_at(at: Vector2) -> bool:
		return at.y < VALID_MAX_Y


var hud: Hud
var arena: FakeArena


func before_each() -> void:
	arena = FakeArena.new()
	add_child_autofree(arena)
	hud = HUD_SCENE.instantiate()
	hud.bind(arena)
	add_child_autofree(hud)
	await wait_process_frames(2)


func _center(sb: SkillButton) -> Vector2:
	return Vector2(sb.size.x * 0.5, SkillButton.DIAMETER * 0.5)


func _touch(sb: SkillButton, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.pressed = pressed
	ev.position = pos
	sb._gui_input(ev)


func _drag(sb: SkillButton, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.position = pos
	sb._gui_input(ev)


## Ponto local do botão que cai `dy` px acima dele, em coordenadas do viewport.
func _up_by(sb: SkillButton, dy: float) -> Vector2:
	return _center(sb) + Vector2(0, -dy)


func test_simple_tap_uses_auto_target() -> void:
	var sb := hud._skill(1)
	_touch(sb, _center(sb), true)
	assert_eq(arena.used.size(), 0, "toque simples dispara ao soltar")
	_drag(sb, _center(sb) + Vector2(10, 0)) # tremida abaixo do limiar
	_touch(sb, _center(sb) + Vector2(10, 0), false)
	assert_eq(arena.used, [[1, Vector2.INF]])
	assert_eq(arena.shown, 0)


func test_drag_aims_and_launches_at_point() -> void:
	var sb := hud._skill(1)
	watch_signals(sb)
	var target := _up_by(sb, 400.0)
	_touch(sb, _center(sb), true)
	_drag(sb, _up_by(sb, 200.0))
	assert_true(sb.aiming, "botão em estado mirando")
	_drag(sb, target)
	assert_gt(arena.shown, 0, "prévia na arena")
	var at := sb.get_global_transform_with_canvas() * target
	assert_almost_eq(arena.last_aim, at, Vector2.ONE * 0.01)
	_touch(sb, target, false)
	assert_false(sb.aiming)
	assert_gt(arena.hidden, 0)
	assert_eq(arena.used.size(), 1)
	assert_eq(arena.used[0][0], 1)
	assert_almost_eq(arena.used[0][1], at, Vector2.ONE * 0.01)
	assert_signal_not_emitted(sb, "activated")


func test_drag_back_to_button_cancels() -> void:
	var sb := hud._skill(1)
	_touch(sb, _center(sb), true)
	_drag(sb, _up_by(sb, 300.0))
	_drag(sb, _center(sb))
	_touch(sb, _center(sb), false)
	assert_eq(arena.used.size(), 0, "soltar sobre o botão cancela")
	assert_gt(arena.hidden, 0)
	assert_false(sb.aiming)


func test_release_on_invalid_area_cancels() -> void:
	var sb := hud._skill(1)
	_touch(sb, _center(sb), true)
	var below := _center(sb) + Vector2(SkillButton.DIAMETER * 1.5, 0) # ao lado, na bandeja
	_drag(sb, below)
	assert_true(sb.aiming)
	assert_false(sb.aim_valid, "anel de área inválida")
	_touch(sb, below, false)
	assert_eq(arena.used.size(), 0)


func test_cooldown_does_not_aim() -> void:
	var sb := hud._skill(1)
	sb.set_cooldown(3.0, 5.0)
	watch_signals(sb)
	_touch(sb, _center(sb), true)
	_drag(sb, _up_by(sb, 300.0))
	_touch(sb, _up_by(sb, 300.0), false)
	assert_signal_not_emitted(sb, "aim_started")
	assert_eq(arena.shown, 0)
	assert_false(sb.aiming)
	for u in arena.used:
		assert_eq(u[1], Vector2.INF, "em recarga só o acionamento automático (rejeitado pelo gameplay)")


func test_cooldown_mid_drag_aborts_aim() -> void:
	var sb := hud._skill(1)
	_touch(sb, _center(sb), true)
	_drag(sb, _up_by(sb, 300.0))
	sb.set_cooldown(3.0, 5.0)
	assert_false(sb.aiming)
	_touch(sb, _up_by(sb, 300.0), false)
	assert_eq(arena.used.size(), 0)


func test_mouse_drag_launches() -> void:
	var sb := hud._skill(1)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _center(sb)
	sb._gui_input(press)
	var move := InputEventMouseMotion.new()
	move.position = _up_by(sb, 400.0)
	sb._gui_input(move)
	var release := press.duplicate()
	release.pressed = false
	release.position = move.position
	sb._gui_input(release)
	assert_eq(arena.used.size(), 1)
	assert_ne(arena.used[0][1], Vector2.INF)


func _action(pressed: bool) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = &"skill_1"
	ev.pressed = pressed
	return ev


func test_key_tap_is_auto_on_release() -> void:
	hud._input(_action(true))
	assert_true(hud._skill(1).aiming, "segurar a tecla mostra a mira")
	assert_eq(arena.used.size(), 0)
	hud._input(_action(false))
	assert_eq(arena.used, [[1, Vector2.INF]])
	assert_false(hud._skill(1).aiming)


func test_key_held_click_launches_at_cursor() -> void:
	hud._input(_action(true))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var at := hud.get_viewport().get_mouse_position()
	click.position = at
	hud._input(click)
	if arena.can_aim_at(at):
		assert_eq(arena.used, [[1, at]])
	hud._input(_action(false))
	assert_eq(arena.used.size(), 1, "soltar depois do clique não dispara de novo")


func test_key_ignored_while_cooldown() -> void:
	hud._skill(1).set_cooldown(3.0, 5.0)
	hud._input(_action(true))
	assert_eq(hud._key_slot, 0)
	assert_false(hud._skill(1).aiming)
