extends Node
## Cena de teste do fluxo de telas (T-113): Título → Partida (Arena + HUD + Pausa) → Resultado → Partida.
## Faz o papel do SceneFlow só aqui; a ligação real é da T-122.

const TITLE := preload("res://src/ui/screens/title_screen.tscn")
const PAUSE := preload("res://src/ui/screens/pause_screen.tscn")
const RESULT := preload("res://src/ui/screens/result_screen.tscn")
const HUD := preload("res://src/ui/hud/hud.tscn")
const ARENA := preload("res://src/match/arena/arena.tscn")

var current: Node


func _ready() -> void:
	show_title()


func show_title() -> void:
	var title: TitleScreen = TITLE.instantiate()
	title.start_requested.connect(start_match)
	_swap(title)


func start_match() -> void:
	var match_root := Node.new()
	match_root.name = "Match"
	var arena := ARENA.instantiate()
	arena.setup(MatchConfig.new())
	var hud: Hud = HUD.instantiate()
	var pause: PauseScreen = PAUSE.instantiate()
	match_root.add_child(hud)
	match_root.add_child(pause)
	hud.bind(arena) # antes de a arena entrar na árvore
	pause.bind(arena)
	pause.restart_requested.connect(start_match)
	arena.match_ended.connect(show_result, CONNECT_ONE_SHOT)
	match_root.add_child(arena)
	_swap(match_root)


func show_result(result: MatchResult) -> void:
	var screen: ResultScreen = RESULT.instantiate()
	screen.show_result(result)
	screen.play_again_requested.connect(start_match)
	_swap(screen)


func _swap(node: Node) -> void:
	get_tree().paused = false
	if current:
		current.queue_free()
	current = node
	add_child.call_deferred(node)
