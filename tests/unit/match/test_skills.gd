extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const PULSE := preload("res://data/skills/skill_pulse.tres")
const METEOR := preload("res://data/skills/skill_meteor.tres")
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


func test_meteor_data_matches_gameplay_doc() -> void:
	assert_eq(METEOR.type, SkillData.Type.AREA)
	assert_eq(METEOR.delivery, SkillData.Delivery.METEOR)
	assert_eq(METEOR.cooldown, 10.0)
	assert_eq(METEOR.radius, 160.0)
	assert_eq(METEOR.damage, 40)
	assert_eq(METEOR.telegraph_time, 0.6)
	assert_true(METEOR.fall_time > 0.0 and METEOR.fall_time <= METEOR.telegraph_time)


func test_meteor_uses_art_and_crater_covers_radius() -> void:
	assert_not_null(METEOR.meteor_texture)
	assert_not_null(METEOR.crater_texture)
	var k := MeteorSkill.crater_scale(METEOR.crater_texture.get_width(), METEOR.radius)
	var width_1x := METEOR.crater_texture.get_width() * SpriteArt.SCALE.x * k
	assert_almost_eq(width_1x, 2.0 * METEOR.radius * MeteorSkill.CRATER_FIT, 0.01)


func test_behavior_by_delivery() -> void:
	var m := SkillController.behavior_for(METEOR)
	var a := SkillController.behavior_for(PULSE)
	assert_true(m is MeteorSkill)
	assert_true(a is AreaSkill and not a is MeteorSkill)
	m.free()
	a.free()


func test_arena_slot_1_is_meteor() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	assert_eq(arena.skills.get_slot(1).data.id, &"skill_meteor")


func test_lead_point_predicts_advancing_enemy() -> void:
	var e := _enemy_at(Vector2(0, -400))
	e.target_position = Vector2.ZERO
	var p := MeteorSkill.lead_point(e, 0.5)
	assert_almost_eq(GroundPlane.distance(e.position, p), RUNNER.speed * 0.5, 0.01)
	e.state = Enemy.State.ATTACK
	assert_eq(MeteorSkill.lead_point(e, 0.5), e.position, "parado: sem previsão")


func test_densest_falls_back_to_nearest() -> void:
	var far := _enemy_at(Vector2(0, 500))
	var near := _enemy_at(Vector2(300, 0))
	assert_eq(AreaSkill.densest_enemy(Vector2.ZERO, [far, near] as Array[Enemy], 600.0, 160.0), near)
	assert_null(AreaSkill.densest_enemy(Vector2.ZERO, [far] as Array[Enemy], 100.0, 160.0))


func test_meteor_hits_only_after_telegraph_and_emits_cast() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -300)
	e.target_position = e.position
	assert_true(arena.use_skill(1))
	await wait_seconds(METEOR.telegraph_time - METEOR.fall_time * 0.5)
	assert_eq(e.hp, TANK.hp, "sem dano durante o telegraph")
	assert_signal_not_emitted(arena, "skill_cast")
	await wait_seconds(METEOR.fall_time * 0.5 + 0.1)
	assert_eq(e.hp, TANK.hp - METEOR.damage)
	assert_signal_emitted_with_parameters(arena, "skill_cast", [1, e.position, METEOR.radius])


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
	assert_signal_emitted_with_parameters(arena, "cooldown_changed", [1, METEOR.cooldown, METEOR.cooldown])
	assert_false(arena.use_skill(1), "em cooldown")
	await wait_seconds(METEOR.telegraph_time + 0.1)
	for e in enemies:
		assert_false(is_instance_valid(e), "morto pela área")
	assert_eq(arena.particles, 3 * RUNNER.particle_drop)


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
	assert_signal_emitted_with_parameters(arena, "cooldown_changed", [1, 0.0, METEOR.cooldown])


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
