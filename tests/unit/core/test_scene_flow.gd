extends GutTest
## Fluxo de cenas: Toque para começar → Partida → Resultado → Toque para começar.


func after_all() -> void:
	# Não deixa cenas do fluxo na árvore do runner.
	var current := get_tree().current_scene
	if current != null and current.scene_file_path.begins_with("res://src/core/"):
		current.queue_free()


func test_match_config_defaults_to_placeholder() -> void:
	var config := MatchConfig.new()
	assert_eq(config.match_scene_path, MatchConfig.DEFAULT_MATCH_SCENE)
	assert_true(ResourceLoader.exists(config.match_scene_path))


func test_placeholder_match_emits_result() -> void:
	var match_root = load(MatchConfig.DEFAULT_MATCH_SCENE).instantiate()
	match_root.setup(MatchConfig.new())
	watch_signals(match_root)
	match_root.finish(MatchResult.Outcome.DEFEAT)
	assert_signal_emitted(match_root, "match_ended")
	var result: MatchResult = get_signal_parameters(match_root, "match_ended")[0]
	assert_eq(result.outcome, MatchResult.Outcome.DEFEAT)
	match_root.free()


func test_full_flow() -> void:
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var match_root := get_tree().current_scene
	assert_eq(match_root.scene_file_path, MatchConfig.DEFAULT_MATCH_SCENE)

	match_root.finish(MatchResult.Outcome.VICTORY)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_eq(get_tree().current_scene.scene_file_path, SceneFlow.RESULT_SCENE)
	assert_eq(SceneFlow.last_result.outcome, MatchResult.Outcome.VICTORY)

	SceneFlow.go_to_title()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_eq(get_tree().current_scene.scene_file_path, SceneFlow.TITLE_SCENE)
