extends Node
## Cena principal (Boot). Hoje só abre o título; depois, auth e config entram aqui.


func _ready() -> void:
	SceneFlow.go_to_title.call_deferred()
