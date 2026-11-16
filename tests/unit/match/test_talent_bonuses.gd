extends GutTest
## T-205 (BRF-154): a partida aplica os bônus dos Núcleos (MatchConfig.talent_bonuses).

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const IDS: Array[StringName] = [
	&"upgrade_atk_power", &"upgrade_atk_spd", &"upgrade_defense", &"upgrade_max_hp", &"upgrade_cooldown",
]


func _upgrades(bonuses: Dictionary = {}, levels: Dictionary = {}) -> MatchUpgrades:
	var u := MatchUpgrades.from_ids(IDS)
	u.talents = bonuses
	for id in levels:
		for i in levels[id]:
			u.level_up(id)
	return u


func _arena(bonuses: Dictionary = {}) -> Arena:
	var config := MatchConfig.new()
	config.talent_bonuses = bonuses
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	arena.setup(config)
	add_child_autofree(arena)
	return arena


func test_empty_dictionary_keeps_base_values() -> void:
	var u := _upgrades()
	assert_eq(u.apply(&"stat_damage", 10.0), 10.0)
	assert_eq(u.apply(&"stat_fire_rate", 2.0), 2.0)
	assert_eq(u.apply(&"stat_core_hp_max", 100.0), 100.0)
	assert_eq(u.apply(&"stat_damage_taken", 10.0), 10.0)
	assert_eq(u.apply(&"stat_cooldown", 10.0), 10.0)
	assert_eq(u.apply(&"stat_skill_damage", 1.0), 1.0)


func test_damage_and_fire_rate_multiply_with_upgrade() -> void:
	var b := {&"stat_damage": 0.20, &"stat_fire_rate": 0.15}
	assert_almost_eq(_upgrades(b).apply(&"stat_damage", 10.0), 12.0, 0.0001)
	assert_almost_eq(_upgrades(b, {&"upgrade_atk_power": 10}).apply(&"stat_damage", 10.0), 24.0, 0.0001) # x2,4
	assert_almost_eq(_upgrades(b).apply(&"stat_fire_rate", 2.0), 2.3, 0.0001)
	assert_almost_eq(_upgrades(b, {&"upgrade_atk_spd": 5}).apply(&"stat_fire_rate", 2.0), 2.0 * 1.15 * 1.4, 0.0001)


func test_fire_rate_cap() -> void:
	var u := _upgrades({&"stat_fire_rate": 0.5}, {&"upgrade_atk_spd": 10})
	assert_almost_eq(u.apply(&"stat_fire_rate", 2.0), MatchUpgrades.MAX_FIRE_RATE, 0.0001)
	var full := _upgrades({&"stat_fire_rate": 0.15}, {&"upgrade_atk_spd": 10})
	assert_almost_eq(full.apply(&"stat_fire_rate", 2.0), 4.14, 0.0001) # abaixo do teto
	assert_almost_eq(_upgrades({}, {&"upgrade_atk_spd": 10}).apply(&"stat_fire_rate", 2.0), 3.6, 0.0001)


func test_reductions_multiply_and_floor() -> void:
	var b := {&"stat_damage_taken": 0.10, &"stat_cooldown": 0.10}
	assert_almost_eq(_upgrades(b).apply(&"stat_damage_taken", 100.0), 90.0, 0.0001)
	assert_almost_eq(_upgrades(b, {&"upgrade_defense": 10}).apply(&"stat_damage_taken", 100.0), 54.0, 0.0001)
	assert_almost_eq(_upgrades(b, {&"upgrade_cooldown": 5}).apply(&"stat_cooldown", 10.0), 7.2, 0.0001)
	var big := {&"stat_damage_taken": 0.30, &"stat_cooldown": 0.30}
	assert_almost_eq(_upgrades(big, {&"upgrade_defense": 10}).apply(&"stat_damage_taken", 100.0), 50.0, 0.0001)
	assert_almost_eq(_upgrades(big, {&"upgrade_cooldown": 10}).apply(&"stat_cooldown", 10.0), 5.0, 0.0001)


func test_damage_taken_minimum_one() -> void:
	var u := _upgrades({&"stat_damage_taken": 0.9}, {&"upgrade_defense": 10})
	assert_eq(u.damage_taken(1), 1)
	assert_eq(u.damage_taken(0), 0)


