extends GutTest
## T-123 (seed) e teste rápido do bot de simulação (BRF-051). A simulação completa é manual:
## tests/tools/run_sim.gd (comando em docs/gameplay.md).

const SWARM := preload("res://data/enemies/enemy_swarm.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func _arena(seed: int, waves := false) -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = waves
	arena.set_seed(seed)
	add_child_autofree(arena)
	return arena


func _group_positions(arena: Arena) -> Array[Vector2]:
	var out: Array[Vector2] = []
	arena.spawn_group(SWARM, WaveEntry.SpawnEdge.RANDOM)
	arena.spawn_group(SWARM, WaveEntry.SpawnEdge.RANDOM)
	for e in arena.active_enemies:
		out.append(e.position)
	return out


func test_same_seed_same_spawns() -> void:
	var a := _group_positions(_arena(42))
	var b := _group_positions(_arena(42))
	var c := _group_positions(_arena(43))
	assert_gt(a.size(), 0)
	assert_eq(a, b, "mesma seed = mesmos spawns")
	assert_ne(a, c, "seed diferente muda o sorteio")


func test_bot_plays_first_seconds() -> void:
	var arena := _arena(1, true)
	watch_signals(arena)
	var bot := SimBot.new()
	bot.attach(arena)
	await wait_seconds(10.0)
	assert_signal_emitted(arena, "skill_used", "usa o meteoro quando pronto")
	assert_gt(bot.particles_earned, 0)
	assert_gt(bot.upgrades_bought, 0, "compra upgrade quando tem Partículas")
	assert_null(bot.result, "partida segue")
