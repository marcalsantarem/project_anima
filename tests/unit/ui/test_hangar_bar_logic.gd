extends GutTest
## T-201 (BRF-146): bloqueios e estados da barra do hangar.

var prog: ProgressionData = load("res://data/meta/progression_m2.tres")


func test_unlock_levels_follow_progression() -> void:
	assert_eq(HangarBarLogic.unlock_level(HangarNav.MODULES, prog), 2)
	assert_eq(HangarBarLogic.unlock_level(HangarNav.CORES, prog), 3)
	assert_eq(HangarBarLogic.unlock_level(HangarNav.COMPONENTS, prog), 4)
	assert_eq(HangarBarLogic.unlock_level(HangarNav.PLAY, prog), 1)
	assert_eq(HangarBarLogic.unlock_level(HangarNav.SETTINGS, prog), 1)


func test_level_1_locks_three_play_and_settings_free() -> void:
	assert_true(HangarBarLogic.is_locked(HangarNav.MODULES, 1, prog))
	assert_true(HangarBarLogic.is_locked(HangarNav.CORES, 1, prog))
	assert_true(HangarBarLogic.is_locked(HangarNav.COMPONENTS, 1, prog))
	assert_false(HangarBarLogic.is_locked(HangarNav.PLAY, 1, prog))
	assert_false(HangarBarLogic.is_locked(HangarNav.SETTINGS, 1, prog))


func test_level_2_unlocks_only_modules() -> void:
	assert_false(HangarBarLogic.is_locked(HangarNav.MODULES, 2, prog))
	assert_true(HangarBarLogic.is_locked(HangarNav.CORES, 2, prog))
	assert_false(HangarBarLogic.is_locked(HangarNav.CORES, 3, prog))
	assert_true(HangarBarLogic.is_locked(HangarNav.COMPONENTS, 3, prog))
	assert_false(HangarBarLogic.is_locked(HangarNav.COMPONENTS, 4, prog))


func test_states_and_texts() -> void:
	assert_eq(HangarBarLogic.state_of(HangarNav.PLAY, HangarNav.PLAY, 1, prog), HangarBarLogic.State.ACTIVE)
	assert_eq(HangarBarLogic.state_of(HangarNav.SETTINGS, HangarNav.PLAY, 1, prog), HangarBarLogic.State.NORMAL)
	assert_eq(HangarBarLogic.state_of(HangarNav.CORES, HangarNav.PLAY, 1, prog), HangarBarLogic.State.LOCKED)
	assert_eq(HangarBarLogic.lock_text(HangarNav.COMPONENTS, prog), "NV 4")
	assert_eq(HangarBarLogic.lock_hint(HangarNav.MODULES, prog), "Módulos libera no NV 2")


func test_order_has_play_in_center() -> void:
	assert_eq(HangarBarLogic.ORDER.size(), 5)
	assert_eq(HangarBarLogic.ORDER[2], HangarNav.PLAY)
	for id in HangarNav.TABS:
		assert_true(id in HangarBarLogic.ORDER)


func test_null_progression_is_free() -> void:
	assert_false(HangarBarLogic.is_locked(HangarNav.CORES, 1, null))
