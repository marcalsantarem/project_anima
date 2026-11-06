class_name EnemyPool
extends RefCounted
## Pool de inimigos comuns (T-118, BRF-086): reutiliza as instâncias (e a arte já montada) por
## EnemyData, sem `instantiate`/`queue_free` por spawn. O pool cresce sob demanda (não há teto: o
## limite da partida é a quantidade viva), mas nunca descarta. Chefes não passam por aqui.

var _free := {} ## EnemyData -> Array[Enemy] (inimigos estacionados)
var created := 0 ## quantos inimigos novos foram instanciados (testes/medição)
var reused := 0 ## quantas vezes uma instância foi reaproveitada


## Um inimigo estacionado deste tipo, ou null (o chamador instancia um novo).
func take(data: EnemyData) -> Enemy:
	var list: Array = _free.get(data, [])
	while not list.is_empty():
		var e: Enemy = list.pop_back()
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			reused += 1
			return e
	return null


## Chamado pelo inimigo ao morrer (já estacionado).
func release(enemy: Enemy) -> void:
	if not _free.has(enemy.data):
		_free[enemy.data] = []
	_free[enemy.data].append(enemy)


func free_count(data: EnemyData = null) -> int:
	if data != null:
		return (_free.get(data, []) as Array).size()
	var n := 0
	for list in _free.values():
		n += (list as Array).size()
	return n
