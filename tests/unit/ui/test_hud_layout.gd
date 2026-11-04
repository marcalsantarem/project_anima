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
