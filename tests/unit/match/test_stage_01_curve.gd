extends GutTest
## T-116: curva da fase 1 percorrida só pelos dados (sem combate).

const BOSS := preload("res://data/enemies/boss_warden.tres")
const PARTICLES_TARGET := 450.0 ## acumulado antes do chefe (drops +1 em 06/11; era ~250 em docs/meta.md)
const PARTICLES_TOLERANCE := 0.15

var stage: StageData


func before_each() -> void:
	stage = load(StageData.path_for(&"stage_01"))


## Partículas médias de uma onda (grupo do enxame pela média de group_min..group_max).
func _wave_particles(w: WaveData) -> float:
	var total := 0.0
	for e in w.entries:
		if e.enemy is BossData:
			continue
		total += e.count * (e.enemy.group_min + maxi(e.enemy.group_min, e.enemy.group_max)) * 0.5 * e.enemy.particle_drop
	return total


func _has_boss(w: WaveData) -> bool:
	return w.entries.any(func(e: WaveEntry) -> bool: return e.enemy is BossData)


func test_boss_only_in_last_wave() -> void:
	var last := stage.waves.size() - 1
	for i in stage.waves.size():
		assert_eq(_has_boss(stage.waves[i]), i == last, "chefe só na onda %d" % (last + 1))
	assert_eq(stage.boss_id, BOSS.id)


func test_particles_before_boss_near_target() -> void:
	var total := 0.0
	for i in stage.waves.size() - 1:
		total += _wave_particles(stage.waves[i])
	gut.p("Partículas médias antes do chefe: %.1f" % total)
	assert_almost_eq(total, PARTICLES_TARGET, PARTICLES_TARGET * PARTICLES_TOLERANCE)


func test_waves_grow_until_boss() -> void:
	var prev := 0.0
	for i in stage.waves.size() - 1:
		var p := _wave_particles(stage.waves[i])
		assert_gt(p, prev, "onda %d mais pesada que a anterior" % (i + 1))
		prev = p


func test_runner_emits_every_spawn_and_clears() -> void:
	var runner := WaveRunner.new(stage)
	watch_signals(runner)
	var expected := 0
	for w in stage.waves:
		for e in w.entries:
			expected += e.count
	runner.start()
	var guard := 0
	while runner.phase != WaveRunner.Phase.CLEARED and guard < 100000:
		runner.tick(0.1, 0)
		guard += 1
	assert_eq(runner.phase, WaveRunner.Phase.CLEARED)
	assert_signal_emit_count(runner, "spawn_requested", expected)
	assert_signal_emit_count(runner, "wave_started", stage.waves.size())
