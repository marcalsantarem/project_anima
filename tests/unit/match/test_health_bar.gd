extends GutTest
## T-149: barra de vida dos inimigos comuns (decisão 38).

const RUNNER := preload("res://data/enemies/enemy_runner.tres")
const SWARM := preload("res://data/enemies/enemy_swarm.tres")
const TANK := preload("res://data/enemies/enemy_tank.tres")
const BOSS := preload("res://data/enemies/boss_warden.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")


func test_color_bands() -> void:
	assert_eq(HealthBar.color_for(1.0), HealthBar.GREEN)
	assert_eq(HealthBar.color_for(0.6), HealthBar.GREEN, "60% ainda é verde")
	assert_eq(HealthBar.color_for(0.59), HealthBar.YELLOW)
	assert_eq(HealthBar.color_for(0.31), HealthBar.YELLOW)
	assert_eq(HealthBar.color_for(0.3), HealthBar.RED, "30% já é vermelha")
	assert_eq(HealthBar.color_for(0.0), HealthBar.RED)


func _arena() -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	return arena


func test_bar_follows_damage_and_size() -> void:
	var arena := _arena()
	var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	var s := arena.spawn(SWARM, WaveEntry.SpawnEdge.TOP)
	assert_not_null(e.health_bar)
	assert_eq(e.health_bar.ratio, 1.0, "cheia no início")
	assert_between(s.health_bar.width, HealthBar.MIN_WIDTH, e.health_bar.width)
	assert_eq(e.health_bar.width, HealthBar.MAX_WIDTH)
	assert_lt(e.health_bar.position.y, -e.sprite_top(), "acima do sprite")
	e.take_damage(roundi(TANK.hp * 0.5))
	assert_almost_eq(e.health_bar.ratio, 0.5, 0.02)


func test_boss_has_no_health_bar() -> void:
	var arena := _arena()
	var b := arena.spawn(BOSS, WaveEntry.SpawnEdge.TOP)
	assert_null(b.health_bar)


func test_no_per_frame_work_with_150_enemies() -> void:
	var arena := _arena()
	var bars: Array[HealthBar] = []
	for i in 150:
		var e := arena.spawn(RUNNER, WaveEntry.SpawnEdge.TOP)
		e.position = Vector2(20 + (i % 15) * 45, 40 + (i / 15) * 25) # longe do Núcleo
		e.target_position = e.position # parados
		bars.append(e.health_bar)
	await wait_process_frames(3)
	var before := 0
	for b in bars:
		assert_false(b.is_processing() or b.is_physics_processing())
		before += b.draw_count
	await wait_process_frames(30)
	var after := 0
	for b in bars:
		after += b.draw_count
	assert_eq(after, before, "sem redesenho sem mudança de vida")
	bars[0].get_parent().take_damage(5)
	await wait_process_frames(2)
	assert_eq(bars[0].draw_count, 1, "escondida não desenha; 1º desenho ao primeiro dano")


func test_bar_hidden_at_full_hp_and_shown_after_damage() -> void:
	var arena := _arena()
	var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	assert_false(e.health_bar.visible, "vida cheia: não desenha")
	e.take_damage(1)
	assert_true(e.health_bar.visible)
	e.recycle(Vector2.ZERO, Vector2.ZERO)
	assert_false(e.health_bar.visible, "reciclado volta a esconder")
