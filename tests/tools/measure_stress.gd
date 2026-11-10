extends SceneTree
## Referência relativa de CPU do modo de estresse em x1 e x2 (T-276, ferramenta manual; NÃO é o iPhone).
## Uso: godot --headless --path . -s tests/tools/measure_stress.gd -- --enemies=150 --projectiles=300 --speed=2 --seconds=15
## Mede, depois de 3 s de aquecimento, o tempo de CPU (Performance TIME_PROCESS + TIME_PHYSICS_PROCESS) por
## segundo real e por passo de física. "carga" = CPU/s real (1.0 = um núcleo cheio; acima de ~0.5 o iPhone sofre).
## Headless não desenha: não inclui o custo de render, só lógica e física.

var ARENA_SCENE: PackedScene ## carregada em _initialize (autoloads já registrados)
const WARMUP_S := 3.0

var _enemies := 150
var _projectiles := 300
var _speed := 1.0
var _seconds := 15.0
var _arena: Arena
var _t0 := 0
var _started := false
var _cpu_ms := 0.0
var _frames := 0
var _steps0 := 0
var _hist: Array[float] = []


func _initialize() -> void:
	ARENA_SCENE = load("res://src/match/arena/arena.tscn")
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"enemies": _enemies = int(kv[1])
			"projectiles": _projectiles = int(kv[1])
			"speed": _speed = float(kv[1])
			"seconds": _seconds = float(kv[1])
	root.size = Vector2i(405, 720)
	_arena = ARENA_SCENE.instantiate()
	root.add_child.call_deferred(_arena)
	_attach.call_deferred()


func _attach() -> void:
	await physics_frame
	var s := StressMode.attach(_arena, _enemies, _projectiles)
	s.speed = _speed
	StressMode.apply_speed(_speed)
	_t0 = Time.get_ticks_msec()


func _process(_delta: float) -> bool:
	if _t0 == 0:
		return false
	var el := (Time.get_ticks_msec() - _t0) / 1000.0
	if not _started:
		if el >= WARMUP_S:
			_started = true
			_t0 = Time.get_ticks_msec()
			_steps0 = Engine.get_physics_frames()
		return false
	var ms := (Performance.get_monitor(Performance.TIME_PROCESS) + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0
	_cpu_ms += ms
	_frames += 1
	_hist.append(ms)
	if el >= _seconds:
		var steps := Engine.get_physics_frames() - _steps0
		_hist.sort()
		print("RESULT enemies=%d projectiles=%d speed=x%d real_s=%.1f steps=%d (%.1f/s) cpu_ms_per_real_s=%.0f carga=%.2f cpu_ms_per_step=%.2f frame_ms_p95=%.2f ativos=%d proj=%d" % [
			_enemies, _projectiles, int(_speed), el, steps, steps / el, _cpu_ms / el, _cpu_ms / el / 1000.0,
			_cpu_ms / maxf(steps, 1), _hist[int(_hist.size() * 0.95)], _arena.active_enemies.size(), 0])
		quit()
	return false
