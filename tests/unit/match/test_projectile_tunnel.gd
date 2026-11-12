extends GutTest
## T-276: túnel de projéteis em x2 (Engine.time_scale=2 mantém 60 passos/s e dobra o delta: passo de 30 px a 900 px/s).
## 100 tiros de seed fixa contra inimigos pequenos (enxame, raio 10), com deslocamento lateral dentro da soma
## dos raios (todos devem acertar geometricamente). Compara acertos em x1 e x2.

const SWARM := preload("res://data/enemies/enemy_swarm.tres")
const BASE := preload("res://data/projectiles/projectile_anima_basic.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const SHOTS := 100
const TARGET_X := 300.0
const ROW_GAP := 60.0
const MAX_DISTANCE := 450.0

var _hits := 0


func _on_hit(_at: Vector2, _kind: StringName) -> void:
	_hits += 1


## Acertos de SHOTS tiros na velocidade `scale`. `data` = projétil usado (raio/velocidade).
func _run(scale: float, data: ProjectileData, frames: int) -> int:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	await wait_physics_frames(1)
	var pool := ProjectilePool.new()
	arena.add_child(pool)
	pool.build(SHOTS, data)
	pool.projectile_hit.connect(_on_hit)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var reach := (SWARM.radius + data.radius) * GroundPlane.Y_SCALE ## semieixo vertical da soma em tela
	var jobs: Array = []
	for i in SHOTS:
		var y := 2000.0 + i * ROW_GAP
		var e := arena.spawn(SWARM, WaveEntry.SpawnEdge.TOP)
		e.set_physics_process(false)
		e.position = Vector2(TARGET_X, y + rng.randf_range(-reach, reach) * 0.95)
		jobs.append([Vector2(rng.randf_range(0.0, 40.0), y), pool.acquire()])
	_hits = 0
	Engine.time_scale = scale
	for j in jobs:
		j[1].fire(j[0], Vector2.RIGHT, MAX_DISTANCE, null, 0)
	await wait_physics_frames(frames)
	Engine.time_scale = 1.0
	return _hits


func after_each() -> void:
	Engine.time_scale = 1.0


func test_fast_projectile_hits_small_enemies_in_x1_and_x2() -> void:
	var h1: int = await _run(1.0, BASE, 40)
	var h2: int = await _run(2.0, BASE, 40)
	gut.p("TUNEL basico 900 px/s: x1=%d x2=%d de %d" % [h1, h2, SHOTS])
	assert_gte(h1, SHOTS - 2, "x1 acerta quase tudo")
	assert_gte(h2, h1 - 2, "x2 nao perde acertos relevantes")
