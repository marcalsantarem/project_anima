extends SceneTree
## Relatório de progressão da conta (BRF-132, T-195; ferramenta manual, não é teste do GUT).
## Joga N partidas por perfil com o bot (x1, seeds fixas), aplica MetaRewards e a curva de
## ProgressionData e imprime XP/Moeda por partida e as partidas até cada nível.
## Uso: godot --headless --path . --fixed-fps 60 -s tests/tools/run_progression.gd -- --seeds=100 --per-day=4
## Perfis: weak = bot passivo (sem skill nem upgrades) com Núcleo a --weak-hp (padrão 0,15) do HP; perde nas ondas 3 a 6, mid = bot atual.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const WINDOW_SIZE := Vector2i(405, 720)
## Fração do HP do Núcleo do perfil fraco (só nesta ferramenta; passivo sozinho cai nas ondas 7-8; com 0,15 cai nas ondas 4-6).
var weak_hp := 0.15
var profiles := ["weak", "mid"]
const LEVELS := [2, 3, 4, 5, 6, 7, 8, 12, 20, 30]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = WINDOW_SIZE
	var n := 100
	var per_day := 4
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2 and kv[0] == "seeds":
			n = int(kv[1])
		elif kv.size() == 2 and kv[0] == "per-day":
			per_day = int(kv[1])
		elif kv.size() == 2 and kv[0] == "weak-hp":
			weak_hp = float(kv[1])
		elif kv.size() == 2 and kv[0] == "only":
			profiles = [kv[1]]
	var prog: ProgressionData = load("res://data/meta/progression_m2.tres")
	var rew: RewardData = load("res://data/meta/rewards_m2.tres")
	for profile in profiles:
		var rows: Array[MatchResult] = []
		for i in n:
			rows.append(await _play(i + 1, profile == "weak"))
		_report(profile, rows, prog, rew, per_day)
	quit()


func _play(seed: int, passive: bool) -> MatchResult:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.set_seed(seed)
	root.add_child(arena)
	var bot := SimBot.new()
	bot.passive = passive
	bot.attach(arena)
	if passive:
		arena.anima.core.max_hp = maxi(int(arena.anima.core.max_hp * weak_hp), 1)
		arena.anima.core.current = arena.anima.core.max_hp
	while bot.result == null and arena.elapsed < 900.0:
		await physics_frame
	var res := bot.result
	arena.queue_free()
	await process_frame
	return res


func _report(profile: String, rows: Array[MatchResult], prog: ProgressionData, rew: RewardData, per_day: int) -> void:
	var wins := 0
	var xp_sum := 0.0
	var coin_sum := 0.0
	var falls := {}
	for r in rows:
		if r.outcome == MatchResult.Outcome.VICTORY:
			wins += 1
		else:
			falls[r.wave_reached] = int(falls.get(r.wave_reached, 0)) + 1
		var c := MetaRewards.compute(r, rew, false)
		xp_sum += c.xp
		coin_sum += c.coins
	print("== %s: %d partidas, vitorias %d%%, XP medio (sem bonus) %.0f, Moeda media %.0f, quedas por onda %s" % [
		profile, rows.size(), 100 * wins / rows.size(), xp_sum / rows.size(), coin_sum / rows.size(), falls])
	# Progressão: 20 ordens circulares (deslocamentos) para estabilizar a média.
	var totals := {}
	var runs := 20
	for off in runs:
		var xp := 0
		var level := 1
		var count := 0
		var day_match := 0
		var won_today := false
		var reached := {}
		while level < prog.max_level and count < 2000:
			var r := rows[(off * 7 + count) % rows.size()]
			if day_match >= per_day:
				day_match = 0
				won_today = false
			var victory := r.outcome == MatchResult.Outcome.VICTORY
			xp += MetaRewards.compute(r, rew, victory and not won_today).xp
			if victory:
				won_today = true
			day_match += 1
			count += 1
			while level < prog.max_level and xp >= _acc(prog, level):
				level += 1
				reached[level] = count
		for lv in LEVELS:
			totals[lv] = float(totals.get(lv, 0.0)) + float(reached.get(lv, 2000))
	var line := "partidas ate nivel (%d/dia):" % per_day
	for lv in LEVELS:
		line += " N%d=%.1f" % [lv, totals[lv] / runs]
	print(line)


func _acc(prog: ProgressionData, level: int) -> int:
	var s := 0
	for i in level:
		s += prog.xp_to_next[i]
	return s
