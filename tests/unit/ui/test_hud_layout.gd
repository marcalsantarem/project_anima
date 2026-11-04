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


## BRF-066/T-172: bandeja até a borda inferior; slots a max(12, 0,5 × inset) da borda, sem somar SPACE_XS.
func test_tray_reaches_bottom_with_safe_area() -> void:
	ScreenKit.simulated_safe_area = {"bottom": 65.0}
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(2)
	var tray: Control = hud.get_node("Root/Tray")
	var screen_h := hud.get_viewport().get_visible_rect().size.y
	assert_eq(tray.get_global_rect().end.y, screen_h, "bandeja termina na borda da tela")
	assert_eq(hud.tray_height(), float(Hud.TRAY_HEIGHT) - UiTokens.SPACE_XS + 33.0)
	assert_eq(tray.size.y, hud.tray_height())
	var skill: Control = hud._skills[0]
	var gap := screen_h - skill.get_global_rect().end.y
	assert_eq(gap, 33.0, "folga entre a base dos slots e a borda = 0,5 × inset")
	var row: Control = hud.upgrade_row
	assert_eq(row.size, Vector2(row.size.x, 80.0))


## T-172: canvas sem cobrir a borda inferior → inset inferior zerada (sem dupla contagem).
func test_tray_ignores_bottom_inset_when_canvas_short() -> void:
	ScreenKit.simulated_safe_area = {"bottom": 65.0, "covers_bottom": false}
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(2)
	assert_eq(hud.tray_height(), float(Hud.TRAY_HEIGHT))
	var screen_h := hud.get_viewport().get_visible_rect().size.y
	assert_eq(screen_h - hud._skills[0].get_global_rect().end.y, float(UiTokens.SPACE_XS))


func test_ui_bottom_inset_rule() -> void:
	assert_eq(ScreenKit.ui_bottom_inset(0.0, true), 0.0, "sem inset")
	assert_eq(ScreenKit.ui_bottom_inset(65.0, false), 0.0, "canvas não cobre a borda")
	assert_eq(ScreenKit.ui_bottom_inset(65.0, true), 32.5, "0,5 × inset")
	assert_eq(ScreenKit.ui_bottom_inset(10.0, true), 12.0, "mínimo de 12")
	ScreenKit.simulated_safe_area = {"bottom": 65.0}
	var sa := ScreenKit.safe_area(get_viewport())
	assert_eq(sa.bottom_raw, 65.0)
	assert_eq(sa.bottom, 32.5)


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


## T-172: a partida pinta a página do shell com a cor da bandeja (faixa abaixo do web view no Safari).
func test_hud_sets_page_color() -> void:
	ScreenKit.last_page_color = Color.BLACK
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_process_frames(1)
	assert_eq(ScreenKit.last_page_color, UiTokens.BG_PANEL_ALT)
