extends GutTest
## BRF-076: foco manual (T-176), mira do meteoro (T-177) e chefe lançado dentro do alcance (decisão 47).

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const METEOR := preload("res://data/skills/skill_meteor.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func _arena() -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	watch_signals(arena)
	return arena


## Inimigo parado em `offset` do Anima.
func _still(arena: Arena, data: EnemyData, offset: Vector2) -> Enemy:
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	e.set_physics_process(false)
	e.state = Enemy.State.ADVANCE
	e.position = arena.anima.position + offset
	e.target_position = e.position
	return e


# --- T-176: foco manual ---

func test_tap_on_enemy_sets_focus_and_targets_it_in_range() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var near := _still(arena, TANK, Vector2(0, -150))
	var far := _still(arena, TANK, Vector2(0, -450))
	assert_true(arena.tap_at(far.position + Vector2(30, -20)), "toque perto do sprite conta")
	assert_eq(arena.focused_enemy(), far)
	assert_signal_emitted_with_parameters(arena, "focus_changed", [far])
	arena.anima.auto_attack_enabled = true
	await wait_physics_frames(3)
	assert_eq(arena.anima.target, far, "mira no focado, não no mais próximo")
	assert_ne(arena.anima.target, near)


func test_focus_out_of_range_falls_back_then_returns() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var near := _still(arena, TANK, Vector2(0, -150))
	var out := _still(arena, TANK, Vector2(0, -(arena.anima.data.attack_range + 100.0) * GroundPlane.Y_SCALE))
	arena.set_focus(out)
	arena.anima.auto_attack_enabled = true
	await wait_physics_frames(3)
	assert_eq(arena.anima.target, near, "fora do alcance: regra automática")
	assert_eq(arena.focused_enemy(), out, "o foco continua")
	out.position = arena.anima.position + Vector2(0, -300)
	await wait_seconds(0.15)
	assert_eq(arena.anima.target, out, "volta ao focado quando entra no alcance")


func test_focus_cleared_on_death() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := _still(arena, RUNNER, Vector2(0, -200))
	arena.set_focus(e)
	e.take_damage(RUNNER.hp)
	assert_null(arena.focused_enemy())
	assert_signal_emitted_with_parameters(arena, "focus_changed", [null])
	assert_null(arena.anima.focus)


func test_tap_same_enemy_or_empty_ground_clears_focus() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := _still(arena, TANK, Vector2(0, -200))
	arena.tap_at(e.position)
	assert_eq(arena.focused_enemy(), e)
	arena.tap_at(e.position)
	assert_null(arena.focused_enemy(), "mesmo inimigo desfaz")
	arena.tap_at(e.position)
	assert_true(arena.tap_at(arena.anima.position + Vector2(250, 200)), "chão vazio desfaz")
	assert_null(arena.focused_enemy())
	assert_false(arena.tap_at(arena.anima.position + Vector2(250, 200)), "sem foco, toque no chão não é usado")



## Bug do iPhone: o toque chega como ScreenTouch e também como clique emulado; o par não pode
## desfazer o foco. Mouse real (PC) continua alternando.
func _touch(at: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.position = at
	return ev


func _click(at: Vector2, emulated: bool) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.pressed = true
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = at
	if emulated:
		ev.device = InputEvent.DEVICE_ID_EMULATION
	return ev


func test_touch_plus_emulated_click_keeps_focus() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := _still(arena, TANK, Vector2(0, -200))
	var screen := arena.get_global_transform_with_canvas() * e.position
	arena._unhandled_input(_touch(screen))
	arena._unhandled_input(_click(screen, true))
	assert_eq(arena.focused_enemy(), e, "clique emulado do mesmo toque é ignorado")
	arena._unhandled_input(_touch(screen))
	arena._unhandled_input(_click(screen, true))
	assert_null(arena.focused_enemy(), "segundo toque no mesmo inimigo desfaz")


func test_real_mouse_click_toggles_focus() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := _still(arena, TANK, Vector2(0, -200))
	var screen := arena.get_global_transform_with_canvas() * e.position
	arena._unhandled_input(_click(screen, false))
	assert_eq(arena.focused_enemy(), e)
	arena._unhandled_input(_click(screen, false))
	assert_null(arena.focused_enemy())

func test_tap_picks_enemy_closest_to_finger() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var a := _still(arena, RUNNER, Vector2(-30, -200))
	var b := _still(arena, RUNNER, Vector2(30, -200))
	assert_eq(Arena.enemy_at(b.position + Vector2(5, 0), arena.active_enemies, arena.focus_pick_radius), b)
	assert_eq(Arena.enemy_at(a.position + Vector2(-5, 0), arena.active_enemies, arena.focus_pick_radius), a)
	assert_null(Arena.enemy_at(a.position + Vector2(-200, 0), arena.active_enemies, arena.focus_pick_radius))


func test_focus_works_with_boss() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var boss := arena.spawn(BOSS, WaveEntry.SpawnEdge.TOP)
	boss.set_physics_process(false)
	boss.position = arena.anima.position + Vector2(0, -250)
	assert_true(arena.tap_at(boss.position + Vector2(0, -boss.sprite_top() * 0.5)), "toque no corpo")
	assert_eq(arena.focused_enemy(), boss)


# --- T-177: mira do meteoro ---

func test_manual_meteor_lands_exactly_without_enemies() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var at := arena.anima.position + Vector2(120, -180)
	assert_true(arena.use_skill(1, at), "mira manual não exige inimigo")
	await wait_seconds(METEOR.telegraph_time + 0.1)
	assert_signal_emitted_with_parameters(arena, "skill_cast", [1, at, METEOR.radius])
	assert_signal_not_emitted(arena, "skill_fizzled")


func test_manual_meteor_does_not_retarget() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := _still(arena, TANK, Vector2(0, -300))
	var at := arena.anima.position + Vector2(-200, 150)
	assert_true(arena.use_skill(1, at))
	await wait_seconds(METEOR.telegraph_time + 0.1)
	assert_eq(e.hp, TANK.hp, "não persegue o inimigo")
	assert_signal_emitted_with_parameters(arena, "skill_cast", [1, at, METEOR.radius])


func test_manual_aim_outside_area_is_refused() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var bad := Vector2(arena.free_rect().get_center().x, arena.free_rect().end.y + 10.0) # na bandeja
	assert_false(arena.can_aim_at(bad))
	assert_false(arena.use_skill(1, bad))
	assert_true(arena.skills.get_slot(1).is_ready(), "cooldown não gasto")
	assert_true(arena.can_aim_at(arena.anima.position))


func test_skill_aim_preview_is_clamped_and_hidden() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var aim := arena._skill_aim
	arena.show_skill_aim(1, Vector2(-500, -500))
	assert_true(aim.visible)
	assert_eq(aim.position, arena.aim_rect().position, "preso à área de mira")
	assert_eq(aim.radius, METEOR.radius)
	arena.hide_skill_aim()
	assert_false(aim.visible)
	arena.show_skill_aim(2, arena.anima.position)
	assert_false(aim.visible, "slot sem Módulo de área não mostra prévia")


# --- Decisão 47: chefe cai dentro do alcance ---

func test_boss_launch_lands_inside_attack_range() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var boss := arena.spawn(BOSS, WaveEntry.SpawnEdge.TOP) as Boss
	boss.position = arena.anima.position + Vector2(0, -100)
	boss.launch()
	await wait_seconds(BOSS.launch_time + 0.1)
	var d := GroundPlane.distance(arena.anima.position, boss.position)
	assert_lte(d, arena.anima.data.attack_range * arena.boss_launch_reach_ratio + 0.5)
	assert_true(boss.launch_bounds.has_point(boss.position), "dentro da área visível")


func test_launch_destination_respects_max_reach() -> void:
	var center := Vector2(360, 700)
	var to := Boss.launch_destination(Vector2(460, 700), center, 600.0, Rect2(), 510.0)
	assert_almost_eq(GroundPlane.distance(center, to), 510.0, 0.01)
	assert_gt(to.x, center.x, "na direção oposta ao Núcleo")
