extends GutTest
## T-200 (BRF-144): hangar no SceneFlow (abrir destino, "Em breve", voltar, cache, volta da partida em Jogar).

const DUMMY_MENU := "res://tests/integration/fixtures/dummy_menu.tscn"

var _old_provider: BackendProvider
var _old_menu := ""


class MemoryProvider extends BackendProvider:
	func save_profile(_p: PlayerProfile) -> bool:
		return true


func before_all() -> void:
	_old_provider = Backend.provider
	Backend.provider = MemoryProvider.new()
	_old_menu = SceneFlow.menu_scene_path
	SceneFlow.menu_scene_path = DUMMY_MENU
	SceneFlow.load_profile()


func after_all() -> void:
	Backend.provider = _old_provider
	SceneFlow.menu_scene_path = _old_menu
	SceneFlow.profile = null
	get_tree().paused = false
	var current := get_tree().current_scene
	if current != null and current.get_parent() == get_tree().root:
		current.queue_free()


func _open_hangar() -> HangarHost:
	SceneFlow.go_to_menu()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	return get_tree().current_scene as HangarHost


func test_hangar_opens_on_play_with_menu() -> void:
	var host := await _open_hangar()
	assert_not_null(host, "cena atual é o hangar")
	assert_eq(SceneFlow.current_tab, HangarNav.PLAY)
	assert_eq(host.cached_count(), 1, "só Jogar carregado")
	assert_eq(SceneFlow.hangar_tab_node(HangarNav.PLAY).scene_file_path, DUMMY_MENU)


func test_open_tab_coming_soon_back_and_cache() -> void:
	var host := await _open_hangar()
	watch_signals(SceneFlow)
	var play := SceneFlow.hangar_tab_node(HangarNav.PLAY)
	assert_true(SceneFlow.open_hangar_tab(HangarNav.MODULES))
	assert_signal_emitted_with_parameters(SceneFlow, "hangar_tab_changed", [HangarNav.MODULES])
	assert_eq(SceneFlow.current_tab, HangarNav.MODULES)
	var soon := SceneFlow.hangar_tab_node(HangarNav.MODULES) as ComingSoonScreen
	assert_not_null(soon, "cena inexistente cai no Em breve (T-207: Núcleos tem tela própria)")
	assert_eq(soon.title_text, "Módulos")
	assert_false(play.visible, "Jogar oculto")
	assert_false(SceneFlow.open_hangar_tab(HangarNav.MODULES), "já está no destino")
	assert_false(SceneFlow.open_hangar_tab(&"x"), "id inválido")
	soon.back_requested.emit()
	assert_eq(SceneFlow.current_tab, HangarNav.PLAY, "Voltar do Em breve")
	assert_same(SceneFlow.hangar_tab_node(HangarNav.PLAY), play, "mesma instância do menu")
	assert_true(play.visible)
	SceneFlow.open_hangar_tab(HangarNav.MODULES)
	assert_same(SceneFlow.hangar_tab_node(HangarNav.MODULES), soon, "cache do destino")
	assert_eq(host.cached_count(), 2)
	assert_false(SceneFlow.hangar_back() and SceneFlow.hangar_back(), "voltar até Jogar e parar")


func test_back_from_match_lands_on_play() -> void:
	await _open_hangar()
	SceneFlow.open_hangar_tab(HangarNav.SETTINGS)
	SceneFlow.hangar_tab_node(HangarNav.PLAY).play_pressed.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := SceneFlow.current_arena() as Arena
	assert_not_null(arena, "Jogar → Partida")
	if arena == null:
		return
	assert_null(SceneFlow.hangar_tab_node(HangarNav.PLAY), "hangar liberado na partida")
	assert_false(SceneFlow.open_hangar_tab(HangarNav.CORES), "sem hangar aberto")
	var pause: PauseScreen = get_tree().current_scene.get_children().filter(func(n: Node) -> bool: return n is PauseScreen)[0]
	pause.menu_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_eq(SceneFlow.current_tab, HangarNav.PLAY, "volta da partida em Jogar")
	assert_true(SceneFlow.hangar_nav.history.is_empty())
	assert_eq((get_tree().current_scene as HangarHost).cached_count(), 1)
