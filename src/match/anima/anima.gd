class_name Anima
extends Area2D
## Receptáculo fixo no centro. Recebe dano de contato no Núcleo e atira sozinho.

signal core_hp_changed(current: int, max_hp: int)
signal core_depleted

@export var data: AnimaData
## Desligável para testes e debug.
@export var auto_attack_enabled := true

var core: CoreHealth
var target: Enemy

var _enemies: Array[Enemy] = []
var _pool: ProjectilePool
var _scan_timer := 0.0
var _fire_timer := 0.0
var _crystal: Sprite2D
var _orbits: Array[Sprite2D] = []
var _art_time := 0.0

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
	_build_art()


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


## Âncora = centro do pedestal no chão. Base e cristal são sprites; o cristal flutua e os nós orbitam.
func _build_art() -> void:
	add_child(SpriteArt.make(data.base_sprite, data.base_anchor))
	_crystal = SpriteArt.make(data.crystal_sprite, data.crystal_anchor)
	add_child(_crystal)
	for i in data.orbit_count:
		# Filho do cristal (escala 0,5): escala 1 e posição em px do PNG mantêm o 1x.
		var orb := SpriteArt.make(data.orbit_sprite, data.orbit_anchor)
		orb.scale = Vector2.ONE
		_crystal.add_child(orb)
		_orbits.append(orb)
	_update_art()


## Só visual (não mexe em regra): oscilação do cristal e órbita dos nós, sem alocar.
func _process(delta: float) -> void:
	_art_time += delta
	_update_art()


func _update_art() -> void:
	var bob := sin(_art_time * TAU / data.crystal_bob_period) * data.crystal_bob_amplitude
	_crystal.position = Vector2(0.0, -data.crystal_height + bob)
	var to_png := Vector2.ONE / SpriteArt.SCALE
	var n := _orbits.size()
	for i in n:
		var a := _art_time * TAU / data.orbit_period + TAU * i / n
		var p := Vector2(cos(a), sin(a))
		_orbits[i].position = p * data.orbit_radii * to_png
		_orbits[i].show_behind_parent = p.y < 0.0 # metade de trás da elipse
