class_name SkillBehavior
extends Node2D
## Base dos comportamentos por tipo. Cada subclasse só lê o SkillData.

## Efeito da skill aplicado no chão (posição de tela, âncora no chão; raio em px no chão).
signal cast(at: Vector2, radius: float)
## A skill foi acionada mas anulada antes do efeito (nada no alvo): o controlador devolve o cooldown.
signal fizzled(at: Vector2)

var data: SkillData
var context: SkillContext


func setup(p_data: SkillData, p_context: SkillContext) -> void:
	data = p_data
	context = p_context


## Aceita mira manual (ponto no chão escolhido pelo jogador). Sem mira, `at` é ignorado.
func can_aim() -> bool:
	return false


## false = acionar agora não faria nada (o cooldown não é gasto). `at` finito = mira manual.
func can_activate(_at: Vector2 = Vector2.INF) -> bool:
	return true


## `at` = Vector2.INF: alvo automático; finito: ponto manual (só se can_aim()).
func activate(_at: Vector2 = Vector2.INF) -> void:
	pass
