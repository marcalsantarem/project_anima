class_name TalentData
extends Resource
## Um Núcleo (talento) da árvore (T-203). Dado puro: a lógica de compra e de efeitos é da T-204/T-205.

enum Mode { ADD_PCT_BASE, ADD_FLAT, REDUCTION_PCT }

@export var id: StringName = &""
## Ramo temático: attack, defense ou economy.
@export var branch: StringName = &""
## Chaves de `data/i18n/strings.csv` (nome e descrição de 1 linha).
@export var name_key: String = ""
@export var desc_key: String = ""
## Ícone (null até a T-206; a UI usa um placeholder).
@export var icon: Texture2D
## Posição na grade da UI: x = coluna, y = linha (0 = camada raiz, no topo).
@export var grid_pos: Vector2i = Vector2i.ZERO
## Pré-requisitos: `prereq_ids[i]` precisa estar no nível `prereq_levels[i]` ou mais.
@export var prereq_ids: Array[StringName] = []
@export var prereq_levels: PackedInt32Array = PackedInt32Array()
## Atributo afetado e como o valor entra (ver docs/meta.md).
@export var stat: StringName = &""
@export var mode: Mode = Mode.ADD_PCT_BASE
## Efeito **acumulado** em cada nível (índice 0 = nível 1). Percentuais em fração (0,04 = 4%).
@export var values: PackedFloat32Array = PackedFloat32Array()
## Custo em Moeda para comprar cada nível (índice 0 = nível 1).
@export var costs: PackedInt32Array = PackedInt32Array()


func max_level() -> int:
	return costs.size()


## Efeito acumulado no nível `level` (0 = sem efeito).
func value_at(level: int) -> float:
	if level <= 0 or values.is_empty():
		return 0.0
	return values[mini(level, values.size()) - 1]


## Lista de erros do próprio talento (vazia = válido). Referências entre talentos: `TalentTree.validate()`.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"" or not String(id).begins_with("talent_"):
		errors.append("id inválido '%s' (prefixo talent_)" % id)
	if branch == &"":
		errors.append("%s sem ramo" % id)
	if name_key == "" or desc_key == "":
		errors.append("%s sem name_key/desc_key" % id)
	if costs.is_empty():
		errors.append("%s sem níveis" % id)
	if values.size() != costs.size():
		errors.append("%s: values e costs com tamanhos diferentes" % id)
	for c in costs:
		if c <= 0:
			errors.append("%s: custo <= 0" % id)
	for i in range(1, costs.size()):
		if costs[i] < costs[i - 1]:
			errors.append("%s: custo cai no nível %d" % [id, i + 1])
	if prereq_ids.size() != prereq_levels.size():
		errors.append("%s: prereq_ids e prereq_levels com tamanhos diferentes" % id)
	if grid_pos.x < 0 or grid_pos.y < 0:
		errors.append("%s: grid_pos negativa" % id)
	return errors
