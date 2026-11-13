class_name MetaTalents
extends RefCounted
## Lógica de compra dos Núcleos (T-204). Pura: sem cena e sem rede. Quem chama salva pelo `Backend`.

const NUCLEI_LEVEL := 3  ## nível da conta que libera os Núcleos (decisão 63)

enum Reason { OK, MAX, LOCKED_PREREQ, NO_COINS, FEATURE_LOCKED, UNKNOWN }


static func level(profile: PlayerProfile, id: StringName) -> int:
	return int(profile.talents.get(id, 0))


## Custo do próximo nível (0 se desconhecido ou já no máximo).
static func next_cost(profile: PlayerProfile, tree: TalentTree, id: StringName) -> int:
	var t := tree.get_talent(id)
	if t == null:
		return 0
	var lv := level(profile, id)
	return t.costs[lv] if lv < t.max_level() else 0


## Pré-requisitos que faltam: `[{id, need, have}]` (vazio = todos ok).
static func prereq_status(profile: PlayerProfile, tree: TalentTree, id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := tree.get_talent(id)
	if t == null:
		return out
	for i in t.prereq_ids.size():
		var need := t.prereq_levels[i]
		var have := level(profile, t.prereq_ids[i])
		if have < need:
			out.append({"id": t.prereq_ids[i], "need": need, "have": have})
	return out


## Motivo da compra: `Reason.OK` se pode comprar o próximo nível agora.
static func can_buy(profile: PlayerProfile, tree: TalentTree, id: StringName, min_level := NUCLEI_LEVEL) -> Reason:
	var t := tree.get_talent(id)
	if t == null:
		return Reason.UNKNOWN
	if profile.level < min_level:
		return Reason.FEATURE_LOCKED
	if level(profile, id) >= t.max_level():
		return Reason.MAX
	if not prereq_status(profile, tree, id).is_empty():
		return Reason.LOCKED_PREREQ
	if profile.coins < next_cost(profile, tree, id):
		return Reason.NO_COINS
	return Reason.OK


## Compra +1 nível, tudo ou nada. Retorna `{ok, reason, cost, level}`.
static func buy(profile: PlayerProfile, tree: TalentTree, id: StringName, min_level := NUCLEI_LEVEL) -> Dictionary:
	var r := can_buy(profile, tree, id, min_level)
	if r != Reason.OK:
		return {"ok": false, "reason": r, "cost": 0, "level": level(profile, id)}
	var cost := next_cost(profile, tree, id)
	profile.coins -= cost
	profile.talents[id] = level(profile, id) + 1
	return {"ok": true, "reason": Reason.OK, "cost": cost, "level": level(profile, id)}


## Moeda gasta nos níveis comprados, pelos custos da tabela atual.
static func spent_coins(profile: PlayerProfile, tree: TalentTree) -> int:
	var s := 0
	for id in profile.talents:
		var t := tree.get_talent(id)
		if t == null:
			continue
		for i in mini(level(profile, id), t.max_level()):
			s += t.costs[i]
	return s


## Respec grátis: devolve 100% da Moeda gasta e zera os Núcleos. Só fora de partida (quem chama garante). Retorna o reembolso.
static func respec(profile: PlayerProfile, tree: TalentTree) -> int:
	var refund := spent_coins(profile, tree)
	profile.coins = clampi(profile.coins + refund, 0, PlayerProfile.MAX_AMOUNT)
	profile.talents = {}
	return refund


## Bônus de Moeda dos Núcleos (fração, ex.: 0,15). Fora de `TalentBonuses.resolve`: é do meta.
static func coin_gain(talents: Dictionary, tree: TalentTree) -> float:
	return TalentBonuses.sum_stat(talents, tree, &"stat_coin_gain")
