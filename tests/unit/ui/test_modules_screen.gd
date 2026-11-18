extends GutTest
## T-216/T-217 (BRF-168): tela de Módulos. Estados por perfil (NV 1, 2, 5, 8), evoluir, valores por nível,
## equipar/desequipar/repetido/slot bloqueado, persistência e a partida usando os Módulos escolhidos.

const SCREEN := preload("res://src/ui/screens/modules_screen.tscn")
const CAT := preload("res://data/skills/module_catalog.tres")
const PROG := preload("res://data/meta/progression_m2.tres")
const METEOR := &"skill_meteor"
const SHOCK := &"skill_shock"
const FREEZE := &"skill_freeze"
const SHIELD := &"skill_shield"

var _saves := 0


func before_each() -> void:
	_saves = 0


func _profile(level: int, coins: int = 0, levels: Dictionary = {}, slots: Array = []) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.level = level
	p.coins = coins
	p.module_levels = levels
	p.module_slots = slots
	return p


func _save(_p: PlayerProfile) -> bool:
	_saves += 1
	return true


func _screen(p: PlayerProfile) -> ModulesScreen:
	var s: ModulesScreen = SCREEN.instantiate()
	s.setup(p, CAT, PROG.slot_unlock_levels, _save)
	add_child_autofree(s)
	await wait_process_frames(2)
	return s


func _state(p: PlayerProfile, id: StringName) -> ModulesScreen.ModState:
	return ModulesScreen.module_state(p, CAT, id)


func _eq(p: PlayerProfile) -> Array[StringName]:
	return MetaModules.equipped(p, CAT, PROG.slot_unlock_levels)


func test_states_by_profile() -> void:
	var p1 := _profile(1)
	for id in [METEOR, SHOCK, FREEZE, SHIELD]:
		assert_eq(_state(p1, id), ModulesScreen.ModState.LOCKED, "NV 1 bloqueia tudo")
	var p2 := _profile(2, 100)
	assert_eq(_state(p2, METEOR), ModulesScreen.ModState.NO_COINS, "250 > 100")
	assert_eq(_state(p2, SHOCK), ModulesScreen.ModState.LOCKED)
	var p5 := _profile(5, 300)
	assert_eq(_state(p5, METEOR), ModulesScreen.ModState.NORMAL)
	assert_eq(_state(p5, FREEZE), ModulesScreen.ModState.NORMAL)
	assert_eq(_state(p5, SHIELD), ModulesScreen.ModState.LOCKED)
	var p8 := _profile(8, 0, {METEOR: 5})
	assert_eq(_state(p8, METEOR), ModulesScreen.ModState.MAX)
	assert_eq(_state(p8, SHIELD), ModulesScreen.ModState.NO_COINS)


func test_list_texts_and_lock_levels() -> void:
	var s := await _screen(_profile(2, 0))
	assert_eq(s._rows.size(), 4)
	assert_eq((s._rows[METEOR].get_node(^"H/Texts/Name") as Label).text, "Meteoro")
	assert_eq((s._rows[METEOR].get_node(^"H/Texts/Info") as Label).text, "Nv 1/5 · no slot 1")
	assert_eq((s._rows[METEOR].get_node(^"H/State") as Label).text, "LIBERADO")
	assert_eq((s._rows[SHOCK].get_node(^"H/State") as Label).text, "NV 5")
	assert_eq((s._rows[SHIELD].get_node(^"H/State") as Label).text, "NV 8")
	assert_eq(s.selected, METEOR)


func test_detail_values_current_and_next() -> void:
	var s := await _screen(_profile(2, 300))
	assert_eq(s.upgrade_button.text, "EVOLUIR · 250")
	assert_false(s.upgrade_button.disabled)
	assert_eq(s._stat_labels[0].text, "Dano: 40 → 48")
	assert_eq(s._stat_labels[1].text, "Raio: 160 → 166")
	assert_eq(s._stat_labels[2].text, "Recarga: 10 s")
	s.select(SHOCK)
	assert_eq(s.detail_sub.text, "NV 5")
	assert_true(s.upgrade_button.disabled)
	assert_eq(s.detail_need.text, "Libera no NV 5")
	assert_eq(s._stat_labels[0].text, "Dano: 25", "bloqueado mostra só o Nv 1")


func test_stat_lines_per_module() -> void:
	var f := ModulesScreen.stat_lines(CAT.get_module(FREEZE), 1)
	assert_eq(f.size(), 3)
	assert_eq(f[1]["cur"], "2 s")
	assert_eq(f[1]["next"], "2,3 s")
	var sh := ModulesScreen.stat_lines(CAT.get_module(SHIELD), 5)
	assert_eq(sh[0]["cur"], "125")
	assert_eq(sh[0]["next"], "", "no máximo não há próximo")
	assert_eq(ModulesScreen.stat_lines(CAT.get_module(SHOCK), 1).size(), 5)


func test_upgrade_spends_saves_and_maxes() -> void:
	var p := _profile(2, 6000)
	var s := await _screen(p)
	assert_true(s.upgrade_selected())
	assert_eq(p.coins, 5750)
	assert_eq(MetaModules.level(p, CAT, METEOR), 2)
	assert_eq(_saves, 1)
	assert_eq(s.coins_label.text, MenuScreen.format_number(5750))
	assert_eq(s.detail_sub.text, "Nv 2/5")
	assert_eq(s.upgrade_button.text, "EVOLUIR · 600")
	for i in 3:
		assert_true(s.upgrade_selected())
	assert_eq(MetaModules.level(p, CAT, METEOR), 5)
	assert_eq(s.upgrade_button.text, "NÍVEL MÁXIMO")
	assert_true(s.upgrade_button.disabled)
	assert_false(s.upgrade_selected())
	assert_eq(_saves, 4)


