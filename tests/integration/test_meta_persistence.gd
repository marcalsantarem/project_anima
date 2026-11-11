extends GutTest
## T-196: ciclo do meta com LocalBackend real (sem fake): liquidar, salvar, reabrir o perfil.

const P := "user://test_qa_m2_save.json"
var prog: ProgressionData = load("res://data/meta/progression_m2.tres")
var rew: RewardData = load("res://data/meta/rewards_m2.tres")


func after_all() -> void:
	LocalBackend.new(P).reset_profile()


func _res(outcome: int, kills: Dictionary) -> MatchResult:
	var r := MatchResult.new()
	r.outcome = outcome
	r.set("kills_by_type", kills)
	return r


func test_three_matches_survive_reopen() -> void:
	var b := LocalBackend.new(P)
	b.reset_profile()
	var p := b.load_profile()
	var win := {&"enemy_runner": 92, &"enemy_swarm": 98, &"enemy_shooter": 7, &"enemy_tank": 10, &"boss_warden": 1}
	MetaFlow.settle(p, _res(MatchResult.Outcome.VICTORY, win), rew, prog, "2026-11-06")
	MetaFlow.settle(p, _res(MatchResult.Outcome.DEFEAT, {&"enemy_runner": 27}), rew, prog, "2026-11-06")
	MetaFlow.settle(p, _res(MatchResult.Outcome.VICTORY, win), rew, prog, "2026-11-06")
	assert_true(b.save_profile(p))
	var q := LocalBackend.new(P).load_profile()
	assert_eq(q.level, p.level)
	assert_eq(q.xp, p.xp)
	assert_eq(q.coins, p.coins)
	assert_eq(q.last_first_win_date, "2026-11-06", "bônus do dia persistido")
	assert_gt(q.level, 1)
	# 2ª vitória no mesmo dia depois de reabrir: sem bônus
	var s := MetaFlow.settle(q, _res(MatchResult.Outcome.VICTORY, win), rew, prog, "2026-11-06")
	assert_false(s["first_win_bonus"])


func test_level_30_cap_survives_reopen() -> void:
	var b := LocalBackend.new(P)
	b.reset_profile()
	var p := PlayerProfile.new()
	p.level = prog.max_level
	p.xp = 0
	MetaFlow.settle(p, _res(MatchResult.Outcome.VICTORY, {&"enemy_runner": 100}), rew, prog, "2026-11-07")
	assert_eq(p.level, prog.max_level)
	assert_true(b.save_profile(p))
	var q := LocalBackend.new(P).load_profile()
	assert_eq(q.level, prog.max_level)
	assert_eq(q.xp, 0, "XP descartado no teto")
