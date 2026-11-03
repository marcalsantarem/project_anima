class_name Anima
extends Area2D
## Receptáculo fixo no centro. Recebe dano de contato no Núcleo.

signal core_hp_changed(current: int, max_hp: int)
signal core_depleted

const BODY_COLOR := Color(0.55, 0.85, 1.0)
const RING_WIDTH := 3.0

@export var data: AnimaData

var core: CoreHealth

@onready var _hurtbox: CollisionShape2D = $Hurtbox


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = data.hurtbox_radius
	_hurtbox.shape = shape
	core = CoreHealth.new(data.core_hp_max)
	core.changed.connect(func(c: int, m: int) -> void: core_hp_changed.emit(c, m))
	core.depleted.connect(func() -> void: core_depleted.emit())
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area is Enemy:
		var enemy := area as Enemy
		core.take_damage(enemy.data.contact_damage)
		enemy.die(Enemy.DeathCause.CONTACT)


func _draw() -> void:
	draw_arc(Vector2.ZERO, data.hurtbox_radius, 0.0, TAU, 48, BODY_COLOR, RING_WIDTH, true)
	draw_circle(Vector2.ZERO, data.hurtbox_radius * 0.4, BODY_COLOR)
