extends GutTest
## MatchRecorder com uma Arena falsa em passos fixos (sem tempo real): amostras, mortes por segundo,
## dano com fonte, upgrades, travadas, pausa, chefe, fim e arquivos.

class FakePool:
	extends RefCounted
	var n := 0
	func active_count() -> int:
		return n


class FakeArena:
	extends Node
	signal core_hp_changed(current: int, max_hp: int)
	signal wave_changed(current: int, total: int)
	signal particles_changed(total: int)
	signal match_ended(result: MatchResult)
	signal skill_used(slot: int)
	signal upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int)
	signal projectile_hit(at: Vector2, target_kind: StringName)
	signal enemy_died(at: Vector2, archetype_id: StringName, cause: int)
	signal skill_cast(slot: int, at: Vector2, radius: float)
	signal boss_spawned(id: StringName)
	signal boss_hp_changed(current: int, max_hp: int)
	signal boss_defense_changed(current: int, max_defense: int)
	signal boss_defeated
	var active_enemies: Array = []
	var particles := 0
	var projectiles := FakePool.new()
	var enemy_projectiles := FakePool.new()


class FakeHud:
	extends Node
	signal ui_pressed(button: StringName, ok: bool)


const FRAME_MS := 1000.0 / 60.0

var arena: FakeArena
var hud: FakeHud
var rec: MatchRecorder


func before_each() -> void:
	arena = FakeArena.new()
	hud = FakeHud.new()
	add_child_autofree(arena)
	add_child_autofree(hud)
	rec = MatchRecorder.new()
	rec.save_enabled = false
	rec.auto_process = false
	rec.attach(arena, hud, null, 42)
	add_child_autofree(rec)
	arena.core_hp_changed.emit(100, 100)


func _run(seconds: float, ms: float = FRAME_MS) -> void:
	for i in roundi(seconds * 1000.0 / ms):
		rec.step(ms)


func _events(type: String) -> Array:
	return rec.events.to_array().filter(func(e: Dictionary) -> bool: return e.e == type)


func test_header_and_start_event() -> void:
	assert_eq(rec.header.seed, 42)
	assert_true(rec.header.has("godot"))
	assert_true(rec.header.has("godot_logger"))
	assert_eq(_events("inicio").size(), 1)


func test_samples_every_second_with_counts() -> void:
	arena.projectiles.n = 4
	arena.enemy_projectiles.n = 2
	arena.wave_changed.emit(2, 10)
	_run(3.05)
	assert_eq(rec.samples.size(), 3)
	var cols := MatchRecorder.SAMPLE_COLS
	var row: Array = rec.samples.last()
	assert_eq(row[cols.find("proj_player")], 4)
	assert_eq(row[cols.find("proj_enemy")], 2)
	assert_eq(row[cols.find("wave")], 2)
	assert_eq(row[cols.find("energy")], 100)
	assert_almost_eq(float(row[cols.find("fps")]), 60.0, 0.5, "FPS da janela em passos fixos")
	assert_eq(_events("onda").size(), 1)


func test_kills_are_aggregated_per_second_and_type() -> void:
	for i in 3:
		arena.enemy_died.emit(Vector2.ZERO, &"enemy_swarm", 0)
	arena.enemy_died.emit(Vector2.ZERO, &"enemy_tank", 0)
	_run(1.1)
	var kills := _events("mortes")
	assert_eq(kills.size(), 1, "um evento por segundo")
	assert_eq(kills[0].por_tipo, {"enemy_swarm": 3, "enemy_tank": 1})
	_run(1.0)
	assert_eq(_events("mortes").size(), 1, "segundo sem mortes não gera evento")


func test_damage_gets_source_in_either_order() -> void:
	arena.projectile_hit.emit(Vector2.ZERO, &"core")
	arena.core_hp_changed.emit(90, 100)
	await wait_physics_frames(1)
	arena.core_hp_changed.emit(80, 100) # dano antes do aviso da fonte
	arena.enemy_died.emit(Vector2.ZERO, &"enemy_swarm", 1)
	var hits := _events("dano")
	assert_eq(hits.size(), 2)
	assert_eq(hits[0].valor, 10)
	assert_eq(hits[0].fonte, "projetil_inimigo")
	assert_eq(hits[1].fonte, "contato:enemy_swarm")
	assert_eq(hits[1].energia, 80)


func test_upgrade_bought_and_denied() -> void:
	arena.upgrade_changed.emit(&"upgrade_atk_power", 0, 5, 20)
	arena.particles = 5
	hud.ui_pressed.emit(&"upgrade_atk_power", false)
	var denied := _events("upgrade_negado")
	assert_eq(denied.size(), 1)
	assert_eq(denied[0].custo, 20)
	assert_eq(denied[0].particulas, 5)
	arena.particles = 3
	arena.upgrade_changed.emit(&"upgrade_atk_power", 1, 5, 35)
	var bought := _events("upgrade")
	assert_eq(bought.size(), 1)
	assert_eq(bought[0].nivel, 1)
	assert_eq(bought[0].custo, 20, "custo pago = next_cost anterior")
	assert_eq(bought[0].particulas_restantes, 3)
	assert_eq(_events("toque").size(), 1)


