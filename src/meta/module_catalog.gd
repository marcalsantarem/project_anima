class_name ModuleCatalog
extends Resource
## Lista dos Módulos equipáveis, na ordem do catálogo (T-213).

@export var modules: Array[ModuleLevelData] = []


func get_module(id: StringName) -> ModuleLevelData:
	for m in modules:
		if m != null and m.module_id == id:
			return m
	return null


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for m in modules:
		out.append(m.module_id)
	return out


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for m in modules:
		errors.append_array(m.validate())
	return errors
