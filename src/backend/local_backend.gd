class_name LocalBackend
extends BackendProvider
## Save local em JSON (`user://save.json`; na Web vira IndexedDB). Nao e autoritativo (ADR 0002).
## Formato: {"version": int, "profile": {...}}. Escrita atomica (.tmp + rename) e copia .bak.

const SCHEMA_VERSION := 1

var path: String
var tmp_path: String
var bak_path: String
## So para testes: simula falha entre gravar o .tmp e renomear.
var _fail_before_rename := false


func _init(save_path := "user://save.json") -> void:
	path = save_path
	tmp_path = save_path + ".tmp"
	bak_path = save_path + ".bak"


func has_save() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(bak_path)


func load_profile() -> PlayerProfile:
	if not has_save():
		return PlayerProfile.new()
	var p := _read(path)
	if p != null:
		return p
	failed.emit(&"corrupt_save", "save.json ilegivel ou invalido")
	p = _read(bak_path)
	if p != null:
		recovered_from_backup.emit()
		return p
	return PlayerProfile.new()


func save_profile(profile: PlayerProfile) -> bool:
	profile.sanitize()
	var text := JSON.stringify({"version": SCHEMA_VERSION, "profile": profile.to_dict()})
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		failed.emit(&"write_failed", "nao abriu %s (erro %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	f.store_string(text)
	f.flush()
	f.close()
	if _fail_before_rename:
		failed.emit(&"write_failed", "falha simulada antes do rename")
		return false
	# Copia de seguranca do ultimo save bom (so se ele for valido).
	if FileAccess.file_exists(path) and _read(path) != null:
		DirAccess.copy_absolute(path, bak_path)
	var err := DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		failed.emit(&"write_failed", "rename falhou (erro %d)" % err)
		return false
	return true


func reset_profile() -> void:
	for p in [path, tmp_path, bak_path]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Le e valida um arquivo; null se ausente, invalido ou fora de faixa.
func _read(file_path: String) -> PlayerProfile:
	if not FileAccess.file_exists(file_path):
		return null
	var json := JSON.new()  # parse() nao loga erro de engine (parse_string loga)
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return null
	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		return null
	var data := _migrate(parsed)
	if data.is_empty() or not (data.get("profile") is Dictionary):
		return null
	if not PlayerProfile.is_valid_dict(data["profile"]):
		return null
	return PlayerProfile.from_dict(data["profile"])


## Leva o save ate SCHEMA_VERSION. Devolve {} se a versao for invalida ou futura.
## v0 = sem campo "version" (perfil solto na raiz) -> v1 (envelope).
func _migrate(data: Dictionary) -> Dictionary:
	var v: Variant = data.get("version", 0)
	if not (v is int or v is float) or int(v) < 0 or int(v) > SCHEMA_VERSION:
		return {}
	var ver := int(v)
	if ver == 0:
		var prof := data.duplicate()
		prof.erase("version")
		data = {"version": 1, "profile": prof}
		ver = 1
	# Proximas migracoes: if ver == 1: ...; ver = 2
	data["version"] = ver
	return data
