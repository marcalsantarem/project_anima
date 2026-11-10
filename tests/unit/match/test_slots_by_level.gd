extends GutTest
## T-188: a partida monta os slots de Módulo pelo nível da conta.

const ARENA_SCENE := "res://src/match/arena/arena.tscn"
var UNLOCK := PackedInt32Array([2, 5, 8])


func _arena(level: int) -> Arena:
	var a: Arena = load(ARENA_SCENE).instantiate()
	a.setup(MatchConfig.for_account(level, UNLOCK))
	add_child_autofree(a)
	return a


func test_level_1_no_skills_basic_attack_keeps_working() -> void:
	var a := _arena(1)
	await wait_physics_frames(2)
	for s in [1, 2, 3]:
		assert_null(a.skills.get_slot(s))
		assert_false(a.use_skill(s))
	assert_not_null(a.anima, "partida segue com o ataque básico")


func test_level_2_only_slot_1() -> void:
	var a := _arena(2)
	await wait_physics_frames(1)
	assert_eq(a.skills.get_slot(1).data.id, &"skill_meteor")
	assert_null(a.skills.get_slot(2))
	assert_null(a.skills.get_slot(3))


func test_level_5_and_8_slots_free_but_empty_beyond_module() -> void:
	var a := _arena(5)
	await wait_physics_frames(1)
	assert_not_null(a.skills.get_slot(1))
	assert_null(a.skills.get_slot(2), "liberado, sem Módulo no M2")
	assert_eq(MatchConfig.for_account(5, UNLOCK).unlocked_slots, 2)
	assert_eq(MatchConfig.for_account(8, UNLOCK).unlocked_slots, 3)
	assert_false(a.use_skill(2))
	assert_false(_arena(8).use_skill(3))


func test_locked_slot_keys_ignored() -> void:
	var a := _arena(1)
	await wait_physics_frames(1)
	var ev := InputEventAction.new()
	ev.action = &"skill_1"
	ev.pressed = true
	Input.parse_input_event(ev)
	await wait_physics_frames(2)
	assert_null(a.skills.get_slot(1))


func test_default_config_keeps_slot_1() -> void:
	var a: Arena = load(ARENA_SCENE).instantiate()
	a.setup(MatchConfig.new())
	add_child_autofree(a)
	await wait_physics_frames(1)
	assert_not_null(a.skills.get_slot(1))


func test_hud_lock_levels_follow_account() -> void:
	assert_eq(MatchConfig.hud_lock_levels(1, UNLOCK), [2, 5, 8] as Array[int])
	assert_eq(MatchConfig.hud_lock_levels(5, UNLOCK), [0, 0, 8] as Array[int])


func test_scene_flow_builds_config_from_profile() -> void:
	SceneFlow.profile = PlayerProfile.new()
	SceneFlow.profile.level = 5
	var c: MatchConfig = SceneFlow.build_match_config()
	assert_eq(c.unlocked_slots, 2)
	assert_eq(c.account_level, 5)
