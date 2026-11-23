class_name FreezeSkill
extends AreaSkill
## Congelamento (T-109): inimigos no raio param por `duration` s e depois ficam lentos
## (`effect_params.slow_after` = fração perdida de velocidade, `slow_time` s). Sem dano. O chefe só
## fica lento (`boss_frozen` = false) durante `duration`. Mira manual como o meteoro (`at`).


func _apply_effect() -> int:
	var p := data.effect_params
	var mult := 1.0 - clampf(float(p.get("slow_after", 0.5)), 0.0, 1.0)
	var slow_time := float(p.get("slow_time", 0.0))
	var boss_frozen := bool(p.get("boss_frozen", false))
	var hits := 0
	for e in context.enemies:
		if not is_instance_valid(e) or e.state == Enemy.State.DEAD:
			continue
		var reach := data.radius + e.data.radius
		if GroundPlane.distance_squared(_target, e.position) > reach * reach:
			continue
		if e is Boss and not boss_frozen:
			e.slow(data.duration, mult)
		else:
			e.freeze(data.duration, slow_time, mult)
		hits += 1
	return hits
