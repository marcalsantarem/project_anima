class_name SkillContext
extends RefCounted
## O que as skills enxergam da partida.

var anima: Anima
## Inimigos vivos (mesma lista da arena).
var enemies: Array[Enemy]


func _init(p_anima: Anima, p_enemies: Array[Enemy]) -> void:
	anima = p_anima
	enemies = p_enemies
