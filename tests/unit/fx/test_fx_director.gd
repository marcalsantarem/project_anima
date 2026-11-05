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


## Cores das .tscn têm 4 casas decimais: compara com tolerância de ~1/255.
func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.004 and absf(a.g - b.g) < 0.004 and absf(a.b - b.b) < 0.004


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


func test_particles_gained_plays_green_pickup() -> void:
	arena.emit_signal("particles_gained", Vector2(5, 5), 1)
	var fx := _active(&"fx_pickup")
	assert_eq(fx.position, Vector2(5, 5), "brilho no ponto da morte (sem item no chão)")
	assert_true(_near(fx.color, Color("#7CF05A")), "corpo verde médio")
	assert_true(_near(fx._outline, Color("#124F24")), "contorno da paleta")
	assert_true(_near(fx.highlight_color, Color("#D2FFB0")), "faísca verde clara")


func test_skill_cast_scales_to_radius() -> void:
	arena.emit_signal("skill_cast", 0, Vector2(100, 100), 320.0)
	assert_almost_eq(_active(&"fx_skill_cast").size_scale, 2.0, 0.001)


func test_boss_telegraph_uses_duration_and_radius() -> void:
	arena.emit_signal("boss_telegraph_started", &"pattern_ring", 1.5, Vector2(360, 300), 45.0)
	var fx := _active(&"fx_telegraph")
	assert_almost_eq(fx.duration, 1.5, 0.001)
	assert_almost_eq(fx.size_scale, 0.5, 0.001)
	assert_true(_near(fx.color, FxDirector.BOSS_WINDUP_COLOR), "aviso do golpe em vermelho")
	assert_almost_eq(_active(&"fx_boss_windup").duration, 1.5, 0.001)
	arena.emit_signal("boss_defeated")
	assert_eq(_active(&"fx_death").position, Vector2(360, 300), "morte no último ponto do chefe")
	assert_eq(pool.active_count(&"fx_meteor_explosion"), 1, "explosão maior na morte")
	assert_eq(pool.active_count(&"fx_boss_windup"), 0)


# --- T-131 / T-132 / T-117 -------------------------------------------------------------------

func test_meteor_impact_plays_explosion_smoke_and_fallback_trail() -> void:
	var sigs: Array = FxDirector.SIGNALS.keys()
	sigs.erase(&"skill_fall_started")
	var old := _fake_arena(sigs) # arena antiga: sem o sinal da queda
	add_child_autofree(old)
	director.bind(old)
	old.emit_signal("skill_cast", 1, Vector2(300, 500), 160.0)
	assert_eq(pool.active_count(&"fx_skill_cast"), 1)
	assert_almost_eq(_active(&"fx_meteor_explosion").size_scale, 1.0, 0.001)
	assert_almost_eq(_active(&"fx_crater_smoke").delay, 0.12, 0.001)
	var trail := _active(&"fx_meteor_trail")
	assert_eq(trail.position, Vector2(300, 500 - FxDirector.METEOR_FALL_HEIGHT), "rastro começa no alto")
	assert_eq(trail.target, Vector2(0, FxDirector.METEOR_FALL_HEIGHT))
	assert_almost_eq(trail.elapsed, trail.travel_time, 0.001, "fallback: já na cauda")


func test_meteor_trail_follows_fall_signal() -> void:
	arena.emit_signal("skill_fall_started", 1, Vector2(300, 500), 0.35)
	var trail := _active(&"fx_meteor_trail")
	assert_almost_eq(trail.elapsed, 0.0, 0.001, "acompanha a queda desde o início")
	assert_almost_eq(trail.travel_time, 0.35, 0.001, "usa o fall_time")
	assert_almost_eq(trail.duration, 0.35 + FxDirector.METEOR_TRAIL_TAIL, 0.001)
	arena.emit_signal("skill_cast", 1, Vector2(300, 500), 160.0)
	assert_eq(pool.active_count(&"fx_meteor_trail"), 1, "com o sinal da queda não há fallback")


func test_fizzle_plays_puff() -> void:
	arena.emit_signal("skill_fizzled", 1, Vector2(10, 20))
	assert_eq(_active(&"fx_fizzle").position, Vector2(10, 20))


func test_module_used_and_ready_on_anima() -> void:
	arena.emit_signal("skill_used", 1)
	arena.emit_signal("skill_ready", 1)
	assert_eq(_active(&"fx_module_used").position, director.core_anchor)
	assert_eq(_active(&"fx_module_ready").position, director.core_anchor)


