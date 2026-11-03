class_name MatchConfig
extends RefCounted
## Entrada da partida. Mínimo do M1; o AG04 amplia com `anima_data` e `skills`.

const DEFAULT_MATCH_SCENE := "res://src/core/placeholder/match_placeholder.tscn"

var stage_id: StringName = &"stage_01"
## Cena raiz da partida. Troque aqui (ou por config) quando a arena real existir.
var match_scene_path: String = DEFAULT_MATCH_SCENE
