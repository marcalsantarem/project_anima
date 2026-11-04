class_name CoreHealth
extends RefCounted
## HP do Núcleo. Lógica pura, sem cena.

signal changed(current: int, max_hp: int)
signal depleted

var max_hp: int
var current: int


func _init(p_max_hp: int) -> void:
	max_hp = maxi(p_max_hp, 1)
	current = max_hp


func is_depleted() -> bool:
	return current <= 0


## Aplica dano e devolve quanto foi efetivamente perdido.
func take_damage(amount: int) -> int:
	if amount <= 0 or is_depleted():
		return 0
	var lost := mini(amount, current)
	current -= lost
	changed.emit(current, max_hp)
	if is_depleted():
		depleted.emit()
	return lost


## Sobe o HP máximo e o atual pelo mesmo valor (não é cura total). Ignora se esgotado.
func raise_max(amount: int) -> void:
	if amount <= 0 or is_depleted():
		return
	max_hp += amount
	current += amount
	changed.emit(current, max_hp)
