class_name SkillSlot
extends RefCounted
## Cooldown de um slot. Lógica pura.

var data: SkillData
var remaining := 0.0
## Duração do cooldown em curso (com upgrades); usada como `total` nos sinais.
var total := 0.0


func _init(p_data: SkillData) -> void:
	data = p_data


func is_ready() -> bool:
	return remaining <= 0.0


## scale: multiplicador de cooldown (upgrades); vale só para este uso.
func start_cooldown(scale: float = 1.0) -> void:
	total = data.cooldown * scale
	remaining = total


## Avança o tempo. Devolve true no passo em que o cooldown termina.
func tick(delta: float) -> bool:
	if remaining <= 0.0:
		return false
	remaining = maxf(remaining - delta, 0.0)
	return remaining == 0.0
