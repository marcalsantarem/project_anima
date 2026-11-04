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


func test_floor_is_behind_everything_and_centered() -> void:
	var arena := _arena()
	await wait_physics_frames(1)
	var floor_sprite := arena.get_child(0) as Sprite2D
	assert_not_null(floor_sprite)
	assert_lt(floor_sprite.z_index, -1) # sombras e decalques: z -1
	assert_eq(floor_sprite.position, arena.anima.position)
	assert_eq(floor_sprite.scale, SpriteArt.SCALE)


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
