extends GutTest
## T-117 (BRF-079): tremor, hit-stop e números de dano.

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")

var arena: Arena


func before_each() -> void:
	arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	arena.hit_stop_enabled = true


func after_each() -> void:
	if is_instance_valid(arena):
		arena.hit_stop.stop()
	Engine.time_scale = 1.0


func _parked(data: EnemyData, offset: Vector2) -> Enemy:
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + offset
	e.target_position = e.position
	return e


# --- hit-stop ---

func test_hit_stop_does_not_stack_and_restores_time() -> void:
	Engine.time_scale = 1.0
	assert_true(arena.start_hit_stop(0.05))
	assert_eq(Engine.time_scale, arena.feel.hit_stop_time_scale)
	assert_false(arena.start_hit_stop(0.05), "máx. 1 ativo")
	await get_tree().create_timer(0.2, true, false, true).timeout
	assert_false(arena.hit_stop.active)
	assert_eq(Engine.time_scale, 1.0, "restaura o tempo")
	assert_true(arena.start_hit_stop(0.05), "pode começar de novo depois")


func test_hit_stop_restores_chosen_speed_on_stop() -> void:
	Engine.time_scale = 0.5 # valor lido ao iniciar não importa: vale SpeedController (T-273)
	var hs := HitStop.new()
	assert_true(hs.start(get_tree(), 1.0, 0.0))
	hs.stop()
	assert_eq(Engine.time_scale, SpeedController.rest_scale())
	Engine.time_scale = 0.25
	hs.stop()
	assert_eq(Engine.time_scale, 0.25, "stop repetido não muda nada")


func test_hit_stop_restored_when_arena_leaves_tree() -> void:
	assert_true(arena.start_hit_stop(5.0))
	arena.get_parent().remove_child(arena)
	assert_eq(Engine.time_scale, 1.0)
	arena.free()


func test_boss_launch_and_death_trigger_hit_stop() -> void:
	var b: Boss = _parked(BOSS, Vector2(0, -150))
	b.take_skill_damage(1)
	assert_true(arena.hit_stop.active, "lançamento do chefe")
	arena.hit_stop.stop()
	b.take_damage(b.hp)
	assert_true(arena.hit_stop.active, "morte do chefe")
	assert_true(arena.shake.is_active())


# --- efeitos reduzidos ---

func test_reduced_effects_disables_hit_stop_and_cuts_shake() -> void:
	arena.reduced_effects = true
	assert_false(arena.start_hit_stop(0.05))
	assert_eq(Engine.time_scale, 1.0)
	arena.shake.add(10.0, 0.25)
	assert_almost_eq(arena.shake.amplitude, 10.0 * arena.feel.shake_reduced_scale, 0.001)


func test_reduced_effects_stops_active_hit_stop() -> void:
	assert_true(arena.start_hit_stop(5.0))
	arena.reduced_effects = true
	assert_false(arena.hit_stop.active)
	assert_eq(Engine.time_scale, 1.0)


func test_hit_stop_off_in_headless_by_default() -> void:
	var a: Arena = ARENA_SCENE.instantiate()
	assert_eq(a.hit_stop_enabled, DisplayServer.get_name() != "headless")
	a.waves_enabled = false
	add_child_autofree(a)


# --- tremor ---

func test_shake_decays_to_zero_and_keeps_stronger() -> void:
	var s := ScreenShake.new()
	assert_true(s.add(10.0, 0.2))
	assert_false(s.add(4.0, 0.2), "mais fraco não substitui")
	var off := s.step(0.1)
	assert_almost_eq(off.length(), 2.5, 0.001, "k² com metade do tempo")
	s.step(0.2)
	assert_false(s.is_active())
	assert_eq(s.step(0.1), Vector2.ZERO)


func test_boss_hit_and_big_core_damage_shake() -> void:
	arena._on_boss_attack(1)
	assert_true(arena.shake.is_active(), "golpe do ogro")
	arena.shake.stop()
	arena.anima.take_core_damage(ceili(arena.anima.core.max_hp * arena.feel.core_big_hit_ratio) + 1)
	assert_true(arena.shake.is_active(), "dano grande no Núcleo")
	arena.shake.stop()
	arena.anima.take_core_damage(1)
	assert_false(arena.shake.is_active(), "dano pequeno não treme")


func test_shake_offsets_root_and_returns() -> void:
	var base := arena.position
	arena.shake.add(10.0, 0.05)
	arena._process(0.01)
	assert_ne(arena.position, base)
	arena._process(1.0)
	arena._process(0.01)
	assert_eq(arena.position, base)


