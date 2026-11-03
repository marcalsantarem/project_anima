class_name Enemy
extends Area2D
## Inimigo genérico guiado por EnemyData. No M1 só o corredor (avança até o centro).

signal died(enemy: Enemy, cause: DeathCause)

enum State { SPAWN, ADVANCE, ATTACK, DEAD }
enum DeathCause { KILLED, CONTACT }

const BODY_COLOR := Color(1.0, 0.45, 0.35)

@export var data: EnemyData

var state: State = State.SPAWN
var hp: int
var target_position: Vector2

@onready var _hitbox: CollisionShape2D = $Hitbox


## Prepara o inimigo para entrar na arena indo até target.
func setup(p_data: EnemyData, spawn_position: Vector2, target: Vector2) -> void:
	data = p_data
	position = spawn_position
	target_position = target


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	_hitbox.shape = shape
	hp = data.hp
	state = State.ADVANCE
	queue_redraw()


func _physics_process(delta: float) -> void:
	if state == State.ADVANCE:
		position = step_towards(position, target_position, data.speed, delta)


## Passo de movimento em linha reta, sem passar do alvo.
static func step_towards(from: Vector2, to: Vector2, speed: float, delta: float) -> Vector2:
	return from.move_toward(to, speed * delta)


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	hp -= amount
	if hp <= 0:
		die(DeathCause.KILLED)


func die(cause: DeathCause) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	set_deferred("monitorable", false)
	died.emit(self, cause)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, data.radius, BODY_COLOR)
