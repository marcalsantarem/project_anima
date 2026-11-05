extends Node2D
## Demo do FxDirector (T-130): este nó faz papel de "arena falsa" (sinais de usuário com os
## nomes da Arena) e dispara o fluxo disparo → impacto → morte → coleta, além de dano no Núcleo,
## skill, telegraph e fase do chefe. Clique/toque alterna o modo reduzido. Não depende de match/.
## Medição (docs/vfx.md §3): rodar com `-- --fx-bench` simula ~150 inimigos e ~300 projéteis e
## imprime o tempo médio de quadro com e sem efeitos (`--fx-reduced` mede o modo reduzido;
## `--fx-boss` soma, a cada 20 quadros, meteoro (queda + impacto) e o ciclo do chefe, T-131).

const FLOOR := Color("#F6E9CF")
const CENTER := Vector2(360, 690)
const ARCHETYPES: Array[StringName] = [&"enemy_runner", &"enemy_tank", &"enemy_shooter", &"enemy_swarm"]
const BENCH_ENEMIES := 150
const BENCH_PROJECTILES := 300
const BENCH_PHASE_FRAMES := 600
const BENCH_WARMUP_FRAMES := 60

var pool: FxPool
var director: FxDirector
var _t := 0.0
var _step := 0
var _core_hp := 100
var _bench := false
var _bench_fx := true
var _bench_boss := false
var _bench_frames := 0
var _bench_usec := 0
var _bench_emit_usec := 0
var _bench_last := 0
var _bench_result := {}
var _enemies: PackedVector2Array = PackedVector2Array()
var _shots: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	for s: StringName in FxDirector.SIGNALS:
		add_user_signal(s)
	var floor_rect := ColorRect.new() # z -10 como o piso da arena: decalques (z -1) ficam por cima
	floor_rect.color = FLOOR
	floor_rect.size = Vector2(720, 1280)
	floor_rect.z_index = -10
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)
	pool = FxPool.new()
	add_child(pool)
	pool.setup_default()
	director = FxDirector.new()
	director.pool = pool
	director.core_anchor = CENTER
	add_child(director)
	director.bind(self)
	emit_signal(&"core_hp_changed", _core_hp, 100)
	_bench = OS.get_cmdline_user_args().has("--fx-bench")
	director.reduced_effects = OS.get_cmdline_user_args().has("--fx-reduced")
	_bench_boss = OS.get_cmdline_user_args().has("--fx-boss")
	if _bench:
		_setup_bench()


func _process(delta: float) -> void:
	if _bench:
		_bench_step()
		return
	_t += delta
	if _t < 0.15:
		return
	_t = 0.0
	_fire(_step)
	_step += 1


## Um passo do fluxo: cada alvo recebe disparo → (0,15 s) impacto → (morte + coleta).
func _fire(i: int) -> void:
	var ang := i * 0.9
	var target := CENTER + Vector2(cos(ang) * 250, sin(ang) * 250 * 0.75)
	emit_signal(&"projectile_fired", CENTER, (target - CENTER).normalized())
	var prev_ang := (i - 1) * 0.9
	var prev := CENTER + Vector2(cos(prev_ang) * 250, sin(prev_ang) * 250 * 0.75)
	emit_signal(&"projectile_hit", prev, &"enemy")
	if i % 2 == 0:
		emit_signal(&"enemy_died", prev, ARCHETYPES[(i / 2) % ARCHETYPES.size()], 0)
		emit_signal(&"particles_gained", prev, 1 + i % 3)
	if i % 5 == 0:
		_core_hp = 100 if _core_hp <= 10 else _core_hp - 5
		emit_signal(&"core_hp_changed", _core_hp, 100)
	_meteor_and_boss(i)