func test_core_hp_rounds_percent_then_adds_flat() -> void:
	var b := {&"stat_core_hp_max": 0.35}
	assert_eq(roundi(_upgrades(b).apply(&"stat_core_hp_max", 100.0)), 135)
	assert_eq(roundi(_upgrades(b, {&"upgrade_max_hp": 3}).apply(&"stat_core_hp_max", 100.0)), 165)
	var arena := _arena(b)
	var expected := roundi(arena.anima.data.core_hp_max * 1.35)
	assert_eq(arena.anima.core.max_hp, expected)
	assert_eq(arena.anima.core.current, expected, "HP inicial = máximo")


func test_buy_hp_upgrade_adds_flat_10_with_talent() -> void:
	var arena := _arena({&"stat_core_hp_max": 0.35})
	var expected := roundi(arena.anima.data.core_hp_max * 1.35) + 10
	arena.particles = 10
	arena.buy_upgrade(&"upgrade_max_hp")
	assert_eq(arena.anima.core.max_hp, expected)
	assert_eq(arena.anima.core.current, expected)


func test_skill_damage_scales_meteor_hit() -> void:
	var arena := _arena({&"stat_skill_damage": 0.25})
	assert_almost_eq(arena.skills.get_behavior(1).context.skill_damage_scale, 1.25, 0.0001)
	var base := _arena()
	assert_eq(base.skills.get_behavior(1).context.skill_damage_scale, 1.0)


func test_cooldown_scale_from_start() -> void:
	var arena := _arena({&"stat_cooldown": 0.10})
	assert_almost_eq(arena.skills.cooldown_scale, 0.9, 0.0001)
	arena.particles = 4
	arena.buy_upgrade(&"upgrade_cooldown")
	assert_almost_eq(arena.skills.cooldown_scale, 0.9 * 0.96, 0.0001)


func test_start_particles() -> void:
	assert_eq(_arena({&"stat_start_particles": 15.0}).particles, 15)
	assert_eq(_arena().particles, 0)


func test_particle_gain_accumulates_fraction() -> void:
	var arena := _arena({&"stat_particle_gain": 0.15})
	var total := 0
	for i in 20:
		total += arena._particles_for_drop(2) # 2,3 por drop: 2,2,2,3...
	assert_eq(total, 46, "20 × 2,3 sem perder resto")
	var none := _arena()
	assert_eq(none._particles_for_drop(2), 2)
	assert_eq(none._particles_for_drop(51), 51)


func test_wave_heal_caps_at_max() -> void:
	var arena := _arena({&"stat_wave_heal": 0.10})
	var core := arena.anima.core
	var step := roundi(core.max_hp * 0.10)
	core.take_damage(step * 3)
	arena._on_wave_started(2, 10)
	assert_eq(core.current, core.max_hp - step * 2)
	for i in 5:
		arena._on_wave_started(3 + i, 10)
	assert_eq(core.current, core.max_hp, "nunca passa do máximo")


func test_wave_heal_emits_hp_signal_only_when_healing() -> void:
	var arena := _arena({&"stat_wave_heal": 0.10})
	watch_signals(arena)
	arena._on_wave_started(1, 10)
	assert_signal_not_emitted(arena, "core_hp_changed")
	arena.anima.core.take_damage(20)
	arena._on_wave_started(2, 10)
	assert_signal_emit_count(arena, "core_hp_changed", 2) # dano + cura


func test_pierce_extra_runtime_without_touching_shared_data() -> void:
	var arena := _arena({&"stat_pierce": 1.0})
	var data := arena.anima.data.projectile
	var before := data.pierce
	var p := arena.projectiles.acquire()
	p.fire(Vector2.ZERO, Vector2.RIGHT, 100.0, null, 10)
	assert_eq(p._hits_left, before + 2)
	assert_eq(data.pierce, before, ".tres compartilhado intacto")
	var plain := _arena().projectiles.acquire()
	plain.fire(Vector2.ZERO, Vector2.RIGHT, 100.0, null, 10)
	assert_eq(plain._hits_left, before + 1)


func test_pool_worst_case_at_fire_cap() -> void:
	var d := load("res://data/anima/anima_default.tres") as AnimaData if ResourceLoader.exists("res://data/anima/anima_default.tres") else _arena().anima.data
	var in_flight := MatchUpgrades.MAX_FIRE_RATE * d.attack_range / d.projectile.speed
	assert_lt(in_flight, 4.0, "~3 tiros em voo")
	assert_lt(in_flight, d.projectile_pool_size)
