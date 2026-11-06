extends Node2D
## Cena de estresse (T-006): sem lógica de jogo. Parâmetros web: ?enemies=150&projectiles=300&seconds=0
## seconds>0 encerra a medição e loga "PERF_RESULT ..." no console (útil para automação).

const ENEMY_TEXTURES: Array[String] = [
	"res://assets/sprites/enemy_runner.png", "res://assets/sprites/enemy_swarm.png",
	"res://assets/sprites/enemy_shooter.png", "res://assets/sprites/enemy_tank.png"]
const PROJECTILE_TEXTURE := "res://assets/sprites/projectile_enemy.png"
const ARENA := Vector2(720.0, 1280.0)
const ENEMY_PX := 56.0
const PROJECTILE_PX := 24.0

var _enemy_count := 150
var _projectile_count := 300
var _seconds := 0.0
var _enemies: Array[Sprite2D] = []
var _enemy_vel := PackedVector2Array()
var _projectiles: Array[Sprite2D] = []
var _projectile_vel := PackedVector2Array()
var _label: Label
var _elapsed := 0.0
var _label_timer := 0.0
var _frames := 0
var _fps_min := 1000000.0
var _warmup := 2.0
var _sum_dt := 0.0
var _max_dt := 0.0
var _reported := false


func _ready() -> void:
	_read_params()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var textures: Array[Texture2D] = []
	for p in ENEMY_TEXTURES:
		textures.append(load(p))
	for i in _enemy_count:
		var s := Sprite2D.new()
		var tex: Texture2D = textures[i % textures.size()]
		s.texture = tex
		s.scale = Vector2.ONE * (ENEMY_PX / maxf(tex.get_width(), tex.get_height()))
		s.position = Vector2(rng.randf() * ARENA.x, rng.randf() * ARENA.y)
		add_child(s)
		_enemies.append(s)
		_enemy_vel.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30.0, 90.0))
	var ptex: Texture2D = load(PROJECTILE_TEXTURE)
	for i in _projectile_count:
		var s := Sprite2D.new()
		s.texture = ptex
		s.scale = Vector2.ONE * (PROJECTILE_PX / maxf(ptex.get_width(), ptex.get_height()))
		s.position = Vector2(rng.randf() * ARENA.x, rng.randf() * ARENA.y)
		add_child(s)
		_projectiles.append(s)
		_projectile_vel.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(150.0, 350.0))
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(_label)


func _read_params() -> void:
	var qs := ""
	if OS.has_feature("web"):
		qs = str(JavaScriptBridge.eval("location.search", true))
	else:
		qs = "?" + "&".join(OS.get_cmdline_user_args())
	if qs.begins_with("?"):
		qs = qs.substr(1)
	for pair in qs.split("&", false):
		var kv := pair.split("=")
		if kv.size() != 2 or not kv[1].is_valid_float():
			continue
		match kv[0]:
			"enemies": _enemy_count = int(kv[1])
			"projectiles": _projectile_count = int(kv[1])
			"seconds": _seconds = float(kv[1])


func _process(delta: float) -> void:
	for i in _enemies.size():
		var p := _enemies[i].position + _enemy_vel[i] * delta
		if p.x < 0.0 or p.x > ARENA.x:
			_enemy_vel[i].x = -_enemy_vel[i].x
			p.x = clampf(p.x, 0.0, ARENA.x)
		if p.y < 0.0 or p.y > ARENA.y:
			_enemy_vel[i].y = -_enemy_vel[i].y
			p.y = clampf(p.y, 0.0, ARENA.y)
		_enemies[i].position = p
	for i in _projectiles.size():
		var p := _projectiles[i].position + _projectile_vel[i] * delta
		p.x = fposmod(p.x, ARENA.x)
		p.y = fposmod(p.y, ARENA.y)
		_projectiles[i].position = p
	_elapsed += delta
	if _elapsed < _warmup:
		return
	_frames += 1
	_sum_dt += delta
	_max_dt = maxf(_max_dt, delta)
	var fps := 1.0 / maxf(delta, 0.0001)
	_fps_min = minf(_fps_min, fps)
	_label_timer -= delta
	if _label_timer <= 0.0:
		_label_timer = 0.25
		_label.text = "FPS %d | med %d | mín %d\nInimigos %d | Projéteis %d" % [
			Engine.get_frames_per_second(), _avg_fps(), _fps_min, _enemy_count, _projectile_count]
	if _seconds > 0.0 and not _reported and _elapsed - _warmup >= _seconds:
		_reported = true
		print("PERF_RESULT enemies=%d projectiles=%d frames=%d fps_avg=%.1f fps_min=%.1f max_frame_ms=%.1f" % [
			_enemy_count, _projectile_count, _frames, _avg_fps(), _fps_min, _max_dt * 1000.0])


func _avg_fps() -> float:
	return _frames / _sum_dt if _sum_dt > 0.0 else 0.0