## Meteoro e chefe (T-131) e Módulo usado/pronto (T-117), em passos de 0,15 s.
func _meteor_and_boss(i: int) -> void:
	var meteor_at := Vector2(240, 430)
	var boss_at := Vector2(360, 560)
	match i % 40:
		0:
			emit_signal(&"skill_used", 1)
		2:
			emit_signal(&"skill_fall_started", 1, meteor_at, 0.35)
		4:
			emit_signal(&"skill_cast", 1, meteor_at, 160.0)
		8:
			emit_signal(&"skill_ready", 1)
		10:
			emit_signal(&"boss_telegraph_started", &"boss_slam", 0.5, boss_at, 110.0)
		14:
			_core_hp = 100 if _core_hp <= 20 else _core_hp - 10
			emit_signal(&"core_hp_changed", _core_hp, 100)
		18:
			emit_signal(&"boss_telegraph_started", &"boss_slam", 0.5, boss_at, 110.0)
		20:
			emit_signal(&"skill_cast", 1, boss_at, 160.0)
			emit_signal(&"boss_launched", boss_at, Vector2(360, 250))
		36:
			emit_signal(&"skill_fizzled", 1, Vector2(500, 420))
		38:
			emit_signal(&"boss_defeated")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		director.reduced_effects = not director.reduced_effects


func _draw() -> void:
	if _bench:
		for p in _enemies:
			draw_circle(p, 14, Color("#FF8A3D"))
		for p in _shots:
			draw_circle(p, 5, Color("#2FE6D2"))
	# Marcador do Anima: base elíptica + cristal ciano (só referência de escala).
	draw_set_transform(CENTER, 0.0, Vector2(1, 0.75))
	draw_circle(Vector2.ZERO, 46, Color("#6B4E8C", 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(CENTER + Vector2(0, -40), 26, Color("#2FE6D2").darkened(0.55))
	draw_circle(CENTER + Vector2(0, -40), 22, Color("#2FE6D2"))


# --- medição -------------------------------------------------------------------------------

func _setup_bench() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_enemies.resize(BENCH_ENEMIES)
	_shots.resize(BENCH_PROJECTILES)
	for i in BENCH_ENEMIES:
		_enemies[i] = CENTER + Vector2.from_angle(i * 2.4) * (120 + (i * 37) % 260) * Vector2(1, 0.75)
	_bench_last = Time.get_ticks_usec()


## Por quadro: 300 projéteis andando; ~5 disparos, ~5 acertos, ~1 morte + coleta por quadro
## (≈ 300 tiros/s a 60 fps). Fase 1 com efeitos, fase 2 com o diretor desligado.
func _bench_step() -> void:
	var now := Time.get_ticks_usec()
	if _bench_frames >= BENCH_WARMUP_FRAMES: # descarta aquecimento (janela, shaders)
		_bench_usec += now - _bench_last
	_bench_last = now
	_bench_frames += 1
	var f := _bench_frames
	for i in BENCH_PROJECTILES:
		_shots[i] = CENTER + Vector2.from_angle(i * 0.37) * float((f * 6 + i * 13) % 400)
	queue_redraw()
	var t0 := Time.get_ticks_usec()
	if _bench_fx:
		for k in 5:
			var e := _enemies[(f * 5 + k) % BENCH_ENEMIES]
			emit_signal(&"projectile_fired", CENTER, (e - CENTER).normalized())
			emit_signal(&"projectile_hit", e, &"enemy")
		var d := _enemies[(f * 7) % BENCH_ENEMIES]
		emit_signal(&"enemy_died", d, ARCHETYPES[f % 4], 0)
		emit_signal(&"particles_gained", d, 1)
		if _bench_boss and f % 20 == 0:
			for k in 41: # um ciclo inteiro do chefe e do meteoro (todos os passos de uma vez)
				_meteor_and_boss(k)
	if f > BENCH_WARMUP_FRAMES:
		_bench_emit_usec += Time.get_ticks_usec() - t0
	if f == BENCH_PHASE_FRAMES:
		var key := ("fx_on" if _bench_fx else "fx_off") + ("_reduced" if director.reduced_effects else "") + ("_boss" if _bench_boss else "")
		_bench_result[key + "_signals_ms"] = _bench_emit_usec / float(f - BENCH_WARMUP_FRAMES) / 1000.0
		_bench_result[key + "_draw_calls"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		_bench_emit_usec = 0
		_bench_result[key] = _bench_usec / float(f - BENCH_WARMUP_FRAMES) / 1000.0
		if _bench_fx:
			var alive := 0
			for t: StringName in FxPool.DEFAULT_TYPES:
				alive += pool.active_count(t)
			_bench_result["fx_alive"] = alive
			_bench_fx = false
			pool.stop_all()
			_bench_frames = 0
			_bench_usec = 0
		else:
			print("FX_BENCH ", _bench_result)
			get_tree().quit()
