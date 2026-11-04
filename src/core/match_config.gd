class_name MatchConfig
extends RefCounted
## Entrada da partida. Mínimo do M1; o AG04 amplia com `anima_data` e `skills`.

const DEFAULT_MATCH_SCENE := "res://src/match/arena/arena.tscn"

var stage_id: StringName = &"stage_01"
## Cena da partida (a Arena). Deve expor `setup(config)` e o sinal `match_ended`.
var match_scene_path: String = DEFAULT_MATCH_SCENE
