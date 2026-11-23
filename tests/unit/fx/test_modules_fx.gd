extends GutTest
## T-215: efeitos do Congelamento, Escudo e Choque (pool, sinais do FxDirector, reduzido, sem vazamento).

class FakeEnemy:
	extends Node2D
	var frozen_left := 2.0
	var slow_left := 1.5


var arena: Node2D
var pool: FxPool
var director: FxDirector


func before_each() -> void:
	arena = Node2D.new()
	arena.set_script(load("res://tests/unit/fx/fake_module_arena.gd"))
	add_child_autofree(arena)
	pool = FxPool.new()
	arena.add_child(pool)
	pool.setup_default()
	director = FxDirector.new()
	director.pool = pool
	arena.add_child(director)
	director.bind(arena)


func _run(seconds: float) -> void:
	for i in int(seconds * 60.0):
		for fx: FxEffect in pool.get_children():
			fx.advance(1.0 / 60.0)
		for e: FakeEnemy in arena.active_enemies:
			e.frozen_left = maxf(e.frozen_left - 1.0 / 60.0, 0.0)


func test_types_registered() -> void:
	for t: StringName in [&"fx_freeze", &"fx_shield", &"fx_shock"]:
		assert_gt(pool.capacity(t), 0, str(t))


func test_shock_hits_are_staggered_and_return_to_pool() -> void:
	for k in 6:
		arena.emit_signal("skill_chain_hit", 3, Vector2(300, 600), Vector2(300 + 40 * k, 500), 10, k)
	assert_eq(pool.active_count(&"fx_shock"), 6)
	var delays := []
	for fx: FxEffect in pool.get_children():
		if fx.active and fx.name.begins_with("fx_shock_"):
			delays.append(fx.delay)
	delays.sort()
	assert_eq(delays[0], 0.0)
	assert_gt(delays[5], delays[1])
	_run(0.8)
	assert_eq(pool.active_count(&"fx_shock"), 0)


func test_shock_cast_has_no_meteor_explosion() -> void:
	arena.emit_signal("skill_cast", 3, Vector2(300, 500), 20.0)
	assert_eq(pool.active_count(&"fx_meteor_explosion"), 0)
	arena.emit_signal("skill_cast", 1, Vector2(300, 500), 160.0)
	assert_eq(pool.active_count(&"fx_meteor_explosion"), 1)


func test_freeze_wave_crystals_and_thaw() -> void:
	for k in 3:
		var e := FakeEnemy.new()
		e.position = Vector2(300 + k * 30, 500)
		arena.add_child(e)
		arena.active_enemies.append(e)
	arena.emit_signal("skill_cast", 2, Vector2(300, 500), 200.0)
	assert_eq(pool.active_count(&"fx_meteor_explosion"), 0)
	assert_eq(pool.active_count(&"fx_freeze"), 1)
	var fx: FxFreeze = null
	for n in pool.get_children():
		if n is FxFreeze and n.active:
			fx = n
	assert_almost_eq(fx.duration, 2.4, 0.001)
	_run(1.0)
	fx.queue_redraw()
	assert_true(fx.active)
	_run(2.0)
	assert_eq(pool.active_count(&"fx_freeze"), 0)


func test_shield_lifecycle_broken_and_expired() -> void:
	arena.emit_signal("shield_started", 50, 4.0)
	assert_eq(pool.active_count(&"fx_shield"), 1)
	arena.emit_signal("shield_absorbed", 20, 30)
	arena.emit_signal("shield_ended", true)
	_run(0.2)
	assert_eq(pool.active_count(&"fx_shield"), 1, "estilhaços ainda em cena")
	_run(0.5)
	assert_eq(pool.active_count(&"fx_shield"), 0)
	arena.emit_signal("shield_started", 50, 4.0)
	arena.emit_signal("shield_ended", false)
	_run(0.5)
	assert_eq(pool.active_count(&"fx_shield"), 0)


func test_shield_renew_reuses_instance() -> void:
	arena.emit_signal("shield_started", 50, 4.0)
	arena.emit_signal("shield_started", 50, 4.0)
	assert_eq(pool.active_count(&"fx_shield"), 1)


func test_reduced_mode_still_plays_and_ends() -> void:
	director.reduced_effects = true
	arena.emit_signal("shield_started", 50, 4.0)
	arena.emit_signal("shield_absorbed", 20, 30)
	arena.emit_signal("skill_chain_hit", 3, Vector2(300, 600), Vector2(340, 500), 10, 0)
	arena.emit_signal("skill_cast", 2, Vector2(300, 500), 200.0)
	arena.emit_signal("shield_ended", true)
	for fx: FxEffect in pool.get_children():
		fx.queue_redraw()
	_run(2.6)
	assert_eq(pool.active_count(&"fx_shield"), 0)
	assert_eq(pool.active_count(&"fx_shock"), 0)
	assert_eq(pool.active_count(&"fx_freeze"), 0)


func test_no_node_leak() -> void:
	var before := pool.get_child_count()
	for r in 5:
		arena.emit_signal("shield_started", 50, 4.0)
		for k in 8:
			arena.emit_signal("skill_chain_hit", 3, Vector2(300, 600), Vector2(300 + k, 500), 10, k)
		arena.emit_signal("skill_cast", 2, Vector2(300, 500), 200.0)
		arena.emit_signal("shield_ended", true)
		_run(0.1)
	assert_eq(pool.get_child_count(), before)
