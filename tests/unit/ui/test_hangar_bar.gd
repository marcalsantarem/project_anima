extends GutTest
## T-201 (BRF-146): cena da barra do hangar (estados, aviso do bloqueado, layout sem arte).

var prog: ProgressionData = load("res://data/meta/progression_m2.tres")


func _bar(level: int) -> HangarBar:
	var b: HangarBar = load("res://src/ui/hangar/hangar_bar.tscn").instantiate()
	b.setup(level, prog)
	add_child_autofree(b)
	await wait_process_frames(2)
	return b


func test_five_items_in_order() -> void:
	var b := await _bar(1)
	assert_eq(b.items.size(), 5)
	var xs: Array = []
	for id in HangarBarLogic.ORDER:
		xs.append(b.items[id].position.x)
	var sorted := xs.duplicate()
	sorted.sort()
	assert_eq(xs, sorted, "da esquerda para a direita")
	assert_gte(b.items[HangarNav.PLAY].size.y, 76.0 * 0.99)


func test_locked_press_only_hints() -> void:
	var b := await _bar(1)
	watch_signals(b)
	b.press(HangarNav.CORES)
	assert_signal_not_emitted(b, "tab_pressed")
	assert_signal_emitted(b, "locked_pressed")
	assert_true(b.hint_label.visible)
	assert_eq(b.hint_label.text, "Núcleos libera no NV 3")


func test_free_press_emits() -> void:
	var b := await _bar(2)
	watch_signals(b)
	b.press(HangarNav.MODULES)
	b.press(HangarNav.SETTINGS)
	assert_signal_emit_count(b, "tab_pressed", 2)
	b.press(HangarNav.COMPONENTS)
	assert_signal_emit_count(b, "tab_pressed", 2, "Componentes ainda bloqueado no NV 2")


func test_active_mark_follows_current_and_hides_when_locked() -> void:
	var b := await _bar(1)
	assert_true(b._mark.visible)
	b.set_current(HangarNav.SETTINGS)
	assert_true(b._mark.visible)
	b.set_current(HangarNav.CORES)
	assert_false(b._mark.visible, "bloqueado não fica ativo")


func test_bar_height_includes_safe_strip() -> void:
	var b := await _bar(1)
	assert_gte(b.bar_height(), 110.0 * 0.99)
