extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const SHOOTER := preload("res://data/enemies/enemy_shooter.tres")
const SWARM := preload("res://data/enemies/enemy_swarm.tres")
const BOLT := preload("res://data/projectiles/projectile_enemy_bolt.tres")
const PLAYER_SHOT := preload("res://data/projectiles/projectile_anima_basic.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func _arena() -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	return arena


func test_data_matches_gameplay_doc() -> void:
	assert_eq([TANK.hp, TANK.speed, TANK.contact_damage, TANK.coin_drop], [120, 50.0, 20, 4])
	assert_eq([SHOOTER.hp, SHOOTER.attack_range, SHOOTER.coin_drop], [35, 380.0, 2])
	assert_almost_eq(1.0 / SHOOTER.fire_rate, 1.5, 0.01)
	assert_eq([BOLT.damage, BOLT.speed], [6, 300.0])
	assert_eq([SWARM.hp, SWARM.contact_damage, SWARM.group_min, SWARM.group_max], [8, 2, 5, 8])


func test_enemy_bolt_is_readable() -> void:
	assert_eq(BOLT.shape, ProjectileData.Shape.DIAMOND)
	assert_ne(BOLT.shape, PLAYER_SHOT.shape)
	# Sem ciano: o canal vermelho domina o verde.
	assert_gt(BOLT.color.r, BOLT.color.g)
	assert_lt(BOLT.speed, PLAYER_SHOT.speed)


func test_tank_reaches_core_and_hits_hard() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var tank := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	tank.position = arena.anima.position + Vector2(0, -100)
	await wait_seconds(100.0 / TANK.speed + 0.3)
	assert_eq(arena.anima.core.current, arena.anima.core.max_hp - TANK.contact_damage)


func test_tank_survives_what_kills_a_runner() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var tank := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	tank.take_damage(RUNNER.hp)
	assert_eq(tank.state, Enemy.State.ADVANCE)


func test_shooter_stops_at_range_and_damages_core() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var shooter := arena.spawn(SHOOTER, WaveEntry.SpawnEdge.TOP)
	shooter.position = arena.anima.position + GroundPlane.to_screen(Vector2(0, -420)) # 420 px no chão
	# 40 px até o alcance + 1º tiro em 1,5 s + 340 px de voo a 300 px/s.
	await wait_seconds(40.0 / SHOOTER.speed + 1.5 + 340.0 / BOLT.speed + 0.3)
	assert_eq(shooter.state, Enemy.State.ATTACK)
	assert_almost_eq(GroundPlane.distance(shooter.position, arena.anima.position), SHOOTER.attack_range, 3.0)
	assert_eq(arena.anima.core.current, arena.anima.core.max_hp - BOLT.damage)
	assert_eq(arena.enemy_projectiles.get_child_count(), arena.enemy_projectile_pool_size, "pool não cresce")


func test_swarm_spawns_as_group() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var n := arena.spawn_group(SWARM, WaveEntry.SpawnEdge.LEFT)
	assert_between(n, SWARM.group_min, SWARM.group_max)
	assert_eq(arena.active_enemies.size(), n)
	var leader := arena.active_enemies[0]
	for e in arena.active_enemies:
		assert_true(e.position.distance_to(leader.position) <= SWARM.group_spread + 0.01)


func test_runner_spawn_group_is_single() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	assert_eq(arena.spawn_group(RUNNER, WaveEntry.SpawnEdge.TOP), 1)
