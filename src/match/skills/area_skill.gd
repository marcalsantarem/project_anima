class_name AreaSkill
extends SkillBehavior
## Dano instantâneo em raio (no chão), no ponto de maior densidade de inimigos ao alcance.
## Fica abaixo dos corpos (z -1): é um decalque no chão, desenhado como elipse 0,75.

const TELEGRAPH_COLOR := Color(0.3, 0.95, 1.0, 0.35)
const IMPACT_COLOR := Color(0.6, 1.0, 1.0, 0.8)
const IMPACT_FX_TIME := 0.2 ## s
const RING_WIDTH := 4.0

var _target := Vector2.ZERO
var _windup_left := 0.0
var _fx_left := 0.0


func _ready() -> void:
	z_index = -1
	visible = false
	set_physics_process(false)


func can_activate() -> bool:
	return Targeting.pick(context.anima.position, context.enemies, data.target_range) != null


func activate() -> void:
	_target = _pick_target()
	position = _target
	_windup_left = _windup_time()
	_fx_left = 0.0
	visible = true
	set_physics_process(true)
	if _windup_left <= 0.0:
		_impact()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _windup_left > 0.0:
		_windup_left -= delta
		if _windup_left <= 0.0:
			_impact()
		else:
			_on_windup_tick()
		return
	_fx_left -= delta
	if _fx_left <= 0.0:
		visible = false
		set_physics_process(false)
		_on_finished()


## Ponto do efeito (subclasses podem mudar a regra).
func _pick_target() -> Vector2:
	return densest_point(context.anima.position, context.enemies, data.target_range, data.radius)


func _windup_time() -> float:
	return data.windup


func _fx_time() -> float:
	return IMPACT_FX_TIME


## Ganchos visuais (sem regra): a cada passo da antecipação e ao fim do efeito.
func _on_windup_tick() -> void:
	pass


func _on_finished() -> void:
	pass


func _impact() -> void:
	apply_damage(_target, context.enemies, data.radius, data.damage)
	_fx_left = _fx_time()
	cast.emit(_target, data.radius)
	queue_redraw()


## Aplica dano a quem toca o círculo. Itera de trás para frente: mortes tiram da lista.
static func apply_damage(center: Vector2, enemies: Array[Enemy], radius: float, damage: int) -> int:
	var hits := 0
	for i in range(enemies.size() - 1, -1, -1):
		var e := enemies[i]
		if not is_instance_valid(e) or e.state == Enemy.State.DEAD:
			continue
		var reach := radius + e.data.radius
		if GroundPlane.distance_squared(center, e.position) <= reach * reach:
			e.take_damage(damage)
			hits += 1
	return hits


## Centro, entre os inimigos ao alcance, que cobre mais inimigos no raio. Empate: o mais próximo da origem.
static func densest_point(origin: Vector2, enemies: Array[Enemy], target_range: float, radius: float) -> Vector2:
	var e := densest_enemy(origin, enemies, target_range, radius)
	return e.position if e else origin


## Inimigo ao alcance com mais vizinhos (ele incluso) dentro do raio, no chão. Empate (inclusive
## todos sozinhos): o mais próximo da origem. null se ninguém está ao alcance.
static func densest_enemy(origin: Vector2, enemies: Array[Enemy], target_range: float, radius: float) -> Enemy:
	var best: Enemy = null
	var best_count := 0
	var best_dist_sq := INF
	var range_sq := target_range * target_range
	var radius_sq := radius * radius
	for candidate in enemies:
		if not is_instance_valid(candidate) or candidate.state == Enemy.State.DEAD:
			continue
		var dist_sq := GroundPlane.distance_squared(origin, candidate.position)
		if dist_sq > range_sq:
			continue
		var count := 0
		for other in enemies:
			if is_instance_valid(other) and other.state != Enemy.State.DEAD 					and GroundPlane.distance_squared(candidate.position, other.position) <= radius_sq:
				count += 1
		if count > best_count or (count == best_count and dist_sq < best_dist_sq):
			best = candidate
			best_count = count
			best_dist_sq = dist_sq
	return best


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	if _windup_left > 0.0:
		draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 64, TELEGRAPH_COLOR, RING_WIDTH, true)
	else:
		draw_circle(Vector2.ZERO, data.radius, IMPACT_COLOR * Color(1, 1, 1, 0.3))
		draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 64, IMPACT_COLOR, RING_WIDTH, true)
