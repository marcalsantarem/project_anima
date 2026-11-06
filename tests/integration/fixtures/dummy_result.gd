extends Control
## Resultado dummy dos testes do SceneFlow (contrato da T-191: `show_result`, `set_reward`, sinais).

signal play_again_requested
signal menu_requested

var result: MatchResult
var reward: Dictionary = {}
var reward_set := false


func show_result(r: MatchResult) -> void:
	result = r


func set_log(_doc: Dictionary) -> void:
	pass


func set_reward(summary: Dictionary) -> void:
	reward = summary
	reward_set = true
