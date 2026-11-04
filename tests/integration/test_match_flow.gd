extends GutTest
## SceneFlow com as telas e a Arena reais: Título → Partida → Resultado → Partida.


func after_all() -> void:
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
