class_name SkillBehavior
extends Node2D
## Base dos comportamentos por tipo. Cada subclasse só lê o SkillData.

## Efeito da skill aplicado no chão (posição de tela, âncora no chão; raio em px no chão).
signal cast(at: Vector2, radius: float)

var data: SkillData
var context: SkillContext


func setup(p_data: SkillData, p_context: SkillContext) -> void:
	data = p_data
	context = p_context


## false = acionar agora não faria nada (o cooldown não é gasto).
func can_activate() -> bool:
	return true


func activate() -> void:
	pass
