extends GutTest
## BRF-171: os níveis 1 a 5 dos 4 Módulos chegam à partida real pelo `SceneFlow.build_match_config`
## (dano, raio, recarga, saltos/falloff, congelamento, escudo).

const TANK := preload("res://data/enemies/enemy_tank.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const IDS: Array[StringName] = [&"skill_meteor", &"skill_shock", &"skill_freeze", &"skill_shield"]

var _old_profile: PlayerProfile
var _dmg_events: Array = []


func before_all() -> void:
	_old_profile = SceneFlow.profile


func after_all() -> void:
	SceneFlow.profile = _old_profile


func _cfg(id: StringName, lv: int) -> MatchConfig:
	var p := PlayerProfile.new()
	p.level = 8
	p.module_levels = {id: lv}
	p.module_slots = [id, &"", &""]
	SceneFlow.profile = p
	return SceneFlow.build_match_config()


func _arena(id: StringName, lv: int) -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	arena.setup(_cfg(id, lv))
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	return arena


func _tank(arena: Arena, at: Vector2) -> Enemy:
	var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	e.position = at
	e.target_position = at
	return e


## A (mais perto do Anima), B a `dx` px de A (para a direita) e C a `dx_c` px de A (para a esquerda).
func _trio(arena: Arena, dx: float, dx_c: float) -> Array[Enemy]:
	var a := arena.anima.position + Vector2(0, -250)
	return [_tank(arena, a), _tank(arena, a + Vector2(dx, 0)), _tank(arena, a - Vector2(dx_c, 0))]


func test_slot_data_and_cooldown_match_level() -> void:
	for id in IDS:
		var lvd: ModuleLevelData = SceneFlow.module_catalog.get_module(id)
		for lv in range(1, 6):
			var arena := _arena(id, lv)
			await wait_physics_frames(1)
			var want := lvd.skill_at(lv)
			var b := arena.skills.get_behavior(1)
			assert_not_null(b, "%s Nv %d: comportamento" % [id, lv])
			assert_eq(b.data.damage, want.damage, "%s Nv %d dano" % [id, lv])
			assert_eq(b.data.radius, want.radius, "%s Nv %d raio" % [id, lv])
			assert_eq(b.data.duration, want.duration, "%s Nv %d duração" % [id, lv])
			assert_eq(b.data.effect_params, want.effect_params, "%s Nv %d params" % [id, lv])
			arena.skills.get_slot(1).start_cooldown(1.0)
			assert_eq(arena.skills.get_slot(1).total, want.cooldown, "%s Nv %d recarga" % [id, lv])
			arena.queue_free()


func test_meteor_damage_and_radius_by_level() -> void:
	var lvd: ModuleLevelData = SceneFlow.module_catalog.get_module(&"skill_meteor")
	for lv in range(1, 6):
		var want := lvd.skill_at(lv)
		var arena := _arena(&"skill_meteor", lv)
		await wait_physics_frames(1)
		var t := _trio(arena, want.radius + TANK.radius - 5.0, want.radius + TANK.radius + 10.0)
		assert_true(arena.use_skill(1), "Nv %d dispara" % lv)
		await wait_seconds(1.3)
		assert_eq(t[0].hp, TANK.hp - want.damage, "Nv %d dano em A" % lv)
		assert_eq(t[1].hp, TANK.hp - want.damage, "Nv %d B dentro do raio" % lv)
		assert_eq(t[2].hp, TANK.hp, "Nv %d C fora do raio" % lv)
		arena.queue_free()


func test_shock_jumps_falloff_and_radius_by_level() -> void:
	var lvd: ModuleLevelData = SceneFlow.module_catalog.get_module(&"skill_shock")
	for lv in range(1, 6):
		var want := lvd.skill_at(lv)
		var arena := _arena(&"skill_shock", lv)
		await wait_physics_frames(1)
		_dmg_events.clear()
		arena.skills.skill_chain_hit.connect(func(_s: int, _f: Vector2, _t: Vector2, d: int, i: int) -> void: _dmg_events.append([i, d]))
		# raio de salto: B a r-5 (atinge), C a r+10 do lado oposto (não)
		var t := _trio(arena, want.radius - 5.0, want.radius + 10.0)
		assert_true(arena.use_skill(1))
		await wait_seconds(0.4)
		assert_eq(_dmg_events.size(), 2, "Nv %d: só A e B (raio de salto)" % lv)
		assert_eq(t[2].hp, TANK.hp, "Nv %d C fora do salto" % lv)
		arena.queue_free()
		# saltos e falloff: 10 inimigos juntos
		var arena2 := _arena(&"skill_shock", lv)
		await wait_physics_frames(1)
		_dmg_events.clear()
		arena2.skills.skill_chain_hit.connect(func(_s: int, _f: Vector2, _t: Vector2, d: int, i: int) -> void: _dmg_events.append([i, d]))
		var base := arena2.anima.position + Vector2(0, -250)
		for k in 10:
			_tank(arena2, base + Vector2(k * 6.0, 0))
		assert_true(arena2.use_skill(1))
		await wait_seconds(0.4)
		var jumps := int(want.effect_params["jumps"])
		var falloff := float(want.effect_params["falloff"])
		assert_eq(_dmg_events.size(), jumps + 1, "Nv %d saltos" % lv)
		var dmg := float(want.damage)
		for k in mini(_dmg_events.size(), jumps + 1):
			assert_eq(_dmg_events[k][1], roundi(dmg), "Nv %d dano do salto %d" % [lv, k])
			dmg *= falloff
		arena2.queue_free()


func test_freeze_duration_and_radius_by_level() -> void:
	var lvd: ModuleLevelData = SceneFlow.module_catalog.get_module(&"skill_freeze")
	for lv in range(1, 6):
		var want := lvd.skill_at(lv)
		var arena := _arena(&"skill_freeze", lv)
		await wait_physics_frames(1)
		var t := _trio(arena, want.radius + TANK.radius - 5.0, want.radius + TANK.radius + 10.0)
		assert_true(arena.use_skill(1), "Nv %d dispara" % lv)
		await wait_seconds(0.25)
		assert_true(t[0].is_frozen() and t[1].is_frozen(), "Nv %d A e B congelados" % lv)
		assert_false(t[2].is_frozen(), "Nv %d C fora do raio" % lv)
		assert_almost_eq(t[0].frozen_left, want.duration - 0.15, 0.2, "Nv %d duração" % lv)
		arena.queue_free()


func test_shield_absorb_and_duration_by_level() -> void:
	var lvd: ModuleLevelData = SceneFlow.module_catalog.get_module(&"skill_shield")
	for lv in range(1, 6):
		var want := lvd.skill_at(lv)
		var arena := _arena(&"skill_shield", lv)
		await wait_physics_frames(1)
		assert_true(arena.use_skill(1))
		assert_eq(arena.anima.shield.remaining_absorb, int(want.effect_params["absorb"]), "Nv %d absorção" % lv)
		assert_almost_eq(arena.anima.shield.remaining_time, want.duration, 0.01, "Nv %d duração" % lv)
		arena.queue_free()
