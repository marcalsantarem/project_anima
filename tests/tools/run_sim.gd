extends SceneTree
## Simulação headless de balanceamento (BRF-051, ferramenta manual; não é teste do GUT).
## Uso (rápido: --fixed-fps faz cada quadro valer 1/60 s sem esperar o relógio):
##   godot --headless --path . --fixed-fps 60 -s tests/tools/run_sim.gd -- --seeds=20 --start=1
## Opções: --seeds=N (padrão 20), --start=S (primeira seed, padrão 1), --max-time=s (corte, padrão 900),
## --bot=0 (partida sem intervenção do jogador; padrão 1).
## Calibração do chefe sem editar o .tres (só nesta execução): --boss-hp=, --boss-dmg=,
## --boss-interval=, --boss-speed=.
## Imprime uma linha CSV por seed, uma linha "CHECK,..." por seed (lida por
## tests/integration/test_stage_01_sim.gd) e o resumo.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
## Mantém a instância do cache (as fases a reutilizam) para os overrides valerem em todas as seeds.
var _boss: BossData = load("res://data/enemies/boss_warden.tres")


func _initialize() -> void:
	_run.call_deferred()


## Janela em retrato (resolução base 720×1280 com stretch expand). Sem isso, a janela headless
## sai quadrada e a arena fica com 1280 px de largura.
const WINDOW_SIZE := Vector2i(405, 720)


func _run() -> void:
	root.size = WINDOW_SIZE
	var opts := {"seeds": 20, "start": 1, "max-time": 900.0, "bot": 1.0}
	var boss_fields := {"boss-hp": "hp", "boss-dmg": "attack_damage", "boss-interval": "attack_interval", "boss-speed": "speed"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2 and opts.has(kv[0]):
			opts[kv[0]] = float(kv[1])
		elif kv.size() == 2 and boss_fields.has(kv[0]):
			var field: String = boss_fields[kv[0]]
			_boss.set(field, int(kv[1]) if typeof(_boss.get(field)) == TYPE_INT else float(kv[1]))
	print("boss: hp %d, golpe %d a cada %.2f s, %.0f px/s" % [_boss.hp, _boss.attack_damage, _boss.attack_interval, _boss.speed])
	print("seed,boss,won,wave,core_at_boss_pct,boss_at_s,time_s,particles,upgrades")
	var rows: Array[Dictionary] = []
	for i in int(opts["seeds"]):
		var seed := int(opts["start"]) + i
		rows.append(await _play(seed, opts["max-time"], opts["bot"] == 0.0))
	_summary(rows)
	quit()


func _play(seed: int, max_time: float, passive := false) -> Dictionary:
	var arena: Arena = ARENA_SCENE.instantiate()
	arena.set_seed(seed)
	root.add_child(arena)
	var bot := SimBot.new()
	bot.passive = passive
	bot.attach(arena)
	while bot.result == null and arena.elapsed < max_time:
		await physics_frame
	var r := {
		"seed": seed, "boss": bot.reached_boss, "won": bot.result != null and bot.result.outcome == MatchResult.Outcome.VICTORY,
		"wave": arena.waves.current_wave(), "core": bot.boss_core_pct * 100.0, "boss_at": bot.boss_at, "time": arena.elapsed,
		"particles": bot.particles_earned, "upgrades": bot.upgrades_bought,
		"dmg": bot.damage_by_source,
		"casts": bot.horde_casts, "zero": bot.horde_zero_hits, "fizz": bot.fizzles,
		"core_end": 100.0 * arena.anima.core.current / maxf(arena.anima.core.max_hp, 1.0),
	}
	print("%d,%s,%s,%d,%.0f,%.0f,%.0f,%d,%d" % [seed, r.boss, r.won, r.wave, r.core, r.boss_at, r.time, r.particles, r.upgrades])
	# ended, outcome, wave_reached, waves_total, core_end, result_particles, arena_particles, match_ended_count
	var res := bot.result
	print("CHECK,%d,%s,%d,%d,%d,%d,%d,%d,%d" % [seed, res != null, res.outcome if res else -1,
		res.wave_reached if res else -1, res.waves_total if res else -1, arena.anima.core.current,
		res.particles if res else -1, arena.particles, bot.match_ended_count])
	arena.queue_free()
	await process_frame
	return r


func _summary(rows: Array[Dictionary]) -> void:
	var n := rows.size()
	var boss := 0
	var won := 0
	var core_sum := 0.0
	var boss_at_sum := 0.0
	var time_sum := 0.0
	var part_sum := 0
	var falls := {}
	var dmg := {}
	var fight_sum := 0.0 ## s de luta contra o chefe (todos que chegaram)
	var won_fight_sum := 0.0
	var won_core_sum := 0.0 ## Energia restante (%) de quem vence
	var casts := 0
	var zero := 0
	var fizz := 0
	for r in rows:
		for k in r.dmg:
			dmg[k] = dmg.get(k, 0) + r.dmg[k]
		time_sum += r.time
		casts += r.casts
		zero += r.zero
		fizz += r.fizz
		part_sum += r.particles
		if r.boss:
			boss += 1
			core_sum += r.core
			boss_at_sum += r.boss_at
			fight_sum += r.time - r.boss_at
		if r.won:
			won += 1
			won_fight_sum += r.time - r.boss_at
			won_core_sum += r.core_end
		elif not r.boss:
			falls[r.wave] = falls.get(r.wave, 0) + 1
	print("--- %d seeds ---" % n)
	print("chega ao chefe: %.0f%%  vence: %.0f%%" % [100.0 * boss / n, 100.0 * won / n])
	print("HP medio do Nucleo ao chegar ao chefe: %.0f%%" % (core_sum / maxi(boss, 1)))
	print("chefe entra em media aos %.0f s" % (boss_at_sum / maxi(boss, 1)))
	print("luta com o chefe: %.0f s (vitorias: %.0f s)  Energia restante de quem vence: %.0f%%" % [
		fight_sum / maxi(boss, 1), won_fight_sum / maxi(won, 1), won_core_sum / maxi(won, 1)])
	print("meteoros contra a horda: %d lancados, %d com 0 acertos (%.1f%%), %d anulados" % [
		casts, zero, 100.0 * zero / maxi(casts, 1), fizz])
	print("tempo medio: %.0f s  Particulas medias: %.0f" % [time_sum / n, float(part_sum) / n])
	print("cai antes do chefe (onda: seeds): %s" % [falls])
	for k in dmg:
		dmg[k] = roundi(float(dmg[k]) / n)
	print("dano bruto medio no Nucleo por origem: %s" % [dmg])
