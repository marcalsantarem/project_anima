class_name Enemy
extends Area2D
## Inimigo genérico guiado por EnemyData: avança até o centro; com attack_range > 0, para e atira.

signal died(enemy: Enemy, cause: DeathCause)

enum State { SPAWN, ADVANCE, ATTACK, DEAD }
enum DeathCause { KILLED, CONTACT }

@export var data: EnemyData
## Pool de projéteis inimigos (só para quem atira); definido pela arena.
var projectile_pool: ProjectilePool

var state: State = State.SPAWN
var hp: int
var target_position: Vector2

var _fire_timer := 0.0

@onready var _hitbox: CollisionShape2D = $Hitbox


## Prepara o inimigo para entrar na arena indo até target.
func setup(p_data: EnemyData, spawn_position: Vector2, target: Vector2) -> void:
	data = p_data
	hp = data.hp
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
	match state:
		State.ADVANCE:
			position = step_towards(position, target_position, data.speed, delta)
			if is_shooter() and position.distance_to(target_position) <= data.attack_range:
				state = State.ATTACK
				_fire_timer = 1.0 / data.fire_rate
		State.ATTACK:
			_fire_timer -= delta
			if _fire_timer <= 0.0:
				_fire_timer += 1.0 / data.fire_rate
				shoot()


func is_shooter() -> bool:
	return data.attack_range > 0.0 and data.fire_rate > 0.0 and data.projectile != null


## Dispara um projétil do pool contra o alvo. Pool esgotado = tiro perdido.
func shoot() -> bool:
	if projectile_pool == null:
		return false
	var p := projectile_pool.acquire()
	if p == null:
		return false
	p.fire(position, target_position - position, data.attack_range, data.projectile)
	return true


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
	draw_circle(Vector2.ZERO, data.radius, data.color)
