extends GutTest
## T-136: estado "bloqueado" do SkillButton e slots bloqueados do HUD.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")


func _button(slot := 2) -> SkillButton:
	var sb := SkillButton.new()
	sb.slot = slot
	add_child_autofree(sb)
	return sb


func _key_action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func test_locked_ignores_gameplay_signals() -> void:
	var sb := _button()
	sb.set_locked(true, 5)
	assert_true(sb.is_locked())
	assert_eq(sb.unlock_level, 5)
	sb.set_cooldown(3.0, 5.0)
	sb.set_ready()
	sb.on_used()
	sb.set_disabled(false)
	assert_eq(sb.state, SkillButton.State.LOCKED)


func test_locked_touch_does_not_activate() -> void:
	var sb := _button()
	sb.set_locked(true, 5)
	watch_signals(sb)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(sb.size.x * 0.5, SkillButton.DIAMETER * 0.5)
	sb._gui_input(touch)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = touch.position
	sb._gui_input(click)
	assert_signal_not_emitted(sb, "activated")


class Listener:
	extends Node
	var seen: Array[StringName] = []
	func _unhandled_input(event: InputEvent) -> void:
		for a in [&"skill_1", &"skill_2"]:
			if event.is_action_pressed(a):
				seen.append(a)


func test_locked_swallows_its_action_only() -> void:
	var sb := _button(2)
	sb.set_locked(true, 5)
	var listener := Listener.new()
	add_child_autofree(listener)
	var vp := sb.get_viewport()
	vp.push_input(_key_action(&"skill_1"))
	vp.push_input(_key_action(&"skill_2"))
	assert_eq(listener.seen, [&"skill_1"] as Array[StringName], "skill_2 é engolida; skill_1 passa")


func test_unlock_returns_to_ready() -> void:
	var sb := _button()
	sb.set_locked(true, 8)
	sb.set_locked(false)
	assert_eq(sb.state, SkillButton.State.READY)
	assert_eq(sb.unlock_level, 0)
	sb.set_cooldown(2.0, 4.0)
	assert_eq(sb.state, SkillButton.State.COOLDOWN)


func test_hud_m1_default_locks_slots_2_and_3() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	assert_false(hud._skill(1).is_locked())
	assert_true(hud._skill(2).is_locked())
	assert_eq(hud._skill(2).unlock_level, 5)
	assert_true(hud._skill(3).is_locked())
	assert_eq(hud._skill(3).unlock_level, 8)


func test_hud_unlock_levels_are_data() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	hud.set_slot_unlock_levels([0, 0, 8] as Array[int])
	assert_false(hud._skill(2).is_locked())
	assert_true(hud._skill(3).is_locked())
	hud.set_slot_unlock_levels([] as Array[int])
	for i in 3:
		assert_false(hud._skill(i + 1).is_locked(), "lista curta = liberado")
