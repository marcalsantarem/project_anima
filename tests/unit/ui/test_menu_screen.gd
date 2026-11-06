extends GutTest
## T-190 (BRF-113): menu principal holográfico. Recebe dados por setup(), emite play_pressed, engrenagem sem ação.

const MENU := preload("res://src/ui/screens/menu_screen.tscn")


func _menu(view: Dictionary) -> MenuScreen:
	var m: MenuScreen = MENU.instantiate()
	add_child_autofree(m)
	m.setup(view)
	await wait_process_frames(2)
	return m


func _texts(n: Node, out: Array) -> Array:
	if n is Label or n is Button:
		out.append(n.text)
	for c in n.get_children():
		_texts(c, out)
	return out


func test_level_one_empty_bar() -> void:
	var m := await _menu({"level": 1, "xp": 0, "xp_to_next": 100, "coins": 0, "is_max": false})
	assert_eq(m.level_label.text, "NÍVEL 1")
	assert_eq(m.badge_label.text, "1")
	assert_eq(m.xp_label.text, "0 / 100 XP")
	assert_eq(m.coins_label.text, "0")
	assert_false(m.get_node("Root/LevelRow/LevelText/XpBar/Fill").visible)


func test_mid_level_partial_bar() -> void:
	var m := await _menu({"level": 4, "xp": 320, "xp_to_next": 500, "coins": 1250, "is_max": false})
	assert_eq(m.xp_label.text, "320 / 500 XP")
	assert_eq(m.coins_label.text, "1.250")
	var bar: Control = m.get_node("Root/LevelRow/LevelText/XpBar")
	var fill: Control = bar.get_node("Fill")
	assert_true(fill.visible)
	assert_almost_eq(fill.size.x, (bar.size.x - 8.0) * 0.64, 1.0)


func test_max_level_shows_max_and_full_bar() -> void:
	var m := await _menu({"level": 30, "xp": 0, "xp_to_next": 0, "coins": 5, "is_max": true})
	assert_eq(m.xp_label.text, "MAX")
	assert_eq(m.level_label.text, "NÍVEL 30")
	var bar: Control = m.get_node("Root/LevelRow/LevelText/XpBar")
	assert_almost_eq(bar.get_node("Fill").size.x, bar.size.x - 8.0, 1.0)


func test_xp_at_limit_is_clamped() -> void:
	assert_eq(MenuScreen.xp_ratio(500, 500, false), 1.0)
	assert_eq(MenuScreen.xp_ratio(900, 500, false), 1.0)
	assert_eq(MenuScreen.xp_ratio(10, 0, false), 0.0)
	assert_eq(MenuScreen.xp_ratio(0, 0, true), 1.0)
	var m := await _menu({"level": 5, "xp": 499, "xp_to_next": 500, "coins": 1, "is_max": false})
	var bar: Control = m.get_node("Root/LevelRow/LevelText/XpBar")
	assert_lte(m.get_node("Root/LevelRow/LevelText/XpBar/Fill").size.x, bar.size.x - 8.0 + 0.01)


func test_format_number() -> void:
	assert_eq(MenuScreen.format_number(999), "999")
	assert_eq(MenuScreen.format_number(1000), "1.000")
	assert_eq(MenuScreen.format_number(1234567), "1.234.567")


func test_play_pressed_emitted() -> void:
	var m := await _menu({"level": 1, "xp": 0, "xp_to_next": 100, "coins": 0, "is_max": false})
	watch_signals(m)
	m.play_button.pressed.emit()
	assert_signal_emit_count(m, "play_pressed", 1)


func test_settings_button_does_nothing() -> void:
	var m := await _menu({"level": 1, "xp": 0, "xp_to_next": 100, "coins": 0, "is_max": false})
	watch_signals(m)
	m.settings_button.pressed.emit()
	assert_signal_not_emitted(m, "play_pressed")
	assert_eq(m.settings_button.get_signal_connection_list("pressed").size(), 0)


func test_no_module_slot_alfa_or_version_text() -> void:
	var m := await _menu({"level": 4, "xp": 320, "xp_to_next": 500, "coins": 1250, "is_max": false})
	for t: String in _texts(m, []):
		var u := t.to_upper()
		for bad in ["MÓDULO", "MODULO", "SLOT", "ALFA", "ALPHA", "VERSÃO", " V0", "VERTICAL"]:
			assert_false(u.contains(bad), "texto proibido '%s' em '%s'" % [bad, t])


func test_play_target_size() -> void:
	for h in [616, 812]:
		var m := await _menu({"level": 1, "xp": 0, "xp_to_next": 100, "coins": 0, "is_max": false})
		assert_gte(m.play_button.size.x, 281.0)
		assert_gte(m.play_button.size.y, 78.0)
		m.queue_free()
