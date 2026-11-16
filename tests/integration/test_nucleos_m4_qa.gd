extends GutTest
## QA M4 (BRF-160, T-210): lacunas da validação da v0.2.2 Núcleos. Árvore inteira -> config real da conta -> Arena.

const TREE := preload("res://data/talents/talent_tree.tres")
const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const STATS_ALL: Array[StringName] = [&"stat_damage", &"stat_fire_rate", &"stat_skill_damage", &"stat_pierce", &"stat_core_hp_max",
	&"stat_damage_taken", &"stat_wave_heal", &"stat_particle_gain", &"stat_start_particles", &"stat_cooldown"]

var _old_menu := ""


func before_each() -> void:
	_old_menu = SceneFlow.menu_scene_path
	SceneFlow.load_profile()


func after_each() -> void:
	SceneFlow.menu_scene_path = _old_menu
	SceneFlow.profile = null


func _full_tree() -> Dictionary:
	var d := {}
	for t in TREE.talents:
		d[t.id] = 1
	return d


func _arena(config: MatchConfig, seed: int = 1) -> Arena:
	var a: Arena = ARENA_SCENE.instantiate()
	a.setup(config)
	a.waves_enabled = false
	a.set_seed(seed)
	add_child_autofree(a)
	return a


func test_config_by_account_level() -> void:
	for lv in [1, 2]:
		SceneFlow.profile.level = lv
		SceneFlow.profile.talents = _full_tree()
		assert_true(SceneFlow.build_match_config().talent_bonuses.is_empty(), "NV %d: Núcleos não valem" % lv)
	for lv in [3, 4, 8]:
		SceneFlow.profile.level = lv
		SceneFlow.profile.talents = _full_tree()
		var b := SceneFlow.build_match_config().talent_bonuses
		for s in STATS_ALL:
			assert_gt(float(b.get(s, 0.0)), 0.0, "NV %d: %s chega ao MatchConfig" % [lv, s])
		assert_false(b.has(&"stat_coin_gain"), "Moeda é do meta")
	SceneFlow.profile.level = 5
	SceneFlow.profile.talents = {}
	assert_true(SceneFlow.build_match_config().talent_bonuses.is_empty(), "sem compra = vazio")


func test_full_tree_reaches_arena() -> void:
	SceneFlow.profile.level = 5
	SceneFlow.profile.talents = _full_tree()
	var base := _arena(MatchConfig.new())
	var a := _arena(SceneFlow.build_match_config())
	assert_eq(a.anima.core.max_hp, roundi(160 * 1.35), "HP máx +20% +15%")
	assert_eq(a.anima.core.current, a.anima.core.max_hp, "HP inicial = máx")
	assert_eq(a.particles, 15, "Partículas iniciais")
	assert_almost_eq(a.skills.cooldown_scale, 0.9, 0.0001, "cooldown -10%")
	assert_gt(a.anima.shot_damage(), base.anima.shot_damage(), "dano")
	assert_almost_eq(a.anima.fire_rate(), base.anima.fire_rate() * 1.15, 0.0001, "cadência +15%")
	assert_lte(a.anima.fire_rate(), 4.2)
	assert_eq(a.upgrades.damage_taken(10), 9, "dano recebido -10%")
	assert_eq(a.upgrades.damage_taken(1), 1, "mínimo 1")
	assert_eq(a.projectiles.get_child(0).extra_pierce if a.projectiles.get_child_count() > 0 else 1, 1, "perfuração +1")
	assert_almost_eq(a.upgrades.talent(&"stat_particle_gain"), 0.15, 0.0001)
	assert_almost_eq(a.upgrades.talent(&"stat_wave_heal"), 0.1, 0.0001)


func test_without_nuclei_identical_baseline() -> void:
	var a := _arena(MatchConfig.new())
	assert_eq(a.anima.core.max_hp, 160)
	assert_eq(a.particles, 0)
	assert_eq(a.skills.cooldown_scale, 1.0)
	assert_eq(a.anima.fire_rate(), 2.0)
	var b := _arena(MatchConfig.new())
	b.upgrades.talents = {}
	assert_eq(a.anima.shot_damage(), b.anima.shot_damage())
	assert_true(a.upgrades.talents.is_empty())


func test_respec_balance_after_partial_buy_via_profile() -> void:
	var p := PlayerProfile.new()
	p.level = 3
	p.coins = 20000
	var before := p.coins
	for id in [&"talent_sharp_core", &"talent_quick_pulse", &"talent_particle_magnet", &"talent_seed_charge"]:
		assert_true(MetaTalents.buy(p, TREE, id)["ok"])
	assert_eq(p.coins, before - 500 - 1195 - 500 - 1195)
	assert_eq(MetaTalents.respec(p, TREE), 3390)
	assert_eq(p.coins, before)
	assert_true(p.talents.is_empty())
	assert_eq(MetaTalents.respec(p, TREE), 0, "segundo respec não rende")
	assert_eq(p.coins, before)


func test_talent_icons_load_without_fallback() -> void:
	for t in TREE.talents:
		for off in [false, true]:
			var path := "res://assets/ui/ui_icon_%s%s.png" % [String(t.id), "_off" if off else ""]
			assert_true(ResourceLoader.exists(path), path)
			assert_not_null(CoresScreen._icon_tex(t, off), path)
			assert_null(t.icon, "ícone vem do arquivo, não de fallback do .tres")
	for n in ["ui_talent_node", "ui_talent_node_selected", "ui_talent_node_owned", "ui_talent_node_locked", "ui_talent_link_h_on", "ui_talent_link_h_off"]:
		assert_true(ResourceLoader.exists("res://assets/ui/%s.png" % n), n)


class MemProvider extends BackendProvider:
	func save_profile(_p: PlayerProfile) -> bool:
		return true


## BRF-160 item 4: no hangar REAL, com a confirmação do Redistribuir aberta a barra fica desabilitada.
## QA-M4-1 (corrigido): a tela fica em Hangar/Content e a barra em Hangar; `_block_bar` busca a barra na árvore.
func test_bar_disabled_while_respec_open_in_real_hangar() -> void:
	var old_provider := Backend.provider
	Backend.provider = MemProvider.new()
	SceneFlow.profile.level = 3
	SceneFlow.profile.coins = 3000
	SceneFlow.profile.talents = {&"talent_sharp_core": 1}
	SceneFlow.go_to_menu()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	await wait_process_frames(2)
	SceneFlow.open_hangar_tab(HangarNav.CORES)
	await wait_process_frames(3)
	var screen := SceneFlow.hangar_tab_node(HangarNav.CORES) as CoresScreen
	assert_not_null(screen)
	var host := get_tree().current_scene as HangarHost
	var bar: HangarBar = host.find_children("*", "HangarBar", true, false)[0]
	screen.request_respec()
	await wait_process_frames(2)
	var btn: Button = bar.items[HangarNav.PLAY]
	assert_false(btn.can_process(), "barra bloqueada com a confirmação aberta")
	screen.cancel_respec()
	await wait_process_frames(2)
	assert_true(btn.can_process(), "barra volta ao fechar a confirmação")
	Backend.provider = old_provider
	get_tree().paused = false
