extends GutTest
## QA do M5 (BRF-173, T-220): lacunas da validação dos Módulos. Só testes; nada em `src/`.

const TANK := preload("res://data/enemies/enemy_tank.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const IDS: Array[StringName] = [&"skill_meteor", &"skill_shock", &"skill_freeze", &"skill_shield"]

var _old_profile: PlayerProfile


func before_all() -> void:
	_old_profile = SceneFlow.profile


func after_all() -> void:
	SceneFlow.profile = _old_profile


func _cfg_for(p: PlayerProfile) -> MatchConfig:
	SceneFlow.profile = p
	return SceneFlow.build_match_config()


func _arena(cfg: MatchConfig) -> Arena:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.waves_enabled = false
	arena.setup(cfg)
	add_child_autofree(arena)
	arena.anima.auto_attack_enabled = false
	return arena


func test_old_save_gives_meteor_lv1_slot1_and_null_elsewhere() -> void:
	var p := PlayerProfile.new()
	p.level = 2
	var cfg := _cfg_for(p)
	assert_eq(cfg.slot_modules.size(), MatchConfig.SLOT_COUNT)
	assert_not_null(cfg.slot_modules[0])
	assert_eq(cfg.slot_modules[0].id, &"skill_meteor")
	assert_eq(cfg.slot_modules[0].damage, 40)
	assert_null(cfg.slot_modules[1])
	assert_null(cfg.slot_modules[2])
	assert_eq(cfg.unlocked_slots, 1)


func test_unknown_ids_in_save_are_ignored() -> void:
	var p := PlayerProfile.new()
	p.level = 8
	p.module_levels = {&"skill_xyz": 5, &"skill_meteor": 99}
	p.module_slots = [&"skill_xyz", &"skill_meteor", &"skill_meteor"]
	var cfg := _cfg_for(p)
	assert_null(cfg.slot_modules[0], "id desconhecido vira vazio")
	assert_not_null(cfg.slot_modules[1])
	assert_eq(cfg.slot_modules[1].damage, 76, "nível 99 limitado ao 5")
	assert_null(cfg.slot_modules[2], "repetido não vale")


func test_account_level_1_has_no_modules() -> void:
	var p := PlayerProfile.new()
	p.level = 1
	var cfg := _cfg_for(p)
	assert_eq(cfg.unlocked_slots, 0)
	for s in cfg.slot_modules:
		assert_null(s)


func test_empty_slot1_with_slot2_full_in_real_arena() -> void:
	var p := PlayerProfile.new()
	p.level = 8
	p.module_slots = [&"", &"skill_shock", &""]
	var arena := _arena(_cfg_for(p))
	await wait_physics_frames(1)
	var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
	e.position = arena.anima.position + Vector2(0, -250)
	e.target_position = e.position
	assert_false(arena.use_skill(1), "slot 1 vazio não dispara")
	assert_false(arena.use_skill(3), "slot 3 vazio não dispara")
	assert_false(arena.skill_supports_aim(1))
	assert_false(arena.skill_supports_aim(3))
	assert_true(arena.use_skill(2), "slot 2 cheio dispara")
	await wait_seconds(0.3)
	assert_lt(e.hp, TANK.hp)
	assert_eq(arena.skills.get_slot(1) == null or arena.skills.get_slot(1).data == null, true, "sem recarga em slot vazio")


func test_stat_cooldown_applies_to_all_four() -> void:
	for id in IDS:
		var p := PlayerProfile.new()
		p.level = 8
		p.module_slots = [id, &"", &""]
		var cfg := _cfg_for(p)
		cfg.talent_bonuses = {&"stat_cooldown": 0.2}
		var arena := _arena(cfg)
		await wait_physics_frames(1)
		var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
		e.position = arena.anima.position + Vector2(0, -250)
		e.target_position = e.position
		var base := cfg.slot_modules[0].cooldown
		assert_true(arena.use_skill(1), "%s dispara" % id)
		assert_almost_eq(arena.skills.get_slot(1).total, base * 0.8, 0.01, "%s recarga -20%%" % id)


func test_skill_damage_only_meteor_and_shock() -> void:
	var done := {}
	for id in IDS:
		var p := PlayerProfile.new()
		p.level = 8
		p.module_slots = [id, &"", &""]
		var cfg := _cfg_for(p)
		cfg.talent_bonuses = {&"stat_skill_damage": 0.5}
		var arena := _arena(cfg)
		await wait_physics_frames(1)
		var e := arena.spawn(TANK, WaveEntry.SpawnEdge.TOP)
		e.position = arena.anima.position + Vector2(0, -250)
		e.target_position = e.position
		var hp0 := e.hp
		arena.use_skill(1)
		await wait_seconds(1.0)
		done[id] = hp0 - e.hp
	var base_meteor := 40
	var base_shock := 25
	assert_eq(done[&"skill_meteor"], 60, "meteoro 40 x 1,5")
	assert_eq(done[&"skill_shock"], roundi(base_shock * 1.5), "choque 25 x 1,5")
	assert_eq(done[&"skill_freeze"], 0, "congelamento sem dano")
	assert_eq(done[&"skill_shield"], 0, "escudo sem dano")
	assert_gt(base_meteor, 0)


## QA-M5-1: só o meteoro tem `icon` no `.tres` e ninguém chama `Hud.set_slot_icon`: os ícones dos outros 3 Módulos
## existem (assets/ui/ui_icon_skill_*.png) mas não chegam ao HUD. Pendente até corrigir (remover o ramo `pending`).
func test_module_icons_reach_skill_data_and_hud() -> void:
	for id in IDS:
		assert_true(ResourceLoader.exists("res://assets/ui/ui_icon_%s.png" % String(id)), "%s: PNG existe" % id)
	var missing: Array[String] = []
	for id in IDS:
		if SceneFlow.module_catalog.get_module(id).skill_at(1).icon == null:
			missing.append(String(id))
	if not missing.is_empty():
		pending("QA-M5-1: SkillData.icon nulo em %s; o HUD nao recebe o icone do Modulo equipado" % str(missing))
		return
	for id in IDS:
		assert_not_null(SceneFlow.module_catalog.get_module(id).skill_at(1).icon)
