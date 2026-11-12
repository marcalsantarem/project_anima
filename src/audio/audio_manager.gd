class_name AudioManager
extends Node
## Autoload `Audio` (T-182, decisão 57): música de entrada e SFX do tiro básico.
## - Web: nada toca antes do 1º gesto (`unlock()`, chamado pela tela "Toque para começar").
## - Música só no Título e no Menu (para com fade ao entrar na partida/resultado; volta ao Menu).
## - SFX com pool fixo de players (`MAX_VOICES`); sem voz livre, o tiro fica mudo (sem alocação por tiro).
## - Volumes 0-1 salvos em `user://settings.cfg`, seção `audio` (não toca na seção `game`).

const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const MUSIC_STREAM := preload("res://assets/audio/mus_entrada.ogg")
const SHOT_STREAM := preload("res://assets/audio/sfx_tiro_basico.ogg")
const MAX_VOICES := 6
const FADE_IN := 1.2
const FADE_OUT := 0.6
const SILENT_DB := -60.0
const PITCH_JITTER := 0.06
const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "audio"
const KEY_MUSIC := "music"
const KEY_SFX := "sfx"
const DEFAULT_MUSIC := 0.7
const DEFAULT_SFX := 0.9

## Só testes: caminho do arquivo de configuração.
var settings_path := SETTINGS_PATH
var music_volume := DEFAULT_MUSIC
var sfx_volume := DEFAULT_SFX
## true depois do 1º gesto do usuário.
var unlocked := false
var _music_wanted := false
var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.bus = BUS_MUSIC
	_music.volume_db = SILENT_DB
	var looped: AudioStream = MUSIC_STREAM.duplicate()
	if "loop" in looped:
		looped.set("loop", true)
	_music.stream = looped
	add_child(_music)
	for i in MAX_VOICES:
		var v := AudioStreamPlayer.new()
		v.name = "Sfx%d" % i
		v.bus = BUS_SFX
		v.stream = SHOT_STREAM
		add_child(v)
		_voices.append(v)
	music_volume = load_volume(settings_path, KEY_MUSIC, DEFAULT_MUSIC)
	sfx_volume = load_volume(settings_path, KEY_SFX, DEFAULT_SFX)
	_apply_bus_volumes()
	var flow := get_node_or_null(^"/root/SceneFlow")
	if flow != null:
		flow.scene_changed.connect(_on_scene_changed)


## Garante os barramentos Music e SFX mesmo se o layout não foi carregado (testes, layout trocado).
func _ensure_buses() -> void:
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


## Libera o áudio (1º gesto). Idempotente; inicia a música se o Título/Menu já a pediram.
func unlock() -> void:
	AudioServer.set_bus_mute(0, false)
	if unlocked:
		return
	unlocked = true
	_apply_music()


func set_music_volume(v: float) -> void:
	music_volume = sanitize_volume(v, DEFAULT_MUSIC)
	_apply_bus_volumes()
	_save(KEY_MUSIC, music_volume)


func set_sfx_volume(v: float) -> void:
	sfx_volume = sanitize_volume(v, DEFAULT_SFX)
	_apply_bus_volumes()
	_save(KEY_SFX, sfx_volume)


## Valor 0-1 válido ou o padrão (NaN, fora da faixa ou não numérico).
static func sanitize_volume(v: Variant, default: float) -> float:
	if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
		return default
	var f := float(v)
	if is_nan(f) or f < 0.0 or f > 1.0:
		return default
	return f


static func load_volume(path: String, key: String, default: float) -> float:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return default
	return sanitize_volume(cfg.get_value(SECTION, key, default), default)


func _save(key: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(settings_path) # mantém as outras seções/chaves (ex.: game/speed); arquivo ausente é normal
	cfg.set_value(SECTION, key, value)
	if cfg.save(settings_path) != OK:
		push_warning("Audio: falha ao salvar %s" % settings_path)


func _apply_bus_volumes() -> void:
	_set_bus(BUS_MUSIC, music_volume)
	_set_bus(BUS_SFX, sfx_volume)


static func _set_bus(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.0)


## Música vale no Título e no Menu; qualquer outra cena (partida, resultado) para.
func wants_music(scene_path: String) -> bool:
	var flow := get_node_or_null(^"/root/SceneFlow")
	if flow == null:
		return false
	return scene_path == flow.title_scene_path or scene_path == flow.menu_scene_path


func _on_scene_changed(scene_path: String) -> void:
	_music_wanted = wants_music(scene_path)
	_apply_music()


func _apply_music() -> void:
	if _music == null:
		return
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if _music_wanted and unlocked:
		if not _music.playing:
			_music.volume_db = SILENT_DB
			_music.play()
		_fade = create_tween()
		_fade.tween_property(_music, "volume_db", 0.0, FADE_IN)
	elif _music.playing:
		_fade = create_tween()
		_fade.tween_property(_music, "volume_db", SILENT_DB, FADE_OUT)
		_fade.tween_callback(_music.stop)


func is_music_playing() -> bool:
	return _music != null and _music.playing


func voices_playing() -> int:
	var n := 0
	for v in _voices:
		if v.playing:
			n += 1
	return n


## Som do tiro básico do Anima. false = não tocou (antes do gesto ou sem voz livre).
func play_shot() -> bool:
	if not unlocked:
		return false
	for v in _voices:
		if not v.playing:
			v.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
			v.play()
			return true
	return false
