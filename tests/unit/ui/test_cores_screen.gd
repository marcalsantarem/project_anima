extends GutTest
## T-207 (BRF-155): tela de Núcleos. Estados do nó por perfil, detalhe, compra (atualiza a UI e salva),
## respec com confirmação e navegação por Input Actions de UI.

const SCREEN := preload("res://src/ui/screens/cores_screen.tscn")
const TREE := preload("res://data/talents/talent_tree.tres")

var _saves: Array[PlayerProfile] = []


func before_each() -> void:
	_saves.clear()


func _profile(level: int, coins: int, talents: Dictionary = {}) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.level = level
	p.coins = coins
	p.talents = talents
	return p


func _save(p: PlayerProfile) -> bool:
	_saves.append(p)
	return true


func _screen(p: PlayerProfile) -> CoresScreen:
	var s: CoresScreen = SCREEN.instantiate()
	s.setup(p, TREE, _save)
	add_child_autofree(s)
	await wait_process_frames(2)
	return s


func _frame(s: CoresScreen, id: StringName) -> Texture2D:
	var b: Button = s._nodes[id]
	return (b.get_node(^"Frame") as TextureRect).texture


func _chip(s: CoresScreen, id: StringName) -> String:
	var b: Button = s._nodes[id]
	return (b.get_node(^"Chip/Text") as Label).text


func test_node_states_by_profile() -> void:
	var p := _profile(3, 0, {&"talent_sharp_core": 2, &"talent_hardened_shell": 5})
	assert_eq(CoresScreen.node_state(p, TREE, &"talent_sharp_core"), CoresScreen.NodeState.OWNED)
	assert_eq(CoresScreen.node_state(p, TREE, &"talent_hardened_shell"), CoresScreen.NodeState.MAX)
	assert_eq(CoresScreen.node_state(p, TREE, &"talent_particle_magnet"), CoresScreen.NodeState.NORMAL)
	assert_eq(CoresScreen.node_state(p, TREE, &"talent_arcane_burst"), CoresScreen.NodeState.LOCKED)
	assert_eq(CoresScreen.node_state(p, TREE, &"talent_quick_pulse"), CoresScreen.NodeState.NORMAL)


func test_tree_frames_chips_and_links() -> void:
	var s := await _screen(_profile(3, 0, {&"talent_sharp_core": 2, &"talent_hardened_shell": 5}))
	assert_eq(s._nodes.size(), 12)
	assert_eq(s.selected, &"talent_sharp_core", "1º nó selecionado ao abrir")
	assert_eq(_frame(s, &"talent_sharp_core"), CoresScreen.T_NODE_SELECTED)
	assert_eq(_frame(s, &"talent_hardened_shell"), CoresScreen.T_NODE_MAX)
	assert_eq(_frame(s, &"talent_particle_magnet"), CoresScreen.T_NODE)
	assert_eq(_frame(s, &"talent_wave_mend"), CoresScreen.T_NODE_LOCKED)
	assert_eq(_chip(s, &"talent_sharp_core"), "2/5")
	assert_eq(_chip(s, &"talent_golden_core"), "0/3")
	var icon: TextureRect = (s._nodes[&"talent_wave_mend"] as Button).get_node(^"Icon")
	assert_string_contains(icon.texture.resource_path, "_off")
	# 9 ligações verticais + 3 entre ramos; acesa = pré-requisito cumprido.
	assert_eq(s._links.size(), 12)
	for link in s._links:
		var line: Line2D = link["line"]
		var on: bool = MetaTalents.level(s.profile, link["from"]) >= int(link["need"])
		assert_eq(line.texture, CoresScreen.T_LINK_ON if on else CoresScreen.T_LINK_OFF, "ligação %s" % line.name)
	var route := CoresScreen.link_points(Vector2i(0, 1), Vector2i(2, 3))
	assert_eq(route.size(), 5, "quick_pulse → golden_core contorna por fora")


func test_touch_target_is_at_least_64() -> void:
	var s := await _screen(_profile(3, 0))
	for b: Button in s._nodes.values():
		assert_gte(b.size.x, 64.0)
		assert_gte(b.size.y, 64.0)
	assert_gte(s.buy_button.size.y, 64.0)
	assert_gte(s.respec_button.size.y, 64.0)


func test_detail_no_coins() -> void:
	var s := await _screen(_profile(3, 30))
	s.select(&"talent_sharp_core")
	assert_eq(s.detail_name.text, "Núcleo Afiado")
	assert_eq(s.detail_sub.text, "ATAQUE · NV 0/5")
	assert_eq(s.detail_effect.text, "Atual: nenhum  ·  Próximo: +4%")
	assert_eq(s.buy_button.text, "COMPRAR · 50")
	assert_true(s.buy_button.disabled)
	assert_eq(s.detail_need.text, "Faltam 20 Moedas")


