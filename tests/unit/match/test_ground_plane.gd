extends GutTest
## T-144: regra no plano do chão (Y da tela encolhido por 0,75) e arena em 3/4.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func test_vertical_screen_distance_is_longer_on_ground() -> void:
	assert_almost_eq(GroundPlane.distance(Vector2.ZERO, Vector2(0, 75)), 100.0, 0.001)
	assert_almost_eq(GroundPlane.distance(Vector2.ZERO, Vector2(100, 0)), 100.0, 0.001)


func test_move_toward_walks_ground_speed() -> void:
	var p := GroundPlane.move_toward(Vector2.ZERO, Vector2(0, 300), 100.0)
	assert_almost_eq(p.y, 75.0, 0.001, "100 px no chão = 75 px na tela em Y")
	assert_eq(GroundPlane.move_toward(p, Vector2(0, 80), 100.0), Vector2(0, 80), "não passa do alvo")


func test_screen_ground_round_trip() -> void:
	var v := Vector2(12, -34)
	assert_almost_eq(GroundPlane.to_screen(GroundPlane.to_ground(v)), v, Vector2(0.001, 0.001))


func test_arena_is_y_sorted_and_anima_at_arena_center() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	assert_true(arena.y_sort_enabled)
	assert_true(arena.get_node("Enemies").y_sort_enabled)
	assert_true(arena.projectiles.y_sort_enabled)
	assert_true(arena.enemy_projectiles.y_sort_enabled)
	assert_eq(arena.anima.position, arena.arena_rect().get_center())


func test_entities_have_ground_shadow_and_ellipse_collision() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	var enemy := arena.spawn(load("res://data/enemies/enemy_runner.tres"), WaveEntry.SpawnEdge.TOP)
	for node: Node2D in [arena.anima, enemy, arena.projectiles.get_child(0)]:
		var shadows := node.get_children().filter(func(c: Node) -> bool: return c is GroundShadow)
		assert_eq(shadows.size(), 1, "%s tem sombra" % node.name)
		assert_eq((shadows[0] as GroundShadow).z_index, -1)
	assert_eq(enemy.get_node("Hitbox").scale, GroundPlane.SHAPE_SCALE)
	assert_eq(arena.anima.get_node("Hurtbox").scale, GroundPlane.SHAPE_SCALE)


func test_contact_uses_ground_ellipse() -> void:
	# Inimigo encostando por baixo, a 0,75 × (soma dos raios) na tela: toca no chão.
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	var data: EnemyData = load("res://data/enemies/enemy_runner.tres").duplicate()
	data.speed = 0.0
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	var reach := (arena.anima.data.hurtbox_radius + data.radius) * GroundPlane.Y_SCALE
	e.position = arena.anima.position + Vector2(0, reach - 2.0)
	await wait_physics_frames(3)
	assert_eq(arena.anima.core.current, arena.anima.core.max_hp - data.contact_damage)
