class_name MetaModules
extends RefCounted
## Evolução e equipamento dos Módulos (T-213, BRF-166). Pura: sem cena e sem rede; quem chama salva pelo `Backend`.
## Save: `profile.module_levels = {id: 1..5}` (ausente = Nv 1 se a conta já liberou) e
## `profile.module_slots = [id|&"", ...]` (índice 0 = slot 1; vazio `[]` = nunca personalizado: padrão automático).
## Sem respec de Módulos. API para a UI: `unlocked`, `level`, `next_cost`, `can_upgrade`, `upgrade`,
## `equipped`, `equip`, `unequip`, `match_skills`, `spent_coins`.

enum Reason { OK, MAX, NO_COINS, LOCKED, UNKNOWN }
enum EquipReason { OK, UNKNOWN, LOCKED, BAD_SLOT, SLOT_LOCKED, ALREADY_EQUIPPED }


## Liberado pelo nível da conta.
static func unlocked(profile: PlayerProfile, cat: ModuleCatalog, id: StringName) -> bool:
	var m := cat.get_module(id)
	return m != null and profile.level >= m.unlock_level


## 0 se bloqueado ou desconhecido; senão 1..5 (liberado sem compra = Nv 1).
static func level(profile: PlayerProfile, cat: ModuleCatalog, id: StringName) -> int:
	if not unlocked(profile, cat, id):
		return 0
	return clampi(int(profile.module_levels.get(id, 1)), 1, ModuleLevelData.MAX_LEVEL)


## Custo do próximo nível (0 se no máximo, bloqueado ou desconhecido).
static func next_cost(profile: PlayerProfile, cat: ModuleCatalog, id: StringName) -> int:
	var lv := level(profile, cat, id)
	if lv == 0 or lv >= ModuleLevelData.MAX_LEVEL:
		return 0
	return cat.get_module(id).cost_from(lv)


static func can_upgrade(profile: PlayerProfile, cat: ModuleCatalog, id: StringName) -> Reason:
	var m := cat.get_module(id)
	if m == null:
		return Reason.UNKNOWN
	var lv := level(profile, cat, id)
	if lv == 0:
		return Reason.LOCKED
	if lv >= ModuleLevelData.MAX_LEVEL:
		return Reason.MAX
	if profile.coins < m.cost_from(lv):
		return Reason.NO_COINS
	return Reason.OK


## Evolui 1 nível, tudo ou nada. Retorna `{ok, reason, cost, level}`.
static func upgrade(profile: PlayerProfile, cat: ModuleCatalog, id: StringName) -> Dictionary:
	var r := can_upgrade(profile, cat, id)
	if r != Reason.OK:
		return {"ok": false, "reason": r, "cost": 0, "level": level(profile, cat, id)}
	var c := next_cost(profile, cat, id)
	var lv := level(profile, cat, id) + 1
	profile.coins -= c
	profile.module_levels[id] = lv
	return {"ok": true, "reason": Reason.OK, "cost": c, "level": lv}


## Moeda gasta nos Módulos (soma dos custos dos níveis alcançados).
static func spent_coins(profile: PlayerProfile, cat: ModuleCatalog) -> int:
	var s := 0
	for m in cat.modules:
		for lv in range(1, level(profile, cat, m.module_id)):
			s += m.cost_from(lv)
	return s


## Módulo de cada slot (tamanho `MatchConfig.SLOT_COUNT`; `&""` = vazio). Só slots liberados e Módulos liberados valem.
## Sem personalização salva, preenche os slots liberados com os Módulos liberados, na ordem do catálogo.
static func equipped(profile: PlayerProfile, cat: ModuleCatalog, slot_levels: PackedInt32Array) -> Array[StringName]:
	var n := MatchConfig.slots_unlocked(profile.level, slot_levels)
	var out: Array[StringName] = []
	out.resize(MatchConfig.SLOT_COUNT)
	out.fill(&"")
	var custom := not profile.module_slots.is_empty()
	var pool: Array[StringName] = []
	for id in cat.ids():
		if unlocked(profile, cat, id):
			pool.append(id)
	for i in n:
		if custom:
			var id: StringName = profile.module_slots[i] if i < profile.module_slots.size() else &""
			if id != &"" and unlocked(profile, cat, id) and not (id in out):
				out[i] = id
		elif i < pool.size():
			out[i] = pool[i]
	return out


## Põe o Módulo no slot (1-based). Recusa com motivo; o mesmo Módulo no mesmo slot é OK.
static func equip(profile: PlayerProfile, cat: ModuleCatalog, slot_levels: PackedInt32Array, slot: int, id: StringName) -> EquipReason:
	if slot < 1 or slot > MatchConfig.SLOT_COUNT:
		return EquipReason.BAD_SLOT
	if cat.get_module(id) == null:
		return EquipReason.UNKNOWN
	if slot > MatchConfig.slots_unlocked(profile.level, slot_levels):
		return EquipReason.SLOT_LOCKED
	if not unlocked(profile, cat, id):
		return EquipReason.LOCKED
	var cur := equipped(profile, cat, slot_levels)
	var at := cur.find(id)
	if at != -1 and at != slot - 1:
		return EquipReason.ALREADY_EQUIPPED
	cur[slot - 1] = id
	profile.module_slots = cur
	return EquipReason.OK


## Esvazia o slot (1-based). Retorna `false` se o slot é inválido, bloqueado ou já vazio.
static func unequip(profile: PlayerProfile, cat: ModuleCatalog, slot_levels: PackedInt32Array, slot: int) -> bool:
	if slot < 1 or slot > MatchConfig.SLOT_COUNT:
		return false
	var cur := equipped(profile, cat, slot_levels)
	if cur[slot - 1] == &"":
		return false
	cur[slot - 1] = &""
	profile.module_slots = cur
	return true


## `SkillData` equipados com os valores do nível (cópias), um por slot; `null` = vazio. Tamanho `SLOT_COUNT`.
static func match_skills(profile: PlayerProfile, cat: ModuleCatalog, slot_levels: PackedInt32Array) -> Array[SkillData]:
	var out: Array[SkillData] = []
	for id in equipped(profile, cat, slot_levels):
		out.append(null if id == &"" else cat.get_module(id).skill_at(level(profile, cat, id)))
	return out
