extends Node
## Autoload `SceneFlow`: Título → Partida (Arena + HUD + Pausa) → Resultado → Partida.
##
## Contrato da cena de partida (nó raiz):
## - `setup(config: MatchConfig)`, chamado antes de entrar na árvore;
## - sinal `match_ended(result: MatchResult)`, emitido uma vez.
## Montagem com a UI: ver `docs/ui.md` §10c.

signal scene_changed(scene_path: String)

const TITLE_SCENE := "res://src/ui/screens/title_screen.tscn"
const RESULT_SCENE := "res://src/ui/screens/result_screen.tscn"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
const PAUSE_SCENE := "res://src/ui/screens/pause_screen.tscn"
## Nome do nó raiz que agrupa Arena, HUD e Pausa.
const MATCH_ROOT_NAME := &"Match"
const ARENA_NODE_NAME := &"Arena"

## Último resultado recebido.
var last_result: MatchResult
## Config da partida atual, reutilizada em "Recomeçar" e "Jogar de novo".
var last_config: MatchConfig
var _changing := false


func go_to_title() -> void:
	if _changing:
		return
	var title: TitleScreen = _instantiate(TITLE_SCENE)
	title.start_requested.connect(start_match, CONNECT_ONE_SHOT)
	_swap(title, TITLE_SCENE)


func start_match(config: MatchConfig = null) -> void:
	if _changing:
		return
	if config == null:
		config = MatchConfig.new()
	last_config = config
	var match_root := Node.new()
	match_root.name = MATCH_ROOT_NAME
	var arena := _instantiate(config.match_scene_path)
	arena.name = ARENA_NODE_NAME
	arena.setup(config)
	var hud: Hud = _instantiate(HUD_SCENE)
	var pause: PauseScreen = _instantiate(PAUSE_SCENE)
	match_root.add_child(hud)
	match_root.add_child(pause)
	# `bind` antes de a arena entrar na árvore, para o HUD receber o estado inicial.
	hud.bind(arena)
	pause.bind(arena)
	pause.restart_requested.connect(func() -> void: start_match(config), CONNECT_ONE_SHOT)
	arena.match_ended.connect(_on_match_ended, CONNECT_ONE_SHOT)
	_link_bottom_inset(arena, hud)
	match_root.add_child(arena)
	_swap(match_root, config.match_scene_path)


## Liga a base da Arena à altura da bandeja do HUD (com a safe area), também ao redimensionar.
## O match não conhece a UI: a ligação fica aqui. O HUD entra na árvore antes da Arena.
func _link_bottom_inset(arena: Arena, hud: Hud) -> void:
	var sync := func() -> void: arena.set_bottom_inset(hud.tray_height())
	hud.ready.connect(func() -> void:
		sync.call()
		hud.get_viewport().size_changed.connect(sync), CONNECT_ONE_SHOT)
	hud.tree_exiting.connect(func() -> void:
		var vp := hud.get_viewport()
		if vp != null and vp.size_changed.is_connected(sync):
			vp.size_changed.disconnect(sync), CONNECT_ONE_SHOT)


## Arena da partida em andamento, ou `null` fora da partida.
func current_arena() -> Node:
	var current := get_tree().current_scene
	if current == null or current.name != MATCH_ROOT_NAME:
		return null
	return current.get_node_or_null(NodePath(ARENA_NODE_NAME))


func _on_match_ended(result: MatchResult) -> void:
	last_result = result
	var screen: ResultScreen = _instantiate(RESULT_SCENE)
	screen.show_result(result)
	screen.play_again_requested.connect(func() -> void: start_match(last_config), CONNECT_ONE_SHOT)
	_swap(screen, RESULT_SCENE)


func _instantiate(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()


func _swap(node: Node, path: String) -> void:
	_changing = true
	get_tree().paused = false
	get_tree().change_scene_to_node.call_deferred(node)
	await get_tree().scene_changed
	_changing = false
	scene_changed.emit(path)
