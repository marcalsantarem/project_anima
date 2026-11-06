extends GutTest
## T-118: pool de inimigos (reaproveita instâncias; chefe e inimigo solto seguem com queue_free).

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func _arena() -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	return arena


func test_dead_enemy_is_parked_and_reused() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var a := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	a.take_damage(a.data.hp)
	assert_eq(a.state, Enemy.State.DEAD)
	assert_false(a.visible)
	assert_false(a.is_queued_for_deletion())
	assert_false(arena.active_enemies.has(a))
	assert_eq(arena.enemy_pool.free_count(RUNNER), 1)
	var b := arena.spawn(RUNNER, WaveEntry.SpawnEdge.LEFT)
	assert_same(b, a)
	assert_eq([arena.enemy_pool.created, arena.enemy_pool.reused], [1, 1])
	assert_eq(arena.enemy_pool.free_count(), 0)


func test_reused_enemy_has_clean_state() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var a := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	a.take_damage(30)
	assert_lt(a.hp, TANK.hp)
	assert_true(a.is_flashing())
	a.die(Enemy.DeathCause.CONTACT)
	var b := arena.spawn(TANK, WaveEntry.SpawnEdge.RIGHT)
	assert_same(b, a)
	assert_eq(b.hp, TANK.hp)
	assert_eq(b.state, Enemy.State.ADVANCE)
	assert_true(b.visible)
	assert_false(b.is_flashing())
	assert_eq(b.health_bar.ratio, 1.0)
	assert_eq(b.target_position, arena.anima.position)
	assert_ne(b.position, Enemy.PARKED_POSITION)
	assert_true(arena.active_enemies.has(b))


func test_pool_is_per_type() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var a := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	a.die(Enemy.DeathCause.KILLED)
	var t := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	assert_ne(t, a)
	assert_eq(t.data, TANK)
	assert_eq(arena.enemy_pool.free_count(RUNNER), 1)


func test_reused_enemy_still_takes_hits_and_kills_count() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var a := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	a.die(Enemy.DeathCause.KILLED)
	var b := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	b.take_damage(b.data.hp)
	assert_eq(arena.enemies_killed, 2)
	assert_eq(arena.particles, RUNNER.particle_drop * 2)


func test_boss_and_standalone_enemy_are_freed() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var boss := arena.spawn(BOSS, WaveEntry.SpawnEdge.TOP)
	assert_null(boss.pool)
	boss.die(Enemy.DeathCause.KILLED)
	assert_true(boss.is_queued_for_deletion())
	assert_eq(arena.enemy_pool.free_count(), 0)


func test_death_clears_anima_target() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var a := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	arena.anima.target = a
	a.die(Enemy.DeathCause.KILLED)
	assert_null(arena.anima.target)


func test_churn_does_not_grow_node_count() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	for i in 20:
		arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	var created := arena.enemy_pool.created
	for round in 5:
		for e in arena.active_enemies.duplicate():
			e.die(Enemy.DeathCause.KILLED)
		for i in 20:
			arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	assert_eq(arena.enemy_pool.created, created)
	assert_eq(arena.enemy_pool.reused, 100)


func test_stress_request_parsing_off_by_default() -> void:
	assert_eq(StressMode.requested(), Vector2i.ZERO)
