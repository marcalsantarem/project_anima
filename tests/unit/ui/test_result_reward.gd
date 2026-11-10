extends GutTest
## Resultado com recompensa (T-191, BRF-115): estado final, animação e pulo.

const SCENE := preload("res://src/ui/screens/result_screen.tscn")


func _result(outcome: MatchResult.Outcome) -> MatchResult:
	var r := MatchResult.new()
	r.outcome = outcome
	r.wave_reached = 10
	r.waves_total = 10
	r.duration_s = 272.0
	r.particles = 321
	r.enemies_killed = 55
	return r


func _sum(over: Dictionary = {}) -> Dictionary:
	var d := {
		"xp": 180, "coins": 95, "first_win_bonus": true, "levels_gained": 1, "slots_unlocked": [1],
		"level_before": 2, "xp_before": 500, "xp_to_next_before": 600,
		"level_after": 3, "xp_after": 40, "xp_to_next_after": 650, "result_outcome": "victory",
	}
	d.merge(over, true)
	return d


func _screen(summary: Dictionary, reduced := true, outcome := MatchResult.Outcome.VICTORY) -> ResultScreen:
	var s: ResultScreen = SCENE.instantiate()
	s.reduced_effects = reduced
	s.show_result(_result(outcome))
	if not summary.is_empty():
		s.set_reward(summary)
	add_child_autofree(s)
	await wait_process_frames(2)
	return s


func _txt(s: Node, n: String) -> String:
	return (s.find_child(n, true, false) as Label).text


func test_victory_with_bonus_and_one_level() -> void:
	var s := await _screen(_sum())
	assert_eq(s.shown_xp, 180)
	assert_eq(s.shown_coins, 95)
	assert_eq(s.shown_level, 3)
	assert_almost_eq(s.bar_frac, 40.0 / 650.0, 0.001)
	assert_true(s._seal.visible)
	assert_true(s._level_panel.visible)
	assert_eq(s._heading.text, "NÍVEL 3!")
	assert_eq(s._sub.text, "NÍVEL 2 → 3")
	assert_eq(s._xp_text.text, "40 / 650 XP")
	assert_eq(s._xp_value.text, "+180")
	assert_eq(s._coin_value.text, "+95")
	assert_eq(s._slots_box.get_child_count(), 1)
	assert_not_null(s.find_child("SlotNotice1", true, false))
	assert_false(s.is_animating())


func test_multiple_levels_one_to_four() -> void:
	var s := await _screen(_sum({"levels_gained": 3, "level_before": 1, "level_after": 4,
		"xp_before": 10, "xp_to_next_before": 100, "xp_after": 20, "xp_to_next_after": 400,
		"slots_unlocked": [1], "first_win_bonus": false}))
	assert_eq(s.shown_level, 4)
	assert_eq(s._sub.text, "NÍVEL 1 → 4")
	assert_almost_eq(s.bar_frac, 0.05, 0.001)
	assert_false(s._seal.visible)


func test_defeat_without_level_up() -> void:
	var s := await _screen(_sum({"xp": 30, "coins": 0, "first_win_bonus": false, "levels_gained": 0,
		"slots_unlocked": [], "level_before": 2, "level_after": 2, "xp_before": 100, "xp_after": 130,
		"xp_to_next_before": 600, "xp_to_next_after": 600}), true, MatchResult.Outcome.DEFEAT)
	assert_eq(s._title.text, "DERROTA")
	assert_eq(s.shown_level, 2)
	assert_eq(s._heading.text, "NÍVEL 2")
	assert_false(s._sub.visible)
	assert_eq(s._xp_text.text, "130 / 600 XP")
	assert_eq(s._slots_box.get_child_count(), 0)
	assert_false(s._seal.visible)


func test_max_level_shows_max_and_full_bar() -> void:
	var s := await _screen(_sum({"levels_gained": 0, "level_before": 30, "level_after": 30,
		"xp_before": 0, "xp_to_next_before": 0, "xp_after": 0, "xp_to_next_after": 0, "slots_unlocked": []}))
	assert_eq(s._xp_text.text, "MAX")
	assert_eq(s.bar_frac, 1.0)
	assert_eq(s.shown_level, 30)


func test_two_slots_unlocked() -> void:
	var s := await _screen(_sum({"slots_unlocked": [1, 2]}))
	assert_eq(s._slots_box.get_child_count(), 2)


func test_without_reward_has_no_section() -> void:
	var s := await _screen({})
	assert_false(s.has_reward())
	assert_false(s._reward_panel.visible)
	assert_false(s._level_panel.visible)
	assert_eq(s._slots_box.get_child_count(), 0)
	assert_eq(s._title.text, "VITÓRIA")
	assert_not_null(s.find_child("SendLog", true, false))
	assert_not_null(s.find_child("PlayAgain", true, false))
	assert_not_null(s.find_child("BackToTitle", true, false))


func test_reward_before_result_and_after_ready() -> void:
	var s: ResultScreen = SCENE.instantiate()
	s.reduced_effects = true
	add_child_autofree(s)
	await wait_process_frames(2)
	s.show_result(_result(MatchResult.Outcome.VICTORY))
	s.set_reward(_sum())
	assert_eq(s.shown_xp, 180)
	assert_eq(s._slots_box.get_child_count(), 1)


func test_animation_runs_then_skip_goes_to_final() -> void:
	var s := await _screen(_sum(), false)
	assert_true(s.is_animating())
	assert_lt(s.shown_xp, 180)
	assert_eq(s._slots_box.get_child_count(), 0, "slot só no fim")
	s.skip_animation()
	assert_false(s.is_animating())
	assert_eq(s.shown_xp, 180)
	assert_eq(s.shown_coins, 95)
	assert_eq(s.shown_level, 3)
	assert_almost_eq(s.bar_frac, 40.0 / 650.0, 0.001)
	assert_eq(s._slots_box.get_child_count(), 1)


func test_tap_skips_animation() -> void:
	var s := await _screen(_sum(), false)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	s._on_root_input(ev)
	assert_false(s.is_animating())
	assert_eq(s.shown_xp, 180)


func test_timeline_is_pure_function_of_time() -> void:
	var s := await _screen(_sum({"levels_gained": 2, "level_before": 1, "level_after": 3}), false)
	s.skip_animation()
	s._apply(0.0, false)
	assert_eq(s.shown_xp, 0)
	assert_eq(s.shown_level, 1)
	s._apply(s._seg_time() * 1.5, false)
	assert_eq(s.shown_level, 2)
	s._apply(s._anim_total, false)
	assert_eq(s.shown_level, 3)
	assert_eq(s.shown_xp, 180)


func test_buttons_not_blocked_during_animation() -> void:
	var s := await _screen(_sum(), false)
	for n in ["PlayAgain", "BackToTitle", "SendLog"]:
		assert_false((s.find_child(n, true, false) as Button).disabled, n)
	assert_lt(s._anim_total, 2.5)
