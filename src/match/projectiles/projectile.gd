class_name Projectile
extends Area2D
## Projétil reutilizável. Fica estacionado fora da arena enquanto inativo, sem alocar.

signal expired(projectile: Projectile)

## Ponto de estacionamento fora de qualquer arena.
const PARKED_POSITION := Vector2(-100000.0, -100000.0)

var active := false
var data: ProjectileData

var _direction := Vector2.ZERO
var _distance_left := 0.0
var _hits_left := 0
var _hit_ids := PackedInt64Array()
var _hit_count := 0

@onready var _shape_node: CollisionShape2D = $Shape


func _ready() -> void:
	_shape_node.shape = CircleShape2D.new()
	area_entered.connect(_on_area_entered)
	park()


## Configura o tamanho uma vez, quando o pool é criado.
func configure(p_data: ProjectileData) -> void:
	data = p_data
	(_shape_node.shape as CircleShape2D).radius = data.radius
	_hit_ids.resize(data.pierce + 1)
	queue_redraw()


func fire(origin: Vector2, direction: Vector2, max_distance: float) -> void:
	position = origin
	_direction = direction.normalized()
	_distance_left = max_distance
	_hits_left = data.pierce + 1
	_hit_count = 0
	active = true
	visible = true
	set_physics_process(true)


func park() -> void:
	active = false
	visible = false
	set_physics_process(false)
	position = PARKED_POSITION


func _physics_process(delta: float) -> void:
	var step := data.speed * delta
	position += _direction * step
	_distance_left -= step
	if _distance_left <= 0.0:
		_expire()


func _on_area_entered(area: Area2D) -> void:
	if not active or not area is Enemy:
		return
	var enemy := area as Enemy
	var enemy_id := enemy.get_instance_id()
	for i in _hit_count:
		if _hit_ids[i] == enemy_id:
			return
	_hit_ids[_hit_count] = enemy_id
	_hit_count += 1
	enemy.take_damage(data.damage)
	_hits_left -= 1
	if _hits_left <= 0:
		_expire()


func _expire() -> void:
	park()
	expired.emit(self)


func _draw() -> void:
	if data:
		draw_circle(Vector2.ZERO, data.radius, data.color)
