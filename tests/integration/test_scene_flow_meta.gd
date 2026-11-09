extends GutTest
## T-187: Título → Menu → Partida → Resultado → Menu, com recompensa (MetaFlow.settle) salva pelo Backend.
## Menu e Resultado são telas dummy (fixtures); a Arena é a real; o provedor do Backend é simulado.

const DUMMY_MENU := "res://tests/integration/fixtures/dummy_menu.tscn"
const DUMMY_RESULT := "res://tests/integration/fixtures/dummy_result.tscn"
const TODAY := "2026-11-06"

const SUMMARY_KEYS := ["xp", "coins", "first_win_bonus", "levels_gained", "slots_unlocked", "level_before",
	"xp_before", "xp_to_next_before", "level_after", "xp_after", "xp_to_next_after", "result_outcome"]


class FakeProvider extends BackendProvider:
	var stored: PlayerProfile = PlayerProfile.new()
	var saves := 0
	var fail_save := false

	func has_save() -> bool:
		return true

	func load_profile() -> PlayerProfile:
		return PlayerProfile.from_dict(stored.to_dict())

	func save_profile(p: PlayerProfile) -> bool:
		if fail_save:
			failed.emit(&"write_failed", "simulado")
			return false
		saves += 1
		stored = PlayerProfile.from_dict(p.to_dict())
		return true


var _fake: FakeProvider
var _old_provider: BackendProvider
var _old_paths: Array


func before_all() -> void:
	_old_provider = Backend.provider
	_old_paths = [SceneFlow.menu_scene_path, SceneFlow.result_scene_path]


func before_each() -> void:
	_fake = FakeProvider.new()
	Backend.provider = _fake
	SceneFlow.menu_scene_path = DUMMY_MENU
	SceneFlow.result_scene_path = DUMMY_RESULT
	SceneFlow.today_override = TODAY
	SceneFlow.load_profile()


func after_all() -> void:
	Backend.provider = _old_provider
	SceneFlow.menu_scene_path = _old_paths[0]
	SceneFlow.result_scene_path = _old_paths[1]
	SceneFlow.today_override = ""
	SceneFlow.profile = null
	get_tree().paused = false
	var current := get_tree().current_scene
	if current != null and current.get_parent() == get_tree().root:
		current.queue_free()


func _result(outcome: MatchResult.Outcome, kills: Dictionary) -> MatchResult:
	var r := MatchResult.new()
	r.outcome = outcome
	r.kills_by_type = kills
	for id in kills:
		r.enemies_killed += int(kills[id])
	return r


func _expected(r: MatchResult, bonus: bool) -> Dictionary:
	return MetaRewards.compute(r, SceneFlow.rewards, bonus)


func test_full_flow_title_menu_match_result_menu() -> void:
	_fake.stored.level = 2
	_fake.stored.xp = 10
	_fake.stored.coins = 7
	SceneFlow.load_profile()
	SceneFlow.go_to_title()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var title := get_tree().current_scene as TitleScreen
	assert_not_null(title, "Título")
	if title == null:
		return
	title.start_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var menu := get_tree().current_scene
	assert_eq(menu.scene_file_path, DUMMY_MENU, "Título → Menu")
	assert_eq(menu.view, {"level": 2, "xp": 10, "xp_to_next": SceneFlow.progression.xp_to_next[1], "coins": 7, "is_max": false})

	menu.play_pressed.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := SceneFlow.current_arena() as Arena
	assert_not_null(arena, "Menu → Partida")
	if arena == null:
		return
	arena.anima.core.take_damage(arena.anima.core.max_hp)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var screen := get_tree().current_scene
	assert_eq(screen.scene_file_path, DUMMY_RESULT, "Partida → Resultado")
	assert_true(screen.reward_set, "set_reward chamado")
	assert_eq(screen.reward.keys().size(), SUMMARY_KEYS.size())
	for k in SUMMARY_KEYS:
		assert_has(screen.reward, k)
	assert_eq(screen.reward.result_outcome, "derrota")
	assert_eq(_fake.saves, 1, "perfil salvo uma vez")

	screen.menu_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	menu = get_tree().current_scene
	assert_eq(menu.scene_file_path, DUMMY_MENU, "Resultado → Menu")
	assert_eq(menu.view.coins, SceneFlow.profile.coins, "menu com o perfil atualizado")


func test_play_again_starts_new_match() -> void:
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var first := SceneFlow.current_arena() as Arena
	first.anima.core.take_damage(first.anima.core.max_hp)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	get_tree().current_scene.play_again_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var second := SceneFlow.current_arena()
	assert_not_null(second, "Jogar de novo abre a partida direto")
	assert_ne(second, first)


