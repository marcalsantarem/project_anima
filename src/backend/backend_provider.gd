class_name BackendProvider
extends RefCounted
## Contrato do provedor de save (LocalBackend hoje; Firebase/Nakama no futuro).
## Quem chama usa so o autoload `Backend`. Erros: sinal `failed(code, message)`.

signal failed(code: StringName, message: String)
signal recovered_from_backup


func has_save() -> bool:
	return false


func load_profile() -> PlayerProfile:
	return PlayerProfile.new()


func save_profile(_profile: PlayerProfile) -> bool:
	return false


func reset_profile() -> void:
	pass