func test_boss_launch_plays_flight_landing_and_stun() -> void:
	arena.emit_signal("boss_launched", Vector2(360, 600), Vector2(360, 200))
	var fly := _active(&"fx_boss_launch")
	assert_eq(fly.target, Vector2(0, -400))
	assert_almost_eq(_active(&"fx_boss_land").delay, FxDirector.BOSS_LAUNCH_TIME, 0.001)
	var stun := _active(&"fx_boss_stun")
	assert_almost_eq(stun.delay, FxDirector.BOSS_LAUNCH_TIME, 0.001)
	assert_almost_eq(stun.duration, FxDirector.BOSS_STUN_TIME, 0.001)
	stun.advance(FxDirector.BOSS_LAUNCH_TIME + FxDirector.BOSS_STUN_TIME + 0.01)
	assert_false(stun.active, "estrelas somem ao fim do atordoamento")


func test_boss_attack_landed_plays_strike() -> void:
	arena.emit_signal("core_hp_changed", 100, 100)
	arena.emit_signal("boss_telegraph_started", &"boss_slam", 0.5, Vector2(360, 600), 110.0)
	arena.emit_signal("boss_attack_landed", Vector2(360, 690))
	assert_eq(_active(&"fx_boss_wave").position, Vector2(360, 690))
	assert_eq(pool.active_count(&"fx_boss_slam"), 1)
	arena.emit_signal("core_hp_changed", 80, 100)
	assert_eq(pool.active_count(&"fx_boss_wave"), 1, "com o sinal, a queda de HP não duplica")


func test_pool_restores_scene_duration() -> void:
	arena.emit_signal("skill_fall_started", 1, Vector2(300, 500), 0.2)
	var trail := _active(&"fx_meteor_trail")
	trail.stop()
	var again := pool.play(&"fx_meteor_trail", Vector2.ZERO)
	assert_almost_eq(again.travel_time, 0.35, 0.001, "valor da cena volta a cada play")


func test_boss_strike_fallback_without_signal() -> void:
	var sigs: Array = FxDirector.SIGNALS.keys()
	sigs.erase(&"boss_attack_landed")
	arena = _fake_arena(sigs)
	add_child_autofree(arena)
	director.bind(arena)
	arena.emit_signal("core_hp_changed", 100, 100)
	arena.emit_signal("core_hp_changed", 90, 100)
	assert_eq(pool.active_count(&"fx_boss_wave"), 0, "dano comum não é golpe do chefe")
	arena.emit_signal("boss_telegraph_started", &"boss_slam", 0.5, Vector2(360, 600), 110.0)
	arena.emit_signal("core_hp_changed", 70, 100)
	assert_eq(pool.active_count(&"fx_boss_wave"), 1)
	assert_eq(pool.active_count(&"fx_boss_slam"), 1)


func test_launch_cancels_pending_strike() -> void:
	arena.emit_signal("core_hp_changed", 100, 100)
	arena.emit_signal("boss_telegraph_started", &"boss_slam", 0.5, Vector2(360, 600), 110.0)
	arena.emit_signal("boss_launched", Vector2(360, 600), Vector2(360, 200))
	assert_eq(pool.active_count(&"fx_boss_windup"), 0, "brilho do wind-up some no lançamento")
	arena.emit_signal("core_hp_changed", 90, 100)
	assert_eq(pool.active_count(&"fx_boss_wave"), 0)


func test_reduced_keeps_warnings_and_cuts_extras() -> void:
	director.reduced_effects = true
	arena.emit_signal("core_hp_changed", 100, 100)
	arena.emit_signal("boss_telegraph_started", &"boss_slam", 0.5, Vector2(360, 600), 110.0)
	assert_eq(pool.active_count(&"fx_telegraph"), 1, "aviso do golpe sempre visível")
	assert_eq(pool.active_count(&"fx_boss_windup"), 0, "sem brilho")
	arena.emit_signal("boss_attack_landed", Vector2(360, 690))
	assert_eq(pool.active_count(&"fx_boss_wave"), 1, "onda do golpe mantida")
	assert_eq(pool.active_count(&"fx_boss_slam"), 0, "sem poeira")
	arena.emit_signal("boss_launched", Vector2(360, 600), Vector2(360, 200))
	assert_eq(pool.active_count(&"fx_boss_launch"), 0, "sem rastro de voo")
	assert_eq(pool.active_count(&"fx_boss_land"), 0)
	assert_eq(pool.active_count(&"fx_boss_stun"), 1, "atordoamento continua legível")
	arena.emit_signal("skill_cast", 1, Vector2(300, 500), 160.0)
	assert_eq(pool.active_count(&"fx_meteor_explosion"), 1)
	assert_eq(pool.active_count(&"fx_skill_cast"), 1)
	assert_eq(pool.active_count(&"fx_crater_smoke"), 0, "sem fumaça")
	assert_eq(pool.active_count(&"fx_meteor_trail"), 0, "sem rastro")


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
