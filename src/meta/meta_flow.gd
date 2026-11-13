class_name MetaFlow
extends RefCounted
## Fecha a partida no perfil (XP, Moeda, nível, bônus do dia). Não salva: quem chama salva pelo Backend.


static func settle(profile: PlayerProfile, result: Object, rewards: RewardData, progression: ProgressionData, today: String, tree: TalentTree = null) -> Dictionary:
	var victory: bool = int(result.get("outcome")) == MatchResult.Outcome.VICTORY
	var eligible := victory and MetaDaily.is_first_win_today(profile, today)
	var r := MetaRewards.compute(result, rewards, eligible, MetaTalents.coin_gain(profile.talents, tree) if tree != null else 0.0)
	profile.coins = clampi(profile.coins + int(r["coins"]), 0, PlayerProfile.MAX_AMOUNT)
	var p := MetaProgress.apply_xp(profile, int(r["xp"]), progression)
	if eligible:
		MetaDaily.mark_first_win(profile, today)
	return {
		"xp": r["xp"], "coins": r["coins"],
		"levels_gained": p["levels_gained"], "new_level": p["new_level"],
		"slots_unlocked": p["slots_unlocked"], "first_win_bonus": eligible,
	}
