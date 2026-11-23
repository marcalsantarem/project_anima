extends SceneTree
## Balanceamento dos Módulos (BRF-171, T-219; ferramenta manual, não é teste do GUT).
## Uso: godot --headless --path . --fixed-fps 60 -s tests/tools/run_modules.gd -- --load=MSF --lv=5 --tree=1 --seeds=100
## --load = letras dos Módulos por slot (M meteoro, S choque, F congelamento, H escudo); --lv = nível dos Módulos
## (1..5); --tree=1 = árvore de Núcleos inteira; --start=primeira seed. Imprime um resumo "MOD,...".

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const WINDOW_SIZE := Vector2i(405, 720)
const LETTERS := {"M": &"skill_meteor", "S": &"skill_shock", "F": &"skill_freeze", "H": &"skill_shield"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = WINDOW_SIZE
	var loadout := "M"
	var lv := 1
	var tree_on := false
	var n := 100
	var start := 1
	var hp_scale := 1.0 ## Núcleo com esta fração do HP (jogador menos eficiente que o bot); 1 = normal
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"load": loadout = kv[1]
			"lv": lv = int(kv[1])
			"tree": tree_on = kv[1] == "1"
			"seeds": n = int(kv[1])
			"start": start = int(kv[1])
			"hp": hp_scale = float(kv[1])
	var cat: ModuleCatalog = load("res://data/skills/module_catalog.tres")
	var prog: ProgressionData = load("res://data/meta/progression_m2.tres")
	var tree: TalentTree = load("res://data/talents/talent_tree.tres")
	var p := PlayerProfile.new()
	p.level = 8
	var slots: Array = []
	for ch in loadout:
		slots.append(LETTERS[ch])
		p.module_levels[LETTERS[ch]] = lv
	while slots.size() < 3:
		slots.append(&"")
	p.module_slots = slots
	if tree_on:
		for t in tree.talents:
			p.talents[t.id] = 1
	var wins := 0
	var boss_n := 0
	var time_sum := 0.0
	var core_all := 0.0
	var core_win := 0.0
	var fight_sum := 0.0
	var fall_sum := 0
	var uses := {}
	for i in n:
		var cfg := MatchConfig.for_account(p.level, prog.slot_unlock_levels)
		cfg.slot_modules = MetaModules.match_skills(p, cat, prog.slot_unlock_levels)
		cfg.talent_bonuses = TalentBonuses.resolve(p.talents, tree)
		var arena: Arena = ARENA_SCENE.instantiate()
		arena.setup(cfg)
		arena.set_seed(start + i)
		root.add_child(arena)
		var bot := SimBot.new()
		bot.use_modules = true
		bot.attach(arena)
		if hp_scale != 1.0:
			arena.anima.core.max_hp = maxi(int(arena.anima.core.max_hp * hp_scale), 1)
			arena.anima.core.current = arena.anima.core.max_hp
		while bot.result == null and arena.elapsed < 900.0:
			await physics_frame
		var won: bool = bot.result != null and bot.result.outcome == MatchResult.Outcome.VICTORY
		var core_pct := 100.0 * arena.anima.core.current / maxf(arena.anima.core.max_hp, 1.0)
		time_sum += arena.elapsed
		core_all += core_pct
		if bot.reached_boss:
			boss_n += 1
			fight_sum += arena.elapsed - bot.boss_at
		if won:
			wins += 1
			core_win += core_pct
		else:
			fall_sum += arena.waves.current_wave()
		for k in bot.module_uses:
			uses[k] = uses.get(k, 0) + bot.module_uses[k]
		arena.queue_free()
		await process_frame
	for k in uses:
		uses[k] = snappedf(float(uses[k]) / n, 0.1)
	print("MOD load=%s lv=%d tree=%d hp=%.2f n=%d | vence %d%% chefe %d%% | tempo %.0fs luta_chefe %.0fs | HP final %.0f%% (vencedores %.0f%%) | onda media da derrota %.1f | usos/partida %s" % [
		loadout, lv, int(tree_on), hp_scale, n, 100 * wins / n, 100 * boss_n / n, time_sum / n, fight_sum / maxi(boss_n, 1),
		core_all / n, core_win / maxi(wins, 1), float(fall_sum) / maxi(n - wins, 1), uses])
	quit()
