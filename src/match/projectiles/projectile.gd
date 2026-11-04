class_name Projectile
extends Area2D
## Projétil reutilizável. Fica estacionado fora da arena enquanto inativo, sem alocar.

signal expired(projectile: Projectile)

## Ponto de estacionamento fora de qualquer arena.
const PARKED_POSITION := Vector2(-100000.0, -100000.0)

var active := false
var data: ProjectileData
## Dano deste disparo (data.damage, ou o valor com upgrades passado em fire()).
var damage := 0

var _direction := Vector2.ZERO ## no chão
var _distance_left := 0.0
var _hits_left := 0
var _hit_ids := PackedInt64Array()
var _hit_count := 0
var _shadow: GroundShadow
var _sprite: Sprite2D

@onready var _shape_node: CollisionShape2D = $Shape


func _ready() -> void:
	_shape_node.shape = CircleShape2D.new()
	area_entered.connect(_on_area_entered)
	park()


## Configura o tamanho uma vez, quando o pool é criado.
func configure(p_data: ProjectileData) -> void:
	data = p_data
	(_shape_node.shape as CircleShape2D).radius = data.radius
	_shape_node.scale = GroundPlane.SHAPE_SCALE # círculo no chão
	if _shadow == null:
		_shadow = GroundShadow.new()
		add_child(_shadow)
	_shadow.radius = data.radius
	_hit_ids.resize(data.pierce + 1)
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite)
	SpriteArt.apply(_sprite, data.sprite, data.sprite_anchor)
	_sprite.position = Vector2(0.0, -data.height) # voa acima da sombra (âncora no chão)


## direction em tela; vira direção no chão. max_distance em px no chão.
## p_data troca o tipo do projétil (pool compartilhado entre atiradores).
## p_damage < 0 usa data.damage.
func fire(origin: Vector2, direction: Vector2, max_distance: float, p_data: ProjectileData = null, p_damage: int = -1) -> void:
	if p_data != null and p_data != data:
		configure(p_data)
	damage = p_damage if p_damage >= 0 else data.damage
	position = origin
	_direction = GroundPlane.to_ground(direction).normalized()
	_distance_left = max_distance
	_hits_left = data.pierce + 1
	_hit_count = 0
	_sprite.rotation = direction.angle() # sprite aponta para +X
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
	position += GroundPlane.to_screen(_direction * step)
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
	enemy.take_damage(damage)
	_hits_left -= 1
	if _hits_left <= 0:
		_expire()


## Usado por quem recebe o acerto (Anima, escudo).
func consume() -> void:
	if active:
		_expire()


func _expire() -> void:
	park()
	expired.emit(self)