func test_hitch_event_has_context() -> void:
	arena.active_enemies = [Node2D.new(), Node2D.new()]
	arena.wave_changed.emit(3, 10)
	_run(0.5)
	rec.step(80.0)
	assert_eq(rec.hitches.size(), 1)
	var h: Dictionary = rec.hitches.last()
	assert_eq(h.ms, 80.0)
	assert_eq(h.inimigos, 2)
	assert_eq(h.onda, 3)
	assert_almost_eq(float(h.desde_anterior_s), 0.58, 0.02)
	assert_eq(rec.frames.over_50, 1)
	for n in arena.active_enemies:
		n.free()
	arena.active_enemies = []


func test_paused_frames_do_not_count() -> void:
	_run(0.5)
	var count := rec.frames.count
	var t := rec.match_time
	for i in 30:
		rec.step(FRAME_MS, true)
	assert_eq(rec.frames.count, count)
	assert_eq(rec.match_time, t)
	rec.step(FRAME_MS)
	assert_eq(_events("pausa").size(), 1)
	assert_eq(_events("retomada").size(), 1)


func test_boss_samples_faster_and_defense_milestones() -> void:
	arena.boss_spawned.emit(&"boss_test")
	arena.boss_defense_changed.emit(100, 100)
	arena.boss_defense_changed.emit(90, 100)
	arena.boss_defense_changed.emit(70, 100)
	arena.boss_defense_changed.emit(0, 100)
	_run(1.1)
	assert_between(rec.samples.size(), 4, 5, "amostras a cada 0,25 s com o chefe")
	assert_eq(_events("chefe_defesa").size(), 3, "início, quarto perdido e zero")
	arena.boss_defeated.emit()
	assert_eq(_events("chefe_derrotado").size(), 1)


func test_finish_builds_summary_once() -> void:
	_run(2.0)
	var result := MatchResult.new()
	result.outcome = MatchResult.Outcome.VICTORY
	result.wave_reached = 10
	result.waves_total = 10
	result.duration_s = 2.0
	watch_signals(rec)
	arena.match_ended.emit(result)
	rec.finish(result)
	assert_signal_emit_count(rec, "finished", 1)
	assert_true(rec.finished_ok)
	assert_eq(rec.log_data.result.resultado, "vitoria")
	assert_eq(rec.log_data.summary.resultado, "vitoria")
	assert_eq(_events("fim").size(), 1)
	var back = JSON.parse_string(JSON.stringify(rec.log_data))
	assert_eq(back.format, MatchRecorder.FORMAT)
	rec.step(FRAME_MS)
	assert_eq(rec.frames.count, 120, "depois do fim não grava mais")


func test_files_saved_and_rotated() -> void:
	var old := MatchRecorder.log_dir
	MatchRecorder.log_dir = "user://test_logs/"
	DirAccess.make_dir_recursive_absolute(MatchRecorder.log_dir)
	for i in 5:
		var r := MatchRecorder.new()
		r.auto_process = false
		r.attach(arena, null, null, i)
		add_child(r)
		r.step(FRAME_MS)
		r.finish(null)
		r.free()
	assert_true(MatchRecorder.has_last_log())
	var last := MatchRecorder.load_last()
	assert_eq(int(last.header.seed), 4, "o mais recente")
	assert_eq(last.result.resultado, "interrompida")
	assert_true(last.has("summary"))
	for i in range(1, 4):
		assert_true(FileAccess.file_exists(MatchRecorder.log_dir.path_join(MatchRecorder.PREV_FILE % i)))
	assert_false(FileAccess.file_exists(MatchRecorder.log_dir.path_join(MatchRecorder.PREV_FILE % 4)), "no máximo 3 anteriores")
	for f in DirAccess.get_files_at(MatchRecorder.log_dir):
		DirAccess.remove_absolute(MatchRecorder.log_dir.path_join(f))
	DirAccess.remove_absolute(MatchRecorder.log_dir)
	MatchRecorder.log_dir = old


func test_godot_errors_are_captured_when_logger_available() -> void:
	if not rec.header.godot_logger:
		pending("OS.add_logger indisponível")
		return
	push_warning("teste_debug_aviso")
	_run(1.05)
	var msgs := rec.errors.to_array().map(func(e: Dictionary) -> String: return str(e.msg))
	assert_true(msgs.any(func(m: String) -> bool: return m.contains("teste_debug_aviso")), "push_warning capturado")


func test_overlay_reads_recorder() -> void:
	var overlay := DebugOverlay.new()
	overlay.setup(rec)
	add_child_autofree(overlay)
	_run(1.05)
	overlay.refresh()
	assert_string_contains(overlay.label.text, "FPS")
	assert_eq(overlay.get_child(0).mouse_filter, Control.MOUSE_FILTER_IGNORE, "não pega toques")
