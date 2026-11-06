extends GutTest
## Integridade dos dados de economia do M2 (BRF-106).

const PROG := "res://data/meta/progression_m2.tres"
const REW := "res://data/meta/rewards_m2.tres"


func test_progression_curve() -> void:
	var p: ProgressionData = load(PROG)
	assert_not_null(p)
	assert_eq(p.max_level, 30)
	assert_eq(p.xp_to_next.size(), 29, "30 níveis = 29 degraus")
	assert_eq(p.validate().size(), 0)
	for i in range(1, p.xp_to_next.size()):
		assert_gte(p.xp_to_next[i], p.xp_to_next[i - 1], "curva monotônica no degrau %d" % i)


func test_slot_unlocks() -> void:
	var p: ProgressionData = load(PROG)
	assert_eq(p.slot_unlock_levels, PackedInt32Array([3, 7, 12]))


func test_rewards_valid_and_cover_enemies() -> void:
	var r: RewardData = load(REW)
	assert_not_null(r)
	assert_eq(r.validate().size(), 0)
	for f in DirAccess.get_files_at("res://data/enemies"):
		if f.ends_with(".tres"):
			var id := f.get_basename()
			assert_true(r.kill_xp.has(StringName(id)), "XP de %s" % id)
			assert_true(r.kill_coins.has(StringName(id)), "Moeda de %s" % id)
	assert_eq(r.defeat_multiplier, 0.7)
	assert_gt(r.first_win_bonus_xp, 0)
	assert_gt(r.first_win_bonus_coins, 0)


func test_curve_milestones() -> void:
	var p: ProgressionData = load(PROG)
	var cum := 0
	for i in 29:
		cum += p.xp_to_next[i]
		if i == 1:
			assert_eq(cum, 150, "nível 3")
	assert_eq(cum, 19780, "nível 30")


func test_validate_rejects_bad_data() -> void:
	var p := ProgressionData.new()
	p.max_level = 3
	p.xp_to_next = PackedInt32Array([50, 40])
	assert_gt(p.validate().size(), 0, "curva decrescente")
	var r := RewardData.new()
	r.kill_xp = {&"x": 0.0}
	r.defeat_multiplier = 0.0
	assert_gt(r.validate().size(), 2)


func test_max_level_matches_profile() -> void:
	var p: ProgressionData = load(PROG)
	assert_eq(PlayerProfile.MAX_LEVEL, p.max_level)
