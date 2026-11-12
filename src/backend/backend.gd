extends Node
## Autoload `Backend`: unica porta de entrada do save. Delega a um `BackendProvider`
## (LocalBackend por padrao); trocar de provedor nao muda quem chama.

signal profile_loaded(profile: PlayerProfile)
signal profile_saved
signal profile_reset
signal backend_error(code: StringName, message: String)
signal recovered_from_backup

var provider: BackendProvider = null:
	set(value):
		if provider != null:
			provider.failed.disconnect(_on_failed)
			provider.recovered_from_backup.disconnect(_on_recovered)
		provider = value
		provider.failed.connect(_on_failed)
		provider.recovered_from_backup.connect(_on_recovered)


func _init() -> void:
	provider = LocalBackend.new()


func has_save() -> bool:
	return provider.has_save()


func load_profile() -> PlayerProfile:
	var p := provider.load_profile()
	profile_loaded.emit(p)
	return p


func save_profile(profile: PlayerProfile) -> bool:
	var ok := provider.save_profile(profile)
	if ok:
		profile_saved.emit()
	return ok


func reset_profile() -> void:
	provider.reset_profile()
	profile_reset.emit()


func _on_failed(code: StringName, message: String) -> void:
	backend_error.emit(code, message)


func _on_recovered() -> void:
	recovered_from_backup.emit()
