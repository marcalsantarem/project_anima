extends GutTest
## QA do M3 (BRF-148, T-202): hangar real (menu + barra) por nível da conta, bloqueios e arte aplicada.

var _old_provider: BackendProvider
var _old_level := 1


class MemoryProvider extends BackendProvider:
	func save_profile(_p: PlayerProfile) -> bool:
		return true


func before_all() -> void:
	_old_provider = Backend.provider
	Backend.provider = MemoryProvider.new()
	SceneFlow.load_profile()
	_old_level = SceneFlow.profile.level


func after_all() -> void:
	SceneFlow.profile.level = _old_level
	Backend.provider = _old_provider
	SceneFlow.profile = null
	get_tree().paused = false
	var current := get_tree().current_scene
	if current != null and current.get_parent() == get_tree().root:
		current.queue_free()


func _open(level: int) -> HangarBar:
	SceneFlow.profile.level = level
	SceneFlow.go_to_menu()
	await wait_for_signal(SceneFlow.scene_changed, 2)
	await wait_process_frames(2)
	var host := get_tree().current_scene as HangarHost
	assert_not_null(host, "cena atual é o hangar")
	var bars := host.find_children("*", "HangarBar", true, false)
	assert_eq(bars.size(), 1, "uma barra no hangar")
	return bars[0] as HangarBar if bars.size() > 0 else null


func _tex_path(icon: TextureRect) -> String:
	return icon.texture.resource_path if icon.texture != null else ""


func test_lock_matrix_by_level() -> void:
	# decisão 63: Módulos NV 2 (slot 1), Núcleos NV 3, Componentes NV 4; Jogar e Ajustes livres.
	var expected := {
		1: [HangarNav.MODULES, HangarNav.CORES, HangarNav.COMPONENTS],
		2: [HangarNav.CORES, HangarNav.COMPONENTS],
		3: [HangarNav.COMPONENTS],
		4: [],
		8: [],
	}
	for level: int in expected:
		var bar := await _open(level)
		if bar == null:
			return
		assert_eq(SceneFlow.current_tab, HangarNav.PLAY, "NV %d abre em Jogar" % level)
		for id: StringName in HangarBarLogic.ORDER:
			var locked: bool = id in expected[level]
			assert_eq(HangarBarLogic.is_locked(id, level, bar.progression), locked, "NV %d %s" % [level, id])
			assert_eq(bar._parts[id].chip.visible, locked, "selo NV %d %s" % [level, id])
			bar.press(id)
			if locked:
				assert_ne(SceneFlow.current_tab, id, "bloqueado não navega (NV %d %s)" % [level, id])
				assert_true(bar.hint_label.visible, "bloqueado avisa")
			else:
				assert_eq(SceneFlow.current_tab, id, "livre navega (NV %d %s)" % [level, id])
				if id == HangarNav.CORES:
					assert_true(SceneFlow.hangar_tab_node(id) is CoresScreen, "Núcleos com tela própria (T-207)")
				elif id != HangarNav.PLAY:
					assert_true(SceneFlow.hangar_tab_node(id) is ComingSoonScreen, "%s cai no Em breve" % id)
					assert_eq(bar.current, id, "barra marca o ativo")


func test_art_pieces_load_without_fallback() -> void:
	for level: int in [1, 8]:
		var bar := await _open(level)
		if bar == null:
			return
		var sb := bar._bg.get_theme_stylebox(&"panel")
		assert_true(sb is StyleBoxTexture, "ui_nav_bar aplicado")
		if sb is StyleBoxTexture:
			assert_string_contains((sb as StyleBoxTexture).texture.resource_path, "ui_nav_bar")
		for id: StringName in HangarBarLogic.ORDER:
			var p: Dictionary = bar._parts[id]
			var locked := HangarBarLogic.is_locked(id, level, bar.progression)
			var want: String = bar.LOCKED_ICON_FILES[id] if locked else bar.ICON_FILES[id]
			assert_string_contains(_tex_path(p.icon), want, "ícone NV %d %s" % [level, id])
			assert_false(p.fb.visible, "sem fallback NV %d %s" % [level, id])
			if locked:
				var chip_sb: StyleBox = p.chip.get_theme_stylebox(&"normal")
				assert_true(chip_sb is StyleBoxTexture, "ui_nav_lock_chip aplicado")
		var active: StyleBox = bar.items[HangarNav.PLAY].get_theme_stylebox(&"normal")
		assert_true(active is StyleBoxTexture, "ui_nav_tab_active aplicado")
		var pressed: StyleBox = bar.items[HangarNav.SETTINGS].get_theme_stylebox(&"pressed")
		assert_true(pressed is StyleBoxTexture, "ui_nav_tab_pressed aplicado")


