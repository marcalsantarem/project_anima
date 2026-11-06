class_name ProgressionData
extends Resource
## Curva de XP da conta e níveis de desbloqueio dos slots de skill (dados puros; lógica na T-186).

@export var max_level: int = 15
## XP para subir do nível N para N+1; índice 0 = nível 1 -> 2. Tamanho = max_level - 1.
@export var xp_to_next: PackedInt32Array = PackedInt32Array()
## Nível da conta que libera cada slot de skill (slot 1, 2, 3).
@export var slot_unlock_levels: PackedInt32Array = PackedInt32Array()


## Retorna a lista de erros (vazia = válido).
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if max_level < 2:
		errors.append("max_level < 2")
	if xp_to_next.size() != max_level - 1:
		errors.append("xp_to_next deve ter max_level - 1 entradas")
	for i in xp_to_next.size():
		if xp_to_next[i] <= 0:
			errors.append("xp_to_next[%d] <= 0" % i)
	return errors
