extends GutTest
## T-273 (BRF-120): SpeedController x1/x2 (decisão 59).

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const REWARDS := preload("res://data/meta/rewards_m2.tres")
const TMP_CFG := "user://test_speed_settings.cfg"
const SIM_FRAMES := 900

var _old_path: String
var _old_chosen: float
var _old_locked: bool


func before_each() -> void:
	_old_path = SpeedController.settings_path
	_old_chosen = SpeedController.chosen
	_old_locked = SpeedController.locked_to_x1
	SpeedController.settings_path = TMP_CFG
	DirAccess.remove_absolute(TMP_CFG)
	SpeedController.locked_to_x1 = false
	SpeedController.chosen = 1.0
	SpeedController.restore()


func after_each() -> void:
	SpeedController.settings_path = _old_path
	SpeedController.chosen = _old_chosen
	SpeedController.locked_to_x1 = _old_locked
	SpeedController.restore()
	DirAccess.remove_absolute(TMP_CFG)


func _write_cfg(value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SpeedController.SECTION, SpeedController.KEY, value)
	cfg.save(TMP_CFG)


func test_set_speed_changes_time_scale_and_emits() -> void:
	watch_signals(SpeedController)
	assert_true(SpeedController.set_speed(2.0))
	assert_eq(Engine.time_scale, 2.0)
	assert_signal_emitted_with_parameters(SpeedController, "speed_changed", [2.0])
	assert_false(SpeedController.set_speed(3.0), "valor inválido recusado")
	assert_eq(SpeedController.chosen, 2.0)


func test_hit_stop_restores_chosen_not_read_value() -> void:
	SpeedController.set_speed(2.0)
	var hs := HitStop.new()
	assert_true(hs.start(get_tree(), 1.0, 0.0))
	assert_eq(Engine.time_scale, 0.0)
	SpeedController.set_speed(1.0) # toque no botão durante o hit-stop: só muda chosen
	assert_eq(Engine.time_scale, 0.0, "durante o hit-stop segue parado")
	hs.stop()
	assert_eq(Engine.time_scale, 1.0, "vale a nova escolha ao fim")
	SpeedController.set_speed(2.0)
	assert_true(hs.start(get_tree(), 1.0, 0.0))
	hs.stop()
	assert_eq(Engine.time_scale, 2.0, "restaura x2")


func test_pause_keeps_chosen() -> void:
	SpeedController.set_speed(2.0)
	get_tree().paused = true
	assert_eq(Engine.time_scale, 2.0)
	get_tree().paused = false
	assert_eq(Engine.time_scale, 2.0)


func test_headless_lock_stays_x1_and_ignores_set_speed() -> void:
	SpeedController.locked_to_x1 = true
	assert_false(SpeedController.set_speed(2.0))
	assert_eq(SpeedController.chosen, 1.0)
	assert_eq(Engine.time_scale, 1.0)
	assert_eq(SpeedController.rest_scale(), 1.0)


func test_default_lock_is_on_in_headless() -> void:
	assert_eq(_old_locked, DisplayServer.get_name() == "headless")


func test_choice_is_saved_and_loaded() -> void:
	SpeedController.set_speed(2.0)
	assert_eq(SpeedController.load_saved(), 2.0)
	SpeedController.set_speed(1.0)
	assert_eq(SpeedController.load_saved(), 1.0)


func test_invalid_file_values_become_x1() -> void:
	for bad: Variant in [3.0, 0.0, -2.0, "x2", true, [2.0]]:
		_write_cfg(bad)
		assert_eq(SpeedController.load_saved(), 1.0, "inválido: %s" % [bad])
	DirAccess.remove_absolute(TMP_CFG)
	assert_eq(SpeedController.load_saved(), 1.0, "sem arquivo")
	_write_cfg(2)
	assert_eq(SpeedController.load_saved(), 2.0, "int 2 vale")


func test_fallen_lock_returns_to_x1() -> void:
	SpeedController.set_speed(2.0)
	watch_signals(SpeedController)
	SpeedController.notify_lock(2.0, false)
	assert_signal_emitted(SpeedController, "speed_lock_changed")
	assert_eq(SpeedController.chosen, 1.0)
	assert_eq(Engine.time_scale, 1.0)


## Joga SIM_FRAMES quadros de física com o bot e devolve o que o MatchResult e a recompensa usariam.
func _play(speed: float) -> Dictionary:
	SpeedController.set_speed(speed)
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.set_seed(7)
	add_child_autofree(arena)
	var bot := SimBot.new()
	bot.attach(arena)
	# time_scale escala o delta de física (x2 = passos de 2/60 s): mesmo tempo de jogo = metade dos quadros.
	await wait_physics_frames(int(SIM_FRAMES / speed))
	var r := MatchResult.new()
	r.outcome = MatchResult.Outcome.DEFEAT
	r.enemies_killed = arena.enemies_killed
	r.kills_by_type = arena.kills_by_type.duplicate()
	r.particles = arena.particles
	var reward := MetaRewards.compute(r, REWARDS, false)
	var out := {"kills": r.enemies_killed, "by_type": r.kills_by_type, "particles": r.particles,
		"xp": reward.xp, "coins": reward.coins}
	arena.queue_free()
	await wait_physics_frames(1)
	return out


func test_x1_and_x2_same_seed_same_result() -> void:
	var a := await _play(1.0)
	var b := await _play(2.0)
	assert_gt(a.kills, 0, "a simulação matou algo")
	assert_eq(b.kills, a.kills, "kills")
	assert_eq(b.by_type, a.by_type)
	assert_eq(b.particles, a.particles, "Partículas")
	assert_eq(b.xp, a.xp, "XP")
	assert_eq(b.coins, a.coins, "Moeda")