func test_state_kept_and_back_chain() -> void:
	var bar := await _open(8)
	if bar == null:
		return
	var play := SceneFlow.hangar_tab_node(HangarNav.PLAY)
	bar.press(HangarNav.MODULES)
	var modules := SceneFlow.hangar_tab_node(HangarNav.MODULES)
	modules.set_meta(&"qa_mark", 7)
	bar.press(HangarNav.CORES)
	assert_true(SceneFlow.hangar_back(), "Voltar")
	assert_eq(SceneFlow.current_tab, HangarNav.MODULES, "volta à aba anterior")
	assert_eq(bar.current, HangarNav.MODULES, "barra acompanha o Voltar")
	assert_same(SceneFlow.hangar_tab_node(HangarNav.MODULES), modules, "mesma instância")
	assert_eq(modules.get_meta(&"qa_mark", 0), 7, "estado preservado")
	assert_eq(modules.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(SceneFlow.hangar_tab_node(HangarNav.CORES).process_mode, Node.PROCESS_MODE_DISABLED, "oculta desligada")
	bar.press(HangarNav.PLAY)
	assert_same(SceneFlow.hangar_tab_node(HangarNav.PLAY), play, "Jogar em cache")
	assert_true(SceneFlow.hangar_nav.history.is_empty(), "Jogar limpa o histórico")


func test_qa_fixes_t298() -> void:
	# T-298 (BRF-149): ressalvas do QA do M3.
	var bar := await _open(1)
	if bar == null:
		return
	var bg := bar._bg.get_theme_stylebox(&"panel") as StyleBoxTexture
	assert_eq(bg.texture_margin_left, 48.0, "ui_nav_bar 9-slice esq")
	assert_eq(bg.texture_margin_top, 16.0, "ui_nav_bar 9-slice topo")
	assert_eq(bg.expand_margin_top, 8.0, "ui_nav_bar expand topo")
	var p: Dictionary = bar._parts[HangarNav.CORES]
	assert_eq(p.icon.modulate.a, 1.0, "bloqueado sem alfa extra (a arte já vem a 45%)")
	var chip := p.chip as Label
	var csb := chip.get_theme_stylebox(&"normal") as StyleBoxTexture
	assert_eq(csb.texture_margin_left, 38.0, "selo 9-slice esq")
	assert_gt(csb.content_margin_left, 0.0, "texto do selo à direita do cadeado")
	assert_gt(chip.get_global_rect().position.x, p.icon.get_global_rect().position.x, "selo à direita do ícone")
	var root := get_tree().root
	var old_size := root.size
	root.size = Vector2i(375, 812) # retrato do iPhone (base 720 → viewport 720×1559)
	await wait_process_frames(3)
	bar.press(HangarNav.CORES)
	await wait_process_frames(1)
	var play := get_tree().current_scene.find_child("PlayButton", true, false) as Control
	assert_not_null(play, "JOGAR no hangar")
	if play != null:
		assert_false(bar.hint_label.get_global_rect().intersects(play.get_global_rect()), "aviso não cobre o JOGAR")
	assert_lt(bar.hint_label.get_global_rect().end.y, bar._bg.get_global_rect().position.y + 0.5, "aviso acima da barra")
	root.size = old_size
	await wait_process_frames(2)
	bar.press(HangarNav.SETTINGS)
	var soon := SceneFlow.hangar_tab_node(HangarNav.SETTINGS) as ComingSoonScreen
	assert_not_null(soon, "Em breve")
	if soon != null:
		assert_eq(soon.tab_id, HangarNav.SETTINGS, "aba deduzida do título")
		assert_not_null(soon.get_node("%ConceptIcon").texture, "ícone do conceito no painel")
		assert_not_null(soon.get_node("%Back").icon, "Voltar com ui_icon_back")
