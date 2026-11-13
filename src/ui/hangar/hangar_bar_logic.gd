class_name HangarBarLogic
extends RefCounted
## Lógica pura da barra do hangar (T-201, BRF-146): ordem visual, nível de desbloqueio (decisão 63, lido de
## `ProgressionData`) e estado de cada item. Sem cena nem autoload.

enum State { NORMAL, ACTIVE, LOCKED }

## Ordem visual da barra (Jogar no centro).
const ORDER: Array[StringName] = [
	HangarNav.MODULES, HangarNav.COMPONENTS, HangarNav.PLAY, HangarNav.CORES, HangarNav.SETTINGS,
]
const LABELS := {
	HangarNav.MODULES: "Módulos", HangarNav.COMPONENTS: "Componentes", HangarNav.PLAY: "Jogar",
	HangarNav.CORES: "Núcleos", HangarNav.SETTINGS: "Ajustes",
}
## Chave de `feature_unlock_levels` por destino; Módulos usa o slot 1; Jogar e Ajustes não bloqueiam.
const FEATURE_KEYS := {HangarNav.COMPONENTS: &"components", HangarNav.CORES: &"nuclei"}


static func label_of(id: StringName) -> String:
	return LABELS.get(id, "")


## Nível da conta que libera o destino (1 = sempre livre).
static func unlock_level(id: StringName, prog: ProgressionData) -> int:
	if prog == null:
		return 1
	if id == HangarNav.MODULES:
		return prog.slot_unlock_levels[0] if prog.slot_unlock_levels.size() > 0 else 1
	if FEATURE_KEYS.has(id):
		return int(prog.feature_unlock_levels.get(String(FEATURE_KEYS[id]), 1))
	return 1


static func is_locked(id: StringName, level: int, prog: ProgressionData) -> bool:
	return level < unlock_level(id, prog)


static func state_of(id: StringName, current: StringName, level: int, prog: ProgressionData) -> State:
	if is_locked(id, level, prog):
		return State.LOCKED
	return State.ACTIVE if id == current else State.NORMAL


## Selo do bloqueado: "NV 4".
static func lock_text(id: StringName, prog: ProgressionData) -> String:
	return "NV %d" % unlock_level(id, prog)


## Aviso curto ao tocar num item bloqueado.
static func lock_hint(id: StringName, prog: ProgressionData) -> String:
	return "%s libera no NV %d" % [label_of(id), unlock_level(id, prog)]
