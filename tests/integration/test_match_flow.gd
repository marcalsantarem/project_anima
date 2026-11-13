extends GutTest
## SceneFlow com as telas e a Arena reais: Título → Menu → Partida → Resultado → Partida ou Menu.
## Menu dummy enquanto a T-190 não entrega a tela; provedor do Backend sem disco (T-187).

const DUMMY_MENU := "res://tests/integration/fixtures/dummy_menu.tscn"

var _old_provider: BackendProvider
var _old_menu := ""


func before_all() -> void:
	_old_provider = Backend.provider
	Backend.provider = MemoryProvider.new()
	_old_menu = SceneFlow.menu_scene_path
	SceneFlow.menu_scene_path = DUMMY_MENU
	SceneFlow.load_profile()


class MemoryProvider extends BackendProvider:
	func save_profile(_p: PlayerProfile) -> bool:
		return true


func after_all() -> void:
	Backend.provider = _old_provider
	SceneFlow.menu_scene_path = _old_menu
	SceneFlow.profile = null
	get_tree().paused = false
	var current := get_tree().current_scene
	if current != null and current.get_parent() == get_tree().root:
		current.queue_free()


func test_default_match_scene_is_arena() -> void:
	assert_true(ResourceLoader.exists(MatchConfig.DEFAULT_MATCH_SCENE))
	assert_true(MatchConfig.new().match_scene_path.ends_with("arena.tscn"))


func test_full_flow_with_real_arena() -> void:
	SceneFlow.go_to_title()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var title := get_tree().current_scene as TitleScreen
	assert_not_null(title, "cena atual é o Título")
	if title == null:
		return

	title.start_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var menu := SceneFlow.hangar_tab_node(HangarNav.PLAY)
	assert_eq(menu.scene_file_path, DUMMY_MENU, "Título → Menu")
	menu.play_pressed.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := SceneFlow.current_arena() as Arena
	assert_not_null(arena, "partida montada com a Arena")
	if arena == null:
		return
	var match_root := get_tree().current_scene
	assert_eq(match_root.get_children().filter(func(n: Node) -> bool: return n is Hud).size(), 1, "HUD montado")
	assert_eq(match_root.get_children().filter(func(n: Node) -> bool: return n is PauseScreen).size(), 1, "Pausa montada")
	assert_eq(arena.config, SceneFlow.last_config, "setup(config) chamado")
	var hud: Hud = match_root.get_children().filter(func(n: Node) -> bool: return n is Hud)[0]
	assert_eq(arena.arena_bottom_inset, hud.tray_height(), "base da Arena = bandeja do HUD")

	var waves_total := arena.stage.waves.size()
	arena.anima.core.take_damage(arena.anima.core.max_hp)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var result := get_tree().current_scene as ResultScreen
	assert_not_null(result, "cena atual é o Resultado")
	assert_eq(SceneFlow.last_result.outcome, MatchResult.Outcome.DEFEAT)
	assert_eq(SceneFlow.last_result.waves_total, waves_total)
	if result == null:
		return

	result.play_again_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_not_null(SceneFlow.current_arena(), "Jogar de novo abre nova partida")


func test_match_wires_fx_pool_and_director() -> void:
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := SceneFlow.current_arena() as Arena
	assert_not_null(arena)
	if arena == null:
		return
	var pool := arena.get_node_or_null(NodePath(SceneFlow.FX_POOL_NODE_NAME)) as FxPool
	var director := get_tree().current_scene.get_node_or_null(NodePath(SceneFlow.FX_DIRECTOR_NODE_NAME)) as FxDirector
	assert_not_null(pool, "FxPool filho da Arena")
	assert_not_null(director, "FxDirector na partida")
	if pool == null or director == null:
		return
	assert_eq(director.pool, pool)
	assert_gt(pool.capacity(&"fx_death"), 0, "pool pré-criado")
	assert_has(director.connected_signals(), &"enemy_died", "director ligado à Arena")
	assert_eq(pool.active_count(&"fx_death"), 0)
	arena.enemy_died.emit(Vector2(360, 400), &"enemy_runner", 0)
	assert_eq(pool.active_count(&"fx_death"), 1, "enemy_died aciona fx_death")


func test_restart_from_pause_starts_new_match() -> void:
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var first := SceneFlow.current_arena()
	var pause: PauseScreen = get_tree().current_scene.get_children().filter(func(n: Node) -> bool: return n is PauseScreen)[0]
	pause.restart_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var second := SceneFlow.current_arena()
	assert_not_null(second)
	assert_ne(second, first, "Recomeçar cria outra Arena")
	assert_false(get_tree().paused, "jogo despausado")


## T-155/T-187: Resultado → "Voltar" → Menu → nova partida, sem vazar a partida anterior.
func test_result_back_to_menu_then_new_match() -> void:
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var first := SceneFlow.current_arena() as Arena
	var first_root := get_tree().current_scene
	assert_not_null(first)
	if first == null:
		return
	first.anima.core.take_damage(first.anima.core.max_hp)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var result := get_tree().current_scene as ResultScreen
	assert_not_null(result, "cena atual é o Resultado")
	if result == null:
		return
	assert_not_null(result.find_child("BackToTitle", true, false), "botão Voltar ao título")
	assert_eq(result.title_requested.get_connections().size(), 1, "title_requested ligado uma vez")

	result.title_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var menu := SceneFlow.hangar_tab_node(HangarNav.PLAY)
	assert_eq(menu.scene_file_path, DUMMY_MENU, "voltou ao Menu")
	assert_false(is_instance_valid(first_root), "partida anterior liberada")
	assert_false(is_instance_valid(first), "Arena anterior liberada")
	assert_false(get_tree().paused, "jogo despausado")
	assert_eq(get_tree().root.get_children().filter(func(n: Node) -> bool: return n.name == SceneFlow.MATCH_ROOT_NAME).size(), 0, "sem nó de partida órfão")
	assert_eq(menu.play_pressed.get_connections().size(), 1, "play_pressed ligado uma vez")

	menu.play_pressed.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var second := SceneFlow.current_arena() as Arena
	assert_not_null(second, "nova partida a partir do Menu")
	assert_ne(second, first)
	var hud_count := get_tree().current_scene.get_children().filter(func(n: Node) -> bool: return n is Hud).size()
	assert_eq(hud_count, 1, "um só HUD")
	if second != null:
		assert_eq(second.match_ended.get_connections().filter(func(c: Dictionary) -> bool: return c.callable.get_object() == SceneFlow).size(), 1, "match_ended ligado uma vez ao SceneFlow")
