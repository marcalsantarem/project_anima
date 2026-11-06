extends GutTest
## Integridade dos dados de economia do M2 (BRF-106).

const PROG := "res://data/meta/progression_m2.tres"
const REW := "res://data/meta/rewards_m2.tres"


func test_progression_curve() -> void:
	var p: ProgressionData = load(PROG)
	assert_not_null(p)
	assert_eq(p.max_level, 15)
	assert_eq(p.xp_to_next.size(), 14, "15 níveis = 14 degraus")
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
	assert_gt(r.wave_xp, 0)
	assert_gt(r.wave_coins, 0)
	assert_gt(r.win_bonus_xp, 0)
	assert_gt(r.win_bonus_coins, 0)
