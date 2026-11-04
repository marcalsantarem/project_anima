extends GutTest
## UpgradeButton (T-135): estados, compra só quando comprável, teclado sem roubar o Espaço, "+1".

var ub: UpgradeButton


func before_each() -> void:
	ub = UpgradeButton.new()
	ub.upgrade_id = &"upgrade_atk_spd"
	add_child_autofree(ub)
	watch_signals(ub)


func _click() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = ub.size * 0.5
	ub._gui_input(ev)


func _key_action(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func test_min_size_and_touch_target() -> void:
	assert_eq(ub.custom_minimum_size, UiTokens.UPGRADE_SIZE)
	assert_true(ub.custom_minimum_size.y >= 44.0)


func test_disabled_until_first_upgrade_signal() -> void:
	assert_eq(ub.state, UpgradeButton.State.DISABLED)
	_click()
	assert_signal_not_emitted(ub, "buy_requested")


func test_states_follow_cost_and_particles() -> void:
	ub.set_upgrade(1, 5, 100)
	assert_eq(ub.state, UpgradeButton.State.POOR)
	ub.set_particles(100)
	assert_eq(ub.state, UpgradeButton.State.AFFORDABLE)
	ub.set_upgrade(5, 5, -1)
	assert_eq(ub.state, UpgradeButton.State.MAX)
	ub.set_disabled(true)
	assert_eq(ub.state, UpgradeButton.State.DISABLED)


func test_click_emits_only_when_affordable() -> void:
	ub.set_upgrade(0, 5, 50)
	_click()
	assert_signal_not_emitted(ub, "buy_requested", "sem Partículas")
	ub.set_particles(50)
	_click()
	assert_signal_emitted_with_parameters(ub, "buy_requested", [&"upgrade_atk_spd"])
	ub.set_upgrade(5, 5, -1)
	_click()
	assert_signal_emit_count(ub, "buy_requested", 1, "MAX não compra")


func test_ui_accept_buys_but_game_actions_do_not() -> void:
	ub.set_upgrade(0, 5, 10)
	ub.set_particles(10)
	ub._gui_input(_key_action(&"ui_accept"))
	assert_signal_emit_count(ub, "buy_requested", 1)
	# Espaço é ui_accept e também skill_4: não pode virar compra.
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.keycode = KEY_SPACE
	space.pressed = true
	if space.is_action(&"skill_4") and space.is_action(&"ui_accept"):
		ub._gui_input(space)
		assert_signal_emit_count(ub, "buy_requested", 1, "Espaço fica com a skill")
	else:
		pass_test("Espaço não é ui_accept + skill_4 neste Input Map")


func test_focusable_for_keyboard() -> void:
	assert_eq(ub.focus_mode, Control.FOCUS_ALL)


func test_plus_one_only_on_level_gain() -> void:
	ub.set_upgrade(1, 5, 10)
	assert_eq(ub._plus, 0.0, "primeiro sinal não mostra +1")
	ub.set_upgrade(2, 5, 20)
	await wait_physics_frames(2)
	assert_gt(ub._plus, 0.0, "+1 após subir de nível")
	await wait_seconds(UiTokens.ANIM_UI * 2.0 + 0.1)
	assert_eq(ub._plus, 0.0, "+1 some")


func test_texture_override() -> void:
	ub.icon_texture = PlaceholderTexture2D.new()
	assert_not_null(ub.icon_texture)
