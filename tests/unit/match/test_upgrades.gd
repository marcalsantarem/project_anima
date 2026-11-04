extends GutTest
## T-134: compra, custo crescente, teto, reset e efeito de cada upgrade.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const COSTS := [5, 7, 10, 14, 20, 27, 38, 53, 74, 104]

var _events: Array = []


func _arena(particles: int = 0) -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	arena.upgrade_changed.connect(func(id, lv, mx, cost) -> void: _events.append([id, lv, mx, cost]))
	add_child_autofree(arena)
	arena.particles = particles
	return arena


func before_each() -> void:
	_events.clear()


func test_data_files_match_meta_doc() -> void:
	var u := MatchUpgrades.from_ids(Arena.UPGRADE_IDS)
	for id in Arena.UPGRADE_IDS:
		var d := u.get_data(id)
		assert_not_null(d, String(id))
		assert_eq(d.max_level, 10)
		assert_eq(Array(d.costs), COSTS)


func test_initial_signals_for_all_five_in_order() -> void:
	_arena()
	assert_eq(_events.size(), 5)
	for i in 5:
		assert_eq(_events[i], [Arena.UPGRADE_IDS[i], 0, 10, 5])


func test_buy_spends_and_cost_grows() -> void:
	var arena := _arena(12)
	_events.clear()
	assert_true(arena.buy_upgrade(&"upgrade_atk_power"))
	assert_eq(arena.particles, 7)
	assert_eq(_events.back(), [&"upgrade_atk_power", 1, 10, 7])
	assert_true(arena.buy_upgrade(&"upgrade_atk_power"))
	assert_eq(arena.particles, 0)
	assert_eq(_events.back(), [&"upgrade_atk_power", 2, 10, 10])


func test_buy_fails_without_particles_or_unknown_id() -> void:
	var arena := _arena(4)
	_events.clear()
	assert_false(arena.buy_upgrade(&"upgrade_atk_spd"))
	assert_false(arena.buy_upgrade(&"upgrade_nope"))
	assert_eq(arena.particles, 4)
	assert_eq(arena.upgrades.level(&"upgrade_atk_spd"), 0)
	assert_eq(_events.size(), 0)


func test_cap_at_max_level() -> void:
	var arena := _arena(352)
	for i in 10:
		assert_true(arena.buy_upgrade(&"upgrade_defense"))
	assert_eq(arena.particles, 0, "acumulado 352")
	assert_eq(_events.back(), [&"upgrade_defense", 10, 10, -1])
	arena.particles = 1000
	assert_false(arena.buy_upgrade(&"upgrade_defense"))
	assert_eq(arena.particles, 1000)


func test_reset_each_match() -> void:
	var a := _arena(5)
	a.buy_upgrade(&"upgrade_atk_power")
	var b := _arena()
	assert_eq(b.upgrades.level(&"upgrade_atk_power"), 0)
	assert_eq(b.particles, 0)


func test_atk_power_raises_shot_damage() -> void:
	var arena := _arena(22)
	var base := arena.anima.shot_damage()
	assert_eq(base, 10)
	for i in 3:
		arena.buy_upgrade(&"upgrade_atk_power")
	assert_eq(arena.anima.shot_damage(), 13)


func test_atk_spd_raises_fire_rate() -> void:
	var arena := _arena(5)
	arena.buy_upgrade(&"upgrade_atk_spd")
	assert_almost_eq(arena.anima.fire_rate(), 2.16, 0.0001)


func test_defense_reduces_core_damage_min_one() -> void:
	var arena := _arena(352)
	for i in 10:
		arena.buy_upgrade(&"upgrade_defense")
	var core := arena.anima.core
	assert_eq(arena.anima.take_core_damage(20), 12, "−40%")
	assert_eq(arena.anima.take_core_damage(1), 1, "mínimo 1")
	assert_eq(core.current, core.max_hp - 13)


func test_max_hp_raises_max_and_current() -> void:
	var arena := _arena(12)
	var hp: Array = []
	arena.core_hp_changed.connect(func(c: int, m: int) -> void: hp.append([c, m]))
	arena.anima.take_core_damage(30)
	arena.buy_upgrade(&"upgrade_max_hp")
	assert_eq(hp.back(), [80, 110])
	arena.buy_upgrade(&"upgrade_max_hp")
	assert_eq(hp.back(), [90, 120])


func test_cooldown_applies_from_next_use() -> void:
	var arena := _arena(5)
	arena.anima.auto_attack_enabled = false
	var e := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -200) # alvo para a skill de área
	assert_true(arena.use_skill(1))
	var slot := arena.skills.get_slot(1)
	var before := slot.remaining
	arena.buy_upgrade(&"upgrade_cooldown")
	assert_eq(slot.remaining, before, "cooldown em curso não muda")
	slot.tick(100.0)
	assert_true(arena.use_skill(1))
	assert_almost_eq(slot.total, slot.data.cooldown * 0.96, 0.0001)
	assert_almost_eq(slot.remaining, slot.total, 0.0001)


func test_buy_does_not_pause_and_fails_after_end() -> void:
	var arena := _arena(100)
	assert_false(arena.get_tree().paused)
	arena.buy_upgrade(&"upgrade_atk_power")
	assert_false(arena.get_tree().paused)
	arena._end(MatchResult.Outcome.DEFEAT)
	assert_false(arena.buy_upgrade(&"upgrade_atk_power"))
