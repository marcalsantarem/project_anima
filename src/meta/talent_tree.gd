class_name TalentTree
extends Resource
## Lista de Núcleos (talentos) da árvore (T-203). Dado puro.

@export var talents: Array[TalentData] = []
## Chave de tradução do nome de cada ramo.
@export var branch_name_keys: Dictionary = {}


func get_talent(id: StringName) -> TalentData:
	for t in talents:
		if t.id == id:
			return t
	return null


## Soma dos custos de todos os níveis (Moeda para completar a árvore).
func total_cost() -> int:
	var s := 0
	for t in talents:
		for c in t.costs:
			s += c
	return s


## Lista de erros (vazia = válido): ids únicos, pré-requisitos existentes e dentro do nível máximo, sem ciclos.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var by_id := {}
	var cells := {}
	for t in talents:
		errors.append_array(t.validate())
		if by_id.has(t.id):
			errors.append("id duplicado %s" % t.id)
		by_id[t.id] = t
		if cells.has(t.grid_pos):
			errors.append("posição %s repetida (%s e %s)" % [t.grid_pos, cells[t.grid_pos], t.id])
		cells[t.grid_pos] = t.id
		if not branch_name_keys.has(String(t.branch)):
			errors.append("%s: ramo %s sem nome" % [t.id, t.branch])
	for t in talents:
		for i in t.prereq_ids.size():
			var p: TalentData = by_id.get(t.prereq_ids[i])
			if p == null:
				errors.append("%s: pré-requisito %s não existe" % [t.id, t.prereq_ids[i]])
			elif i < t.prereq_levels.size() and (t.prereq_levels[i] < 1 or t.prereq_levels[i] > p.max_level()):
				errors.append("%s: nível %d fora de 1..%d em %s" % [t.id, t.prereq_levels[i], p.max_level(), p.id])
	if _has_cycle(by_id):
		errors.append("ciclo nos pré-requisitos")
	return errors


func _has_cycle(by_id: Dictionary) -> bool:
	var state := {}  # 1 = visitando, 2 = pronto
	for id in by_id:
		if _visit(id, by_id, state):
			return true
	return false


func _visit(id: StringName, by_id: Dictionary, state: Dictionary) -> bool:
	if state.get(id, 0) == 2 or not by_id.has(id):
		return false
	if state.get(id, 0) == 1:
		return true
	state[id] = 1
	for p in (by_id[id] as TalentData).prereq_ids:
		if _visit(p, by_id, state):
			return true
	state[id] = 2
	return false
