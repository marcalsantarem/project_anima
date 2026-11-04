class_name UpgradeData
extends Resource
## Um upgrade da partida (pago com Partículas). Valores em data/upgrades/ (ver docs/meta.md).

enum Mode {
	ADD_PCT_BASE, ## base × (1 + per_level·L)
	ADD_FLAT, ## base + per_level·L
	REDUCTION_PCT, ## base × (1 − per_level·L)
}

@export var id: StringName
@export var stat: StringName
@export var per_level: float = 0.0
@export var mode: Mode = Mode.ADD_PCT_BASE
@export var max_level: int = 10
## Custo de cada nível comprado (índice 0 = nível 1). A tabela é a fonte da verdade.
@export var costs: PackedInt32Array = PackedInt32Array()


## Custo para comprar o nível `level` (1-based); -1 se acima do máximo.
func cost_for(level: int) -> int:
	if level < 1 or level > max_level or level > costs.size():
		return -1
	return costs[level - 1]


## Valor do atributo no nível `level` a partir do valor base.
func value_at(base: float, level: int) -> float:
	match mode:
		Mode.ADD_FLAT:
			return base + per_level * level
		Mode.REDUCTION_PCT:
			return base * maxf(1.0 - per_level * level, 0.0)
		_:
			return base * (1.0 + per_level * level)
