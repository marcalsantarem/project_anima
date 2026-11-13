class_name Projectile
extends Area2D
## Projétil reutilizável. Fica estacionado fora da arena enquanto inativo, sem alocar.

signal expired(projectile: Projectile)
## Disparo: origem (âncora no chão, tela) e direção em tela normalizada.
signal fired(from: Vector2, dir: Vector2)
## Acerto: posição do projétil (âncora no chão, tela) e tipo do alvo (TARGET_*).
signal hit(at: Vector2, target_kind: StringName)

const TARGET_ENEMY := &"enemy"
const TARGET_BOSS := &"boss"
const TARGET_CORE := &"core"

## Anti-túnel (T-276): com passo maior que isto (x2: 900 px/s * 2/60 s = 30 px), uma 2ª forma de colisão
## cobre o ponto médio do trajeto do passo, dando o mesmo espaçamento de ~15 px do x1.
const MID_SHAPE_MIN_STEP := 20.0

## Ponto de estacionamento fora de qualquer arena.
const PARKED_POSITION := Vector2(-100000.0, -100000.0)

var active := false
var data: ProjectileData
## Dano deste disparo (data.damage, ou o valor com upgrades passado em fire()).
var damage := 0
## Perfuração extra dos Núcleos (T-205), somada a data.pierce em tempo de execução (o .tres não muda).
var extra_pierce := 0

var _direction := Vector2.ZERO ## no chão
var _distance_left := 0.0
var _hits_left := 0
var _hit_ids := PackedInt64Array()
var _hit_count := 0
var _shadow: GroundShadow
var _sprite: Sprite2D
var _mid_shape: CollisionShape2D ## ponto médio do passo (só com passo grande)
var _mid_delta := -1.0 ## delta com que a forma média foi posicionada

@onready var _shape_node: CollisionShape2D = $Shape


func _ready() -> void:
	_shape_node.shape = CircleShape2D.new()
	area_entered.connect(_on_area_entered)
	park()


## Configura o tamanho uma vez, quando o pool é criado.
func configure(p_data: ProjectileData, p_extra_pierce: int = 0) -> void:
	data = p_data
	extra_pierce = maxi(p_extra_pierce, 0)
	(_shape_node.shape as CircleShape2D).radius = data.radius
	_shape_node.scale = GroundPlane.SHAPE_SCALE # círculo no chão
	if _mid_shape == null:
		_mid_shape = CollisionShape2D.new()
		_mid_shape.shape = _shape_node.shape # mesmo círculo (raio compartilhado)
		_mid_shape.scale = GroundPlane.SHAPE_SCALE
		_mid_shape.disabled = true
		add_child(_mid_shape)
	if _shadow == null:
		_shadow = GroundShadow.new()
		add_child(_shadow)
	_shadow.radius = data.radius
	_hit_ids.resize(data.pierce + extra_pierce + 1)
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
	_hits_left = data.pierce + extra_pierce + 1
	_hit_count = 0
	_mid_delta = -1.0
	_sprite.rotation = direction.angle() # sprite aponta para +X
	active = true
	visible = true
	set_physics_process(true)
	fired.emit(origin, direction.normalized())


func park() -> void:
	active = false
	visible = false
	set_physics_process(false)
	position = PARKED_POSITION


func _physics_process(delta: float) -> void:
	var step := data.speed * delta
	if _mid_shape != null and not is_equal_approx(delta, _mid_delta):
		_update_mid_shape(step, delta)
	position += GroundPlane.to_screen(_direction * step)
	_distance_left -= step
	if _distance_left <= 0.0:
		_expire()


## Posiciona (ou desliga) a forma do ponto médio para o passo atual.
func _update_mid_shape(step: float, delta: float) -> void:
	_mid_delta = delta
	var needed := step > MID_SHAPE_MIN_STEP
	_mid_shape.set_deferred("disabled", not needed)
	_mid_shape.position = GroundPlane.to_screen(_direction * -step * 0.5) if needed else Vector2.ZERO


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
	hit.emit(position, TARGET_BOSS if enemy is Boss else TARGET_ENEMY)
	enemy.take_damage(damage)
	_hits_left -= 1
	if _hits_left <= 0:
		_expire()


## Usado por quem recebe o acerto (Anima, escudo). Emite `hit` com o tipo do alvo.
func consume(target_kind: StringName = TARGET_CORE) -> void:
	if active:
		hit.emit(position, target_kind)
		_expire()


func _expire() -> void:
	park()
	expired.emit(self)

