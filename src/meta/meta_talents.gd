class_name MetaTalents
extends RefCounted
## Lógica de compra dos Núcleos (T-204, T-299: compra única, sem níveis). Pura: sem cena e sem rede.
## Quem chama salva pelo `Backend`. Save: `profile.talents = {id: 1}` (só os comprados; save antigo com nível >= 1 vale 1).
## API para a UI: `owned(profile, id) -> bool`, `cost(tree, id) -> int`, `prereq_status(profile, tree, id)`,
## `can_buy(profile, tree, id) -> Reason`, `buy(...)`, `spent_coins`, `respec`.

const NUCLEI_LEVEL := 3  ## nível da conta que libera os Núcleos (decisão 63)

enum Reason { OK, OWNED, LOCKED_PREREQ, NO_COINS, FEATURE_LOCKED, UNKNOWN }


static func owned(profile: PlayerProfile, id: StringName) -> bool:
	return int(profile.talents.get(id, 0)) >= 1


## 0 ou 1. Compatibilidade com a UI antiga; prefira `owned`.
static func level(profile: PlayerProfile, id: StringName) -> int:
	return 1 if owned(profile, id) else 0


## Custo do Núcleo (0 se desconhecido).
static func cost(tree: TalentTree, id: StringName) -> int:
	var t := tree.get_talent(id)
	return t.cost if t != null else 0


## Custo ainda a pagar (0 se desconhecido ou já comprado). Compatibilidade com a UI antiga.
static func next_cost(profile: PlayerProfile, tree: TalentTree, id: StringName) -> int:
	return 0 if owned(profile, id) else cost(tree, id)


## Pré-requisitos não comprados: `[{id}]` (vazio = todos ok).
static func prereq_status(profile: PlayerProfile, tree: TalentTree, id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := tree.get_talent(id)
	if t == null:
		return out
	for p in t.prereq_ids:
		if not owned(profile, p):
			out.append({"id": p})
	return out


## Motivo da compra: `Reason.OK` se pode comprar agora.
static func can_buy(profile: PlayerProfile, tree: TalentTree, id: StringName, min_level := NUCLEI_LEVEL) -> Reason:
	var t := tree.get_talent(id)
	if t == null:
		return Reason.UNKNOWN
	if profile.level < min_level:
		return Reason.FEATURE_LOCKED
	if owned(profile, id):
		return Reason.OWNED
	if not prereq_status(profile, tree, id).is_empty():
		return Reason.LOCKED_PREREQ
	if profile.coins < t.cost:
		return Reason.NO_COINS
	return Reason.OK


## Compra o Núcleo, tudo ou nada. Retorna `{ok, reason, cost}`.
static func buy(profile: PlayerProfile, tree: TalentTree, id: StringName, min_level := NUCLEI_LEVEL) -> Dictionary:
	var r := can_buy(profile, tree, id, min_level)
	if r != Reason.OK:
		return {"ok": false, "reason": r, "cost": 0}
	var c := cost(tree, id)
	profile.coins -= c
	profile.talents[id] = 1
	return {"ok": true, "reason": Reason.OK, "cost": c}


## Moeda gasta nos Núcleos comprados, pelos custos da tabela atual.
static func spent_coins(profile: PlayerProfile, tree: TalentTree) -> int:
	var s := 0
	for id in profile.talents:
		if owned(profile, id):
			s += cost(tree, id)
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
