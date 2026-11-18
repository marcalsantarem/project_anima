class_name ShieldSkill
extends SkillBehavior
## Escudo no Núcleo (T-110): absorve `effect_params.absorb` de dano por `duration` s. Sempre dispara;
## reacionar renova. Ignora `at` e `skill_damage_scale`. Os sinais ficam em `anima.shield`.


func activate(_at: Vector2 = Vector2.INF) -> void:
	context.anima.shield.activate(int(data.effect_params.get("absorb", 0)), data.duration)
	cast.emit(context.anima.position, 0.0)
