extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const BASIC := preload("res://data/projectiles/projectile_anima_basic.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func _make_pool(size: int) -> ProjectilePool:
	var pool := ProjectilePool.new()
	add_child_autofree(pool)
	pool.build(size, BASIC)
	return pool


func test_pool_exhausts_without_growing() -> void:
	var pool := _make_pool(2)
	assert_not_null(pool.acquire())
	assert_not_null(pool.acquire())
	assert_null(pool.acquire())
	assert_eq(pool.get_child_count(), 2)


func test_pool_reuses_expired_projectile() -> void:
	var pool := _make_pool(1)
	var p := pool.acquire()
	p.fire(Vector2.ZERO, Vector2.RIGHT, 10.0)
	assert_eq(pool.active_count(), 1)
	await wait_physics_frames(3) # 10 px a 900 px/s expira no 1º passo
	assert_eq(pool.active_count(), 0)
	assert_false(p.active)
	assert_eq(pool.acquire(), p)


func test_enemy_damage_and_death() -> void:
	var e: Enemy = preload("res://src/match/enemies/enemy.tscn").instantiate()
	e.setup(RUNNER, Vector2.ZERO, Vector2.ZERO)
	add_child_autofree(e)
	watch_signals(e)
	e.take_damage(BASIC.damage)
	assert_eq(e.hp, RUNNER.hp - BASIC.damage)
	e.take_damage(BASIC.damage)
	assert_eq(e.state, Enemy.State.DEAD)
	assert_signal_emitted_with_parameters(e, "died", [e, Enemy.DeathCause.KILLED])


func test_anima_kills_runner_before_contact_using_pool() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.spawn_interval = 999.0 # só o spawn manual abaixo
	add_child_autofree(arena)
	await wait_physics_frames(1)
	var pool_size := arena.projectiles.get_child_count()
	var enemy := arena.spawn(RUNNER, Arena.Edge.TOP)
	var dist := enemy.position.distance_to(arena.anima.position)
	await wait_seconds(dist / RUNNER.speed + 0.5)
	assert_false(is_instance_valid(enemy), "corredor morto")
	assert_eq(arena.anima.core.current, arena.anima.core.max_hp, "Núcleo intacto")
	assert_eq(arena.active_enemies.size(), 0)
	assert_eq(arena.projectiles.get_child_count(), pool_size, "pool não cresceu")
	assert_eq(pool_size, arena.anima.data.projectile_pool_size)
