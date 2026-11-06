class_name RewardData
extends Resource
## Pesos de recompensa por partida (XP da conta e Moeda). Nunca dependem do tempo. Lógica na T-186.

## id do inimigo (enemy_* / boss_*) -> XP por unidade derrotada.
@export var kill_xp: Dictionary = {}
## id do inimigo -> Moeda por unidade derrotada.
@export var kill_coins: Dictionary = {}
## Por onda concluída.
@export var wave_xp: int = 0
@export var wave_coins: int = 0
## Bônus só na vitória.
@export var win_bonus_xp: int = 0
@export var win_bonus_coins: int = 0
## Multiplicador do total na derrota (0 < x <= 1).
@export var defeat_multiplier: float = 0.8


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for id in kill_xp:
		if int(kill_xp[id]) <= 0:
			errors.append("kill_xp[%s] <= 0" % id)
	for id in kill_coins:
		if int(kill_coins[id]) <= 0:
			errors.append("kill_coins[%s] <= 0" % id)
	if defeat_multiplier <= 0.0 or defeat_multiplier > 1.0:
		errors.append("defeat_multiplier fora de (0, 1]")
	return errors
