class_name StageData
extends Resource
## Uma fase: lista de ondas. Valores em data/waves/<stage_id>.tres.

const PATH_FORMAT := "res://data/waves/%s.tres"

@export var id: StringName
@export var waves: Array[WaveData] = []
@export var wave_break: float = 3.0 ## s de respiro entre ondas
@export var boss_id: StringName ## chefe da última onda (T-115)


static func path_for(stage_id: StringName) -> String:
	return PATH_FORMAT % stage_id
