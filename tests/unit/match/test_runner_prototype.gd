extends GutTest

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func test_runner_data_matches_gameplay_doc() -> void:
	assert_eq(RUNNER.id, &"enemy_runner")
	assert_eq(RUNNER.hp, 20)
	assert_eq(RUNNER.speed, 140.0)
	assert_eq(RUNNER.contact_damage, 4)


func test_step_towards_moves_by_speed_and_stops_at_target() -> void:
	var p := Enemy.step_towards(Vector2.ZERO, Vector2(100, 0), 140.0, 0.5)
	assert_eq(p, Vector2(70, 0))
	p = Enemy.step_towards(p, Vector2(100, 0), 140.0, 0.5)
	assert_eq(p, Vector2(100, 0))


func test_arena_rect_goes_from_top_to_tray() -> void:
	assert_eq(Arena.rect_for(Vector2(720, 1280), 282.0), Rect2(0, 0, 720, 998))
	assert_eq(Arena.rect_for(Vector2(720, 1560), 282.0), Rect2(0, 0, 720, 1278))


func test_edge_points_are_outside_screen() -> void:
	var rect := Rect2(0, 0, 720, 1280) # spawn é por fora da tela inteira
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.TOP, rect, 64.0, 0.5), Vector2(360, -64))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.BOTTOM, rect, 64.0, 0.0), Vector2(0, 1344))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.LEFT, rect, 64.0, 1.0), Vector2(-64, 1280))
	assert_eq(Arena.edge_point(WaveEntry.SpawnEdge.RIGHT, rect, 64.0, 0.5), Vector2(784, 640))


func test_spawn_margin_covers_sprite() -> void:
	var boss: EnemyData = load("res://data/enemies/boss_warden.tres")
	assert_eq(Arena.spawn_margin_for(RUNNER, 32.0, WaveEntry.SpawnEdge.LEFT), 32.0 + 32.0, "meia largura 1x")
	assert_eq(Arena.spawn_margin_for(boss, 32.0, WaveEntry.SpawnEdge.RIGHT), 32.0 + 128.0)
	assert_eq(Arena.spawn_margin_for(boss, 32.0, WaveEntry.SpawnEdge.BOTTOM), 32.0 + 236.0, "altura acima da âncora")
	assert_eq(Arena.spawn_margin_for(boss, 32.0, WaveEntry.SpawnEdge.TOP), 32.0 + boss.radius)


## Caixa do desenho (sprite 1x a partir da âncora, mais a sombra) fora da tela em todas as bordas.
func test_spawned_enemies_are_not_visible() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	var screen := arena.screen_rect()
	for id in ["enemy_runner", "enemy_tank", "enemy_shooter", "enemy_swarm", "boss_warden"]:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		var size := data.sprite.get_size() * SpriteArt.SCALE
		var anchor := data.sprite_anchor * SpriteArt.SCALE
		for edge in [WaveEntry.SpawnEdge.TOP, WaveEntry.SpawnEdge.LEFT, WaveEntry.SpawnEdge.RIGHT, WaveEntry.SpawnEdge.BOTTOM]:
			var e := arena.spawn(data, edge)
			var body := Rect2(e.position - anchor, size).merge(Rect2(e.position - Vector2.ONE * data.radius, Vector2.ONE * data.radius * 2.0))
			if data.ring_sprite != null and edge != WaveEntry.SpawnEdge.TOP and edge != WaveEntry.SpawnEdge.BOTTOM:
				var rw := data.ring_sprite.get_width() * SpriteArt.SCALE.x
				body = body.merge(Rect2(e.position.x - rw * 0.5, e.position.y, rw, 1.0))
			assert_false(screen.intersects(body), "%s nasce fora da tela (borda %d)" % [id, edge])
			arena.active_enemies.erase(e)
			e.free()


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
