extends GutTest
## T-130: FxDirector reage aos sinais da arena (emissor falso), tolera sinais ausentes e reusa o pool.

var arena: Node2D
var pool: FxPool
var director: FxDirector


func _fake_arena(signals: Array) -> Node2D:
	var a := Node2D.new()
	for s: String in signals:
		a.add_user_signal(s)
	return a


func before_each() -> void:
	arena = _fake_arena(FxDirector.SIGNALS.keys())
	add_child_autofree(arena)
	pool = FxPool.new()
	arena.add_child(pool)
	pool.setup_default()
	director = FxDirector.new()
	director.pool = pool
	arena.add_child(director)
	director.bind(arena)


func _active(type: StringName) -> FxEffect:
	for fx: FxEffect in pool.get_children():
		if fx.active and fx.name.begins_with(type + "_"):
			return fx
	return null


func test_binds_all_signals() -> void:
	assert_eq(director.connected_signals().size(), FxDirector.SIGNALS.size())


func test_missing_signals_are_tolerated() -> void:
	var partial := _fake_arena(["projectile_hit"])
	add_child_autofree(partial)
	var got := director.bind(partial)
	assert_eq(got, [&"projectile_hit"] as Array[StringName])
	partial.emit_signal("projectile_hit", Vector2(1, 2), &"enemy")
	assert_eq(pool.active_count(&"fx_hit"), 1)


func test_projectile_fired_plays_muzzle_and_trail() -> void:
	arena.emit_signal("projectile_fired", Vector2(360, 690), Vector2(3, 0))
	assert_eq(pool.active_count(&"fx_muzzle"), 1)
	var trail := _active(&"fx_trail")
	assert_not_null(trail)
	assert_eq(trail.direction, Vector2.RIGHT)
	assert_eq(trail.position, Vector2(360, 690))


func test_reduced_effects_skip_trail() -> void:
	director.reduced_effects = true
	assert_true(pool.reduced_effects)
	arena.emit_signal("projectile_fired", Vector2.ZERO, Vector2.UP)
	assert_eq(pool.active_count(&"fx_muzzle"), 1)
	assert_eq(pool.active_count(&"fx_trail"), 0)


func test_projectile_hit_by_target_kind() -> void:
	arena.emit_signal("projectile_hit", Vector2(10, 10), &"enemy")
	var hit := _active(&"fx_hit")
	assert_eq(hit.color, hit.default_color, "inimigo comum: cor do jogador (accent)")
	pool.stop_all()
	arena.emit_signal("projectile_hit", Vector2(10, 10), &"boss")
	assert_eq(_active(&"fx_hit").color, FxDirector.BOSS_COLOR)


func test_enemy_died_uses_archetype_color_and_size() -> void:
	arena.emit_signal("enemy_died", Vector2(50, 60), &"enemy_tank", 0)
	var fx := _active(&"fx_death")
	assert_eq(fx.color, Color("#E8344E"))
	assert_almost_eq(fx.size_scale, 1.4, 0.001)
	assert_eq(fx.position, Vector2(50, 60))


func test_particles_gained_plays_gold_pickup() -> void:
	arena.emit_signal("particles_gained", Vector2(5, 5), 1)
	assert_eq(_active(&"fx_pickup").color, FxDirector.GOLD)


func test_skill_cast_scales_to_radius() -> void:
	arena.emit_signal("skill_cast", 0, Vector2(100, 100), 320.0)
	assert_almost_eq(_active(&"fx_skill_cast").size_scale, 2.0, 0.001)


func test_boss_telegraph_uses_duration_and_radius() -> void:
	arena.emit_signal("boss_telegraph_started", &"pattern_ring", 1.5, Vector2(360, 300), 45.0)
	var fx := _active(&"fx_telegraph")
	assert_almost_eq(fx.duration, 1.5, 0.001)
	assert_almost_eq(fx.size_scale, 0.5, 0.001)
	arena.emit_signal("boss_phase_changed", 2)
	assert_eq(_active(&"fx_death").position, Vector2(360, 300), "fase nasce no último ponto do chefe")


func test_core_pulse_only_when_hp_drops() -> void:
	arena.emit_signal("core_hp_changed", 100, 100)
	assert_eq(pool.active_count(&"fx_core_pulse"), 0, "primeiro valor é só referência")
	arena.emit_signal("core_hp_changed", 90, 100)
	assert_eq(pool.active_count(&"fx_core_pulse"), 1)
	arena.emit_signal("core_hp_changed", 95, 100)
	assert_eq(pool.active_count(&"fx_core_pulse"), 1, "cura não pulsa")


func test_upgrade_only_when_level_rises() -> void:
	arena.emit_signal("upgrade_changed", &"upgrade_damage", 0, 5, 10)
	assert_eq(pool.active_count(&"fx_upgrade"), 0)
	arena.emit_signal("upgrade_changed", &"upgrade_damage", 1, 5, 20)
	assert_eq(pool.active_count(&"fx_upgrade"), 1)


func test_burst_of_signals_reuses_pool() -> void:
	var before := pool.get_child_count()
	for i in 200:
		arena.emit_signal("projectile_fired", Vector2(i, i), Vector2.UP)
		arena.emit_signal("projectile_hit", Vector2(i, i), &"enemy")
		arena.emit_signal("enemy_died", Vector2(i, i), &"enemy_swarm", 0)
	assert_eq(pool.get_child_count(), before, "nada é instanciado por sinal")
	assert_eq(pool.active_count(&"fx_hit"), pool.capacity(&"fx_hit"))


func test_unbind_disconnects() -> void:
	director.unbind()
	arena.emit_signal("projectile_hit", Vector2.ZERO, &"enemy")
	assert_eq(pool.active_count(&"fx_hit"), 0)
