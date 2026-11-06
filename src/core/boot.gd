extends Node
## Cena principal (Boot): carrega o perfil e abre o Título (ou a partida, no modo de estresse).


func _ready() -> void:
	SceneFlow.boot.call_deferred()
