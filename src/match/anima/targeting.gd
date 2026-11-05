class_name Targeting
extends RefCounted
## Escolha de alvo: maior target_priority; no empate, o mais próximo. Só dentro do alcance (no chão).


static func pick(origin: Vector2, enemies: Array[Enemy], attack_range: float) -> Enemy:
	var best: Enemy = null
	var best_priority := 0
	var best_dist_sq := INF
	var range_sq := attack_range * attack_range
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.state == Enemy.State.DEAD:
			continue
		var dist_sq := GroundPlane.distance_squared(origin, enemy.position)
		if dist_sq > range_sq:
			continue
		var priority := enemy.data.target_priority
		if best == null or priority > best_priority or (priority == best_priority and dist_sq < best_dist_sq):
			best = enemy
			best_priority = priority
			best_dist_sq = dist_sq
	return best


## Foco manual (T-176): o focado, se vivo e dentro do alcance; senão a regra automática.
static func pick_with_focus(origin: Vector2, enemies: Array[Enemy], attack_range: float, focus: Enemy) -> Enemy:
	if is_instance_valid(focus) and focus.state != Enemy.State.DEAD 			and GroundPlane.distance_squared(origin, focus.position) <= attack_range * attack_range:
		return focus
	return pick(origin, enemies, attack_range)
