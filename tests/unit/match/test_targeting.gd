extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")

var _enemies: Array[Enemy] = []


func after_each() -> void:
	for e in _enemies:
		e.free()
	_enemies.clear()


func _make(pos: Vector2, priority := 0) -> Enemy:
	var data: EnemyData = RUNNER.duplicate()
	data.target_priority = priority
	var e: Enemy = preload("res://src/match/enemies/enemy.tscn").instantiate()
	e.setup(data, pos, Vector2.ZERO)
	e.state = Enemy.State.ADVANCE
	_enemies.append(e)
	return e


func test_picks_nearest() -> void:
	var far := _make(Vector2(300, 0))
	var near := _make(Vector2(0, 100))
	assert_eq(Targeting.pick(Vector2.ZERO, [far, near] as Array[Enemy], 600.0), near)


func test_priority_beats_distance() -> void:
	var near := _make(Vector2(0, 100))
	var boss := _make(Vector2(500, 0), 10)
	assert_eq(Targeting.pick(Vector2.ZERO, [near, boss] as Array[Enemy], 600.0), boss)


func test_ignores_out_of_range_and_dead() -> void:
	var out := _make(Vector2(700, 0))
	var dead := _make(Vector2(10, 0))
	dead.state = Enemy.State.DEAD
	assert_null(Targeting.pick(Vector2.ZERO, [out, dead] as Array[Enemy], 600.0))
