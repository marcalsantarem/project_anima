class_name MetaRewards
extends RefCounted
## Recompensa da partida (XP da conta e Moeda). Pura: sem cena, rede ou relógio.


## `result` precisa de `outcome` e `kills_by_type` (MatchResult). Retorna {xp, coins, breakdown}.
static func compute(result: Object, rewards: RewardData, first_win_today: bool, coin_gain := 0.0) -> Dictionary:
	## `coin_gain`: fração dos Núcleos (T-204); depois do ×0,7 da derrota e antes do bônus do dia.
	var kills: Variant = result.get("kills_by_type")
	if not (kills is Dictionary):
		kills = {}
	var xp_raw := 0.0
	var coins_raw := 0.0
	for id in kills:
		var n := maxi(int(kills[id]), 0)
		xp_raw += n * float(rewards.kill_xp.get(id, 0.0))
		coins_raw += n * float(rewards.kill_coins.get(id, 0.0))
	var victory: bool = int(result.get("outcome")) == MatchResult.Outcome.VICTORY
	var mult := 1.0 if victory else rewards.defeat_multiplier
	var xp := roundi(xp_raw * mult)
	var coins := roundi(coins_raw * mult)
	if coin_gain > 0.0:
		coins = roundi(coins * (1.0 + coin_gain))
	var bonus := victory and first_win_today
	if bonus:
		xp += rewards.first_win_bonus_xp
		coins += rewards.first_win_bonus_coins
	return {
		"xp": xp,
		"coins": coins,
		"breakdown": {"xp_raw": xp_raw, "coins_raw": coins_raw, "multiplier": mult, "first_win_bonus": bonus},
	}
