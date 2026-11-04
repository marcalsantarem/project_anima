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


func test_edge_points_are_outside_arena() -> void:
	var size := Vector2(720, 1280)
	var rect := Arena.rect_for(size, 164.0, 293.0) # arena do mockup: y 164..987
	assert_eq(rect, Rect2(0, 164, 720, 823))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.TOP, rect, 64.0, 0.5), Vector2(360, 100))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.BOTTOM, rect, 64.0, 0.0), Vector2(0, 1051))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.LEFT, rect, 64.0, 1.0), Vector2(-64, 987))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.RIGHT, rect, 64.0, 0.5), Vector2(784, 575.5))


func test_runner_reaches_core_and_deals_contact_damage() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false # só o spawn manual abaixo
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false # isola o contato do ataque automático
	await wait_physics_frames(1)
	var enemy := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	# Distância até o centro + margem, dividida pela velocidade, com folga.
	var dist := GroundPlane.distance(enemy.position, arena.anima.position)
	await wait_seconds(dist / RUNNER.speed + 0.5)
	assert_eq(arena.anima.core.current, arena.anima.core.max_hp - RUNNER.contact_damage)
	assert_false(is_instance_valid(enemy))
