extends GutTest
## BRF-039: sem tooltips no HUD, alturas expostas (Hud.TOP_INSET/TRAY_HEIGHT) e linha de Partículas do Resultado.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const RESULT_SCENE := preload("res://src/ui/screens/result_screen.tscn")


func _all_controls(n: Node, out: Array) -> Array:
	if n is Control:
		out.append(n)
	for c in n.get_children():
		_all_controls(c, out)
	return out


func test_hud_has_no_tooltips() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(2)
	for c in _all_controls(hud, []):
		assert_eq(c.tooltip_text, "", "tooltip em %s" % c.get_path())


func test_exposed_heights_match_layout() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(2)
	assert_eq(hud.get_node("Root/Top").size.y, float(Hud.TOP_INSET))
	assert_eq(hud.get_node("Root/Tray").size.y, float(Hud.TRAY_HEIGHT))
	assert_eq(hud.top_inset(), float(Hud.TOP_INSET)) # sem safe area fora da web/mobile
	assert_eq(hud.tray_height(), float(Hud.TRAY_HEIGHT))


## BRF-066: bandeja até a borda inferior cobrindo a safe area; slots acima dela, com folga curta.
func test_tray_reaches_bottom_with_safe_area() -> void:
	ScreenKit.simulated_safe_area = {"bottom": 65.0}
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(2)
	var tray: Control = hud.get_node("Root/Tray")
	var screen_h := hud.get_viewport().get_visible_rect().size.y
	assert_eq(tray.get_global_rect().end.y, screen_h, "bandeja termina na borda da tela")
	assert_eq(hud.tray_height(), float(Hud.TRAY_HEIGHT) + 65.0)
	assert_eq(tray.size.y, hud.tray_height())
	var skill: Control = hud._skills[0]
	var gap := screen_h - 65.0 - skill.get_global_rect().end.y
	assert_between(gap, 0.0, 32.0, "folga entre slots e a safe area")
	var row: Control = hud.upgrade_row
	assert_eq(row.size, Vector2(row.size.x, 80.0))


func after_each() -> void:
	ScreenKit.simulated_safe_area = {}


func test_result_particles_row_does_not_wrap() -> void:
	var screen: ResultScreen = RESULT_SCENE.instantiate()
	var r := MatchResult.new()
	r.particles = 12345
	screen.show_result(r)
	add_child_autofree(screen)
	await wait_process_frames(2)
	var row: HBoxContainer = screen.find_child("ParticlesRow", true, false)
	var label: Label = row.get_child(1)
	assert_eq(label.get_line_count(), 1)
	assert_gt(label.size.x, label.size.y)
