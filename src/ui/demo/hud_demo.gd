extends Node
## Cena de teste: Arena + HUD juntos (T-112). A ligação ao SceneFlow é da T-122.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")

var arena: Node
var hud: Hud


func _ready() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	arena = ARENA_SCENE.instantiate()
	arena.setup(MatchConfig.new())
	hud.bind(arena) # antes de entrar na árvore: pega os valores iniciais
	add_child(arena)
