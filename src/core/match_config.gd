class_name MatchConfig
extends RefCounted
## Entrada da partida (dado puro). T-188: slots de Módulo pelo nível da conta; o AG04 amplia com `anima_data`.

const DEFAULT_MATCH_SCENE := "res://src/match/arena/arena.tscn"
const SLOT_COUNT := 3

var stage_id: StringName = &"stage_01"
## Cena da partida (a Arena). Deve expor `setup(config)` e o sinal `match_ended`.
var match_scene_path: String = DEFAULT_MATCH_SCENE
## Nível da conta que gerou a config (0 = config explícita, sem conta: testes, bot, demo).
var account_level := 0
## Slots de Módulo liberados (os `unlocked_slots` primeiros; 0 = só o ataque básico). Padrão explícito: slot 1.
var unlocked_slots := 1
## Módulo de cada slot (índice 0 = slot 1). Vazio = os Módulos da cena da Arena (hoje só o meteoro no slot 1).
var slot_modules: Array[SkillData] = []
## Bônus dos Núcleos (T-205): `{ &"stat_x": valor }` só com chaves > 0 (fração somada; `stat_pierce` e `stat_start_particles` aditivos). Vazio = partida padrão.
var talent_bonuses: Dictionary = {}


## Config da conta: slot n liberado só se `level >= unlock_levels[n-1]` (slots em ordem).
static func for_account(level: int, unlock_levels: PackedInt32Array) -> MatchConfig:
	var c := MatchConfig.new()
	c.account_level = level
	c.unlocked_slots = slots_unlocked(level, unlock_levels)
	return c


static func slots_unlocked(level: int, unlock_levels: PackedInt32Array) -> int:
	var n := 0
	for req in unlock_levels:
		if level < req:
			break
		n += 1
	return mini(n, SLOT_COUNT)


## Níveis para o HUD (`set_slot_unlock_levels`): 0 = liberado; > 0 = bloqueado com "NV x".
static func hud_lock_levels(level: int, unlock_levels: PackedInt32Array) -> Array[int]:
	var out: Array[int] = []
	for req in unlock_levels:
		out.append(0 if level >= req else req)
	return out