# --- números de dano ---

func test_damage_numbers_reuse_pool() -> void:
	var dn := arena.damage_numbers
	var n := dn.pool_size()
	var children := dn.get_child_count()
	for i in n + 10:
		dn._spawn_frame = -1 # ignora o limite por quadro neste teste
		dn.show_damage(1000 + i, Vector2.ZERO, 5, false)
	assert_eq(dn.pool_size(), n, "o pool não cresce")
	assert_eq(dn.active_count(), n)
	assert_eq(dn.get_child_count(), children, "sem nós novos")
	dn._process(arena.feel.damage_lifetime + 0.01)
	assert_eq(dn.active_count(), 0)


func test_damage_aggregates_same_target_same_frame_and_limits() -> void:
	var dn := arena.damage_numbers
	dn.clear()
	assert_true(dn.show_damage(7, Vector2.ZERO, 5, false))
	assert_true(dn.show_damage(7, Vector2.ZERO, 8, true))
	assert_eq(dn.active_count(), 1, "mesmo alvo, mesmo quadro = 1 número")
	var accepted := 0
	for i in arena.feel.damage_max_per_frame + 5:
		if dn.show_damage(100 + i, Vector2.ZERO, 1, false):
			accepted += 1
	assert_eq(accepted, arena.feel.damage_max_per_frame - 1, "limite por quadro")


func test_enemy_damage_emits_signal_and_number() -> void:
	watch_signals(arena)
	arena.damage_numbers.clear()
	var e := _parked(TANK, Vector2(0, -200))
	e.take_damage(3)
	assert_signal_emitted_with_parameters(arena, "enemy_damaged", [e.position, 3, false])
	assert_eq(arena.damage_numbers.active_count(), 1)
	e.take_skill_damage(4)
	assert_signal_emitted_with_parameters(arena, "enemy_damaged", [e.position, 4, true])


func test_reduced_effects_shows_only_skill_and_boss_numbers() -> void:
	arena.reduced_effects = true
	arena.damage_numbers.clear()
	var e := _parked(TANK, Vector2(0, -200))
	e.take_damage(3)
	assert_eq(arena.damage_numbers.active_count(), 0, "tiro comum some")
	e.take_skill_damage(3)
	assert_eq(arena.damage_numbers.active_count(), 1, "meteoro aparece")
	var b: Boss = _parked(BOSS, Vector2(0, -150))
	b.take_damage(1)
	assert_eq(arena.damage_numbers.active_count(), 2, "chefe aparece")


# --- sinais extras para o AG09 e flash de acerto ---

func test_skill_fall_started_once_before_impact() -> void:
	var meteor: SkillData = arena.skills.get_slot(1).data
	watch_signals(arena)
	await wait_physics_frames(1)
	var e := _parked(TANK, Vector2(0, -250))
	assert_true(arena.use_skill(1, e.position))
	assert_signal_not_emitted(arena, "skill_fall_started", "não no acionamento")
	await wait_seconds(meteor.telegraph_time - meteor.fall_time * 0.5)
	assert_signal_emit_count(arena, "skill_fall_started", 1)
	assert_signal_not_emitted(arena, "skill_cast", "antes do impacto")
	var p: Array = get_signal_parameters(arena, "skill_fall_started")
	assert_eq(p[0], 1)
	assert_eq(p[1], e.position)
	assert_almost_eq(p[2], meteor.fall_time, 0.05)
	await wait_seconds(meteor.fall_time)
	assert_signal_emit_count(arena, "skill_fall_started", 1)
	assert_signal_emitted(arena, "skill_cast")


func test_boss_attack_landed_at_core() -> void:
	watch_signals(arena)
	arena._on_boss_attack(1)
	assert_signal_emitted_with_parameters(arena, "boss_attack_landed", [arena.anima.position])


func test_hit_flash_on_damage_and_reset() -> void:
	var e := _parked(TANK, Vector2(0, -200))
	var b: Boss = _parked(BOSS, Vector2(0, -150))
	e.take_damage(1)
	b.take_damage(1)
	for x: Enemy in [e, b]:
		assert_true(x.is_flashing())
		assert_eq(x._body.self_modulate, arena.feel.hit_flash_color)
		x._process(arena.feel.hit_flash_time + 0.01)
		assert_false(x.is_flashing())
		assert_eq(x._body.self_modulate, Color.WHITE)
