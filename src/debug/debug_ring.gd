class_name DebugRing
extends RefCounted
## Buffer circular de tamanho fixo (pré-alocado). Cheio, sobrescreve o mais antigo e conta em `dropped`.

var capacity: int
## Quantos itens foram descartados (sobrescritos) por falta de espaço.
var dropped := 0

var _items: Array = []
var _head := 0 # próximo índice a escrever
var _count := 0


func _init(p_capacity: int) -> void:
	capacity = maxi(p_capacity, 1)
	_items.resize(capacity)


func push(item: Variant) -> void:
	_items[_head] = item
	_head = (_head + 1) % capacity
	if _count < capacity:
		_count += 1
	else:
		dropped += 1


func size() -> int:
	return _count


## Item mais recente, ou null.
func last() -> Variant:
	return null if _count == 0 else _items[(_head - 1 + capacity) % capacity]


## Os `n` itens mais recentes, do mais antigo para o mais novo.
func tail(n: int) -> Array:
	n = clampi(n, 0, _count)
	var out := []
	out.resize(n)
	var start := (_head - n + capacity) % capacity
	for i in n:
		out[i] = _items[(start + i) % capacity]
	return out


## Todos os itens, do mais antigo para o mais novo (aloca: usar só ao salvar/resumir).
func to_array() -> Array:
	return tail(_count)


func clear() -> void:
	_items.fill(null)
	_head = 0
	_count = 0
	dropped = 0
