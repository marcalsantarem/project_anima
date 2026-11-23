extends GutTest
## T-213: evolução e equipamento dos Módulos (BRF-166).

const CAT_PATH := "res://data/skills/module_catalog.tres"
var SLOTS := PackedInt32Array([2, 5, 8])
const M := &"skill_meteor"
const SH := &"skill_shock"
const FR := &"skill_freeze"
const SD := &"skill_shield"

var cat: ModuleCatalog


func before_each() -> void:
	cat = load(CAT_PATH)


func _p(level: int, coins := 0) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.level = level
	p.coins = coins
	return p


func test_catalog_valid_and_total_cost() -> void:
	assert_eq(cat.validate().size(), 0, str(cat.validate()))
	assert_eq(cat.modules.size(), 4)
	var total := 0
	for m in cat.modules:
		assert_eq(m.total_cost(), 4800)
		total += m.total_cost()
	assert_eq(total, 19200)


func test_level1_equals_base_tres() -> void:
	for m in cat.modules:
		var s := m.skill_at(1)
		assert_eq(s.damage, m.base.damage, str(m.module_id))
		assert_eq(s.radius, m.base.radius, str(m.module_id))
		assert_eq(s.cooldown, m.base.cooldown, str(m.module_id))
		assert_eq(s.duration, m.base.duration, str(m.module_id))
		assert_eq(s.effect_params, m.base.effect_params, str(m.module_id))


func test_values_per_level() -> void:
	var meteor := cat.get_module(M)
	assert_eq(meteor.skill_at(5).damage, 76)
	assert_eq(meteor.skill_at(5).cooldown, 8.0)
	var shock := cat.get_module(SH).skill_at(5)
	assert_eq(shock.effect_params["jumps"], 5)
	assert_eq(shock.effect_params["falloff"], 0.88)
	var freeze := cat.get_module(FR).skill_at(3)
	assert_eq(freeze.duration, 2.6)
	assert_eq(freeze.effect_params["boss_frozen"], false)
	var shield := cat.get_module(SD).skill_at(4)
	assert_eq(shield.effect_params["absorb"], 100)
	assert_eq(shield.duration, 4.5)


func test_skill_at_does_not_change_loaded_resource() -> void:
	var meteor := cat.get_module(M)
	var base_damage := meteor.base.damage
	var shock := cat.get_module(SH)
	var base_params: Dictionary = shock.base.effect_params.duplicate(true)
	meteor.skill_at(5)
	shock.skill_at(5)
	assert_eq(meteor.base.damage, base_damage)
	assert_eq(shock.base.effect_params, base_params)


func test_unlock_by_account_level() -> void:
	assert_false(MetaModules.unlocked(_p(1), cat, M))
	assert_eq(MetaModules.level(_p(1), cat, M), 0)
	assert_eq(MetaModules.level(_p(2), cat, M), 1)
	assert_false(MetaModules.unlocked(_p(4), cat, SH))
	assert_eq(MetaModules.level(_p(5), cat, SH), 1)
	assert_eq(MetaModules.level(_p(5), cat, FR), 1)
	assert_eq(MetaModules.level(_p(7), cat, SD), 0)
	assert_eq(MetaModules.level(_p(8), cat, SD), 1)
	assert_eq(MetaModules.level(_p(30), cat, &"skill_x"), 0)


func test_exact_cost_per_level_and_total_4800() -> void:
	var p := _p(2, 4800)
	var expected := [250, 600, 1300, 2650]
	for i in 4:
		assert_eq(MetaModules.next_cost(p, cat, M), expected[i])
		var r := MetaModules.upgrade(p, cat, M)
		assert_true(r["ok"])
		assert_eq(r["cost"], expected[i])
		assert_eq(r["level"], i + 2)
	assert_eq(p.coins, 0)
	assert_eq(MetaModules.level(p, cat, M), 5)
	assert_eq(MetaModules.spent_coins(p, cat), 4800)
	assert_eq(MetaModules.next_cost(p, cat, M), 0)


func test_upgrade_reasons_and_all_or_nothing() -> void:
	var p := _p(2, 249)
	assert_eq(MetaModules.can_upgrade(p, cat, M), MetaModules.Reason.NO_COINS)
	var r := MetaModules.upgrade(p, cat, M)
	assert_false(r["ok"])
	assert_eq(p.coins, 249)
	assert_eq(MetaModules.level(p, cat, M), 1)
	assert_eq(MetaModules.can_upgrade(p, cat, SH), MetaModules.Reason.LOCKED)
	assert_eq(MetaModules.can_upgrade(p, cat, &"x"), MetaModules.Reason.UNKNOWN)
	p.coins = 100000
	p.module_levels[M] = 5
	assert_eq(MetaModules.can_upgrade(p, cat, M), MetaModules.Reason.MAX)
	assert_false(MetaModules.upgrade(p, cat, M)["ok"])
	assert_eq(p.coins, 100000)


func test_no_modules_beyond_unlocked() -> void:
	var p := _p(1)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [&"", &"", &""])
	p = _p(2)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, &"", &""])
	p = _p(5)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, SH, &""])
	p = _p(8)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, SH, FR])


