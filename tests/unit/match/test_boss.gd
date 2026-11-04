extends GutTest
## T-115: fases por vida, telegraph antes do ataque, padrões, drop e vitória.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const WARDEN := preload("res://data/enemies/boss_warden.tres")
const BOSS_HP := 2500 # BRF-051

var _arena: Arena
var _boss: Boss


func before_each() -> void:
	_arena = ARENA_SCENE.instantiate()
	_arena.waves_enabled = false
	add_child_autofree(_arena)
	_arena.anima.auto_attack_enabled = false


func _spawn_boss() -> Boss:
	_boss = _arena.spawn(WARDEN, WaveEntry.SpawnEdge.TOP) as Boss
	return _boss


## Coloca o chefe em ataque com só um padrão valendo.
func _attack_with(pattern_id: StringName) -> BossPattern:
	_spawn_boss()
	_boss.position = _arena.anima.position + Vector2(0, -300)
	var p: BossPattern
	for q in WARDEN.patterns:
		if q.id == pattern_id:
			p = q
	_boss.boss_data = WARDEN.duplicate()
	_boss.boss_data.patterns = [p] as Array[BossPattern]
	_boss.phase = 2 # todos os padrões têm peso > 0 na fase 3
	_boss.state = Enemy.State.ATTACK
	_boss._wait()
	return p


func test_data_is_boss() -> void:
	assert_true(WARDEN is BossData)
	assert_eq(WARDEN.phase_count(), 3)
	assert_gte(WARDEN.patterns.size(), 2)
	for p in WARDEN.patterns:
		assert_gte(p.telegraph, 0.8, "aviso longo: %s" % p.id)


func test_phase_for_hp_ratio() -> void:
	assert_eq(WARDEN.phase_for(1.0), 0)
	assert_eq(WARDEN.phase_for(0.61), 0)
	assert_eq(WARDEN.phase_for(0.59), 1)
	assert_eq(WARDEN.phase_for(0.29), 2)


func test_spawn_emits_boss_signals() -> void:
	watch_signals(_arena)
	_spawn_boss()
	assert_signal_emitted_with_parameters(_arena, "boss_spawned", [&"boss_warden"])
	assert_signal_emitted_with_parameters(_arena, "boss_hp_changed", [BOSS_HP, BOSS_HP])


func test_phase_changes_with_damage() -> void:
	_spawn_boss()
	watch_signals(_boss)
	watch_signals(_arena)
	_boss.take_damage(roundi(BOSS_HP / 3.0)) # 67%
	assert_eq(_boss.phase, 0)
	_boss.take_damage(roundi(BOSS_HP / 12.0)) # ~58%
	assert_eq(_boss.phase, 1)
	_boss.take_damage(roundi(BOSS_HP / 3.0)) # ~25%
	assert_eq(_boss.phase, 2)
	assert_signal_emit_count(_boss, "phase_changed", 2)
	assert_signal_emitted_with_parameters(_arena, "boss_hp_changed", [_boss.hp, BOSS_HP])


func test_telegraph_comes_before_fan() -> void:
	var p := _attack_with(&"pattern_fan")
	watch_signals(_boss)
	_boss.tick_patterns(WARDEN.interval_for(2) + 0.01)
	assert_signal_emitted(_boss, "telegraph_started")
	assert_signal_not_emitted(_boss, "pattern_executed")
	assert_eq(_arena.enemy_projectiles.active_count(), 0, "nada sai durante o aviso")
	_boss.tick_patterns(p.telegraph * 0.5)
	assert_eq(_arena.enemy_projectiles.active_count(), 0)
	_boss.tick_patterns(p.telegraph * 0.5 + 0.01)
	assert_signal_emitted_with_parameters(_boss, "pattern_executed", [&"pattern_fan"])
	assert_eq(_arena.enemy_projectiles.active_count(), p.projectile_count)


func test_ring_fires_all_projectiles() -> void:
	var p := _attack_with(&"pattern_ring")
	_boss.tick_patterns(WARDEN.interval_for(2) + 0.01)
	_boss.tick_patterns(p.telegraph + 0.01)
	assert_eq(_arena.enemy_projectiles.active_count(), p.projectile_count)


func test_summon_spawns_near_boss() -> void:
	var p := _attack_with(&"pattern_summon")
	var before := _arena.active_enemies.size()
	_boss.tick_patterns(WARDEN.interval_for(2) + 0.01)
	_boss.tick_patterns(p.telegraph + 0.01)
	assert_eq(_arena.active_enemies.size(), before + p.summon_count)
	var last := _arena.active_enemies.back() as Enemy
	assert_almost_eq(GroundPlane.distance(last.position, _boss.position), p.summon_radius, 1.0)


func test_pattern_weights_respect_phase() -> void:
	_spawn_boss()
	_boss.phase = 0
	for i in 50:
		assert_ne(_boss.pick_pattern().id, &"pattern_ring", "anel só a partir da fase 2")


func test_kill_drops_particles_and_wins() -> void:
	watch_signals(_arena)
	_spawn_boss()
	_boss.take_damage(WARDEN.hp)
	assert_eq(_arena.particles, WARDEN.particle_drop)
	assert_signal_emitted(_arena, "boss_defeated")
	assert_signal_emitted(_arena, "match_ended")
	var result: MatchResult = get_signal_parameters(_arena, "match_ended")[0]
	assert_eq(result.outcome, MatchResult.Outcome.VICTORY)


func test_boss_stops_at_attack_range() -> void:
	_spawn_boss()
	for i in 600:
		_boss._physics_process(1.0 / 60.0)
		if _boss.state == Enemy.State.ATTACK:
			break
	assert_eq(_boss.state, Enemy.State.ATTACK)
	assert_almost_eq(GroundPlane.distance(_boss.position, _arena.anima.position), WARDEN.attack_range, 2.0)
