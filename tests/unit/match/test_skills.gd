extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const PULSE := preload("res://data/skills/skill_pulse.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const ENEMY_SCENE := preload("res://src/match/enemies/enemy.tscn")

var _loose: Array[Enemy] = []


func after_each() -> void:
	for e in _loose:
		if is_instance_valid(e):
			e.free()
	_loose.clear()


func _enemy_at(pos: Vector2) -> Enemy:
	var e: Enemy = ENEMY_SCENE.instantiate()
	e.setup(RUNNER, pos, pos)
	e.state = Enemy.State.ADVANCE
	_loose.append(e)
	return e


func test_pulse_data_matches_gameplay_doc() -> void:
	assert_eq(PULSE.type, SkillData.Type.AREA)
	assert_eq(PULSE.cooldown, 10.0)
	assert_eq(PULSE.radius, 180.0)
	assert_eq(PULSE.damage, 60)


func test_slot_cooldown_cycle() -> void:
	var s := SkillSlot.new(PULSE)
	assert_true(s.is_ready())
	s.start_cooldown()
	assert_false(s.is_ready())
	assert_false(s.tick(9.9))
	assert_true(s.tick(0.2), "termina no passo que zera")
	assert_true(s.is_ready())
	assert_false(s.tick(1.0), "pronto não dispara de novo")


func test_densest_point_prefers_cluster() -> void:
	var lone := _enemy_at(Vector2(100, 0))
	var a := _enemy_at(Vector2(0, 400))
	var b := _enemy_at(Vector2(50, 400))
	var c := _enemy_at(Vector2(-50, 420))
	var p := AreaSkill.densest_point(Vector2.ZERO, [lone, a, b, c] as Array[Enemy], 600.0, 180.0)
	assert_eq(p, a.position)


func test_area_damage_hits_only_inside_radius() -> void:
	var inside := _enemy_at(Vector2(150, 0))
	var edge := _enemy_at(Vector2(190, 0)) # 180 + raio 16 alcança
	var outside := _enemy_at(Vector2(300, 0))
	var list: Array[Enemy] = [inside, edge, outside]
	assert_eq(AreaSkill.apply_damage(Vector2.ZERO, list, 180.0, 5), 2)
	assert_eq(inside.hp, RUNNER.hp - 5)
	assert_eq(edge.hp, RUNNER.hp - 5)
	assert_eq(outside.hp, RUNNER.hp)


func _arena() -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	watch_signals(arena)
	return arena


func test_use_skill_kills_cluster_and_starts_cooldown() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var enemies: Array[Enemy] = []
	for x in [-40.0, 0.0, 40.0]:
		var e := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
		e.position = arena.anima.position + Vector2(x, -300)
		e.target_position = e.position # parados
		enemies.append(e)
	assert_true(arena.use_skill(1))
	assert_signal_emitted_with_parameters(arena, "skill_used", [1])
	assert_signal_emitted_with_parameters(arena, "cooldown_changed", [1, PULSE.cooldown, PULSE.cooldown])
	assert_false(arena.use_skill(1), "em cooldown")
	await wait_seconds(PULSE.windup + 0.1)
	for e in enemies:
		assert_false(is_instance_valid(e), "morto pela área")
	assert_eq(arena.coins, 3 * RUNNER.coin_drop)


func test_no_target_does_not_spend_cooldown() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	assert_false(arena.use_skill(1))
	assert_true(arena.skills.get_slot(1).is_ready())
	assert_false(arena.use_skill(2), "slot vazio")
	assert_false(arena.use_skill(0), "slot inválido")


func test_cooldown_ends_with_skill_ready() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -300)
	e.target_position = e.position
	arena.use_skill(1)
	arena.skills.get_slot(1).remaining = 0.05 # encurta a espera
	await wait_physics_frames(6)
	assert_signal_emitted_with_parameters(arena, "skill_ready", [1])
	assert_signal_emitted_with_parameters(arena, "cooldown_changed", [1, 0.0, PULSE.cooldown])


func test_input_action_triggers_slot() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -300)
	e.target_position = e.position
	var ev := InputEventAction.new()
	ev.action = &"skill_1"
	ev.pressed = true
	Input.parse_input_event(ev)
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(arena, "skill_used", [1])