func test_equip_validation() -> void:
	var p := _p(5)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 2, FR), MetaModules.EquipReason.OK)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, FR, &""])
	assert_eq(MetaModules.equip(p, cat, SLOTS, 1, FR), MetaModules.EquipReason.ALREADY_EQUIPPED)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 2, FR), MetaModules.EquipReason.OK)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 3, SH), MetaModules.EquipReason.SLOT_LOCKED)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 1, SD), MetaModules.EquipReason.LOCKED)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 1, &"x"), MetaModules.EquipReason.UNKNOWN)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 4, M), MetaModules.EquipReason.BAD_SLOT)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 0, M), MetaModules.EquipReason.BAD_SLOT)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, FR, &""])


func test_unequip_and_swap() -> void:
	var p := _p(5)
	assert_true(MetaModules.unequip(p, cat, SLOTS, 1))
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [&"", SH, &""])
	assert_false(MetaModules.unequip(p, cat, SLOTS, 1))
	assert_eq(MetaModules.equip(p, cat, SLOTS, 1, SH), MetaModules.EquipReason.ALREADY_EQUIPPED)
	assert_true(MetaModules.unequip(p, cat, SLOTS, 2))
	assert_eq(MetaModules.equip(p, cat, SLOTS, 1, SH), MetaModules.EquipReason.OK)
	assert_eq(MetaModules.equip(p, cat, SLOTS, 2, M), MetaModules.EquipReason.OK)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [SH, M, &""])


func test_customization_survives_new_unlocks() -> void:
	var p := _p(5)
	MetaModules.unequip(p, cat, SLOTS, 2)
	p.level = 8
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, &"", &""])


func test_match_skills_have_level_values() -> void:
	var p := _p(5)
	p.module_levels[M] = 3
	p.module_levels[SH] = 5
	var skills := MetaModules.match_skills(p, cat, SLOTS)
	assert_eq(skills.size(), 3)
	assert_eq(skills[0].id, M)
	assert_eq(skills[0].damage, 57)
	assert_eq(skills[1].id, SH)
	assert_eq(skills[1].damage, 46)
	assert_null(skills[2])
	assert_ne(skills[0], cat.get_module(M).base, "copia, nao o recurso carregado")


# --- save ---

func test_old_save_migrates_to_meteor_slot1() -> void:
	var p := PlayerProfile.from_dict({"level": 2, "xp": 10, "coins": 5})
	p.sanitize()
	assert_eq(p.module_levels, {})
	assert_eq(p.module_slots, [])
	assert_eq(MetaModules.level(p, cat, M), 1)
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [M, &"", &""])
	assert_true(PlayerProfile.is_valid_dict({"level": 2, "coins": 5}))


func test_roundtrip_via_json() -> void:
	var p := _p(8, 5000)
	MetaModules.upgrade(p, cat, SD)
	MetaModules.equip(p, cat, SLOTS, 1, SD)
	MetaModules.equip(p, cat, SLOTS, 3, M)
	var json := JSON.new()
	json.parse(JSON.stringify(p.to_dict()))
	var q := PlayerProfile.from_dict(json.data)
	q.sanitize()
	assert_eq(MetaModules.level(q, cat, SD), 2)
	assert_eq(MetaModules.equipped(q, cat, SLOTS), [SD, SH, M])
	assert_eq(q.coins, 4750)


func test_sanitize_unknown_ids_and_levels() -> void:
	var p := PlayerProfile.from_dict({"level": 8, "module_levels": {"skill_meteor": 99, "skill_shock": -3, "skill_x": 2, "skill_shield": "a"},
		"module_slots": ["skill_x", "skill_meteor", "skill_meteor", "skill_shock", 5]})
	p.sanitize()
	assert_eq(p.module_levels, {M: 5, SH: 1, SD: 1})
	assert_eq(p.module_slots, [&"", M, &""])
	assert_eq(MetaModules.equipped(p, cat, SLOTS), [&"", M, &""])


func test_module_coins_not_refunded_by_talent_respec() -> void:
	var p := _p(8, 250)
	MetaModules.upgrade(p, cat, M)
	var tree: TalentTree = load("res://data/talents/talent_tree.tres")
	MetaTalents.respec(p, tree)
	assert_eq(p.coins, 0)
	assert_eq(MetaModules.level(p, cat, M), 2)


# --- MatchConfig / SceneFlow ---

func test_scene_flow_match_config_uses_levels() -> void:
	var old: PlayerProfile = SceneFlow.profile
	var p := _p(5)
	p.module_levels[SH] = 4
	SceneFlow.profile = p
	var c := SceneFlow.build_match_config()
	SceneFlow.profile = old
	assert_eq(c.unlocked_slots, 2)
	assert_eq(c.slot_modules.size(), 3)
	assert_eq(c.slot_modules[0].id, M)
	assert_eq(c.slot_modules[0].damage, 40)
	assert_eq(c.slot_modules[1].id, SH)
	assert_eq(c.slot_modules[1].damage, 41)
	assert_eq(c.slot_modules[1].effect_params["jumps"], 5)
	assert_null(c.slot_modules[2])
	assert_eq(cat.get_module(SH).base.damage, 25, ".tres carregado intacto")
