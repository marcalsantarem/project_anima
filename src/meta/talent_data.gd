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
## Pré-requisitos: todos os `prereq_ids` precisam estar comprados.
@export var prereq_ids: Array[StringName] = []
## Atributo afetado e como o valor entra (ver docs/meta.md).
@export var stat: StringName = &""
@export var mode: Mode = Mode.ADD_PCT_BASE
## Efeito do Núcleo comprado (compra única, sem níveis). Percentuais em fração (0,25 = 25%).
@export var value: float = 0.0
## Custo único em Moeda.
@export var cost: int = 0


## Sempre 1 (compra única). Mantido só por compatibilidade com a UI antiga.
func max_level() -> int:
	return 1


## Efeito com o Núcleo `owned` (comprado) ou 0.
func value_at(level: int) -> float:
	return value if level >= 1 else 0.0


## Lista de erros do próprio talento (vazia = válido). Referências entre talentos: `TalentTree.validate()`.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"" or not String(id).begins_with("talent_"):
		errors.append("id inválido '%s' (prefixo talent_)" % id)
	if branch == &"":
		errors.append("%s sem ramo" % id)
	if name_key == "" or desc_key == "":
		errors.append("%s sem name_key/desc_key" % id)
	if cost <= 0:
		errors.append("%s: custo <= 0" % id)
	if value <= 0.0:
		errors.append("%s: valor <= 0" % id)
	if grid_pos.x < 0 or grid_pos.y < 0:
		errors.append("%s: grid_pos negativa" % id)
	return errors
