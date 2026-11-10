extends GutTest
## Lógica pura do meta (BRF-111 / T-186).

const PROG := "res://data/meta/progression_m2.tres"
const REW := "res://data/meta/rewards_m2.tres"

var prog: ProgressionData
var rew: RewardData


func before_each() -> void:
	prog = load(PROG)
	rew = load(REW)


func _res(outcome: int, kills: Dictionary) -> MatchResult:
	var r := MatchResult.new()
	r.outcome = outcome
	r.set("kills_by_type", kills)
	return r


func _win(kills := {&"enemy_runner": 92, &"enemy_swarm": 98, &"enemy_shooter": 7, &"enemy_tank": 10, &"boss_warden": 1}) -> MatchResult:
	return _res(MatchResult.Outcome.VICTORY, kills)


func test_victory_phase1() -> void:
	var o := MetaRewards.compute(_win(), rew, false)
	assert_eq(o["xp"], 195)
	assert_eq(o["coins"], 232)


func test_victory_with_bonus() -> void:
	var o := MetaRewards.compute(_win(), rew, true)
	assert_eq(o["xp"], 295)
	assert_eq(o["coins"], 347)


func test_defeat_wave3() -> void:
	var o := MetaRewards.compute(_res(MatchResult.Outcome.DEFEAT, {&"enemy_runner": 27}), rew, true)
	assert_eq(o["xp"], 19, "27 x 0,7 = 18,9 -> 19; derrota não leva bônus")
	assert_false(o["breakdown"]["first_win_bonus"])


func test_zero_kills_and_invalid() -> void:
	assert_eq(MetaRewards.compute(_res(MatchResult.Outcome.DEFEAT, {}), rew, false)["xp"], 0)
	var o := MetaRewards.compute(_res(MatchResult.Outcome.DEFEAT, {&"enemy_runner": -5, &"desconhecido": 9}), rew, false)
	assert_eq(o["xp"], 0)
	assert_eq(o["coins"], 0)


func test_swarm_rounds_only_total() -> void:
	var o := MetaRewards.compute(_res(MatchResult.Outcome.DEFEAT, {&"enemy_swarm": 1}), rew, false)
	assert_eq(o["xp"], 0, "0,5 x 0,7 = 0,35")
	o = MetaRewards.compute(_win({&"enemy_swarm": 3}), rew, false)
	assert_eq(o["xp"], 2, "1,5 arredonda no total")


func test_boss_only() -> void:
	assert_eq(MetaRewards.compute(_win({&"boss_warden": 1}), rew, false)["xp"], 20)


func test_apply_xp_exact_limit() -> void:
	var p := PlayerProfile.new()
	var o := MetaProgress.apply_xp(p, 50, prog)
	assert_eq(o["new_level"], 2)
	assert_eq(p.xp, 0)
	p = PlayerProfile.new()
	o = MetaProgress.apply_xp(p, 49, prog)
	assert_eq(o["levels_gained"], 0)
	assert_eq(p.xp, 49)


func test_multiple_levels_and_slots() -> void:
	var p := PlayerProfile.new()
	var o := MetaProgress.apply_xp(p, 50 + 150 + 7, prog)
	assert_eq(o["new_level"], 3)
	assert_eq(o["levels_gained"], 2)
	assert_eq(o["slots_unlocked"], [1] as Array[int])
	assert_eq(p.xp, 7)
	o = MetaProgress.apply_xp(p, 300 + 500 + 500 + 500 - 7 + 7, prog)
	assert_eq(o["new_level"], 7)
	assert_eq(o["slots_unlocked"], [2] as Array[int])


func test_slot3_at_8_and_slots_for_level() -> void:
	var p := PlayerProfile.new()
	var o := MetaProgress.apply_xp(p, 100000, prog)
	assert_eq(o["new_level"], 30)
	assert_eq(o["slots_unlocked"], [1, 2, 3] as Array[int])
	assert_eq(MetaProgress.slots_for_level(1, prog), 0)
	assert_eq(MetaProgress.slots_for_level(2, prog), 1)
	assert_eq(MetaProgress.slots_for_level(4, prog), 1)
	assert_eq(MetaProgress.slots_for_level(5, prog), 2)
	assert_eq(MetaProgress.slots_for_level(7, prog), 2)
	assert_eq(MetaProgress.slots_for_level(8, prog), 3)


func test_cap_30_discards_xp() -> void:
	var p := PlayerProfile.new()
	p.level = 30
	var o := MetaProgress.apply_xp(p, 5000, prog)
	assert_eq(o["levels_gained"], 0)
	assert_eq(p.level, 30)
	assert_eq(p.xp, 0)
	var q := PlayerProfile.new()
	MetaProgress.apply_xp(q, -10, prog)
	assert_eq(q.xp, 0, "XP negativo ignorado")


func test_daily_bonus_cycle() -> void:
	var p := PlayerProfile.new()
	var s1 := MetaFlow.settle(p, _win(), rew, prog, "2026-11-06")
	assert_true(s1["first_win_bonus"])
	assert_eq(s1["xp"], 295)
	assert_eq(p.last_first_win_date, "2026-11-06")
	var s2 := MetaFlow.settle(p, _win(), rew, prog, "2026-11-06")
	assert_false(s2["first_win_bonus"])
	assert_eq(s2["xp"], 195)
	var s3 := MetaFlow.settle(p, _win(), rew, prog, "2026-11-07")
	assert_true(s3["first_win_bonus"])


func test_defeat_never_marks() -> void:
	var p := PlayerProfile.new()
	var s := MetaFlow.settle(p, _res(MatchResult.Outcome.DEFEAT, {&"enemy_runner": 27}), rew, prog, "2026-11-06")
	assert_false(s["first_win_bonus"])
	assert_eq(p.last_first_win_date, "")
	assert_eq(s["xp"], 19)
	assert_eq(p.coins, 19)


func test_settle_applies_profile() -> void:
	var p := PlayerProfile.new()
	var s := MetaFlow.settle(p, _win(), rew, prog, "2026-11-06")
	assert_eq(p.coins, 347)
	assert_eq(s["new_level"], p.level)
	assert_gt(s["levels_gained"], 0)


func test_invalid_today_no_bonus() -> void:
	var p := PlayerProfile.new()
	assert_false(MetaDaily.is_first_win_today(p, ""))
	assert_false(MetaDaily.is_first_win_today(p, "ontem"))
	MetaDaily.mark_first_win(p, "ontem")
	assert_eq(p.last_first_win_date, "")


func test_profile_date_field() -> void:
	var old := PlayerProfile.from_dict({"level": 2, "xp": 1, "coins": 3})
	assert_eq(old.last_first_win_date, "", "save antigo sem o campo")
	var p := PlayerProfile.from_dict({"last_first_win_date": "2026-11-06"})
	assert_eq(p.to_dict()["last_first_win_date"], "2026-11-06")
	assert_false(p.extra.has("last_first_win_date"))
	p.last_first_win_date = "lixo"
	p.sanitize()
	assert_eq(p.last_first_win_date, "")
	p.last_first_win_date = "2026-13-40"
	p.sanitize()
	assert_eq(p.last_first_win_date, "")
	assert_eq(PlayerProfile.from_dict({"last_first_win_date": 5}).last_first_win_date, "")