func test_upgrade_without_coins_is_all_or_nothing() -> void:
	var p := _profile(2, 249)
	var s := await _screen(p)
	assert_true(s.upgrade_button.disabled)
	assert_eq(s.detail_need.text, "Faltam 1 Moedas")
	assert_false(s.upgrade_selected())
	assert_eq(p.coins, 249)
	assert_eq(MetaModules.level(p, CAT, METEOR), 1)
	assert_eq(_saves, 0)


func test_slot_states_by_level() -> void:
	var s1 := await _screen(_profile(1))
	assert_eq(ModulesScreen.slot_state(s1.profile, CAT, PROG.slot_unlock_levels, 1), &"locked")
	assert_eq(s1.slot_buttons[0].text, "SLOT 1\nNV 2")
	var s2 := await _screen(_profile(2))
	assert_eq(s2.slot_buttons[0].text, "SLOT 1\nMeteoro")
	assert_eq(s2.slot_buttons[1].text, "SLOT 2\nNV 5")
	var s5 := await _screen(_profile(5, 0, {}, [&"", &"", &""]))
	assert_eq(s5.slot_buttons[0].text, "SLOT 1\nvazio")
	assert_eq(s5.slot_buttons[2].text, "SLOT 3\nNV 8")
	var s8 := await _screen(_profile(8))
	assert_eq(ModulesScreen.slot_state(s8.profile, CAT, PROG.slot_unlock_levels, 3), &"filled")


func test_equip_swap_unequip_and_persist() -> void:
	var p := _profile(5)
	var s := await _screen(p)
	s.select(FREEZE)
	assert_true(s.press_slot(2), "equipa o escolhido no slot 2")
	assert_eq(_eq(p)[1], FREEZE)
	assert_eq(s.slot_buttons[1].text, "SLOT 2\nCongelamento")
	assert_eq(s.hint_label.text, "Congelamento equipado no slot 2.")
	assert_eq(_saves, 1)
	assert_true(s.press_slot(2), "tocar de novo desequipa")
	assert_eq(_eq(p)[1], &"")
	assert_eq(s.hint_label.text, "Slot 2 esvaziado.")
	s.select(SHOCK)
	assert_true(s.press_slot(1), "troca o Meteoro do slot 1 pelo Choque")
	assert_eq(_eq(p)[0], SHOCK)
	assert_eq(p.module_slots[0], SHOCK, "salvo no perfil")


func test_duplicate_is_refused_with_reason() -> void:
	var p := _profile(5)
	var s := await _screen(p)
	s.select(METEOR)
	assert_false(s.press_slot(2), "Meteoro já está no slot 1")
	assert_eq(s.hint_label.text, "Meteoro já está no slot 1. Toque nele para esvaziar.")
	assert_eq(_eq(p)[0], METEOR)
	assert_eq(_saves, 0)


func test_locked_slot_and_locked_module_are_refused() -> void:
	var p := _profile(2)
	var s := await _screen(p)
	assert_false(s.press_slot(2))
	assert_eq(s.hint_label.text, "Este slot libera no NV 5.")
	s.select(SHOCK)
	assert_false(s.press_slot(1))
	assert_eq(s.hint_label.text, "Choque libera no NV 5.")
	assert_eq(_eq(p)[0], METEOR)


func test_match_uses_equipped_modules_with_levels() -> void:
	var p := _profile(8, 0, {SHOCK: 3})
	var s := await _screen(p)
	s.select(SHIELD)
	s.press_slot(3)
	var flow: Node = get_node("/root/SceneFlow")
	var saved: PlayerProfile = flow.profile
	flow.profile = p
	var cfg: MatchConfig = flow.build_match_config()
	flow.profile = saved
	assert_eq(cfg.slot_modules[1].id, SHOCK)
	assert_eq(cfg.slot_modules[1].damage, 36, "valores do Nv 3")
	assert_eq(cfg.slot_modules[2].id, SHIELD)


func test_empty_slot_gives_null_in_match() -> void:
	var p := _profile(5)
	var s := await _screen(p)
	s.select(METEOR)
	s.press_slot(1)
	var skills := MetaModules.match_skills(p, CAT, PROG.slot_unlock_levels)
	assert_null(skills[0])
	assert_not_null(skills[1])


func test_touch_targets_at_375() -> void:
	var s := await _screen(_profile(8, 5000))
	var k := 375.0 / 720.0
	for b: Button in [s.upgrade_button, s.slot_buttons[0]]:
		assert_gte(b.custom_minimum_size.y * k, 64.0, "alvo de toque %s" % b.name)
	# Linha da lista: em retrato 126 px (>= 64 de tela); em janela larga (desktop, mouse) 108 px para caberem as 4 (BRF-174).
	var view := s.get_viewport_rect().size
	var row_h: float = s._rows[METEOR].custom_minimum_size.y
	assert_eq(row_h, ModulesScreen.ROW_H_WIDE if view.x > view.y else ModulesScreen.BTN_H)
	assert_gte(ModulesScreen.BTN_H * k, 64.0, "linha em retrato")
