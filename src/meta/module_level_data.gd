class_name ModuleLevelData
extends Resource
## Valores por nível (1..5) de um Módulo (T-213). Dado puro; o `.tres` do Módulo (`base`) guarda o Nv 1 e é só leitura.

const MAX_LEVEL := 5

@export var module_id: StringName
## Nível da conta que libera o Módulo (cria o Nv 1, sem custo).
@export var unlock_level: int = 2
## SkillData base (Nv 1 e campos sem variação por nível). Nunca é alterado.
@export var base: SkillData
## Moeda para ir do nível N ao N+1; índice 0 = Nv 1 -> 2 (4 entradas).
@export var cost_to_next: PackedInt32Array = PackedInt32Array()
## 5 Dictionaries (índice 0 = Nv 1). Chaves opcionais: damage, radius, cooldown, duration, params (vai para effect_params).
@export var levels: Array = []


func cost_from(level: int) -> int:
	if level < 1 or level > cost_to_next.size():
		return 0
	return cost_to_next[level - 1]


func total_cost() -> int:
	var s := 0
	for c in cost_to_next:
		s += c
	return s


## Cópia do `base` com os valores do nível (1..5, fora da faixa é ajustado). O recurso carregado não muda.
func skill_at(level: int) -> SkillData:
	if base == null:
		return null
	var s: SkillData = base.duplicate()
	s.effect_params = base.effect_params.duplicate(true)
	var lv := clampi(level, 1, MAX_LEVEL)
	if lv - 1 < levels.size() and levels[lv - 1] is Dictionary:
		var d: Dictionary = levels[lv - 1]
		if d.has("damage"):
			s.damage = int(d["damage"])
		if d.has("radius"):
			s.radius = float(d["radius"])
		if d.has("cooldown"):
			s.cooldown = float(d["cooldown"])
		if d.has("duration"):
			s.duration = float(d["duration"])
		var params: Variant = d.get("params", {})
		if params is Dictionary:
			for k in params:
				s.effect_params[k] = params[k]
	return s


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if module_id == &"":
		errors.append("module_id vazio")
	if base == null:
		errors.append("%s: base ausente" % module_id)
	elif base.id != module_id:
		errors.append("%s: base.id diferente (%s)" % [module_id, base.id])
	if levels.size() != MAX_LEVEL:
		errors.append("%s: levels deve ter %d entradas" % [module_id, MAX_LEVEL])
	if cost_to_next.size() != MAX_LEVEL - 1:
		errors.append("%s: cost_to_next deve ter %d entradas" % [module_id, MAX_LEVEL - 1])
	for c in cost_to_next:
		if c <= 0:
			errors.append("%s: custo <= 0" % module_id)
	return errors
