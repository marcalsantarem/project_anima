extends TapScreen
## Partida placeholder: um toque encerra com vitória. Será trocada pela arena do AG01.

signal match_ended(result: MatchResult)

var config: MatchConfig
var _elapsed := 0.0


func setup(match_config: MatchConfig) -> void:
	config = match_config


func _process(delta: float) -> void:
	_elapsed += delta


func _on_tap() -> void:
	finish(MatchResult.Outcome.VICTORY)


func finish(outcome: MatchResult.Outcome) -> void:
	var result := MatchResult.new()
	result.outcome = outcome
	result.duration_s = _elapsed
	match_ended.emit(result)