func test_victory_with_daily_bonus_applied_and_saved() -> void:
	var r := _result(MatchResult.Outcome.VICTORY, {&"enemy_runner": 10})
	var e := _expected(r, true)
	var s := SceneFlow.settle_and_save(r)
	assert_true(s.first_win_bonus)
	assert_eq(s.xp, int(e.xp))
	assert_eq(s.coins, int(e.coins))
	assert_eq(s.result_outcome, "vitoria")
	assert_eq(_fake.saves, 1)
	assert_eq(_fake.stored.coins, int(e.coins), "Moeda salva")
	assert_eq(_fake.stored.last_first_win_date, TODAY, "bônus do dia marcado e salvo")
	assert_eq(s.level_before, 1)
	assert_eq(s.xp_before, 0)
	assert_eq(s.xp_to_next_before, SceneFlow.progression.xp_to_next[0])
	assert_eq(s.level_after, _fake.stored.level)
	assert_eq(s.xp_after, _fake.stored.xp)


func test_second_victory_same_day_has_no_bonus() -> void:
	var r := _result(MatchResult.Outcome.VICTORY, {&"enemy_runner": 10})
	SceneFlow.settle_and_save(r)
	var s := SceneFlow.settle_and_save(r)
	assert_false(s.first_win_bonus)
	assert_eq(s.xp, int(_expected(r, false).xp))


func test_multiple_level_ups_and_slot_unlock() -> void:
	var r := _result(MatchResult.Outcome.VICTORY, {&"enemy_runner": 400})
	var s := SceneFlow.settle_and_save(r)
	assert_gt(s.levels_gained, 1, "várias subidas")
	assert_eq(s.level_after, 1 + s.levels_gained)
	assert_has(s.slots_unlocked, 1, "slot 1 liberado no nível 2")
	assert_true(s.slots_unlocked is Array)
	assert_eq(s.xp_to_next_after, SceneFlow.progression.xp_to_next[s.level_after - 1])
	assert_eq(_fake.stored.level, s.level_after)


func test_level_cap_xp_to_next_zero() -> void:
	SceneFlow.profile.level = SceneFlow.progression.max_level
	var s := SceneFlow.settle_and_save(_result(MatchResult.Outcome.VICTORY, {&"enemy_runner": 5}))
	assert_eq(s.xp_to_next_after, 0)
	assert_eq(s.xp_after, 0)
	assert_true(SceneFlow.menu_view(SceneFlow.profile, SceneFlow.progression).is_max)


func test_defeat_reduced_reward_no_bonus() -> void:
	var r := _result(MatchResult.Outcome.DEFEAT, {&"enemy_runner": 10})
	var s := SceneFlow.settle_and_save(r)
	assert_false(s.first_win_bonus)
	assert_eq(s.result_outcome, "derrota")
	assert_eq(s.xp, int(_expected(r, false).xp))
	assert_eq(_fake.stored.last_first_win_date, "", "derrota não marca o bônus do dia")


func test_save_failure_does_not_block_flow() -> void:
	_fake.fail_save = true
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := SceneFlow.current_arena() as Arena
	arena.anima.core.take_damage(arena.anima.core.max_hp)
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var screen := get_tree().current_scene
	assert_eq(screen.scene_file_path, DUMMY_RESULT, "Resultado abre mesmo sem salvar")
	assert_true(screen.reward_set)
	assert_eq(_fake.saves, 0)
	screen.menu_requested.emit()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_eq(get_tree().current_scene.scene_file_path, DUMMY_MENU, "segue para o Menu")


func test_stress_match_gives_no_reward_and_does_not_save() -> void:
	var before := SceneFlow.profile.to_dict()
	SceneFlow.start_match()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var arena := SceneFlow.current_arena() as Arena
	StressMode.attach(arena, 1, 1)
	await wait_physics_frames(1)
	arena.end_by_timeout()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	var screen := get_tree().current_scene
	assert_eq(screen.scene_file_path, DUMMY_RESULT)
	assert_false(screen.reward_set, "sem set_reward no estresse")
	assert_eq(SceneFlow.last_summary, {})
	assert_eq(_fake.saves, 0, "estresse não salva")
	assert_eq(SceneFlow.profile.to_dict(), before, "estresse não dá XP nem Moeda")
	assert_true(SceneFlow.last_log.get("header", {}).has("stress"), "log marcado como estresse")


func test_missing_menu_falls_back_to_match() -> void:
	SceneFlow.menu_scene_path = "res://nao_existe_menu.tscn"
	SceneFlow.go_to_menu()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	assert_not_null(SceneFlow.current_arena(), "sem o menu, vai direto para a partida")
