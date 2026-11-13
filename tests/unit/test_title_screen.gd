extends GutTest
## Título tecnológico (T-179): escala da arte igual à do shell, botão tocável e véu de saída.

var title: TitleScreen


func before_each() -> void:
	title = load("res://src/ui/screens/title_screen.tscn").instantiate()
	add_child_autofree(title)
	await wait_process_frames(1)


func test_art_scale_matches_shell() -> void:
	# --s = min(h/1376, max(w/768, 0,88·h/1376))
	assert_almost_eq(TitleScreen.art_scale(Vector2(720, 1280)), 1280.0 / 1376.0, 0.0001, "16:9 cobre a altura")
	assert_almost_eq(TitleScreen.art_scale(Vector2(720, 1560)), 1560.0 * 0.88 / 1376.0, 0.0001, "alta: 88% da altura")
	assert_almost_eq(TitleScreen.art_scale(Vector2(2048, 1280)), 1280.0 / 1376.0, 0.0001, "larga: altura inteira")


func test_start_button_is_touchable() -> void:
	var b := title.find_child("StartButton", true, false) as Button
	assert_not_null(b)
	if b != null:
		assert_gte(b.size.y, float(UiTokens.TOUCH_MIN))
		assert_eq(b.mouse_filter, Control.MOUSE_FILTER_IGNORE, "o gesto vale na tela toda")


func test_gesture_emits_once_and_fades_from_dark() -> void:
	watch_signals(title)
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	title._input(key)
	title._input(key)
	assert_signal_emit_count(title, "start_requested", 1)
	var veil := get_tree().root.get_node_or_null(NodePath(TitleScreen.FADE_NAME))
	assert_not_null(veil, "véu de saída na raiz")
	await wait_seconds(TitleScreen.FADE_TIME + 0.2)
	assert_null(get_tree().root.get_node_or_null(NodePath(TitleScreen.FADE_NAME)), "véu se libera")


func test_build_tag_shows_alfa_in_red() -> void:
	var tag := title.find_child("BuildTag", true, false) as Label
	if TitleScreen.TXT_BUILD_TAG == "":
		assert_null(tag, "gancho vazio: sem nó")
		return
	assert_not_null(tag)
	if tag != null:
		assert_eq(Loc.t(TitleScreen.TXT_BUILD_TAG), "ALFA")
		assert_eq(tag.text, "ALFA")
		assert_eq(tag.get_theme_color("font_color"), TitleScreen.TAG_COLOR)
		var b := title.find_child("StartButton", true, false) as Button
		assert_lt(tag.position.y, b.position.y, "acima do botão")
