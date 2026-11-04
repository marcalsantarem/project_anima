extends GutTest
## T-148: sinais da Arena para VFX (docs/vfx.md, docs/gameplay.md "Sinais para VFX").

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const SWARM := preload("res://data/enemies/enemy_swarm.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const METEOR := preload("res://data/skills/skill_meteor.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")

var arena: Arena


func before_each() -> void:
	arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	watch_signals(arena)


func _parked(data: EnemyData, offset: Vector2) -> Enemy:
	var e := arena.spawn(data, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + offset
	e.target_position = e.position
	return e


func test_projectile_fired_and_hit_enemy() -> void:
	await wait_physics_frames(1)
	var e := _parked(RUNNER, Vector2(0, -200))
	arena.anima.auto_attack_enabled = true
	await wait_seconds(0.5)
	assert_signal_emitted(arena, "projectile_fired")
	var fired: Array = get_signal_parameters(arena, "projectile_fired", 0)
	assert_eq(fired[0], arena.anima.position)
	assert_almost_eq((fired[1] as Vector2).length(), 1.0, 0.001, "direção normalizada")
	assert_true((fired[1] as Vector2).y < 0.0, "para cima, rumo ao inimigo")
	assert_signal_emitted(arena, "projectile_hit")
	var hit: Array = get_signal_parameters(arena, "projectile_hit", 0)
	assert_eq(hit[1], Projectile.TARGET_ENEMY)
	assert_lt(GroundPlane.distance(hit[0], e.position), 60.0, "acerto perto do alvo")


func test_enemy_projectile_hit_on_core() -> void:
	await wait_physics_frames(1)
	var p := arena.enemy_projectiles.acquire()
	p.fire(arena.anima.position + Vector2(0, -100), Vector2.DOWN, 400.0)
	await wait_seconds(0.5)
	assert_signal_emitted(arena, "projectile_hit")
	assert_eq(get_signal_parameters(arena, "projectile_hit")[1], Projectile.TARGET_CORE)
	assert_signal_not_emitted(arena, "projectile_fired", "só tiros do Anima")


func test_enemy_died_and_particles_gained_on_kill() -> void:
	await wait_physics_frames(1)
	var e := _parked(SWARM, Vector2(100, -150))
	var at := e.position
	e.take_damage(SWARM.hp)
	assert_signal_emitted_with_parameters(arena, "enemy_died", [at, SWARM.id, Enemy.DeathCause.KILLED])
	assert_signal_emitted_with_parameters(arena, "particles_gained", [at, SWARM.particle_drop])


func test_contact_death_has_no_particles() -> void:
	await wait_physics_frames(1)
	var e := _parked(RUNNER, Vector2(0, -150))
	var at := e.position
	e.die(Enemy.DeathCause.CONTACT)
	assert_signal_emitted_with_parameters(arena, "enemy_died", [at, RUNNER.id, Enemy.DeathCause.CONTACT])
	assert_signal_not_emitted(arena, "particles_gained")


func test_skill_cast_on_meteor_impact() -> void:
	await wait_physics_frames(1)
	var e := _parked(RUNNER, Vector2(0, -250))
	var at := e.position
	assert_true(arena.use_skill(1))
	assert_signal_not_emitted(arena, "skill_cast", "só no impacto")
	await wait_seconds(METEOR.telegraph_time + 0.1)
	assert_signal_emitted_with_parameters(arena, "skill_cast", [1, at, METEOR.radius])
	assert_signal_emit_count(arena, "skill_cast", 1)


func test_boss_telegraph_and_phase() -> void:
	await wait_physics_frames(1)
	var boss := _parked(BOSS, Vector2(0, -300)) as Boss
	boss.state = Enemy.State.ATTACK
	boss.tick_patterns(BOSS.interval_for(0) + 0.01) # espera → aviso
	assert_signal_emitted(arena, "boss_telegraph_started")
	var p: Array = get_signal_parameters(arena, "boss_telegraph_started")
	assert_eq(p[0], boss.current_pattern.id)
	assert_eq(p[1], boss.current_pattern.telegraph)
	assert_eq(p[2], boss.position)
	assert_eq(p[3], boss.current_pattern.telegraph_radius)
	var hp_to_phase_1 := BOSS.hp - int(BOSS.hp * BOSS.phase_thresholds[0]) + 1
	boss.take_damage(hp_to_phase_1)
	assert_signal_emitted_with_parameters(arena, "boss_phase_changed", [1])
