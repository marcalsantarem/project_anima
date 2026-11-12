extends GutTest

const P := "user://test_save.json"
var b: LocalBackend


func before_each() -> void:
	b = LocalBackend.new(P)
	b.reset_profile()


func after_all() -> void:
	LocalBackend.new(P).reset_profile()


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_sem_save_devolve_perfil_novo() -> void:
	assert_false(b.has_save())
	var p := b.load_profile()
	assert_eq(p.level, 1)
	assert_eq(p.coins, 0)


func test_salvar_e_carregar() -> void:
	var p := PlayerProfile.new()
	p.level = 5
	p.xp = 120
	p.coins = 999
	p.settings["sound_on"] = false
	p.extra["modules"] = ["module_meteor"]
	assert_true(b.save_profile(p))
	assert_true(b.has_save())
	var q := b.load_profile()
	assert_eq([q.level, q.xp, q.coins], [5, 120, 999])
	assert_false(q.settings["sound_on"])
	assert_eq(q.extra["modules"], ["module_meteor"])


func test_migracao_v0_sem_version() -> void:
	_write(P, '{"level": 3, "xp": 10, "coins": 50}')
	var q := b.load_profile()
	assert_eq([q.level, q.xp, q.coins], [3, 10, 50])


func test_versao_futura_e_invalida() -> void:
	_write(P, '{"version": 99, "profile": {"level": 3}}')
	assert_eq(b.load_profile().level, 1)


func test_corrompido_sem_bak_vira_perfil_novo() -> void:
	_write(P, "{lixo")
	watch_signals(b)
	assert_eq(b.load_profile().level, 1)
	assert_signal_emitted(b, "failed")


func test_corrompido_com_bak_recupera() -> void:
	var p := PlayerProfile.new()
	p.level = 4
	b.save_profile(p)
	p.level = 6
	b.save_profile(p)  # o .bak guarda o nivel 4
	_write(P, "{lixo")
	watch_signals(b)
	assert_eq(b.load_profile().level, 4)
	assert_signal_emitted(b, "recovered_from_backup")


func test_fora_de_faixa_conta_como_corrompido() -> void:
	_write(P, '{"version":1,"profile":{"level":-3,"coins":5}}')
	assert_eq(b.load_profile().coins, 0)
	_write(P, '{"version":1,"profile":{"level":1000}}')
	assert_eq(b.load_profile().level, 1)


func test_reset() -> void:
	b.save_profile(PlayerProfile.new())
	b.save_profile(PlayerProfile.new())
	b.reset_profile()
	assert_false(b.has_save())
	assert_false(FileAccess.file_exists(P + ".bak"))


func test_sanitize_ao_salvar() -> void:
	var p := PlayerProfile.new()
	p.level = 5000
	p.coins = -10
	p.settings["music_volume"] = 7.0
	b.save_profile(p)
	var q := b.load_profile()
	assert_eq(q.level, PlayerProfile.MAX_LEVEL)
	assert_eq(q.coins, 0)
	assert_eq(q.settings["music_volume"], 1.0)


func test_falha_entre_tmp_e_rename_preserva_save_anterior() -> void:
	var p := PlayerProfile.new()
	p.level = 2
	b.save_profile(p)
	p.level = 9
	b._fail_before_rename = true
	assert_false(b.save_profile(p))
	assert_eq(b.load_profile().level, 2)
	b._fail_before_rename = false
	assert_true(b.save_profile(p))
	assert_eq(b.load_profile().level, 9)


func test_autoload_delega_ao_provedor() -> void:
	var node: Node = load("res://src/backend/backend.gd").new()
	node.provider = LocalBackend.new(P)
	add_child_autofree(node)
	var p := PlayerProfile.new()
	p.coins = 7
	assert_true(node.save_profile(p))
	assert_eq(node.load_profile().coins, 7)
