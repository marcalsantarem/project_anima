class_name Anima
extends Area2D
## Receptáculo fixo no centro. Recebe dano de contato no Núcleo e atira sozinho.

signal core_hp_changed(current: int, max_hp: int)
signal core_depleted

const BODY_COLOR := Color(0.55, 0.85, 1.0)
const RING_WIDTH := 3.0
## Altura do desenho do núcleo acima da âncora, em frações do raio (placeholder).
const CORE_HEIGHT_FACTOR := 0.6

@export var data: AnimaData
## Desligável para testes e debug.
@export var auto_attack_enabled := true

var core: CoreHealth
var target: Enemy

var _enemies: Array[Enemy] = []
var _pool: ProjectilePool
var _scan_timer := 0.0
var _fire_timer := 0.0

@onready var _hurtbox: CollisionShape2D = $Hurtbox


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = data.hurtbox_radius
	_hurtbox.shape = shape
	_hurtbox.scale = GroundPlane.SHAPE_SCALE # círculo no chão
	add_child(GroundShadow.new(data.hurtbox_radius))
	core = CoreHealth.new(data.core_hp_max)
	core.changed.connect(func(c: int, m: int) -> void: core_hp_changed.emit(c, m))
	core.depleted.connect(func() -> void: core_depleted.emit())
	area_entered.connect(_on_area_entered)
	queue_redraw()


## Liga o ataque à lista de inimigos vivos e ao pool (mesmo espaço de coordenadas do Anima).
func setup_attack(enemies: Array[Enemy], pool: ProjectilePool) -> void:
	_enemies = enemies
	_pool = pool


func _physics_process(delta: float) -> void:
	if not auto_attack_enabled or _pool == null or core.is_depleted():
		return
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer += data.target_scan_interval
		target = Targeting.pick(position, _enemies, data.attack_range)
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _fire_timer > 0.0 or not _is_target_valid():
		return
	var projectile := _pool.acquire()
	if projectile == null:
		return
	projectile.fire(position, target.position - position, data.attack_range)
	_fire_timer = 1.0 / data.fire_rate


func _is_target_valid() -> bool:
	return is_instance_valid(target) and target.state != Enemy.State.DEAD


func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		var enemy := area as Enemy
		core.take_damage(enemy.data.contact_damage)
		enemy.die(Enemy.DeathCause.CONTACT)
	elif area is Projectile:
		var p := area as Projectile
		if p.active:
			core.take_damage(p.data.damage)
			p.consume()


## Âncora = centro do pedestal no chão: o anel é a hurtbox (elipse) e o núcleo flutua acima.
func _draw() -> void:
	draw_circle(Vector2(0.0, -data.hurtbox_radius * CORE_HEIGHT_FACTOR), data.hurtbox_radius * 0.4, BODY_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	draw_arc(Vector2.ZERO, data.hurtbox_radius, 0.0, TAU, 48, BODY_COLOR, RING_WIDTH, true)
