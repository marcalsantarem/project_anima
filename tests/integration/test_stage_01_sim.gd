extends GutTest
## A fase real (stage_01) termina de forma consistente. Determinístico e rápido: roda
## tests/tools/run_sim.gd num processo filho com seed fixa e --fixed-fps 60 (cada quadro = 1/60 s,
## sem depender do relógio). Substitui o antigo test_stage_01_full_match_is_consistent (tempo real 4×).

const MAX_TIME := 900.0 ## s de partida; acima disso a simulação corta e o teste falha


## Linha "CHECK" do run_sim: CHECK, seed, ended, outcome, wave, total, core, result_particles, arena_particles, ended_count.
func _simulate(seed: int, bot: bool) -> PackedStringArray:
	var out: Array = []
	var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--fixed-fps", "60", "-s", "res://tests/tools/run_sim.gd", "--",
		"--seeds=1", "--start=%d" % seed, "--bot=%d" % int(bot), "--max-time=%d" % MAX_TIME])
	var code := OS.execute(OS.get_executable_path(), args, out, true)
	assert_eq(code, 0, "run_sim terminou")
	for chunk in out:
		for line in String(chunk).split("\n"):
			if line.begins_with("CHECK,"):
				return line.strip_edges().split(",")
	fail_test("sem linha CHECK na saída do run_sim")
	return PackedStringArray()


func _assert_consistent(c: PackedStringArray, label: String) -> void:
	if c.size() < 10:
		return
	gut.p("%s: %s" % [label, ",".join(c)])
	var total: int = load(StageData.path_for(&"stage_01")).waves.size()
	var outcome := int(c[3])
	var wave := int(c[4])
	var core := int(c[6])
	assert_eq(c[2], "true", "%s: partida termina" % label)
	assert_eq(int(c[9]), 1, "%s: match_ended uma vez" % label)
	assert_eq(int(c[5]), total, "%s: waves_total" % label)
	assert_between(wave, 1, total, label)
	assert_eq(int(c[7]), int(c[8]), "%s: Partículas do resultado = da arena" % label)
	if outcome == MatchResult.Outcome.VICTORY:
		assert_eq(wave, total, "%s: vitória só na última onda" % label)
		assert_gt(core, 0, label)
	else:
		assert_eq(core, 0, "%s: derrota com Núcleo zerado" % label)


func test_stage_01_without_player_ends_consistently() -> void:
	_assert_consistent(_simulate(1, false), "sem jogador")


func test_stage_01_with_bot_ends_consistently() -> void:
	var c := _simulate(1, true)
	_assert_consistent(c, "bot")
	if c.size() >= 10:
		assert_eq(int(c[4]), 10, "o bot médio chega ao chefe (BRF-051)")
