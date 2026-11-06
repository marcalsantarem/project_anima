extends GutTest
## T-150/T-166: chefe ogro (decisões 39 e 42): golpe corpo a corpo com wind-up, meteoro que lança
## e atordoa sempre, drop e vitória. A defesa (escudo) está arquivada: testada com SHIELDED.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const WARDEN := preload("res://data/enemies/boss_warden.tres")
const METEOR := preload("res://data/skills/skill_meteor.tres")
const STEP := 1.0 / 60.0

var _arena: Arena
var _boss: Boss
## Defesa arquivada ligada por dados (outro chefe hipotético).
var SHIELDED: BossData


func before_each() -> void:
	SHIELDED = WARDEN.duplicate()
	SHIELDED.defense_max = 500
	_arena = ARENA_SCENE.instantiate()
	_arena.waves_enabled = false
	add_child_autofree(_arena)
	_arena.anima.auto_attack_enabled = false


func _spawn_boss(data: BossData = WARDEN) -> Boss:
	_boss = _arena.spawn(data, WaveEntry.SpawnEdge.TOP) as Boss
	_boss.set_physics_process(false) # passos manuais
	return _boss


## Chefe encostado no Núcleo, em ciclo de golpe.
func _boss_in_reach(data: BossData = WARDEN) -> Boss:
	_spawn_boss(data)
	_boss.position = _arena.anima.position + GroundPlane.to_screen(Vector2(0, -WARDEN.attack_range + 1.0))
	_boss._physics_process(STEP)
	return _boss


func _steps(seconds: float) -> void:
	for i in roundi(seconds / STEP):
		_boss._physics_process(STEP)


func test_data_is_simple_ogre() -> void:
	assert_true(WARDEN is BossData)
	assert_eq([WARDEN.attack_interval, WARDEN.attack_windup], [1.8, 0.5])
	assert_eq(WARDEN.defense_max, 0, "defesa arquivada (decisão 42)")
	assert_false(WARDEN.show_health_bar, "só a barra Boss do HUD")
	assert_gt(WARDEN.attack_range, WARDEN.radius + _arena.anima.data.hurtbox_radius, "bate sem encostar na hurtbox")


func test_spawn_emits_boss_signals() -> void:
	watch_signals(_arena)
	_spawn_boss()
	assert_signal_emitted_with_parameters(_arena, "boss_spawned", [&"boss_warden"])
	assert_signal_emitted_with_parameters(_arena, "boss_hp_changed", [WARDEN.hp, WARDEN.hp])
	assert_signal_not_emitted(_arena, "boss_defense_changed", "sem defesa, sem sinal")
	assert_null(_boss.defense_bar, "sem barra sobre o chefe")
	assert_false(_arena.has_signal(&"boss_phase_changed"), "uma fase só")


func test_shielded_spawn_emits_defense() -> void:
	watch_signals(_arena)
	_spawn_boss(SHIELDED)
	assert_signal_emitted_with_parameters(_arena, "boss_defense_changed", [SHIELDED.defense_max, SHIELDED.defense_max])
	assert_not_null(_boss.defense_bar)


func test_damage_goes_straight_to_hp() -> void:
	_boss_in_reach()
	_boss.take_damage(40)
	assert_eq(_boss.hp, WARDEN.hp - 40)
	assert_eq(_boss.mode, Boss.Mode.ATTACK, "tiro comum não lança")


func test_meteor_always_launches_damages_and_stuns() -> void:
	watch_signals(_arena)
	_boss_in_reach()
	var from := _boss.position
	_boss.take_skill_damage(METEOR.damage)
	assert_eq(_boss.hp, WARDEN.hp - METEOR.damage, "o meteoro fere a vida")
	assert_eq(_boss.mode, Boss.Mode.LAUNCHED)
	var to: Vector2 = get_signal_parameters(_arena, "boss_launched")[1]
	assert_lt(to.y, from.y, "para trás, longe do Núcleo")
	assert_true(_arena.boss_launch_bounds(_boss).grow(0.5).has_point(to), "dentro da área visível")
	_boss.take_skill_damage(METEOR.damage)
	assert_signal_emit_count(_arena, "boss_launched", 1, "em voo não relança")
	await wait_seconds(WARDEN.launch_time + 0.15)
	assert_eq(_boss.mode, Boss.Mode.STUNNED)
	assert_eq(_boss._body.texture, WARDEN.sprite_stunned)
	var core := _arena.anima.core.current
	_steps(WARDEN.stun_time - 0.1)
	assert_eq(_arena.anima.core.current, core, "atordoado não bate")
	_boss.take_skill_damage(METEOR.damage)
	assert_signal_emit_count(_arena, "boss_launched", 1, "atordoado não relança")
	_steps(0.2)
	assert_eq(_boss.mode, Boss.Mode.ADVANCE, "acorda e volta andando")
	_boss.take_skill_damage(METEOR.damage)
	assert_signal_emit_count(_arena, "boss_launched", 1, "imunidade curta ao acordar")
	_steps(WARDEN.relaunch_immunity + 0.05)
	_boss.take_skill_damage(METEOR.damage)
	assert_signal_emit_count(_arena, "boss_launched", 2, "depois da imunidade, lança de novo")


func test_meteor_kill_does_not_launch() -> void:
	watch_signals(_arena)
	_boss_in_reach()
	_boss.take_skill_damage(WARDEN.hp)
	assert_signal_not_emitted(_arena, "boss_launched")
	assert_signal_emitted(_arena, "boss_defeated")


