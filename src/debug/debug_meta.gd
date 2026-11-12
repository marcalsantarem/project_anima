class_name DebugMeta
extends RefCounted
## Ações de debug sobre o meta (T-193; docs/debug.md §4.1). Só pelo `MetaProgress` e pelo `Backend`
## (nunca grava arquivo direto). As funções `apply_*` mudam o perfil em memória; `run` aplica, salva
## e devolve o snapshot.

const XP_SMALL := 100
const XP_BIG := 1000
const COINS_STEP := 500

enum Action { XP_SMALL, XP_BIG, COINS, LEVEL_DOWN, LEVEL_UP, RESET }


static func snapshot(p: PlayerProfile) -> Dictionary:
	return {"nivel": p.level, "xp": p.xp, "moeda": p.coins}


static func line(p: PlayerProfile) -> String:
	return "Nível %d · XP %d · Moeda %d" % [p.level, p.xp, p.coins]


static func apply_xp(p: PlayerProfile, amount: int, prog: ProgressionData) -> void:
	MetaProgress.apply_xp(p, amount, prog)


static func apply_coins(p: PlayerProfile, amount: int) -> void:
	p.coins = clampi(p.coins + amount, 0, PlayerProfile.MAX_AMOUNT)


static func apply_level_step(p: PlayerProfile, step: int, prog: ProgressionData) -> void:
	MetaProgress.debug_set_level(p, p.level + step, prog)


static func action_name(a: Action) -> String:
	return Action.keys()[a].to_lower()


## Aplica a ação no perfil da conta (`SceneFlow.profile`) e persiste pelo `Backend`. `RESET` zera o save
## e recarrega o perfil. Retorna o snapshot depois da ação.
static func run(a: Action) -> Dictionary:
	if a == Action.RESET:
		Backend.reset_profile()
		return snapshot(SceneFlow.load_profile())
	var p: PlayerProfile = SceneFlow.profile if SceneFlow.profile != null else SceneFlow.load_profile()
	var prog: ProgressionData = SceneFlow.progression
	match a:
		Action.XP_SMALL:
			apply_xp(p, XP_SMALL, prog)
		Action.XP_BIG:
			apply_xp(p, XP_BIG, prog)
		Action.COINS:
			apply_coins(p, COINS_STEP)
		Action.LEVEL_DOWN:
			apply_level_step(p, -1, prog)
		Action.LEVEL_UP:
			apply_level_step(p, 1, prog)
	Backend.save_profile(p)
	return snapshot(p)
