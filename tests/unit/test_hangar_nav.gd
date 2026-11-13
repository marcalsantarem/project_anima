extends GutTest
## T-200 (BRF-144): navegação do hangar, lógica pura (ids, mapa, voltar) e cache do HangarHost.


func test_ids_and_map() -> void:
	assert_eq(HangarNav.TABS.size(), 5)
	for id in HangarNav.TABS:
		assert_true(HangarNav.is_valid(id))
		assert_ne(HangarNav.title_of(id), "", "título de %s" % id)
		assert_true(HangarNav.new().scene_path(id).begins_with("res://"), "caminho de %s" % id)
	assert_false(HangarNav.is_valid(&"nao_existe"))
	assert_eq(HangarNav.title_of(HangarNav.CORES), "Núcleos")
	assert_eq(HangarNav.new().current, HangarNav.PLAY, "começa em Jogar")


func test_open_and_back() -> void:
	var nav := HangarNav.new()
	assert_false(nav.open(HangarNav.PLAY), "já está em Jogar")
	assert_false(nav.open(&"x"), "id inválido")
	assert_true(nav.open(HangarNav.CORES))
	assert_true(nav.open(HangarNav.MODULES))
	assert_eq(nav.history, [HangarNav.PLAY, HangarNav.CORES] as Array[StringName])
	assert_true(nav.back())
	assert_eq(nav.current, HangarNav.CORES, "volta ao anterior")
	assert_true(nav.back())
	assert_eq(nav.current, HangarNav.PLAY)
	assert_false(nav.back(), "em Jogar sem histórico")


func test_history_without_duplicates_and_play_clears() -> void:
	var nav := HangarNav.new()
	nav.open(HangarNav.CORES)
	nav.open(HangarNav.MODULES)
	nav.open(HangarNav.CORES)
	assert_eq(nav.history, [HangarNav.PLAY, HangarNav.MODULES] as Array[StringName], "sem duplicatas")
	nav.open(HangarNav.PLAY)
	assert_true(nav.history.is_empty(), "Jogar limpa o histórico")
	nav.open(HangarNav.SETTINGS)
	nav.history.clear()
	assert_true(nav.back(), "sem histórico fora de Jogar volta a Jogar")
	assert_eq(nav.current, HangarNav.PLAY)


func test_reset() -> void:
	var nav := HangarNav.new()
	nav.open(HangarNav.COMPONENTS)
	nav.reset()
	assert_eq(nav.current, HangarNav.PLAY)
	assert_true(nav.history.is_empty())


func test_host_loads_on_demand_and_caches() -> void:
	var host := HangarHost.new()
	add_child_autofree(host)
	var made := [0]
	var factory := func() -> Control:
		made[0] += 1
		return Control.new()
	assert_eq(host.cached_count(), 0, "nada carregado no início")
	var a := host.show_screen(HangarNav.PLAY, factory)
	var b := host.show_screen(HangarNav.CORES, factory)
	assert_eq(made[0], 2)
	assert_false(a.visible, "anterior oculta")
	assert_eq(a.process_mode, Node.PROCESS_MODE_DISABLED, "anterior sem processar")
	assert_true(b.visible)
	a.set_meta(&"state", 42)
	var again := host.show_screen(HangarNav.PLAY, factory)
	assert_eq(made[0], 2, "2ª visita não recria")
	assert_same(again, a, "mesma instância (estado preservado)")
	assert_eq(again.get_meta(&"state"), 42)
	assert_true(a.visible)
	assert_false(b.visible)
	assert_eq(host.screen(HangarNav.MODULES), null)
