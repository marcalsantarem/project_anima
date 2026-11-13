extends GutTest
## T-204: compra, respec, save, bônus e ganho de Moeda dos Núcleos.

const TREE := "res://data/talents/talent_tree.tres"
const REW := "res://data/meta/rewards_m2.tres"

var tree: TalentTree
var p: PlayerProfile


func before_each() -> void:
	tree = load(TREE)
	p = PlayerProfile.new()
	p.level = 3
	p.coins = 1000


func _all_orders() -> Array[StringName]:
	# ordem que respeita os pré-requisitos (capstones por último)
	var o: Array[StringName] = []
	for id in [&"talent_sharp_core", &"talent_hardened_shell", &"talent_particle_magnet", &"talent_quick_pulse",
			&"talent_deflect", &"talent_seed_charge", &"talent_arcane_burst", &"talent_wave_mend", &"talent_cool_mind",
			&"talent_piercing_ray", &"talent_bastion", &"talent_golden_core"]:
		o.append(id)
	return o


func test_buy_ok() -> void:
	var r := MetaTalents.buy(p, tree, &"talent_sharp_core")
	assert_true(r["ok"])
	assert_eq(r["cost"], 50)
	assert_eq(p.coins, 950)
	assert_eq(MetaTalents.level(p, &"talent_sharp_core"), 1)
	assert_eq(MetaTalents.next_cost(p, tree, &"talent_sharp_core"), 70)


func test_reasons() -> void:
	assert_eq(MetaTalents.can_buy(p, tree, &"talent_nope"), MetaTalents.Reason.UNKNOWN)
	assert_eq(MetaTalents.can_buy(p, tree, &"talent_quick_pulse"), MetaTalents.Reason.LOCKED_PREREQ)
	p.level = 2
	assert_eq(MetaTalents.can_buy(p, tree, &"talent_sharp_core"), MetaTalents.Reason.FEATURE_LOCKED)
	p.level = 3
	p.coins = 49
	assert_eq(MetaTalents.can_buy(p, tree, &"talent_sharp_core"), MetaTalents.Reason.NO_COINS)
	p.coins = 100000
	for i in 5:
		assert_true(MetaTalents.buy(p, tree, &"talent_sharp_core")["ok"])
	assert_eq(MetaTalents.can_buy(p, tree, &"talent_sharp_core"), MetaTalents.Reason.MAX)
	assert_eq(MetaTalents.next_cost(p, tree, &"talent_sharp_core"), 0)


func test_all_or_nothing() -> void:
	p.coins = 10
	var before := p.to_dict()
	var r := MetaTalents.buy(p, tree, &"talent_sharp_core")
	assert_false(r["ok"])
	assert_eq(r["reason"], MetaTalents.Reason.NO_COINS)
	assert_eq(p.to_dict(), before)
	p.level = 1
	p.coins = 1000
	before = p.to_dict()
	assert_false(MetaTalents.buy(p, tree, &"talent_sharp_core")["ok"])
	assert_eq(p.to_dict(), before)


func test_prereq_status_and_capstone() -> void:
	var st := MetaTalents.prereq_status(p, tree, &"talent_piercing_ray")
	assert_eq(st.size(), 2)
	assert_eq(st[0]["need"], 3)
	assert_eq(st[0]["have"], 0)
	p.talents = {&"talent_arcane_burst": 3, &"talent_deflect": 1}
	assert_eq(MetaTalents.prereq_status(p, tree, &"talent_piercing_ray").size(), 0)


func test_full_tree_exact_coins() -> void:
	p.coins = 18355
	for id in _all_orders():
		var t := tree.get_talent(id)
		for i in t.max_level():
			var r := MetaTalents.buy(p, tree, id)
			assert_true(r["ok"], "%s nível %d" % [id, i + 1])
	assert_eq(p.coins, 0)
	assert_eq(MetaTalents.spent_coins(p, tree), 18355)


func test_respec_refunds_all() -> void:
	p.coins = 5000
	for id in [&"talent_sharp_core", &"talent_hardened_shell", &"talent_quick_pulse"]:
		MetaTalents.buy(p, tree, id)
	MetaTalents.buy(p, tree, &"talent_sharp_core")
	assert_lt(p.coins, 5000)
	var refund := MetaTalents.respec(p, tree)
	assert_eq(refund, 50 + 70 + 50 + 120)
	assert_eq(p.coins, 5000)
	assert_true(p.talents.is_empty())
	assert_eq(MetaTalents.respec(p, tree), 0)


