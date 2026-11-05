extends GutTest
## T-117 (BRF-080): pulsos do HUD e opção "Efeitos reduzidos" (T-132) na pausa.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const PAUSE_SCENE := preload("res://src/ui/screens/pause_screen.tscn")
const TEST_CFG := "user://test_feel_debug.cfg"

var _old_path := ""


func before_each() -> void:
	_old_path = DebugSettings.path
	DebugSettings.path = TEST_CFG
	DebugSettings.reset()


func after_each() -> void:
	DirAccess.remove_absolute(TEST_CFG)
	DebugSettings.path = _old_path
	DebugSettings.reset()
	get_tree().paused = false


func _button() -> SkillButton:
	var sb := SkillButton.new()
	sb.slot = 1
	add_child_autofree(sb)
	return sb


func test_ready_pulse_after_cooldown() -> void:
	var sb := _button()
	sb.set_cooldown(2.0, 2.0)
	sb.set_ready()
	assert_eq(sb.ready_glow, 1.0, "anel acende no skill_ready")
	await wait_seconds(0.12)
	assert_gt(sb.scale.x, 1.0, "escala sobe no pulso")
	await wait_seconds(0.3)
	assert_almost_eq(sb.scale.x, 1.0, 0.001, "volta a 1")
	assert_eq(sb.ready_glow, 0.0, "brilho apaga em ~0,3 s")


func test_ready_pulse_when_zero_cooldown_arrives_first() -> void:
	var sb := _button()
	sb.set_cooldown(1.0, 2.0)
	sb.set_cooldown(0.0, 2.0) # cooldown_changed com 0 antes do skill_ready
	sb.set_ready()
	assert_eq(sb.ready_glow, 1.0)


func test_no_pulse_without_cooldown() -> void:
	var sb := _button()
	sb.set_ready()
	assert_eq(sb.ready_glow, 0.0, "início da partida não pulsa")


func test_use_sinks_and_flashes() -> void:
	var sb := _button()
	sb.on_used()
	await wait_seconds(0.08)
	assert_lt(sb.scale.x, 1.0, "afunda no uso")


func test_hud_skill_ready_signal_pulses_button() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	hud._on_cooldown_changed(1, 3.0, 3.0)
	hud._on_skill_ready(1)
	assert_eq(hud._skill(1).ready_glow, 1.0)


func test_particles_pill_pulses_on_gain_and_first_affordable() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child_autofree(hud)
	var ub := hud.upgrade_button(UpgradeButton.IDS[0])
	hud._on_upgrade_changed(UpgradeButton.IDS[0], 0, 5, 10)
	watch_signals(ub)
	hud._on_particles_changed(5)
	assert_eq(hud.pill_pulses, 1, "ganho pulsa")
	hud._on_particles_changed(12)
	assert_signal_emit_count(ub, "first_affordable", 1)
	assert_eq(hud.pill_pulses, 3, "ganho + 1ª vez comprável")
	hud._on_particles_changed(2) # gastou
	hud._on_particles_changed(12)
	assert_signal_emit_count(ub, "first_affordable", 1, "só na primeira vez")
	assert_eq(hud.pill_pulses, 4, "gasto não pulsa; novo ganho pulsa")


func test_reduced_effects_saved_and_reloaded() -> void:
	assert_false(DebugSettings.reduced_effects(), "desligado por padrão")
	DebugSettings.set_overlay_enabled(true)
	DebugSettings.set_reduced_effects(true)
	DebugSettings.reset()
	assert_true(DebugSettings.reduced_effects(), "salvo")
	assert_true(DebugSettings.overlay_enabled(), "não apaga o overlay")
	DebugSettings.set_overlay_enabled(false)
	DebugSettings.reset()
	assert_true(DebugSettings.reduced_effects(), "overlay não apaga a opção")


func test_pause_toggle_emits_and_saves() -> void:
	var pause: PauseScreen = PAUSE_SCENE.instantiate()
	add_child_autofree(pause)
	watch_signals(pause)
	assert_string_contains(pause.reduced_toggle.text, "não")
	pause.reduced_toggle.pressed.emit()
	assert_signal_emitted_with_parameters(pause, "reduced_effects_changed", [true])
	assert_string_contains(pause.reduced_toggle.text, "sim")
	DebugSettings.reset()
	assert_true(DebugSettings.reduced_effects())


class FakeArena:
	extends Node
	var reduced_effects := false


func test_scene_flow_apply_reduced_effects() -> void:
	var arena := FakeArena.new()
	var director := FxDirector.new()
	var plain := Node.new()
	add_child_autofree(arena)
	add_child_autofree(director)
	add_child_autofree(plain)
	SceneFlow.apply_reduced_effects(arena, director, true)
	assert_true(arena.reduced_effects, "Arena recebe")
	assert_true(director.reduced_effects, "FxDirector recebe")
	SceneFlow.apply_reduced_effects(plain, director, false)
	assert_false(director.reduced_effects, "Arena sem a propriedade não quebra")
