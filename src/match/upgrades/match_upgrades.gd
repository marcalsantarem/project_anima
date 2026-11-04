class_name MatchUpgrades
extends RefCounted
## Níveis dos upgrades de uma partida. Lógica pura: não conhece Partículas nem cena.
## Uma instância nova por partida (reset).

const STAT_DAMAGE := &"stat_damage"
const STAT_FIRE_RATE := &"stat_fire_rate"
const STAT_DAMAGE_TAKEN := &"stat_damage_taken"
const STAT_CORE_HP_MAX := &"stat_core_hp_max"
const STAT_COOLDOWN := &"stat_cooldown"
const MIN_DAMAGE_TAKEN := 1

var _data: Array[UpgradeData] = []
var _levels: Dictionary = {} ## id -> nível


func _init(data: Array[UpgradeData] = []) -> void:
	for d in data:
		_data.append(d)
		_levels[d.id] = 0


static func path_for(id: StringName) -> String:
	return "res://data/upgrades/%s.tres" % id


static func from_ids(ids: Array[StringName]) -> MatchUpgrades:
	var list: Array[UpgradeData] = []
	for id in ids:
		list.append(load(path_for(id)))
	return MatchUpgrades.new(list)


func has(id: StringName) -> bool:
	return _levels.has(id)


func get_data(id: StringName) -> UpgradeData:
	for d in _data:
		if d.id == id:
			return d
	return null


func level(id: StringName) -> int:
	return _levels.get(id, 0)


func max_level(id: StringName) -> int:
	var d := get_data(id)
	return d.max_level if d else 0


## Custo do próximo nível; -1 no máximo ou se o id não existir.
func next_cost(id: StringName) -> int:
	var d := get_data(id)
	return d.cost_for(level(id) + 1) if d else -1


func can_buy(id: StringName, particles: int) -> bool:
	var cost := next_cost(id)
	return cost >= 0 and particles >= cost


## Sobe 1 nível (sem checar Partículas; quem cobra é a Arena). Devolve o custo pago ou -1.
func level_up(id: StringName) -> int:
	var cost := next_cost(id)
	if cost < 0:
		return -1
	_levels[id] += 1
	return cost


## Valor do atributo `stat` sobre `base`, somando os upgrades que o afetam.
func apply(stat: StringName, base: float) -> float:
	var value := base
	for d in _data:
		if d.stat == stat:
			value = d.value_at(value, _levels[d.id])
	return value


## Dano recebido pelo Núcleo depois da defesa (antes do escudo). Mínimo 1 se houver dano.
func damage_taken(amount: int) -> int:
	if amount <= 0:
		return 0
	return maxi(MIN_DAMAGE_TAKEN, roundi(apply(STAT_DAMAGE_TAKEN, amount)))
