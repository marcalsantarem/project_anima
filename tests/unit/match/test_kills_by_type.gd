extends GutTest
## T-287 (BRF-112): MatchResult.kills_by_type.

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const SWARM := preload("res://data/enemies/enemy_swarm.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")

var arena: Arena
var result: MatchResult


func before_each() -> void:
	arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	result = null
	arena.match_ended.connect(func(r: MatchResult) -> void: result = r)
	await wait_physics_frames(1)


func _spawn(data: EnemyData) -> Enemy:
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	e.set_physics_process(false)
	return e


func test_counts_per_type_and_sum() -> void:
	for i in 3:
		_spawn(RUNNER).take_damage(RUNNER.hp)
	for i in 5:
		_spawn(SWARM).take_damage(SWARM.hp) # enxame: 1 por membro
	_spawn(BOSS).take_damage(100000) # chefe conta e encerra a partida
	assert_not_null(result)
	assert_eq(result.kills_by_type.get(&"enemy_runner", 0), 3)
	assert_eq(result.kills_by_type.get(&"enemy_swarm", 0), 5)
	assert_eq(result.kills_by_type.get(&"boss_warden", 0), 1)
	var sum := 0
	for v in result.kills_by_type.values():
		sum += v
	assert_eq(sum, result.enemies_killed)


func test_contact_death_not_counted() -> void:
	_spawn(RUNNER).die(Enemy.DeathCause.CONTACT)
	arena.end_by_timeout()
	assert_eq(result.enemies_killed, 0)
	assert_true(result.kills_by_type.is_empty())


func test_recycled_pool_instance_counts_each_life() -> void:
	for i in 4: # reaproveita a mesma instância do pool
		_spawn(RUNNER).take_damage(RUNNER.hp)
	arena.end_by_timeout()
	assert_eq(result.kills_by_type.get(&"enemy_runner", 0), 4)
	assert_eq(result.enemies_killed, 4)


func test_meteor_kills_counted() -> void:
	var e := _spawn(SWARM)
	e.position = arena.anima.position + Vector2(0, -300)
	e.target_position = e.position
	e.hp = 1
	assert_true(arena.use_skill(1))
	await wait_seconds(1.5)
	arena.end_by_timeout()
	assert_eq(result.kills_by_type.get(&"enemy_swarm", 0), 1)
	assert_eq(result.enemies_killed, 1)
