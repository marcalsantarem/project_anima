class_name HitStop
extends RefCounted
## Hit-stop (T-117): baixa Engine.time_scale por `duration` s de tempo REAL e restaura o valor
## anterior. Nunca empilha: com um ativo, novos pedidos são ignorados. O HUD não depende da
## simulação para responder ao toque e a música não usa time_scale. Quem cria chama stop() ao sair.

var active := false
var _saved_scale := 1.0
var _timer: SceneTreeTimer


## Devolve true se começou (false se já há um ativo, duração <= 0 ou sem árvore).
func start(tree: SceneTree, duration: float, time_scale: float) -> bool:
	if active or duration <= 0.0 or tree == null:
		return false
	active = true
	_saved_scale = Engine.time_scale
	Engine.time_scale = time_scale
	# process_always (vale com a pausa), em _process, ignorando time_scale.
	_timer = tree.create_timer(duration, true, false, true)
	_timer.timeout.connect(stop)
	return true


func stop() -> void:
	if not active:
		return
	active = false
	Engine.time_scale = _saved_scale
	if _timer and _timer.timeout.is_connected(stop):
		_timer.timeout.disconnect(stop)
	_timer = null