func test_walks_to_core_and_stops_in_reach() -> void:
	_spawn_boss()
	for i in 1200:
		_boss._physics_process(STEP)
		if _boss.mode == Boss.Mode.ATTACK:
			break
	assert_eq(_boss.mode, Boss.Mode.ATTACK)
	assert_almost_eq(GroundPlane.distance(_boss.position, _arena.anima.position), WARDEN.attack_range, WARDEN.speed * STEP)


func test_windup_then_hit_core() -> void:
	watch_signals(_arena)
	_boss_in_reach()
	var core := _arena.anima.core
	_steps(WARDEN.attack_interval - WARDEN.attack_windup - 0.05)
	assert_signal_not_emitted(_arena, "boss_telegraph_started")
	_steps(0.1)
	assert_signal_emitted_with_parameters(_arena, "boss_telegraph_started",
			[WARDEN.attack_id, WARDEN.attack_windup, _boss.position, WARDEN.telegraph_radius])
	assert_eq(core.current, core.max_hp, "wind-up ainda não bate")
	_steps(WARDEN.attack_windup)
	assert_eq(core.current, core.max_hp - WARDEN.attack_damage)
	_steps(WARDEN.attack_interval)
	assert_eq(core.current, core.max_hp - 2 * WARDEN.attack_damage, "a cada attack_interval")


func test_archived_defense_shields_hp_then_launch_and_stun() -> void:
	watch_signals(_arena)
	_boss_in_reach(SHIELDED)
	_boss.take_damage(SHIELDED.defense_max - 1)
	assert_eq(_boss.hp, SHIELDED.hp, "vida intacta com defesa")
	assert_signal_emitted_with_parameters(_arena, "boss_defense_changed", [1, SHIELDED.defense_max])
	var from := _boss.position
	_boss.take_damage(50) # excedente não passa para a vida
	assert_eq(_boss.hp, SHIELDED.hp)
	assert_eq(_boss.defense, 0)
	assert_eq(_boss.mode, Boss.Mode.LAUNCHED)
	assert_signal_emitted(_arena, "boss_launched")
	var p: Array = get_signal_parameters(_arena, "boss_launched")
	assert_eq(p[0], from)
	var to: Vector2 = p[1]
	assert_lt(to.y, from.y, "para longe do Núcleo (que está abaixo)")
	assert_true(_arena.boss_launch_bounds(_boss).grow(0.5).has_point(to), "dentro da arena visível")
	_boss.take_damage(10)
	assert_eq(_boss.hp, SHIELDED.hp - 10, "sem defesa, o dano vai para a vida")
	assert_signal_emitted_with_parameters(_arena, "boss_hp_changed", [SHIELDED.hp - 10, SHIELDED.hp])
	await wait_seconds(SHIELDED.launch_time + 0.15) # voo por tween (física)
	assert_eq(_boss.mode, Boss.Mode.STUNNED)
	assert_almost_eq(_boss.position.distance_to(to), 0.0, 0.5)
	var core := _arena.anima.core.current
	_steps(SHIELDED.stun_time - 0.1)
	assert_eq(_boss.mode, Boss.Mode.STUNNED)
	assert_eq(_arena.anima.core.current, core, "atordoado não bate")
	_steps(0.2)
	assert_eq(_boss.mode, Boss.Mode.ADVANCE)
	assert_eq(_boss.defense, SHIELDED.defense_max, "defesa volta cheia")


func test_archived_meteor_launches_with_full_defense() -> void:
	watch_signals(_arena)
	_boss_in_reach(SHIELDED)
	_boss.take_skill_damage(METEOR.damage)
	assert_eq(_boss.hp, SHIELDED.hp, "meteoro não fere a vida quando há defesa")
	assert_eq(_boss.defense, 0)
	assert_signal_emitted(_arena, "boss_launched")
	_boss.take_skill_damage(METEOR.damage)
	assert_eq(_boss.hp, SHIELDED.hp - METEOR.damage, "sem defesa: dano normal")
	assert_signal_emit_count(_arena, "boss_launched", 1)


func test_meteor_area_reaches_boss() -> void:
	_boss_in_reach()
	var edge := _boss.position + Vector2(METEOR.radius + WARDEN.radius - 2.0, 0)
	AreaSkill.apply_damage(edge, _arena.active_enemies, METEOR.radius, METEOR.damage)
	assert_eq(_boss.mode, Boss.Mode.LAUNCHED, "o raio que toca o chefe conta")


func test_launch_destination_is_clipped() -> void:
	var bounds := Rect2(0, 0, 720, 900)
	var to := Boss.launch_destination(Vector2(360, 400), Vector2(360, 500), 600.0, bounds)
	assert_eq(to, Vector2(360, 0), "corta na borda de cima")
	var free := Boss.launch_destination(Vector2(360, 400), Vector2(360, 500), 100.0, bounds)
	assert_almost_eq(GroundPlane.distance(free, Vector2(360, 400)), 100.0, 0.01)


func test_kill_drops_particles_and_wins() -> void:
	watch_signals(_arena)
	_spawn_boss()
	_boss.take_damage(WARDEN.hp)
	assert_eq(_arena.particles, WARDEN.particle_drop)
	assert_signal_emitted(_arena, "boss_defeated")
	assert_signal_emitted(_arena, "match_ended")
	var result: MatchResult = get_signal_parameters(_arena, "match_ended")[0]
	assert_eq(result.outcome, MatchResult.Outcome.VICTORY)
