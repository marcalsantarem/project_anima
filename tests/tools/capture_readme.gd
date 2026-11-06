extends SceneTree
## Captura as imagens do README (BRF-082) com o jogo real, em 720×1474 (retrato do iPhone).
## Uso (com janela, não --headless):
##   godot --path . -s res://tests/tools/capture_readme.gd -- <pasta_saida>
## Gera titulo.png, partida.png e chefe-ogro.png (2 quadros lado a lado) na pasta (padrão: docs/img).
## A splash é HTML do shell: capture-a antes com o navegador em `<pasta_saida>/splash_raw.png`
## (ex.: chrome --headless=new --window-size=720,1474 --virtual-time-budget=4000 --screenshot=...
## servindo build/web por HTTP); o script a converte em splash.png. PNGs reduzidos até ≤ 400 KB.

const SIZE := Vector2i(720, 1474)
const SEED := 82
const MAX_BYTES := 400_000
const BOSS_W := 600 ## largura de cada quadro do chefe (2 × 600 = 1200)

var _out := "res://docs/img"
var _shots := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0]
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(SIZE)
	root.size = SIZE
	await _wait(1.0)
	var flow: Node = root.get_node("SceneFlow")
	flow.go_to_title()
	await _wait(2.5)
	await _shot("titulo.png")

	flow.start_match()
	var arena: Node = null
	while arena == null:
		await process_frame
		arena = root.find_child("Arena", true, false)
	arena.set_seed(SEED)
	await _wait(0.5)
	arena.particles = 400
	arena._emit_particles()
	# Partida: avança até a onda 3 com horda na tela e mostra a prévia de mira do meteoro.
	Engine.time_scale = 4.0
	while arena.waves.current_wave() < 3:
		await process_frame
	await _wait(5.0)
	Engine.time_scale = 1.0
	var t := 0.0
	while _on_screen(arena) < 10 and t < 40.0:
		await process_frame
		t += 1.0 / 60.0
	arena.particles = 400
	for id in [&"upgrade_atk_power", &"upgrade_atk_power", &"upgrade_atk_spd", &"upgrade_max_hp"]:
		arena.buy_upgrade(id)
	arena.show_skill_aim(1, _crowd(arena))
	await _wait(0.3)
	await _shot("partida.png")
	arena.hide_skill_aim()

	# Chefe: pula para a última onda e espera o ogro chegar perto do Núcleo.
	for e in arena.active_enemies.duplicate():
		e.queue_free()
	arena.active_enemies.clear()
	arena.anima.core.current = arena.anima.core.max_hp
	arena.waves._begin_wave(arena.waves.total_waves() - 1)
	var boss: Node = null
	while boss == null:
		await process_frame
		for e in arena.active_enemies:
			if e is Boss:
				boss = e
	Engine.time_scale = 3.0
	while not boss.in_reach():
		await process_frame
	Engine.time_scale = 1.0
	await _wait(0.8)
	await _shot("chefe_1.png")
	arena.skills.get_slot(1).remaining = 0.0
	arena.use_skill(1, boss.position)
	while boss.get("_stun_left") <= 0.0:
		await process_frame
	await _wait(1.1)
	await _shot("chefe_2.png")
	_finish()
	quit()


func _finish() -> void:
	_save(_shots["titulo.png"], "titulo.png")
	_save(_shots["partida.png"], "partida.png")
	var a: Image = _shots["chefe_1.png"]
	var b: Image = _shots["chefe_2.png"]
	var h := int(round(SIZE.y * float(BOSS_W) / SIZE.x))
	for img in [a, b]:
		img.convert(Image.FORMAT_RGB8)
		img.resize(BOSS_W, h, Image.INTERPOLATE_LANCZOS)
	var both := Image.create(BOSS_W * 2, h, false, Image.FORMAT_RGB8)
	both.blit_rect(a, Rect2i(0, 0, BOSS_W, h), Vector2i.ZERO)
	both.blit_rect(b, Rect2i(0, 0, BOSS_W, h), Vector2i(BOSS_W, 0))
	_save(both, "chefe-ogro.png")
	var raw := _path("splash_raw.png")
	if FileAccess.file_exists(raw):
		_save(Image.load_from_file(raw), "splash.png")


## Salva sem alfa; se passar de MAX_BYTES, reduz os bits por canal (6, 5, 4) até caber.
func _save(src: Image, file: String) -> void:
	var path := _path(file)
	for bits: int in [8, 6, 5, 4]:
		var img := src.duplicate() as Image
		img.convert(Image.FORMAT_RGB8)
		if bits < 8:
			var data := img.get_data()
			var mask: int = (0xFF << (8 - bits)) & 0xFF
			for i in data.size():
				data[i] = data[i] & mask
			img.set_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGB8, data)
		img.save_png(path)
		var size := FileAccess.get_file_as_bytes(path).size()
		print("salvo: ", path, " ", img.get_size(), " ", size / 1024, " KB (", bits, " bits)")
		if size <= MAX_BYTES:
			return


func _path(file: String) -> String:
	var path := _out.path_join(file)
	return ProjectSettings.globalize_path(path) if path.begins_with("res://") else path


func _crowd(arena: Node) -> Vector2:
	var best := Vector2.ZERO
	var best_n := -1
	for a in arena.active_enemies:
		var n := 0
		for b in arena.active_enemies:
			if a.position.distance_to(b.position) < 120.0:
				n += 1
		if n > best_n and arena.can_aim_at(a.position):
			best_n = n
			best = a.position
	return best


func _on_screen(arena: Node) -> int:
	var n := 0
	for e in arena.active_enemies:
		if arena.can_aim_at(e.position):
			n += 1
	return n


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _shot(file: String) -> void:
	await process_frame
	await process_frame
	_shots[file] = root.get_texture().get_image()
