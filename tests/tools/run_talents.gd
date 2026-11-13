extends SceneTree
## Balanceamento com Núcleos (BRF-157, T-209; ferramenta manual, não é teste do GUT).
## Política do bot: guarda `--share` (0,5 ou 1,0) da Moeda de cada partida para Núcleos e compra,
## enquanto der, o próximo nível mais barato disponível; empate = alterna ramos (Ataque, Defesa, Economia).
## A ordem de compra só depende da Moeda, então os marcos (1º talento, 25%, 50%, 100% do custo) são prefixos fixos.
## Uso:
##   bench:    godot --headless --path . --fixed-fps 60 -s tests/tools/run_talents.gd -- --mode=bench --states=none,first,p25,p50,p100 --only=mid
##   campanha: godot --headless --path . --fixed-fps 60 -s tests/tools/run_talents.gd -- --mode=campaign --only=mid --share=0.5 --per-day=4
## Perfis como em run_progression.gd: weak = passivo com Núcleo a 15% do HP; mid = bot atual.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const WINDOW_SIZE := Vector2i(405, 720)
const BRANCHES: Array[StringName] = [&"attack", &"defense", &"economy"]
const MILESTONES := {"p25": 0.25, "p50": 0.5, "p100": 1.0}
var weak_hp := 0.15
var profiles := ["weak", "mid"]
var tree: TalentTree
var prog: ProgressionData
var rew: RewardData


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = WINDOW_SIZE
	tree = load("res://data/talents/talent_tree.tres")
	prog = load("res://data/meta/progression_m2.tres")
	rew = load("res://data/meta/rewards_m2.tres")
	var mode := "bench"
	var n := 100
	var per_day := 4
	var share := 0.5
	var max_matches := 3000
	var states := ["none", "first", "p25", "p50", "p100"]
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"mode": mode = kv[1]
			"seeds": n = int(kv[1])
			"per-day": per_day = int(kv[1])
			"share": share = float(kv[1])
			"max": max_matches = int(kv[1])
			"only": profiles = [kv[1]]
			"states": states = Array(kv[1].split(","))
			"weak-hp": weak_hp = float(kv[1])
	print("arvore: %d Moeda; ordem de compra: %s" % [_total(), _order_text()])
	if mode == "bench":
		for profile in profiles:
			for s in states:
				await _bench(profile, s, n)
	else:
		for profile in profiles:
			await _campaign(profile, share, per_day, max_matches)
	quit()


# --- política -------------------------------------------------------------

func _total() -> int:
	var s := 0
	for t in tree.talents:
		for c in t.costs:
			s += c
	return s


## Próximo id pela política (ignora Moeda), ou &"" se a árvore estiver completa. `ptr` = ramo preferido.
func _pick(talents: Dictionary, ptr: int) -> StringName:
	var p := PlayerProfile.new()
	p.level = PlayerProfile.MAX_LEVEL
	p.coins = PlayerProfile.MAX_AMOUNT
	p.talents = talents
	var best: StringName = &""
	var best_cost := 0
	var best_rank := 99
	for t in tree.talents:
		if MetaTalents.can_buy(p, tree, t.id) != MetaTalents.Reason.OK:
			continue
		var cost := MetaTalents.next_cost(p, tree, t.id)
		var rank := posmod(BRANCHES.find(t.branch) - ptr, BRANCHES.size())
		if best == &"" or cost < best_cost or (cost == best_cost and rank < best_rank):
			best = t.id
			best_cost = cost
			best_rank = rank
	return best


## Sequência completa de compras: `[{id, cost, spent}]`.
func _order() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var talents := {}
	var ptr := 0
	var spent := 0
	while true:
		var id := _pick(talents, ptr)
		if id == &"":
			break
		var t := tree.get_talent(id)
		var cost: int = t.costs[int(talents.get(id, 0))]
		talents[id] = int(talents.get(id, 0)) + 1
		spent += cost
		ptr = (BRANCHES.find(t.branch) + 1) % BRANCHES.size()
		out.append({"id": id, "cost": cost, "spent": spent})
	return out


func _order_text() -> String:
	var parts := []
	for o in _order():
		parts.append(String(o.id).trim_prefix("talent_"))
	return ",".join(parts)


## Estado dos Núcleos num marco: "none", "first" (1ª compra) ou pXX (prefixo até gastar >= XX% do total).
func _state(name: String) -> Dictionary:
	var talents := {}
	if name == "none":
		return talents
	if ":" in name: # estado explícito: id:nível+id:nível (sem o prefixo talent_)
		for pair in name.split("+"):
			var kv := pair.split(":")
			talents[StringName("talent_" + kv[0])] = int(kv[1])
		return talents
	var goal := 1 if name == "first" else ceili(float(MILESTONES[name]) * _total())
	for o in _order():
		talents[o.id] = int(talents.get(o.id, 0)) + 1
		if name == "first" or int(o.spent) >= goal:
			break
	return talents