func test_save_roundtrip_and_old_save() -> void:
	MetaTalents.buy(p, tree, &"talent_sharp_core")
	var d: Dictionary = JSON.parse_string(JSON.stringify(p.to_dict()))
	assert_true(PlayerProfile.is_valid_dict(d))
	var q := PlayerProfile.from_dict(d)
	assert_eq(MetaTalents.level(q, &"talent_sharp_core"), 1)
	var old := {"level": 4, "xp": 3, "coins": 9}
	assert_true(PlayerProfile.is_valid_dict(old))
	assert_true(PlayerProfile.from_dict(old).talents.is_empty())
	assert_false(PlayerProfile.is_valid_dict({"talents": {"talent_sharp_core": -1}}))
	assert_false(PlayerProfile.is_valid_dict({"talents": [1]}))
	assert_false(PlayerProfile.is_valid_dict({"talents": {"talent_sharp_core": "x"}}))


func test_sanitize_levels() -> void:
	p.talents = {&"talent_sharp_core": 99, &"talent_deflect": -2, &"talent_zzz": 3}
	p.sanitize(tree)
	assert_eq(p.talents, {&"talent_sharp_core": 5})
	p.talents = {&"talent_sharp_core": -1}
	p.sanitize()
	assert_true(p.talents.is_empty())


func test_resolve_empty_and_two_branches() -> void:
	assert_eq(TalentBonuses.resolve({}, tree), {})
	var b := TalentBonuses.resolve({&"talent_sharp_core": 3, &"talent_quick_pulse": 2, &"talent_hardened_shell": 5,
			&"talent_piercing_ray": 1, &"talent_seed_charge": 2, &"talent_golden_core": 3}, tree)
	assert_almost_eq(float(b[&"stat_damage"]), 0.14, 0.0001) # raiz com Nv 1 dobrado (T-209)
	assert_almost_eq(float(b[&"stat_fire_rate"]), 0.06, 0.0001)
	assert_almost_eq(float(b[&"stat_core_hp_max"]), 0.2, 0.0001)
	assert_almost_eq(float(b[&"stat_pierce"]), 1.0, 0.0001)
	assert_almost_eq(float(b[&"stat_start_particles"]), 6.0, 0.0001)
	assert_false(b.has(&"stat_coin_gain"))
	assert_false(b.has(&"stat_skill_damage"))


func test_hp_sum_and_caps() -> void:
	var full := {}
	for t in tree.talents:
		full[t.id] = t.max_level()
	var b := TalentBonuses.resolve(full, tree)
	assert_almost_eq(float(b[&"stat_core_hp_max"]), 0.35, 0.0001)
	assert_lte(float(b[&"stat_core_hp_max"]), 0.4)
	assert_lte(float(b[&"stat_damage_taken"]), 0.5)
	assert_lte(float(b[&"stat_cooldown"]), 0.5)
	assert_eq(float(TalentBonuses.CAPS[&"stat_core_hp_max"]), 0.4)
	# o teto corta de fato
	var cap_tree := TalentTree.new()
	var td := TalentData.new()
	td.id = &"talent_x"
	td.stat = &"stat_cooldown"
	td.values = PackedFloat32Array([0.7])
	td.costs = PackedInt32Array([1])
	cap_tree.talents.append(td)
	assert_almost_eq(float(TalentBonuses.resolve({&"talent_x": 1}, cap_tree)[&"stat_cooldown"]), 0.5, 0.0001)


func test_coin_gain_order() -> void:
	var rew: RewardData = load(REW)
	var r := MatchResult.new()
	r.outcome = MatchResult.Outcome.DEFEAT
	r.set("kills_by_type", {&"enemy_runner": 27})
	var base := MetaRewards.compute(r, rew, false)
	var g := MetaTalents.coin_gain({&"talent_golden_core": 3}, tree)
	assert_almost_eq(g, 0.15, 0.0001)
	var o := MetaRewards.compute(r, rew, false, g)
	assert_eq(o["coins"], roundi(int(base["coins"]) * 1.15))
	# vitória com bônus do dia: o ganho não multiplica o bônus
	r.outcome = MatchResult.Outcome.VICTORY
	var v0 := MetaRewards.compute(r, rew, true)
	var v1 := MetaRewards.compute(r, rew, true, 0.15)
	var no_bonus := MetaRewards.compute(r, rew, false, 0.15)
	assert_eq(v1["coins"], no_bonus["coins"] + rew.first_win_bonus_coins)
	assert_gt(v1["coins"], v0["coins"])


func test_settle_applies_coin_gain() -> void:
	var rew: RewardData = load(REW)
	var prog: ProgressionData = load("res://data/meta/progression_m2.tres")
	var r := MatchResult.new()
	r.outcome = MatchResult.Outcome.VICTORY
	r.set("kills_by_type", {&"enemy_runner": 100})
	var a := PlayerProfile.new()
	var b := PlayerProfile.new()
	b.talents = {&"talent_golden_core": 3}
	var sa := MetaFlow.settle(a, r, rew, prog, "2026-11-06", tree)
	var sb := MetaFlow.settle(b, r, rew, prog, "2026-11-06", tree)
	assert_gt(sb["coins"], sa["coins"])
