extends GutTest
## T-137: arte final na arena (sprites 2x a 0,5, âncora no chão), sem desenho geométrico.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const ENEMY_IDS := ["enemy_runner", "enemy_tank", "enemy_shooter", "enemy_swarm"]


func _arena() -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	return arena


func _sprites(node: Node) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	for c in node.find_children("*", "Sprite2D", true, false):
		out.append(c as Sprite2D)
	return out


func _assert_sprite_rules(s: Sprite2D) -> void:
	assert_not_null(s.texture, "%s sem textura" % s.get_path())
	assert_false(s.centered)
	assert_eq(s.offset, -s.offset.abs(), "offset = -âncora")
	assert_eq(s.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR)


## BRF-041: fundo em tela cheia (tile, selo no Anima, degradê, 4 pilares com sombra e Y-sort).
func test_floor_covers_screen_without_ring_and_pillars_in_corners() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var floor_node := arena.get_node("Floor") as ArenaFloor
	assert_true(floor_node.y_sort_enabled)
	var sprites := _sprites(floor_node)
	assert_eq(sprites.size(), 2 + 4, "tile, degradê e 4 pilares (sem selo, T-292)")
	for s in sprites:
		_assert_sprite_rules(s)
		assert_eq(s.texture.get_mipmap_count(), 0, "%s sem mipmaps" % s.texture.resource_path)
	var tile := sprites[0]
	assert_lt(tile.z_index, -1) # sombras e decalques: z -1
	assert_eq(tile.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED)
	assert_eq(tile.position, Vector2.ZERO)
	assert_eq(tile.region_rect.size * SpriteArt.SCALE, arena.arena_size(), "tile cobre a tela inteira")
	for s in sprites:
		assert_false(s.texture.resource_path.contains("floor_ring"), "T-292: sem selo/anel no chão")
	var rect := arena.free_rect()
	var pillars := floor_node.get_children().filter(func(c: Node) -> bool: return c.get_child_count() == 2)
	assert_eq(pillars.size(), 4)
	for p: Node2D in pillars:
		assert_true(rect.has_point(p.position), "pilar dentro da arena")
		assert_true(p.get_child(0) is GroundShadow)
		assert_eq((p.get_child(1) as Sprite2D).z_index, 0, "pilar no Y-sort das entidades")


func test_layout_follows_tray_inset() -> void:
	var arena := _arena()
	arena.set_bottom_inset(400.0)
	assert_eq(arena.arena_rect().end.y, arena.arena_size().y - 400.0)
	var center_y := (arena.arena_top_inset + arena.arena_rect().end.y) / 2.0
	assert_eq(arena.anima.position, Vector2(arena.arena_size().x / 2.0, center_y), "centro da área livre")


## T-169: Anima no centro da área livre entre o topo do HUD (fixo) e a bandeja.
func test_free_rect_between_top_hud_and_tray() -> void:
	assert_eq(Arena.free_rect_for(Vector2(720, 1280), 164.0, 282.0), Rect2(0, 164, 720, 834))
	assert_eq(Arena.free_rect_for(Vector2(720, 1474), 164.0, 282.0).get_center(), Vector2(360, 678))
	var arena := _arena()
	assert_eq(arena.arena_top_inset, 164.0, "= Hud.TOP_INSET, fixo")
	var e := arena.spawn(load("res://data/enemies/enemy_tank.tres"), WaveEntry.SpawnEdge.TOP)
	arena.set_bottom_inset(200.0)
	assert_eq(e.target_position, arena.anima.position, "inimigos em campo seguem o novo centro")


func test_anima_has_base_crystal_and_orbit_nodes() -> void:
	var arena := _arena()
	var sprites := _sprites(arena.anima)
	assert_eq(sprites.size(), 2 + arena.anima.data.orbit_count)
	for s in sprites:
		_assert_sprite_rules(s)
	await wait_frames(5)
	var crystal := sprites[1]
	assert_almost_eq(-crystal.position.y, arena.anima.data.crystal_height, arena.anima.data.crystal_bob_amplitude + 0.01)


func test_each_archetype_gets_its_sprite() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	for id in ENEMY_IDS:
		var data: EnemyData = load("res://data/enemies/%s.tres" % id)
		var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
		var sprites := _sprites(e)
		assert_eq(sprites.size(), 1, id)
		_assert_sprite_rules(sprites[0])
		assert_eq(sprites[0].texture.resource_path.get_file().get_basename(), id)


func test_projectiles_use_sprites_and_point_to_direction() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	for pool in [arena.projectiles, arena.enemy_projectiles]:
		var p: Projectile = pool.acquire()
		p.fire(arena.anima.position, Vector2.LEFT, 100.0)
		var s := _sprites(p)
		assert_eq(s.size(), 1)
		_assert_sprite_rules(s[0])
		assert_almost_eq(s[0].rotation, PI, 0.001)
		assert_eq(s[0].position, Vector2(0.0, -p.data.height))
