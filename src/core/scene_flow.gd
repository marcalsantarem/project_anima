extends Node
## Autoload `SceneFlow`: Toque para começar → Partida → Resultado → Toque para começar.
##
## Contrato da cena de partida (nó raiz):
## - `setup(config: MatchConfig)`, chamado antes de entrar na árvore;
## - sinal `match_ended(result: MatchResult)`, emitido uma vez.

signal scene_changed(scene_path: String)

const TITLE_SCENE := "res://src/core/main.tscn"
const RESULT_SCENE := "res://src/core/placeholder/result_placeholder.tscn"

## Último resultado recebido; a tela de resultado lê daqui.
var last_result: MatchResult
var _changing := false


func go_to_title() -> void:
	_change_to(TITLE_SCENE)


func start_match(config: MatchConfig = null) -> void:
	if config == null:
		config = MatchConfig.new()
	if _changing:
		return
	var match_root := (load(config.match_scene_path) as PackedScene).instantiate()
	match_root.setup(config)
	match_root.match_ended.connect(_on_match_ended, CONNECT_ONE_SHOT)
	_swap(match_root, config.match_scene_path)


func _on_match_ended(result: MatchResult) -> void:
	last_result = result
	_change_to(RESULT_SCENE)


func _change_to(path: String) -> void:
	if _changing:
		return
	_swap((load(path) as PackedScene).instantiate(), path)


func _swap(node: Node, path: String) -> void:
	_changing = true
	get_tree().change_scene_to_node.call_deferred(node)
	await get_tree().scene_changed
	_changing = false
	scene_changed.emit(path)
