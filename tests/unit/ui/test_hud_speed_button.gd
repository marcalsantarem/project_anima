extends GutTest
## T-275 (BRF-122): botão x1/x2 do HUD da partida.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")

var _old_path: String
var _old_locked: bool
var _old_chosen: float


func before_each() -> void:
	_old_path = SpeedController.settings_path
	_old_locked = SpeedController.locked_to_x1
	_old_chosen = SpeedController.chosen
	SpeedController.settings_path = "user://test_hud_speed.cfg"
	SpeedController.locked_to_x1 = false
	SpeedController.chosen = SpeedController.SPEED_X1


func after_each() -> void:
	SpeedController.chosen = _old_chosen
	SpeedController.locked_to_x1 = _old_locked
	SpeedController.settings_path = _old_path
	SpeedController.restore()
	DirAccess.remove_absolute("user://test_hud_speed.cfg")


func _make_hud() -> Hud:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(2)
	return hud


func _is_x2(hud: Hud) -> bool:
	return hud.get_node("Root/Top").find_child("Speed", true, false).texture_normal == UiArt.SPEED_X2


func test_initial_state_x1() -> void:
	var hud := await _make_hud()
	assert_false(_is_x2(hud))


func test_initial_state_reflects_saved_x2() -> void:
	SpeedController.chosen = SpeedController.SPEED_X2
	var hud := await _make_hud()
	assert_true(_is_x2(hud))


func test_touch_toggles() -> void:
	var hud := await _make_hud()
	var btn: TextureButton = hud.get_node("Root/Top").find_child("Speed", true, false)
	btn.pressed.emit()
	assert_eq(SpeedController.chosen, SpeedController.SPEED_X2)
	assert_true(_is_x2(hud))
	btn.pressed.emit()
	assert_eq(SpeedController.chosen, SpeedController.SPEED_X1)
	assert_false(_is_x2(hud))


func test_key_action_toggles() -> void:
	var hud := await _make_hud()
	var ev := InputEventAction.new()
	ev.action = &"toggle_speed"
	ev.pressed = true
	hud._input(ev)
	assert_eq(SpeedController.chosen, SpeedController.SPEED_X2)
	assert_true(_is_x2(hud))
	assert_true(InputMap.has_action(&"toggle_speed"))


func test_reacts_to_external_change() -> void:
	var hud := await _make_hud()
	SpeedController.set_speed(SpeedController.SPEED_X2)
	assert_true(_is_x2(hud))


func test_no_toggle_when_paused() -> void:
	var hud := await _make_hud()
	get_tree().paused = true
	assert_false(hud.toggle_speed())
	get_tree().paused = false
	assert_eq(SpeedController.chosen, SpeedController.SPEED_X1)


func test_touch_target_and_no_overlap_both_sizes() -> void:
	for size in [Vector2i(375, 812), Vector2i(1280, 720)]:
		get_window().size = size
		var hud := await _make_hud()
		var btn: Control = hud.get_node("Root/Top").find_child("Speed", true, false)
		var pause: Control = hud.get_node("Root/Top").find_child("Pause", true, false)
		var wave: Control = hud._wave_label.get_parent()
		var r := btn.get_global_rect()
		assert_true(r.size.x >= 64.0 and r.size.y >= 64.0, "alvo >= 64 em %s" % size)
		assert_false(r.intersects(pause.get_global_rect()), "não cobre a pausa %s" % size)
		assert_false(r.intersects(wave.get_global_rect()), "não cobre a onda %s" % size)
		hud.queue_free()
		await wait_process_frames(1)
