class_name HitStop
extends RefCounted
## Hit-stop (T-117): baixa Engine.time_scale por `duration` s de tempo REAL e restaura a velocidade
## escolhida (SpeedController). Nunca empilha: com um ativo, novos pedidos são ignorados. O HUD não depende da
## simulação para responder ao toque e a música não usa time_scale. Quem cria chama stop() ao sair.

var active := false
var _timer: SceneTreeTimer
var _tree: SceneTree


## Devolve true se começou (false se já há um ativo, duração <= 0 ou sem árvore).
func start(tree: SceneTree, duration: float, time_scale: float) -> bool:
	if active or duration <= 0.0 or tree == null:
		return false
	active = true
	_tree = tree
	var sc := _controller(tree)
	if sc:
		sc.held = true
	Engine.time_scale = time_scale
	# process_always (vale com a pausa), em _process, ignorando time_scale.
	_timer = tree.create_timer(duration, true, false, true)
	_timer.timeout.connect(stop)
	return true


func stop() -> void:
	if not active:
		return
	active = false
	var sc := _controller(_tree)
	if sc:
		sc.held = false
		sc.restore() # velocidade escolhida (x1/x2), não o valor lido ao iniciar
	else:
		Engine.time_scale = 1.0
	if _timer and _timer.timeout.is_connected(stop):
		_timer.timeout.disconnect(stop)
	_timer = null


## Autoload buscado por nome: scripts `-s` (run_sim) compilam antes dos autoloads existirem.
func _controller(tree: SceneTree) -> Node:
	return tree.root.get_node_or_null("SpeedController") if tree else null
