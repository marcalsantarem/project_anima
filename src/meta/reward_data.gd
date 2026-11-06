class_name RewardData
extends Resource
## Pesos de recompensa por partida (XP da conta e Moeda). Só monstros derrotados contam; nunca o tempo. Lógica na T-186.
## total = round(Σ kills × valor) ; na derrota × defeat_multiplier. Sem bônus por onda nem de vitória.

## id do inimigo (enemy_* / boss_*) -> XP por unidade derrotada (float; arredonda só no total).
@export var kill_xp: Dictionary = {}
## id do inimigo -> Moeda por unidade derrotada.
@export var kill_coins: Dictionary = {}
## Multiplicador do total na derrota (0 < x <= 1).
@export var defeat_multiplier: float = 0.7
## Bônus da 1ª vitória do dia (data local do aparelho; PlayerProfile.last_first_win_date, T-186).
@export var first_win_bonus_xp: int = 0
@export var first_win_bonus_coins: int = 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for id in kill_xp:
		if float(kill_xp[id]) <= 0.0:
			errors.append("kill_xp[%s] <= 0" % id)
	for id in kill_coins:
		if float(kill_coins[id]) <= 0.0:
			errors.append("kill_coins[%s] <= 0" % id)
	if defeat_multiplier <= 0.0 or defeat_multiplier > 1.0:
		errors.append("defeat_multiplier fora de (0, 1]")
	if first_win_bonus_xp <= 0:
		errors.append("first_win_bonus_xp <= 0")
	if first_win_bonus_coins <= 0:
		errors.append("first_win_bonus_coins <= 0")
	return errors
