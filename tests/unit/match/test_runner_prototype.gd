extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func test_runner_data_matches_gameplay_doc() -> void:
	assert_eq(RUNNER.id, &"enemy_runner")
	assert_eq(RUNNER.hp, 20)
	assert_eq(RUNNER.speed, 140.0)
	assert_eq(RUNNER.contact_damage, 5)


func test_step_towards_moves_by_speed_and_stops_at_target() -> void:
	var p := Enemy.step_towards(Vector2.ZERO, Vector2(100, 0), 140.0, 0.5)
	assert_eq(p, Vector2(70, 0))
	p = Enemy.step_towards(p, Vector2(100, 0), 140.0, 0.5)
	assert_eq(p, Vector2(100, 0))


func test_edge_points_are_off_screen() -> void:
	var size := Vector2(720, 1280)
	assert_eq(Arena.edge_point(Arena.Edge.TOP, size, 64.0, 0.5), Vector2(360, -64))
	assert_eq(Arena.edge_point(Arena.Edge.BOTTOM, size, 64.0, 0.0), Vector2(0, 1344))
	assert_eq(Arena.edge_point(Arena.Edge.LEFT, size, 64.0, 1.0), Vector2(-64, 1280))
	assert_eq(Arena.edge_point(Arena.Edge.RIGHT, size, 64.0, 0.5), Vector2(784, 640))


func test_runner_reaches_core_and_deals_contact_damage() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.spawn_interval = 999.0 # só o spawn manual abaixo
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false # isola o contato do ataque automático
	await wait_physics_frames(1)
	var enemy := arena.spawn(RUNNER, Arena.Edge.TOP)
	# Distância até o centro + margem, dividida pela velocidade, com folga.
	var dist := enemy.position.distance_to(arena.anima.position)
	await wait_seconds(dist / RUNNER.speed + 0.5)
	assert_eq(arena.anima.core.current, arena.anima.core.max_hp - RUNNER.contact_damage)
	assert_false(is_instance_valid(enemy))
