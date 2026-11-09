extends GutTest
## T-288 (BRF-119): botão "Voltar ao menu" na pausa.

const PAUSE_SCENE := preload("res://src/ui/screens/pause_screen.tscn")


func after_each() -> void:
	get_tree().paused = false


func test_menu_button_emits_menu_requested() -> void:
	var pause: PauseScreen = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	watch_signals(pause)
	pause.open()
	assert_not_null(pause.menu_button, "botão existe")
	assert_eq(pause.menu_button.text, "Voltar ao menu")
	assert_gte(pause.menu_button.custom_minimum_size.y, 88.0, "alvo de toque")
	pause.menu_button.pressed.emit()
	assert_signal_emitted(pause, "menu_requested")
	assert_false(pause.is_open(), "fecha o overlay")
	assert_false(get_tree().paused, "despausa")
