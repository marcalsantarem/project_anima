class_name ShockSkill
extends SkillBehavior
## Choque (T-212): automático. 1º alvo = inimigo ao alcance com mais vizinhos no raio de salto
## (empate: o mais próximo do Anima); salta para o vivo mais próximo ainda não atingido dentro de
## `radius` (raio de salto). `effect_params.jumps` saltos, cada um com dano anterior × `falloff`.
## Dano inicial × `skill_damage_scale` (Núcleos). Não lança o chefe. Ignora `at`.

## Um golpe da cadeia: `from` → `to` (posições de tela), dano e índice (0 = Anima → 1º alvo).
signal chain_hit(from: Vector2, to: Vector2, damage: int, index: int)

var last_hits := 0
var _windup_left := 0.0
var _pending := false


func _ready() -> void:
	set_physics_process(false)


func can_activate(_at: Vector2 = Vector2.INF) -> bool:
	return AreaSkill.densest_enemy(context.anima.position, context.enemies, data.target_range, data.radius) != null


func activate(_at: Vector2 = Vector2.INF) -> void:
	_windup_left = data.windup
	_pending = true
	if _windup_left <= 0.0:
		_fire()
	else:
		set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _pending:
		set_physics_process(false)
		return
	_windup_left -= delta
	if _windup_left <= 0.0:
		_fire()


func _fire() -> void:
	_pending = false
	set_physics_process(false)
	var target := AreaSkill.densest_enemy(context.anima.position, context.enemies, data.target_range, data.radius)
	if target == null:
		return
	var jumps := int(data.effect_params.get("jumps", 0))
	var falloff := float(data.effect_params.get("falloff", 1.0))
	var dmg := float(data.damage) * context.skill_damage_scale
	var hit: Dictionary = {}
	var from := context.anima.position
	last_hits = 0
	cast.emit(target.position, data.radius)
	for k in jumps + 1:
		var at := target.position
		var amount := maxi(roundi(dmg), 1) if data.damage > 0 else 0
		hit[target.get_instance_id()] = true
		chain_hit.emit(from, at, amount, k)
		last_hits += 1
		target.take_chain_damage(amount)
		dmg *= falloff
		from = at
		target = _next(at, hit)
		if target == null:
			break


## Vivo mais próximo de `from` (no chão), ainda não atingido, dentro do raio de salto.
func _next(from: Vector2, hit: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_sq := data.radius * data.radius
	for e in context.enemies:
		if not is_instance_valid(e) or e.state == Enemy.State.DEAD or hit.has(e.get_instance_id()):
			continue
		var d := GroundPlane.distance_squared(from, e.position)
		if d <= best_sq:
			best = e
			best_sq = d
	return best
