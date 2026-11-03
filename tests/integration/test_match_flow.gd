extends GutTest
## SceneFlow com a Arena real (não o placeholder): partida → match_ended → Resultado.

const ARENA_PATH := "res://src/match/arena/arena.tscn"


func after_all() -> void:
	var current := get_tree().current_scene
	if current != null and not current.scene_file_path.is_empty():
		current.queue_free()


func test_real_arena_defeat_goes_to_result() -> void:
	var config := MatchConfig.new()
	config.match_scene_path = ARENA_PATH
	SceneFlow.start_match(config)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := get_tree().current_scene as Arena
	assert_not_null(arena, "cena atual é a Arena")
	if arena == null:
		return
	assert_eq(arena.config, config, "setup(config) chamado")
	assert_eq(arena.stage.resource_path, StageData.path_for(config.stage_id))

	var waves_total := arena.stage.waves.size()
	arena.anima.core.take_damage(arena.anima.core.max_hp)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_eq(get_tree().current_scene.scene_file_path, SceneFlow.RESULT_SCENE)
	assert_eq(SceneFlow.last_result.outcome, MatchResult.Outcome.DEFEAT)
	assert_eq(SceneFlow.last_result.waves_total, waves_total)

	SceneFlow.go_to_title()
	await wait_for_signal(SceneFlow.scene_changed, 2)
