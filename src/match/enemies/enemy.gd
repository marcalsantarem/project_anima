class_name Enemy
extends Area2D
## Inimigo genérico guiado por EnemyData: avança até o centro; com attack_range > 0, para e atira.

signal died(enemy: Enemy, cause: DeathCause)
## Dano na vida (antes de `died`). by_skill = meteoro/skill de área (números de dano, T-117).
signal damaged(enemy: Enemy, amount: int, by_skill: bool)

enum State { SPAWN, ADVANCE, ATTACK, DEAD }
enum DeathCause { KILLED, CONTACT }

@export var data: EnemyData
## Pool de projéteis inimigos (só para quem atira); definido pela arena.
var projectile_pool: ProjectilePool

var state: State = State.SPAWN
var hp: int
var target_position: Vector2

var _fire_timer := 0.0
var _ring: Sprite2D
var health_bar: HealthBar
var _body: Sprite2D
var _shadow: GroundShadow
## Passos procedurais; nulo quando data.walk_bob = 0.
var walk: WalkAnimator
## true durante take_skill_damage (o dano vem de skill).
var _skill_hit := false
## Flash branco ao levar dano (T-117); a Arena define a partir do GameFeelData. 0 = desligado.
var hit_flash_time := 0.07
var hit_flash_color := Color(3.0, 3.0, 3.0)
var _flash_left := 0.0

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
	_hitbox.scale = GroundPlane.SHAPE_SCALE # círculo no chão
	_shadow = GroundShadow.new(data.radius)
	add_child(_shadow)
	hp = data.hp
	state = State.ADVANCE
	_build_art()
	var w := WalkAnimator.new(_body, _shadow, data)
	if w.enabled():
		walk = w


func _physics_process(delta: float) -> void:
	match state:
		State.ADVANCE:
			var before := position
			position = step_towards(position, target_position, data.speed, delta)
			if walk:
				walk.step(GroundPlane.distance(before, position))
			if is_shooter() and GroundPlane.distance(position, target_position) <= data.attack_range:
				state = State.ATTACK
				_fire_timer = 1.0 / data.fire_rate
				if walk:
					walk.rest()
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


## Passo em linha reta no chão (speed em px/s no chão), sem passar do alvo.
static func step_towards(from: Vector2, to: Vector2, speed: float, delta: float) -> Vector2:
	return GroundPlane.move_toward(from, to, speed * delta)


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	hp -= amount
	damaged.emit(self, amount, _skill_hit)
	flash()
	if health_bar:
		health_bar.set_ratio(float(hp) / data.hp)
	if hp <= 0:
		die(DeathCause.KILLED)


## Dano de skill de área (meteoro). Igual ao dano comum; o chefe trata à parte (lançamento).
func take_skill_damage(amount: int) -> void:
	_skill_hit = true
	take_damage(amount)
	_skill_hit = false


func die(cause: DeathCause) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	set_deferred("monitorable", false)
	died.emit(self, cause)
	queue_free()


## Âncora na base: o sprite fica em pé sobre o ponto de contato. Anel opcional (chefe) atrás do corpo.
func _build_art() -> void:
	if data.ring_sprite != null:
		_ring = SpriteArt.make(data.ring_sprite, data.ring_anchor)
		_ring.position = Vector2(0.0, -data.ring_height)
		add_child(_ring)
	_body = SpriteArt.make(data.sprite, data.sprite_anchor)
	add_child(_body)
	if data.show_health_bar:
		health_bar = HealthBar.new()
		health_bar.configure(data.radius, sprite_top())
		add_child(health_bar)
	set_process(_spins())


## px (1x) do topo do sprite acima da âncora (sem sprite: o diâmetro).
func sprite_top() -> float:
	if data.sprite == null:
		return data.radius * 2.0
	return data.sprite_anchor.y * SpriteArt.SCALE.y


func _spins() -> bool:
	return _ring != null and data.ring_spin_speed != 0.0


## Flash de acerto: corpo em hit_flash_color por hit_flash_time s (sem alocar).
func flash() -> void:
	if hit_flash_time <= 0.0 or _body == null or state == State.DEAD:
		return
	_flash_left = hit_flash_time
	_body.self_modulate = hit_flash_color
	set_process(true)


func is_flashing() -> bool:
	return _flash_left > 0.0


func _process(delta: float) -> void:
	if _spins():
		_ring.rotation += data.ring_spin_speed * delta
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash_left = 0.0
			_body.self_modulate = Color.WHITE
			set_process(_spins())
