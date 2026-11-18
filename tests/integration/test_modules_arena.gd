extends GutTest
## Os 3 Módulos novos disparam juntos numa Arena real (BRF-165).

const TANK := preload("res://data/enemies/enemy_tank.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func test_three_modules_fire_in_arena() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	var cfg := MatchConfig.new()
	cfg.slot_modules = [
		load("res://data/skills/skill_freeze.tres"),
		load("res://data/skills/skill_shield.tres"),
		load("res://data/skills/skill_shock.tres"),
	]
	cfg.unlocked_slots = 3
	arena.setup(cfg)
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	watch_signals(arena)
	await wait_physics_frames(1)
	var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -300)
	e.target_position = e.position
	for slot in 3:
		assert_true(arena.use_skill(slot + 1), "slot %d dispara" % (slot + 1))
	await wait_seconds(0.4)
	assert_true(e.is_frozen())
	assert_true(arena.anima.shield.is_active())
	assert_lt(e.hp, TANK.hp)
	assert_signal_emitted(arena, "shield_started")
	assert_signal_emitted(arena, "skill_chain_hit")