func test_detail_prereq_and_max() -> void:
	var s := await _screen(_profile(3, 5000, {&"talent_arcane_burst": 3}))
	s.select(&"talent_piercing_ray")
	assert_true(s.buy_button.disabled)
	assert_eq(s.detail_need.text, "Requer Desvio NV 1")
	s.select(&"talent_deflect")
	assert_eq(s.detail_need.text, "Requer Casca Reforçada NV 1")
	var p := _profile(3, 0, {&"talent_bastion": 1})
	s.setup(p, TREE, _save)
	s.select(&"talent_bastion")
	assert_eq(s.buy_button.text, "MAX")
	assert_true(s.buy_button.disabled)
	assert_eq(s.detail_need.text, "Nível máximo")
	assert_eq(s.detail_effect.text, "Atual: +15%")


func test_effect_text_formats() -> void:
	assert_eq(CoresScreen.effect_text(TREE.get_talent(&"talent_deflect"), 2), "−4%")
	assert_eq(CoresScreen.effect_text(TREE.get_talent(&"talent_seed_charge"), 3), "+9")
	assert_eq(CoresScreen.effect_text(TREE.get_talent(&"talent_piercing_ray"), 1), "+1")
	assert_eq(CoresScreen.effect_text(TREE.get_talent(&"talent_wave_mend"), 5), "+10%")


func test_feature_locked_below_level_3() -> void:
	var s := await _screen(_profile(2, 999))
	assert_true(s.buy_button.disabled)
	assert_eq(s.detail_need.text, "Núcleos liberam no NV 3")
	assert_false(s.buy_selected())
	assert_eq(_saves.size(), 0)


func test_buy_updates_ui_and_saves() -> void:
	var p := _profile(3, 200)
	var s := await _screen(p)
	watch_signals(s)
	s.select(&"talent_sharp_core")
	assert_false(s.buy_button.disabled)
	s.buy_button.pressed.emit()
	assert_eq(MetaTalents.level(p, &"talent_sharp_core"), 1)
	assert_eq(p.coins, 150)
	assert_eq(_saves.size(), 1, "salvou uma vez")
	assert_eq(s.coins_label.text, "150")
	assert_eq(_chip(s, &"talent_sharp_core"), "1/5")
	assert_eq(s.detail_sub.text, "ATAQUE · NV 1/5")
	assert_eq(s.buy_button.text, "COMPRAR · 70")
	assert_signal_emitted(s, "profile_changed")
	# Pré-requisito cumprido: Pulso Veloz desbloqueia e a ligação acende.
	assert_eq(_frame(s, &"talent_quick_pulse"), CoresScreen.T_NODE)
	for link in s._links:
		if link["from"] == &"talent_sharp_core" and link["to"] == &"talent_quick_pulse":
			assert_eq((link["line"] as Line2D).texture, CoresScreen.T_LINK_ON)
	s.select(&"talent_hardened_shell")
	assert_eq(_frame(s, &"talent_sharp_core"), CoresScreen.T_NODE_OWNED)


func test_respec_confirm_refunds_and_saves() -> void:
	var p := _profile(3, 10, {&"talent_sharp_core": 2, &"talent_quick_pulse": 1})
	var s := await _screen(p)
	assert_false(s.respec_button.disabled)
	s.respec_button.pressed.emit()
	assert_true(s.confirm_box.visible)
	assert_eq(s.confirm_label.text, "Devolve 240 Moedas e zera os Núcleos.")
	s.cancel_respec()
	assert_false(s.confirm_box.visible)
	assert_eq(_saves.size(), 0, "cancelar não salva")
	s.respec_button.pressed.emit()
	s.confirm_button.pressed.emit()
	assert_false(s.confirm_box.visible)
	assert_eq(p.coins, 250)
	assert_true(p.talents.is_empty())
	assert_eq(_saves.size(), 1)
	assert_eq(s.coins_label.text, "250")
	assert_true(s.respec_button.disabled, "sem Núcleos comprados")
	assert_eq(_chip(s, &"talent_sharp_core"), "0/5")


func test_respec_disabled_without_talents() -> void:
	var s := await _screen(_profile(3, 100))
	assert_true(s.respec_button.disabled)
	s.request_respec()
	assert_false(s.confirm_box.visible)


func test_keyboard_focus_selects_and_accept_goes_to_buy() -> void:
	var s := await _screen(_profile(3, 500))
	var b: Button = s._nodes[&"talent_hardened_shell"]
	b.grab_focus()
	assert_eq(s.selected, &"talent_hardened_shell", "foco seleciona")
	var ev := InputEventAction.new()
	ev.action = &"ui_accept"
	ev.pressed = true
	s._on_node_input(ev, &"talent_hardened_shell")
	assert_true(s.buy_button.has_focus(), "ui_accept leva ao Comprar")


func test_state_preserved_across_visibility() -> void:
	var p := _profile(3, 500)
	var s := await _screen(p)
	s.select(&"talent_particle_magnet")
	var first: Button = s._nodes[&"talent_particle_magnet"]
	s.visible = false
	p.coins = 42
	s.visible = true
	assert_eq(s.selected, &"talent_particle_magnet")
	assert_same(s._nodes[&"talent_particle_magnet"], first, "não recria a árvore")
	assert_eq(s.coins_label.text, "42", "atualiza ao voltar")
