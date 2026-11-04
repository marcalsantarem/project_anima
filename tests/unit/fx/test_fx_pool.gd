extends GutTest
## T-129: pool de efeitos (reuso, limite, reciclagem, sem instanciar no play).

const HIT := preload("res://src/fx/fx_hit.tscn")
const TELEGRAPH := preload("res://src/fx/fx_telegraph.tscn")

var pool: FxPool


func before_each() -> void:
	pool = FxPool.new()
	add_child_autofree(pool)
	pool.register(&"fx_hit", HIT, 3)


func test_register_precreates_hidden_instances() -> void:
	assert_eq(pool.capacity(&"fx_hit"), 3)
	assert_eq(pool.get_child_count(), 3)
	assert_eq(pool.active_count(&"fx_hit"), 0)
	for fx: FxEffect in pool.get_children():
		assert_false(fx.visible)


func test_play_does_not_instantiate() -> void:
	for i in 10:
		pool.play(&"fx_hit", Vector2(i, i))
	assert_eq(pool.get_child_count(), 3, "nada é criado durante a partida")
	assert_eq(pool.active_count(&"fx_hit"), 3, "limite respeitado")


func test_finished_instance_is_reused() -> void:
	var a := pool.play(&"fx_hit", Vector2(10, 20))
	assert_eq(a.position, Vector2(10, 20))
	assert_true(a.active and a.visible)
	watch_signals(a)
	a.advance(a.duration + 0.01)
	assert_signal_emitted(a, "finished")
	assert_false(a.active)
	assert_false(a.visible)
	var b := pool.play(&"fx_hit", Vector2(5, 5))
	assert_same(b, a, "reusa a instância livre")


func test_full_pool_recycles_oldest() -> void:
	var first := pool.play(&"fx_hit", Vector2.ZERO)
	first.advance(0.1)
	var second := pool.play(&"fx_hit", Vector2.ZERO)
	second.advance(0.05)
	pool.play(&"fx_hit", Vector2.ZERO)
	var recycled := pool.play(&"fx_hit", Vector2(1, 1))
	assert_same(recycled, first, "a mais antiga é reciclada")
	assert_almost_eq(recycled.elapsed, 0.0, 0.0001)
	assert_eq(recycled.position, Vector2(1, 1))


func test_default_and_custom_color() -> void:
	var fx := pool.play(&"fx_hit", Vector2.ZERO)
	assert_eq(fx.color, fx.default_color)
	fx = pool.play(&"fx_hit", Vector2.ZERO, Color.RED, 2.0)
	assert_eq(fx.color, Color.RED)
	assert_eq(fx.size_scale, 2.0)


func test_unknown_type_returns_null() -> void:
	assert_null(pool.play(&"fx_nope", Vector2.ZERO))
	assert_eq(pool.capacity(&"fx_nope"), 0)


func test_reduced_mode_halves_dots() -> void:
	var fx := pool.play(&"fx_hit", Vector2.ZERO)
	var full := fx.dots_to_draw()
	pool.reduced_effects = true
	fx = pool.play(&"fx_hit", Vector2.ZERO)
	assert_true(fx.reduced)
	assert_eq(fx.dots_to_draw(), int(ceil(full * 0.5)))


func test_ground_ring_is_floor_decal() -> void:
	pool.register(&"fx_telegraph", TELEGRAPH, 1)
	var fx := pool.play(&"fx_telegraph", Vector2.ZERO)
	assert_eq(fx.z_index, -1, "decalque de chão abaixo dos corpos")
	assert_true(pool.y_sort_enabled)


func test_default_types_load_and_play() -> void:
	var full := FxPool.new()
	add_child_autofree(full)
	full.setup_default()
	for type: StringName in FxPool.DEFAULT_TYPES:
		assert_not_null(full.play(type, Vector2(100, 100)), String(type))
		assert_eq(full.capacity(type), FxPool.DEFAULT_TYPES[type][1])
	full.stop_all()
	for type: StringName in FxPool.DEFAULT_TYPES:
		assert_eq(full.active_count(type), 0)
