extends GutTest
## Ações de debug do meta (T-193, BRF-134): XP, Moeda, nível, zerar e o par antes/depois no log.

const P := "user://test_debug_meta.json"
var _old_provider: BackendProvider
var _old_profile: PlayerProfile


func before_each() -> void:
	_old_provider = Backend.provider
	_old_profile = SceneFlow.profile
	Backend.provider = LocalBackend.new(P)
	Backend.reset_profile()
	SceneFlow.profile = PlayerProfile.new()


func after_each() -> void:
	Backend.reset_profile()
	Backend.provider = _old_provider
	SceneFlow.profile = _old_profile


func test_xp_passa_pelo_apply_xp_e_persiste() -> void:
	var prog: ProgressionData = SceneFlow.progression
	var snap := DebugMeta.run(DebugMeta.Action.XP_BIG)
	var expected := PlayerProfile.new()
	MetaProgress.apply_xp(expected, 1000, prog)
	assert_eq(snap["nivel"], expected.level)
	assert_eq(snap["xp"], expected.xp)
	var saved := Backend.load_profile()
	assert_eq(saved.level, expected.level, "persistiu")
	assert_eq(saved.xp, expected.xp)


func test_xp_pequeno() -> void:
	var snap := DebugMeta.run(DebugMeta.Action.XP_SMALL)
	var p := PlayerProfile.new()
	MetaProgress.apply_xp(p, 100, SceneFlow.progression)
	assert_eq(snap["xp"], p.xp)
	assert_eq(snap["nivel"], p.level)


func test_moeda_soma_500_e_persiste() -> void:
	DebugMeta.run(DebugMeta.Action.COINS)
	DebugMeta.run(DebugMeta.Action.COINS)
	assert_eq(SceneFlow.profile.coins, 1000)
	assert_eq(Backend.load_profile().coins, 1000)


func test_nivel_mais_menos_com_xp_no_inicio_e_limites() -> void:
	SceneFlow.profile.xp = 40
	DebugMeta.run(DebugMeta.Action.LEVEL_UP)
	assert_eq(SceneFlow.profile.level, 2)
	assert_eq(SceneFlow.profile.xp, 0, "XP no início do nível")
	DebugMeta.run(DebugMeta.Action.LEVEL_DOWN)
	DebugMeta.run(DebugMeta.Action.LEVEL_DOWN)
	assert_eq(SceneFlow.profile.level, 1, "piso 1")
	var max_level: int = SceneFlow.progression.max_level
	for i in max_level + 3:
		DebugMeta.run(DebugMeta.Action.LEVEL_UP)
	assert_eq(SceneFlow.profile.level, max_level, "teto 30")
	assert_eq(Backend.load_profile().level, max_level)


func test_xp_no_teto_descarta_excedente() -> void:
	MetaProgress.debug_set_level(SceneFlow.profile, SceneFlow.progression.max_level, SceneFlow.progression)
	var snap := DebugMeta.run(DebugMeta.Action.XP_BIG)
	assert_eq(snap["nivel"], SceneFlow.progression.max_level)
	assert_eq(snap["xp"], 0)


func test_zerar_save_apaga_e_recarrega_perfil_novo() -> void:
	DebugMeta.run(DebugMeta.Action.COINS)
	DebugMeta.run(DebugMeta.Action.LEVEL_UP)
	assert_true(Backend.has_save())
	var snap := DebugMeta.run(DebugMeta.Action.RESET)
	assert_false(Backend.has_save())
	assert_eq(snap, {"nivel": 1, "xp": 0, "moeda": 0})
	assert_eq(SceneFlow.profile.level, 1)


func test_botao_zerar_exige_dois_toques() -> void:
	var panel := DebugMetaPanel.new()
	add_child_autofree(panel)
	DebugMeta.run(DebugMeta.Action.COINS)
	panel.reset_button.pressed.emit()
	assert_eq(panel.reset_button.text, "Confirmar?")
	assert_eq(SceneFlow.profile.coins, 500, "1º toque não zera")
	panel.reset_button.pressed.emit()
	assert_eq(SceneFlow.profile.coins, 0, "2º toque zera")
	assert_eq(panel.reset_button.text, "Zerar save")


func test_botoes_tem_64px_e_sinal_de_acao() -> void:
	var panel := DebugMetaPanel.new()
	add_child_autofree(panel)
	for b: Button in [panel.toggle, panel.reset_button]:
		assert_gte(b.custom_minimum_size.y, 64.0)
	watch_signals(panel)
	panel.set_open(true)
	panel._act(DebugMeta.Action.COINS)
	assert_signal_emitted(panel, "action_done")
	assert_eq(panel.line.text, "Nível 1 · XP 0 · Moeda 500")


func test_log_registra_antes_e_depois_da_partida() -> void:
	SceneFlow.profile.level = 3
	SceneFlow.profile.coins = 70
	var rec := MatchRecorder.new()
	rec.save_enabled = false
	rec.auto_process = false
	var arena := Node.new()
	add_child_autofree(arena)
	rec.attach(arena)
	add_child_autofree(rec)
	assert_eq(rec.meta_before, {"nivel": 3, "xp": 0, "moeda": 70})
	rec.event("debug_meta", {"acao": "coins"})
	rec.finish(null)
	SceneFlow.profile.coins = 170
	Backend.save_profile(SceneFlow.profile)
	var log := rec.log_data
	assert_eq(log["meta"]["antes"]["moeda"], 70)
	assert_eq(log["meta"]["depois"]["moeda"], 170)
	var names: Array = []
	for e in log["events"]:
		names.append(e["e"])
	assert_has(names, "meta_antes")
	assert_has(names, "meta_depois")
	assert_has(names, "debug_meta")