# --- partida --------------------------------------------------------------

func _play(seed: int, passive: bool, talents: Dictionary) -> MatchResult:
	var arena: Arena = ARENA_SCENE.instantiate()
	var cfg := MatchConfig.new()
	cfg.talent_bonuses = TalentBonuses.resolve(talents, tree)
	arena.setup(cfg)
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


func _bench(profile: String, state: String, n: int) -> void:
	var talents := _state(state)
	var g := MetaTalents.coin_gain(talents, tree)
	var wins := 0
	var fall_sum := 0
	var dur_sum := 0.0
	var dur_min := INF
	var xp_sum := 0.0
	var coin_sum := 0.0
	for i in n:
		var r := await _play(i + 1, profile == "weak", talents)
		if r.outcome == MatchResult.Outcome.VICTORY:
			wins += 1
		else:
			fall_sum += r.wave_reached
		dur_sum += r.duration_s
		dur_min = minf(dur_min, r.duration_s)
		var c := MetaRewards.compute(r, rew, false, g)
		xp_sum += c.xp
		coin_sum += c.coins
	var losses := n - wins
	print("BENCH %s %s (gasto %d): vitorias %d%%, onda media da derrota %s, duracao media %.0fs (min %.0fs), XP %.0f, Moeda %.0f por partida | %s" % [
		profile, state, MetaTalents.spent_coins(_profile_with(talents), tree), 100 * wins / n,
		("%.1f" % (float(fall_sum) / losses)) if losses > 0 else "-", dur_sum / n, dur_min,
		xp_sum / n, coin_sum / n, talents])


func _profile_with(talents: Dictionary) -> PlayerProfile:
	var p := PlayerProfile.new()
	p.talents = talents
	return p


# --- campanha -------------------------------------------------------------

func _campaign(profile: String, share: float, per_day: int, max_matches: int) -> void:
	var p := PlayerProfile.new()
	var wallet := 0.0 # Moeda reservada para Núcleos (fração `share`)
	var ptr := 0
	var total := _total()
	var marks := {}
	var count := 0
	var won_today := false
	var day_match := 0
	var block := {"wins": 0, "dur": 0.0, "coins": 0.0, "n": 0}
	while count < max_matches:
		if day_match >= per_day:
			day_match = 0
			won_today = false
		var r := await _play(count % 100 + 1, profile == "weak", p.talents)
		var victory := r.outcome == MatchResult.Outcome.VICTORY
		var c := MetaRewards.compute(r, rew, victory and not won_today, MetaTalents.coin_gain(p.talents, tree))
		if victory:
			won_today = true
		day_match += 1
		count += 1
		p.xp += c.xp
		while p.level < prog.max_level and p.xp >= _acc(p.level):
			p.level += 1
		wallet += share * c.coins
		block.wins += int(victory)
		block.dur += r.duration_s
		block.coins += c.coins
		block.n += 1
		# Compra enquanto der.
		while true:
			var id := _pick(p.talents, ptr)
			if id == &"":
				break
			p.coins = int(wallet)
			var res := MetaTalents.buy(p, tree, id)
			if not res.ok:
				break
			wallet -= res.cost
			ptr = (BRANCHES.find(tree.get_talent(id).branch) + 1) % BRANCHES.size()
		var spent := MetaTalents.spent_coins(p, tree)
		if spent > 0 and not marks.has("first"):
			marks["first"] = count
			print("CAMP %s share %.1f: 1o talento na partida %d (dia %d, NV %d)" % [profile, share, count, _day(count, per_day), p.level])
		for m in MILESTONES:
			if not marks.has(m) and spent >= ceili(float(MILESTONES[m]) * total):
				marks[m] = count
				print("CAMP %s share %.1f: %s na partida %d (dia %d, NV %d)" % [profile, share, m, count, _day(count, per_day), p.level])
		if count % 100 == 0 or marks.has("p100"):
			print("  [%d] gasto %d (%d%%), NV %d, ultimas %d: vitorias %d%%, duracao %.0fs, Moeda %.0f" % [
				count, spent, 100 * spent / total, p.level, block.n, 100 * block.wins / maxi(block.n, 1),
				block.dur / maxi(block.n, 1), block.coins / maxi(block.n, 1)])
			block = {"wins": 0, "dur": 0.0, "coins": 0.0, "n": 0}
		if marks.has("p100"):
			break
	if not marks.has("p100"):
		print("CAMP %s share %.1f: arvore incompleta apos %d partidas (%d dias), gasto %d" % [
			profile, share, count, _day(count, per_day), MetaTalents.spent_coins(p, tree)])


func _day(count: int, per_day: int) -> int:
	return ceili(float(count) / per_day)


func _acc(level: int) -> int:
	var s := 0
	for i in level:
		s += prog.xp_to_next[i]
	return s
