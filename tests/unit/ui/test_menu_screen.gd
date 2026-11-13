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


## BRF-116: o texto de Jogar fica no centro da FACE (retângulo menos a base escura de 12 px), em qualquer janela.
func _face_offset(b: Button, state: String) -> float:
	var sb: StyleBoxTexture = b.get_theme_stylebox(state)
	var content_center := (sb.content_margin_top + (b.size.y - sb.content_margin_bottom)) / 2.0
	var base := 12.0 if state == "normal" else 6.0 # a base escura encolhe 12 → 6 no pressionado (corpo desce 6)
	var face_center := (0.0 + (b.size.y - base) + (6.0 if state == "pressed" else 0.0)) / 2.0
	return content_center - face_center


func test_play_text_centered_on_face_in_two_viewports() -> void:
	var win := get_tree().root
	var old := win.size
	for sz in [Vector2i(375, 812), Vector2i(1280, 720)]:
		win.size = sz
		var m := await _menu({"level": 3, "xp": 10, "xp_to_next": 100, "coins": 5, "is_max": false})
		await wait_process_frames(2)
		assert_lt(absf(_face_offset(m.play_button, "normal")), 2.0, "normal %s" % [sz])
		assert_lt(absf(_face_offset(m.play_button, "pressed")), 2.0, "pressed %s" % [sz])
		var n: StyleBoxTexture = m.play_button.get_theme_stylebox("normal")
		var p: StyleBoxTexture = m.play_button.get_theme_stylebox("pressed")
		assert_almost_eq(p.content_margin_top - n.content_margin_top, 6.0, 0.5, "texto desce 6 px")
		assert_eq(n.content_margin_left, n.content_margin_right)
	win.size = old
