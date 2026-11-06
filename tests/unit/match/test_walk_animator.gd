extends GutTest
## T-167: passos procedurais (WalkAnimator): ritmo pela distância andada, parado não anima.

const WARDEN := preload("res://data/enemies/boss_warden.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const STEP := 1.0 / 60.0


func _animator(data: EnemyData) -> WalkAnimator:
	var body := autofree(SpriteArt.make(data.sprite, data.sprite_anchor)) as Sprite2D
	var shadow := autofree(GroundShadow.new(data.radius)) as GroundShadow
	return WalkAnimator.new(body, shadow, data)


func test_boss_walk_data() -> void:
	assert_between(WARDEN.walk_bob, 6.0, 8.0, "bob ~6–8 px")
	assert_between(WARDEN.walk_tilt_deg, 4.0, 6.0, "inclinação ±4–6°")
	assert_gt(WARDEN.walk_squash, 0.0)
	assert_true(_animator(WARDEN).enabled())


func test_rhythm_scales_with_distance() -> void:
	var slow := _animator(WARDEN)
	var fast := _animator(WARDEN)
	for i in 10:
		slow.step(1.0)
		fast.step(2.0)
	assert_almost_eq(fast.phase, slow.phase * 2.0, 0.0001, "o dobro da velocidade, o dobro de passos")
	assert_almost_eq(slow.phase, PI * 10.0 / WARDEN.walk_step_length, 0.0001)


func test_pose_at_mid_step_and_foot_plant() -> void:
	var w := _animator(WARDEN)
	w.step(WARDEN.walk_step_length * 0.5) # alto do passo
	assert_almost_eq(w.body.position.y, -WARDEN.walk_bob, 0.01)
	assert_almost_eq(absf(rad_to_deg(w.body.rotation)), WARDEN.walk_tilt_deg, 0.01)
	assert_lt(w.shadow.scale.x, 1.0, "sombra encolhe no alto")
	w.step(WARDEN.walk_step_length * 0.5) # apoio do pé
	assert_almost_eq(w.body.position.y, 0.0, 0.01)
	assert_gt(w.body.scale.x, SpriteArt.SCALE.x, "squash no apoio")
	assert_lt(w.body.scale.y, SpriteArt.SCALE.y)


func test_standing_still_does_not_animate() -> void:
	var w := _animator(WARDEN)
	w.step(0.0)
	assert_eq(w.phase, 0.0)
	assert_eq(w.body.position, Vector2.ZERO)
	w.step(10.0)
	w.step(0.0)
	assert_eq([w.body.position, w.body.rotation, w.body.scale, w.shadow.scale],
			[Vector2.ZERO, 0.0, SpriteArt.SCALE, Vector2.ONE], "parado volta à pose neutra")


func test_walk_frames_follow_steps_and_reset() -> void:
	assert_eq(WARDEN.walk_frames.size(), 4, "boss_ogre_walk_1..4 (AG08)")
	var w := _animator(WARDEN)
	var quarter := WARDEN.walk_step_length * 0.5 # PI/2 de fase
	w.step(quarter * 0.5)
	assert_eq(w.body.texture, WARDEN.walk_frames[0])
	w.step(quarter)
	assert_eq(w.body.texture, WARDEN.walk_frames[1])
	w.step(quarter * 2.0)
	assert_eq(w.body.texture, WARDEN.walk_frames[3])
	w.rest()
	assert_eq(w.body.texture, WARDEN.sprite, "parado volta ao sprite de repouso")


func test_disabled_by_data() -> void:
	var plain := EnemyData.new()
	assert_false(_animator(plain).enabled(), "walk_bob = 0 desliga")


func test_boss_walks_then_rests_on_attack_and_launch() -> void:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	var boss := arena.spawn(WARDEN, WaveEntry.SpawnEdge.TOP) as Boss
	boss.set_physics_process(false)
	assert_not_null(boss.walk)
	for i in 30:
		boss._physics_process(STEP)
	assert_true(boss.walk.walking)
	assert_gt(boss.walk.phase, 0.0)
	boss.take_skill_damage(1)
	assert_false(boss.walk.walking, "lançado não anda")
	assert_eq(boss._body.position, Vector2.ZERO)
	boss.position = arena.anima.position + GroundPlane.to_screen(Vector2(0, -WARDEN.attack_range + 1.0))
	boss.mode = Boss.Mode.ADVANCE
	boss._immune_left = 0.0
	boss._physics_process(STEP)
	assert_eq(boss.mode, Boss.Mode.ATTACK)
	assert_false(boss.walk.walking, "atacando não anda")
