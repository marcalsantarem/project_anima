extends GutTest
## Módulos novos na partida (T-109 congelamento, T-110 escudo, T-212 choque).

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const FREEZE := preload("res://data/skills/skill_freeze.tres")
const METEOR_AIM := preload("res://data/skills/skill_meteor.tres")
const SHIELD := preload("res://data/skills/skill_shield.tres")
const SHOCK := preload("res://data/skills/skill_shock.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const ENEMY_SCENE := preload("res://src/match/enemies/enemy.tscn")


func _arena(slots: Array[SkillData]) -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	var cfg := MatchConfig.new()
	cfg.slot_modules = slots
	cfg.unlocked_slots = 3
	arena.setup(cfg)
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	watch_signals(arena)
	return arena


func _spawn(arena: Arena, data: EnemyData, offset: Vector2) -> Enemy:
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + offset
	e.target_position = e.position
	return e


# --- Dados ---

func test_data_nv1() -> void:
	assert_eq(FREEZE.type, SkillData.Type.CONTROL)
	assert_eq(FREEZE.duration, 2.0)
	assert_eq(FREEZE.effect_params["slow_after"], 0.5)
	assert_eq(SHIELD.type, SkillData.Type.DEFENSE)
	assert_eq(SHIELD.effect_params["absorb"], 50)
	assert_eq(SHOCK.effect_params["jumps"], 3)
	assert_eq(SHOCK.damage, 25)


func test_behavior_by_module() -> void:
	var f := SkillController.behavior_for(FREEZE)
	var s := SkillController.behavior_for(SHIELD)
	var k := SkillController.behavior_for(SHOCK)
	f.data = FREEZE
	assert_true(f is FreezeSkill and f.can_aim())
	assert_true(s is ShieldSkill and not s.can_aim())
	assert_true(k is ShockSkill and not k.can_aim())
	for b in [f, s, k]:
		b.free()


# --- Congelamento ---

func test_freeze_stops_then_slows_without_damage() -> void:
	var arena := _arena([FREEZE, null, null])
	await wait_physics_frames(1)
	var e := _spawn(arena, TANK, Vector2(0, -300))
	assert_true(arena.use_skill(1))
	await wait_seconds(FREEZE.windup + 0.2)
	assert_true(e.is_frozen())
	assert_eq(e.hp, TANK.hp, "sem dano")
	e.target_position = arena.anima.position
	var p := e.position
	await wait_physics_frames(5)
	assert_eq(e.position, p, "parado")
	e.frozen_left = 0.0
	assert_true(e.is_slowed())
	assert_almost_eq(e.status_delta(1.0), 0.5, 0.001)


func test_freeze_no_target_does_not_fire() -> void:
	var arena := _arena([FREEZE, null, null])
	await wait_physics_frames(1)
	assert_false(arena.use_skill(1))
	assert_eq(arena.skills.get_slot(1).remaining, 0.0)


func test_freeze_manual_aim() -> void:
	var arena := _arena([FREEZE, null, null])
	await wait_physics_frames(1)
	var e := _spawn(arena, RUNNER, Vector2(0, -300))
	assert_true(arena.use_skill(1, e.position))
	await wait_seconds(FREEZE.windup + 0.2)
	assert_true(e.is_frozen())


func test_freeze_boss_only_slowed() -> void:
	var arena := _arena([FREEZE, null, null])
	await wait_physics_frames(1)
	var boss := _spawn(arena, BOSS, Vector2(0, -300))
	boss.set_physics_process(false)
	assert_true(arena.use_skill(1))
	await wait_seconds(FREEZE.windup + 0.2)
	assert_false(boss.is_frozen())
	assert_true(boss.is_slowed())
	assert_eq(boss.hp, BOSS.hp)


func test_freeze_outside_radius_unaffected() -> void:
	var arena := _arena([FREEZE, null, null])
	await wait_physics_frames(1)
	var near := _spawn(arena, RUNNER, Vector2(0, -300))
	var far := _spawn(arena, RUNNER, Vector2(0, -300 - FREEZE.radius * 3.0))
	assert_true(arena.use_skill(1, near.position))
	await wait_seconds(FREEZE.windup + 0.2)
	assert_true(near.is_frozen())
	assert_false(far.is_frozen())


func test_freeze_refresh_does_not_stack() -> void:
	var e: Enemy = ENEMY_SCENE.instantiate()
	e.setup(RUNNER, Vector2.ZERO, Vector2.ZERO)
	add_child_autofree(e)
	e.freeze(2.0, 1.5, 0.5)
	e.freeze(2.0, 1.5, 0.5)
	assert_eq(e.frozen_left, 2.0)
	assert_eq(e.slow_left, 1.5)


func test_recycle_clears_status() -> void:
	var e: Enemy = ENEMY_SCENE.instantiate()
	e.setup(RUNNER, Vector2.ZERO, Vector2.ZERO)
	add_child_autofree(e)
	e.freeze(2.0, 1.5, 0.5)
	e.recycle(Vector2.ZERO, Vector2.ZERO)
	assert_false(e.is_frozen() or e.is_slowed())


func test_freeze_ignores_skill_damage_scale() -> void:
	var arena := _arena([FREEZE, null, null])
	await wait_physics_frames(1)
	arena.skills.get_behavior(1).context.skill_damage_scale = 3.0
	var e := _spawn(arena, RUNNER, Vector2(0, -300))
	arena.use_skill(1)
	await wait_seconds(FREEZE.windup + 0.2)
	assert_eq(e.hp, RUNNER.hp)


# --- Escudo ---

func test_shield_absorbs_then_hp() -> void:
	var s := CoreShield.new()
	s.activate(50, 4.0)
	assert_eq(s.absorb(30), 0)
	assert_eq(s.remaining_absorb, 20)
	assert_eq(s.absorb(35), 15, "sobra passa para o HP")
	assert_false(s.is_active())


func test_shield_expires_by_time() -> void:
	var s := CoreShield.new()
	watch_signals(s)
	s.activate(50, 1.0)
	s.tick(1.1)
	assert_false(s.is_active())
	assert_signal_emitted_with_parameters(s, "ended", [false])
	assert_eq(s.absorb(10), 10)


func test_shield_reactivate_renews() -> void:
	var s := CoreShield.new()
	s.activate(50, 4.0)
	s.absorb(40)
	s.tick(2.0)
	s.activate(50, 4.0)
	assert_eq(s.remaining_absorb, 50)
	assert_eq(s.remaining_time, 4.0)


func test_shield_in_arena_protects_core_and_signals() -> void:
	var arena := _arena([SHIELD, null, null])
	await wait_physics_frames(1)
	var hp := arena.anima.core.current
	assert_true(arena.use_skill(1), "sempre dispara")
	assert_signal_emitted_with_parameters(arena, "shield_started", [50, 4.0])
	assert_eq(arena.anima.take_core_damage(20), 0)
	assert_eq(arena.anima.core.current, hp)
	assert_signal_emitted_with_parameters(arena, "shield_absorbed", [20, 30])
	var lost := arena.anima.take_core_damage(60) # 30 absorvidos, 30 no HP
	assert_eq(lost, 30)
	assert_signal_emitted_with_parameters(arena, "shield_ended", [true])
	assert_eq(arena.anima.core.current, hp - 30)


func test_shield_absorbs_boss_hit() -> void:
	var arena := _arena([SHIELD, null, null])
	await wait_physics_frames(1)
	assert_true(arena.use_skill(1))
	var hp := arena.anima.core.current
	arena._on_boss_attack(30)
	assert_eq(arena.anima.core.current, hp, "golpe do chefe absorvido")


# --- Choque ---

func test_shock_chain_damage_and_falloff() -> void:
	var arena := _arena([SHOCK, null, null])
	await wait_physics_frames(1)
	var es: Array[Enemy] = []
	for i in 6:
		es.append(_spawn(arena, TANK, Vector2(i * 60.0, -300)))
	assert_true(arena.use_skill(1))
	await wait_seconds(SHOCK.windup + 0.2)
	assert_signal_emit_count(arena, "skill_chain_hit", 4, "1 + 3 saltos")
	var dmg: Array = []
	for e in es:
		dmg.append(TANK.hp - e.hp)
	dmg.sort()
	dmg.reverse()
	assert_eq(dmg.slice(0, 4), [25, 20, 16, 13])
	assert_eq(dmg[4], 0, "só 4 atingidos")


func test_shock_stops_when_targets_run_out() -> void:
	var arena := _arena([SHOCK, null, null])
	await wait_physics_frames(1)
	var a := _spawn(arena, TANK, Vector2(0, -300))
	var b := _spawn(arena, TANK, Vector2(50, -300))
	arena.use_skill(1)
	await wait_seconds(SHOCK.windup + 0.2)
	assert_signal_emit_count(arena, "skill_chain_hit", 2)
	assert_eq(TANK.hp - a.hp + TANK.hp - b.hp, 25 + 20)


func test_shock_single_enemy_and_no_target() -> void:
	var arena := _arena([SHOCK, null, null])
	await wait_physics_frames(1)
	assert_false(arena.use_skill(1), "sem alvo")
	assert_eq(arena.skills.get_slot(1).remaining, 0.0)
	var e := _spawn(arena, TANK, Vector2(0, -300))
	assert_true(arena.use_skill(1))
	await wait_seconds(SHOCK.windup + 0.2)
	assert_eq(TANK.hp - e.hp, 25)
	assert_signal_emit_count(arena, "skill_chain_hit", 1)


func test_shock_first_target_is_densest() -> void:
	var arena := _arena([SHOCK, null, null])
	await wait_physics_frames(1)
	_spawn(arena, TANK, Vector2(-100, -100)) # mais perto, sozinho
	var g1 := _spawn(arena, TANK, Vector2(150, -250))
	_spawn(arena, TANK, Vector2(190, -250))
	_spawn(arena, TANK, Vector2(230, -250))
	arena.use_skill(1)
	await wait_seconds(SHOCK.windup + 0.2)
	assert_eq(TANK.hp - g1.hp, 25, "começa no grupo denso")


func test_shock_hits_boss_without_launch() -> void:
	var arena := _arena([SHOCK, null, null])
	await wait_physics_frames(1)
	var boss := _spawn(arena, BOSS, Vector2(0, -300))
	boss.set_physics_process(false)
	arena.use_skill(1)
	await wait_seconds(SHOCK.windup + 0.2)
	assert_eq(BOSS.hp - boss.hp, 25)
	assert_eq(boss.mode, Boss.Mode.ADVANCE, "não lança")


func test_shock_scales_with_skill_damage_scale() -> void:
	var arena := _arena([SHOCK, null, null])
	await wait_physics_frames(1)
	arena.skills.get_behavior(1).context.skill_damage_scale = 2.0
	var e := _spawn(arena, TANK, Vector2(0, -300))
	arena.use_skill(1)
	await wait_seconds(SHOCK.windup + 0.2)
	assert_eq(TANK.hp - e.hp, 50)


func test_cooldown_scale_applies_to_all_three() -> void:
	var arena := _arena([FREEZE, SHIELD, SHOCK])
	await wait_physics_frames(1)
	arena.skills.cooldown_scale = 0.5
	_spawn(arena, TANK, Vector2(0, -300))
	for slot in 3:
		assert_true(arena.use_skill(slot + 1))
	assert_eq(arena.skills.get_slot(1).total, FREEZE.cooldown * 0.5)
	assert_eq(arena.skills.get_slot(2).total, SHIELD.cooldown * 0.5)
	assert_eq(arena.skills.get_slot(3).total, SHOCK.cooldown * 0.5)


# --- T-218: mira manual por Módulo ---

func test_manual_aim_flag_per_module() -> void:
	assert_true(METEOR_AIM.manual_aim)
	assert_true(FREEZE.manual_aim)
	assert_false(SHIELD.manual_aim)
	assert_false(SHOCK.manual_aim)
	assert_true(FREEZE.duplicate().manual_aim, "a cópia por nível mantém o campo")


func test_skill_supports_aim_and_freeze_preview() -> void:
	var arena := _arena([METEOR_AIM, FREEZE, SHOCK] as Array[SkillData])
	await wait_physics_frames(1)
	assert_true(arena.skill_supports_aim(1))
	assert_true(arena.skill_supports_aim(2))
	assert_false(arena.skill_supports_aim(3))
	assert_false(arena.skill_supports_aim(4), "slot vazio")
	var at := arena.anima.position + Vector2(100, 100)
	arena.show_skill_aim(2, at)
	assert_true(arena._skill_aim.visible)
	assert_eq(arena._skill_aim.radius, FREEZE.radius)
	assert_eq(arena._skill_aim.fill, SkillAim.ICE_FILL)
	arena.show_skill_aim(3, at)
	assert_false(arena._skill_aim.visible, "choque não tem prévia")
	arena.hide_skill_aim()


func test_freeze_out_of_area_fails_without_cooldown() -> void:
	var arena := _arena([METEOR_AIM, FREEZE, SHOCK] as Array[SkillData])
	await wait_physics_frames(1)
	var bad := Vector2(arena.free_rect().get_center().x, arena.free_rect().end.y + 10.0)
	assert_false(arena.use_skill(2, bad))
	assert_true(arena.skills.get_slot(2).is_ready())
	assert_true(arena.use_skill(2, arena.anima.position), "manual sem inimigo dispara")
	assert_false(arena.skills.get_slot(2).is_ready())
