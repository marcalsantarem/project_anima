class_name TalentBonuses
extends RefCounted
## Resolve os níveis comprados em bônus por atributo para o `MatchConfig.talent_bonuses` (T-204/T-205).
## Formato: `{ &"stat_x": float }` só com valores > 0. Percentuais e reduções = fração positiva somada
## (0,12 = +12% ou −12%); `stat_pierce`, `stat_start_particles` e `stat_wave_heal` = valor aditivo.
## `stat_coin_gain` fica de fora (é do meta, ver `MetaTalents.coin_gain`).

## Tetos dos Núcleos por atributo (ver docs/meta.md).
const CAPS := {
	&"stat_damage_taken": 0.5,
	&"stat_cooldown": 0.5,
	&"stat_core_hp_max": 0.4,
}


static func sum_stat(talents: Dictionary, tree: TalentTree, stat: StringName) -> float:
	var s := 0.0
	for t in tree.talents:
		if t.stat == stat:
			s += t.value_at(clampi(int(talents.get(t.id, 0)), 0, t.max_level()))
	return snappedf(s, 0.000001)


static func resolve(talents: Dictionary, tree: TalentTree) -> Dictionary:
	var stats := {}
	for t in tree.talents:
		if t.stat != &"stat_coin_gain":
			stats[t.stat] = true
	var out := {}
	for stat in stats:
		var v := minf(sum_stat(talents, tree, stat), float(CAPS.get(stat, INF)))
		if v > 0.0:
			out[stat] = v
	return out
