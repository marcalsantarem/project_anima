extends GutTest
## Áudio básico (T-182): volume salvo, música só no Título/Menu, limite de vozes, nada antes do gesto.

const TMP := "user://test_audio_settings.cfg"
var audio: AudioManager


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	audio = AudioManager.new()
	audio.settings_path = TMP
	add_child_autofree(audio)


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_padrao_sem_arquivo() -> void:
	assert_eq(audio.music_volume, AudioManager.DEFAULT_MUSIC)
	assert_eq(audio.sfx_volume, AudioManager.DEFAULT_SFX)


func test_volume_salvo_e_lido_sem_apagar_game_speed() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "speed", 2.0)
	cfg.save(TMP)
	audio.set_music_volume(0.25)
	audio.set_sfx_volume(0.5)
	assert_eq(AudioManager.load_volume(TMP, "music", 1.0), 0.25)
	assert_eq(AudioManager.load_volume(TMP, "sfx", 1.0), 0.5)
	var back := ConfigFile.new()
	back.load(TMP)
	assert_eq(back.get_value("game", "speed"), 2.0)


func test_valor_invalido_vira_padrao() -> void:
	assert_eq(AudioManager.sanitize_volume(1.5, 0.7), 0.7)
	assert_eq(AudioManager.sanitize_volume(-0.1, 0.7), 0.7)
	assert_eq(AudioManager.sanitize_volume(NAN, 0.7), 0.7)
	assert_eq(AudioManager.sanitize_volume("alto", 0.7), 0.7)
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 9.0)
	cfg.save(TMP)
	assert_eq(AudioManager.load_volume(TMP, "music", 0.7), 0.7)
	audio.set_sfx_volume(7.0)
	assert_eq(audio.sfx_volume, AudioManager.DEFAULT_SFX)


func test_nada_toca_antes_do_gesto() -> void:
	audio._on_scene_changed(SceneFlow.title_scene_path)
	assert_false(audio.is_music_playing())
	assert_false(audio.play_shot())
	assert_eq(audio.voices_playing(), 0)


func test_musica_comeca_no_gesto_e_para_na_partida() -> void:
	audio._on_scene_changed(SceneFlow.title_scene_path)
	audio.unlock()
	assert_true(audio.is_music_playing())
	audio._on_scene_changed(SceneFlow.menu_scene_path)
	assert_true(audio.is_music_playing())
	audio._on_scene_changed("res://src/match/arena/arena.tscn")
	await wait_seconds(AudioManager.FADE_OUT + 0.3)
	assert_false(audio.is_music_playing())
	audio._on_scene_changed(SceneFlow.menu_scene_path)
	assert_true(audio.is_music_playing())


func test_sfx_respeita_limite_de_vozes() -> void:
	audio.unlock()
	var played := 0
	for i in AudioManager.MAX_VOICES + 5:
		if audio.play_shot():
			played += 1
	assert_eq(played, AudioManager.MAX_VOICES)
	assert_lte(audio.voices_playing(), AudioManager.MAX_VOICES)
