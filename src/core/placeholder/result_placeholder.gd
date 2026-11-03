extends TapScreen
## Resultado placeholder. A versão final é do AG02.

@onready var _label: Label = $Label


func _ready() -> void:
	var result := SceneFlow.last_result
	if result == null:
		_label.text = "Sem resultado"
	else:
		var outcome := "Vitória" if result.outcome == MatchResult.Outcome.VICTORY else "Derrota"
		_label.text = "%s\n%.1f s\n\nToque para continuar" % [outcome, result.duration_s]


func _on_tap() -> void:
	SceneFlow.go_to_title()
