extends Node2D
## Arena falsa dos testes T-215: sinais da Arena + `skills` e `active_enemies` (duck typing do FxDirector).

signal skill_cast(slot: int, at: Vector2, radius: float)
signal skill_chain_hit(slot: int, from: Vector2, to: Vector2, damage: int, index: int)
signal shield_started(absorb: int, duration: float)
signal shield_absorbed(amount: int, remaining: int)
signal shield_ended(broken: bool)

class FakeSkills:
	extends RefCounted
	var ids: Array = [&"fx_skill_cast", &"fx_freeze", &"fx_shock"]
	func get_slot(slot: int) -> Dictionary:
		return {"data": {"fx_id": ids[slot - 1], "duration": 2.0}}

var skills := FakeSkills.new()
var active_enemies: Array = []
