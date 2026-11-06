class_name MetaProgress
extends RefCounted
## Nível da conta. No teto (nível máximo) o XP excedente é descartado e `xp` fica em 0.


## Soma XP ao perfil, com várias subidas de nível. Retorna {levels_gained, new_level, slots_unlocked}.
static func apply_xp(profile: PlayerProfile, xp: int, progression: ProgressionData) -> Dictionary:
	var old_level := clampi(profile.level, 1, progression.max_level)
	var level := old_level
	var pool := profile.xp + maxi(xp, 0)
	while level < progression.max_level and pool >= progression.xp_to_next[level - 1]:
		pool -= progression.xp_to_next[level - 1]
		level += 1
	if level >= progression.max_level:
		pool = 0
	profile.level = level
	profile.xp = pool
	var unlocked: Array[int] = []
	for i in progression.slot_unlock_levels.size():
		var lv := progression.slot_unlock_levels[i]
		if lv > old_level and lv <= level:
			unlocked.append(i + 1)
	return {"levels_gained": level - old_level, "new_level": level, "slots_unlocked": unlocked}


## Quantidade de slots liberados no nível dado.
static func slots_for_level(level: int, progression: ProgressionData) -> int:
	var n := 0
	for lv in progression.slot_unlock_levels:
		if level >= lv:
			n += 1
	return n
