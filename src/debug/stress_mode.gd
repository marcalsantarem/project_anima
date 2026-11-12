class_name StressMode
extends Node
## Modo de estresse da partida (T-118, BRF-086): mantém N inimigos vivos e M projéteis em voo para
## medir desempenho (iPhone). Só liga com o debug ligado (`?debug=1`) e `stress=150,300` na URL
## (ou `--stress=150,300` na linha de comando no PC). Núcleo imortal; sem ondas; sem chefe.
## Os projéteis do estresse têm dano 0 (colidem de verdade, mas não matam: o giro vem do contato).

const ENEMY_PATHS: Array[String] = [
	"res://data/enemies/enemy_runner.tres", "res://data/enemies/enemy_swarm.tres",
	"res://data/enemies/enemy_tank.tres", "res://data/enemies/enemy_shooter.tres",
]
const PER_FRAME := 20 ## no máximo de inimigos/projéteis repostos por quadro
const SHOT_RANGE_MIN := 900.0 ## alcance sorteado, para os tiros não expirarem todos juntos
const SHOT_RANGE_MAX := 1400.0
const PIERCE := 1000 ## atravessa os inimigos: o projétil só some ao fim do alcance (mantém M vivos)
const CORE_BOOST := 1000000000
const DURATION_S := 60.0 ## tempo real de partida (sem pausa) até encerrar e abrir o Resultado

signal time_up

var arena: Arena
var enemy_target := 150
var projectile_target := 300
var speed := 0.0 ## velocidade pedida (0 = não pedida; fica a escolhida do jogador)

var time_left := DURATION_S
var _done := false
var _datas: Array[EnemyData] = []
var _pool := ProjectilePool.new()
var _rng := RandomNumberGenerator.new()


## (inimigos, projéteis) pedidos, ou Vector2i.ZERO. Exige o debug ligado.
static func requested() -> Vector2i:
	var raw := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stress="):
			raw = arg.trim_prefix("--stress=")
	if raw == "" and OS.has_feature("web") and DebugSettings.overlay_enabled():
		var v = JavaScriptBridge.eval("(new URLSearchParams(location.search)).get('stress') || ''", true)
		raw = str(v) if v != null else ""
	var parts := raw.split(",")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(maxi(int(parts[0]), 0), maxi(int(parts[1]), 0))


## Velocidade pedida (`speed=2` na URL ou `--speed=2`): 1.0, 2.0 ou 0.0 (não pedida/inválida).
static func requested_speed() -> float:
	var raw := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--speed="):
			raw = arg.trim_prefix("--speed=")
	if raw == "" and OS.has_feature("web") and DebugSettings.overlay_enabled():
		var v = JavaScriptBridge.eval("(new URLSearchParams(location.search)).get('speed') || ''", true)
		raw = str(v) if v != null else ""
	if not raw.is_valid_float() or not (is_equal_approx(float(raw), 1.0) or is_equal_approx(float(raw), 2.0)):
		return 0.0
	return float(raw)


## Aplica a velocidade do estresse SEM salvar em `user://settings.cfg` (não usa `set_speed`). Destrava o
## x1 forçado do headless para a medição no PC. Só deve ser chamada com o estresse ativo.
static func apply_speed(speed: float) -> void:
	if speed <= 0.0:
		return
	# Acesso dinâmico: scripts com class_name compilam antes dos autoloads em ferramentas `-s`.
	var sc := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("SpeedController")
	if sc == null:
		return
	sc.set("locked_to_x1", false)
	sc.set("chosen", 2.0 if is_equal_approx(speed, 2.0) else 1.0)
	sc.call("restore")


## Cópia do projétil do Anima que atravessa tudo (dano 0 vem do fire). Não altera o recurso original.
static func stress_projectile(base: ProjectileData) -> ProjectileData:
	var d := base.duplicate() as ProjectileData
	d.pierce = PIERCE
	return d


static func attach(p_arena: Arena, enemies: int, projectiles: int) -> StressMode:
	var s := StressMode.new()
	s.arena = p_arena
	s.enemy_target = enemies
	s.projectile_target = projectiles
	p_arena.waves_enabled = false
	s.speed = requested_speed()
	apply_speed(s.speed)
	s.time_up.connect(p_arena.end_by_timeout)
	p_arena.add_child(s)
	return s


func _ready() -> void:
	name = "StressMode"
	if arena == null: # só testes do temporizador
		return
	for path in ENEMY_PATHS:
		_datas.append(load(path))
	arena.anima.core.raise_max(CORE_BOOST)
	arena.add_child(_pool)
	_pool.build(projectile_target, stress_projectile(arena.anima.data.projectile))


func _physics_process(_delta: float) -> void:
	var n := 0
	while arena.active_enemies.size() < enemy_target and n < PER_FRAME:
		arena.spawn(_datas[_rng.randi() % _datas.size()], WaveEntry.SpawnEdge.RANDOM)
		n += 1
	n = 0
	while n < PER_FRAME:
		var p := _pool.acquire()
		if p == null:
			break
		p.fire(arena.anima.position, Vector2.from_angle(_rng.randf() * TAU), _rng.randf_range(SHOT_RANGE_MIN, SHOT_RANGE_MAX), null, 0)
		n += 1


func _process(delta: float) -> void:
	tick(delta / maxf(Engine.time_scale, 0.01))


## Avança o relógio do estresse (tempo real, só com a partida rodando). Ao zerar, encerra a partida.
func tick(real_delta: float) -> void:
	if _done or get_tree().paused:
		return
	time_left -= real_delta
	if time_left <= 0.0:
		_done = true
		time_up.emit()
