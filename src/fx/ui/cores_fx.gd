class_name CoresFx
extends RefCounted
## T-208 (BRF-156): efeitos de UI da tela de Núcleos (compra, nível máximo, desbloqueio, respec, falha).
## Só `Tween` e `CPUParticles2D` curtos (<= 0,6 s), criados por ação do jogador (nunca por quadro) e
## liberados por timer. Não bloqueiam a interação (`mouse_filter` ignorado). Modo reduzido: só a troca
## de estado (que a tela já faz) e, na falha, um tom vermelho sem movimento; nada de partículas.
## Quem chama passa as cores (ramo) e as texturas: `fx/` não depende de `ui/` nem de `meta/`.

const GOLD := Color("#FFD34D")
const FAIL_TINT := Color("#FF8080")
const DIM := Color(0.45, 0.5, 0.6)
const BUY_TIME := 0.45
const MAX_TIME := 0.55
const UNLOCK_RUN := 0.32
const RESPEC_TIME := 0.5
const FAIL_TIME := 0.3
const FAIL_SHAKE := 8.0
## Prefixo dos nós temporários (testes contam por ele).
const TEMP_PREFIX := "Fx"

const _K_PULSE := &"cores_fx_pulse"
const _K_CHIP := &"cores_fx_chip"
const _K_CHIP_Y := &"cores_fx_chip_y"
const _K_SHAKE := &"cores_fx_shake"
const _K_SHAKE_X := &"cores_fx_shake_x"
const _K_COUNT := &"cores_fx_count"
const _K_COUNT_TEXT := &"cores_fx_count_text"

## Ligado pela tela (DebugSettings) antes de cada ação.
static var reduced_effects := false

static var _dot: Texture2D
static var _add: CanvasItemMaterial
static var _fade: Gradient


## (1) Compra de nível: pulso + brilho na cor do ramo, anel e gotas; o selo n/máx "pula".
static func play_buy(node: Control, color: Color) -> void:
	if reduced_effects or not _ok(node):
		return
	_pulse(node, color, 1.12, BUY_TIME)
	_chip_jump(node, 12.0)
	_ring(node, color, BUY_TIME, 0.55, 0.85)
	_burst(node, color, 8, BUY_TIME)


## (2) Nível máximo: brilho dourado, anel e gotas douradas e a moldura `_max` entrando (escala → 1).
static func play_max(node: Control, max_frame: Texture2D = null) -> void:
	if reduced_effects or not _ok(node):
		return
	_pulse(node, GOLD, 1.16, MAX_TIME)
	_chip_jump(node, 14.0)
	_ring(node, GOLD, MAX_TIME, 0.5, 1.0)
	_burst(node, GOLD, 12, MAX_TIME)
	if max_frame == null:
		return
	var src := node.get_node_or_null(^"Frame") as Control
	var f := TextureRect.new()
	f.name = TEMP_PREFIX + "MaxFrame"
	f.texture = max_frame
	f.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f.stretch_mode = TextureRect.STRETCH_SCALE
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.position = src.position if src != null else Vector2.ZERO
	f.size = src.size if src != null else node.size
	f.pivot_offset = f.size / 2.0
	f.scale = Vector2.ONE * 1.35
	f.modulate.a = 0.0
	node.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, ^"scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(f, ^"modulate:a", 1.0, 0.12)
	tw.tween_property(f, ^"modulate:a", 0.0, MAX_TIME - 0.25).set_delay(0.03)
	_free_after(f, MAX_TIME)


## (3) Desbloqueio: a ligação acende com um ponto de luz correndo da origem ao destino; o nó liberado
## (`target`, opcional) pisca uma vez na chegada.
static func play_unlock(line: Line2D, target: Control, color: Color) -> void:
	if reduced_effects or not _ok(line) or line.points.size() < 2:
		return
	var pts := line.points
	var total := 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	_prepare()
	var head := Sprite2D.new()
	head.name = TEMP_PREFIX + "LinkHead"
	head.texture = _dot
	head.material = _add
	head.modulate = color.lightened(0.45)
	head.scale = Vector2.ONE * 0.9
	head.position = pts[0]
	line.add_child(head)
	var trail := _particles(color, 10, 0.22)
	trail.one_shot = false
	trail.explosiveness = 0.0
	trail.local_coords = false
	trail.spread = 180.0
	trail.initial_velocity_min = 5.0
	trail.initial_velocity_max = 20.0
	head.add_child(trail)
	trail.emitting = true
	var tw := line.create_tween()
	tw.tween_method(_move_along.bind(head, pts, total), 0.0, total, UNLOCK_RUN).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void: trail.emitting = false)
	tw.parallel().tween_property(head, ^"modulate:a", 0.0, 0.2)
	line.modulate = Color(1.6, 1.6, 1.6)
	line.create_tween().tween_property(line, ^"modulate", Color.WHITE, UNLOCK_RUN + 0.2)
	_free_after(head, UNLOCK_RUN + 0.25)
	if _ok(target):
		target.scale = Vector2.ONE
		var bt := _restart(target, _K_PULSE)
		bt.tween_interval(UNLOCK_RUN)
		bt.tween_property(target, ^"modulate", Color(1.9, 1.9, 1.9), 0.06)
		bt.tween_property(target, ^"modulate", Color.WHITE, 0.18)


## (4) Redistribuir: os nós comprados (`nodes`, na ordem) apagam em sequência rápida e o saldo conta de
## `from` até `to` (`fmt: func(int) -> String`). Se outro código mudar o texto no meio, a contagem para.
static func play_respec(nodes: Array, label: Label, from: int, to: int, fmt: Callable) -> void:
	if reduced_effects:
		return
	var live: Array[Control] = []
	for n: Variant in nodes:
		if n is Control and _ok(n as Control):
			live.append(n as Control)
	var step := minf(0.05, 0.3 / maxf(1.0, float(live.size())))
	for i in live.size():
		var n := live[i]
		n.modulate = Color(1.5, 1.5, 1.5)
		n.scale = Vector2.ONE
		var tw := _restart(n, _K_PULSE)
		tw.tween_interval(step * i)
		tw.tween_property(n, ^"modulate", DIM, 0.1)
		tw.tween_property(n, ^"modulate", Color.WHITE, 0.12)
	if not _ok(label) or from == to or not fmt.is_valid():
		return
	label.set_meta(_K_COUNT_TEXT, label.text)
	var ct := _restart(label, _K_COUNT)
	ct.tween_method(_count_step.bind(label, fmt), float(from), float(to), RESPEC_TIME).set_ease(Tween.EASE_OUT)


## (5) Sem Moeda / bloqueado: tremida horizontal curta (reduzido: só o tom vermelho, sem movimento).
static func play_fail(button: Control) -> void:
	if not _ok(button):
		return
	if reduced_effects:
		button.modulate = FAIL_TINT
		_restart(button, _K_SHAKE).tween_property(button, ^"modulate", Color.WHITE, FAIL_TIME)
		return
	if not button.has_meta(_K_SHAKE_X):
		button.set_meta(_K_SHAKE_X, button.position.x)
	var base: float = button.get_meta(_K_SHAKE_X)
	button.modulate = FAIL_TINT
	var tw := _restart(button, _K_SHAKE)
	tw.tween_method(_shake_step.bind(button, base), 0.0, 1.0, FAIL_TIME)
	tw.parallel().tween_property(button, ^"modulate", Color.WHITE, FAIL_TIME)
	tw.tween_callback(_shake_end.bind(button, base))


# --- Internos ---------------------------------------------------------------------------------

static func _ok(n: Node) -> bool:
	return n != null and is_instance_valid(n) and n.is_inside_tree()


## Mata o tween anterior da mesma chave (cliques rápidos não empilham) e cria outro preso ao nó.
static func _restart(node: Node, key: StringName) -> Tween:
	var old: Variant = node.get_meta(key) if node.has_meta(key) else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var tw := node.create_tween()
	node.set_meta(key, tw)
	return tw


static func _pulse(node: Control, color: Color, peak: float, time: float) -> void:
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE
	node.modulate = Color.WHITE.lerp(color, 0.5) * 1.6
	node.modulate.a = 1.0
	var tw := _restart(node, _K_PULSE)
	tw.tween_property(node, ^"scale", Vector2.ONE * peak, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, ^"modulate", Color.WHITE, time)
	tw.tween_property(node, ^"scale", Vector2.ONE, time - 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func _chip_jump(node: Control, height: float) -> void:
	var chip := node.get_node_or_null(^"Chip") as Control
	if chip == null:
		return
	if not chip.has_meta(_K_CHIP_Y):
		chip.set_meta(_K_CHIP_Y, chip.position.y)
	var y: float = chip.get_meta(_K_CHIP_Y)
	chip.position.y = y
	chip.pivot_offset = chip.size / 2.0
	var tw := _restart(chip, _K_CHIP)
	tw.tween_property(chip, ^"position:y", y - height, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(chip, ^"scale", Vector2.ONE * 1.18, 0.12)
	tw.tween_property(chip, ^"position:y", y, 0.26).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tw.parallel().tween_property(chip, ^"scale", Vector2.ONE, 0.2)


static func _ring(node: Control, color: Color, time: float, r0: float, r1: float) -> void:
	var r := Ring.new()
	r.name = TEMP_PREFIX + "Ring"
	r.color = color
	r.r0 = node.size.x * r0
	r.r1 = node.size.x * r1
	r.size = node.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(r)
	r.create_tween().tween_property(r, ^"t", 1.0, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_free_after(r, time)


static func _burst(node: Control, color: Color, amount: int, time: float) -> void:
	var p := _particles(color, amount, time - 0.05)
	p.position = node.size / 2.0
	node.add_child(p)
	p.emitting = true
	_free_after(p, time)


static func _particles(color: Color, amount: int, life: float) -> CPUParticles2D:
	_prepare()
	var p := CPUParticles2D.new()
	p.name = TEMP_PREFIX + "Particles"
	p.texture = _dot
	p.material = _add
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0.0, 120.0)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 170.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.55
	p.color = color.lightened(0.2)
	p.color_ramp = _fade
	return p


## Atlas mínimo, gerado uma vez: gota radial branca (tingida), material aditivo e rampa de fade.
static func _prepare() -> void:
	if _dot != null:
		return
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.85))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	_dot = tex
	_add = CanvasItemMaterial.new()
	_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fade = Gradient.new()
	_fade.set_color(0, Color(1, 1, 1, 1))
	_fade.set_color(1, Color(1, 1, 1, 0))


static func _free_after(n: Node, time: float) -> void:
	n.get_tree().create_timer(time + 0.05).timeout.connect(n.queue_free)


static func _move_along(d: float, head: Node2D, pts: PackedVector2Array, _total: float) -> void:
	if not is_instance_valid(head):
		return
	var left := d
	for i in range(1, pts.size()):
		var seg := pts[i - 1].distance_to(pts[i])
		if left <= seg or i == pts.size() - 1:
			head.position = pts[i - 1].lerp(pts[i], clampf(left / maxf(seg, 0.001), 0.0, 1.0))
			return
		left -= seg


static func _count_step(v: float, label: Label, fmt: Callable) -> void:
	if label.text != str(label.get_meta(_K_COUNT_TEXT, label.text)):
		var tw: Variant = label.get_meta(_K_COUNT) if label.has_meta(_K_COUNT) else null
		if tw is Tween:
			(tw as Tween).kill()
		return
	var s := str(fmt.call(roundi(v)))
	label.text = s
	label.set_meta(_K_COUNT_TEXT, s)


static func _shake_step(t: float, button: Control, base: float) -> void:
	button.position.x = base + sin(t * TAU * 4.0) * FAIL_SHAKE * (1.0 - t)


static func _shake_end(button: Control, base: float) -> void:
	button.position.x = base
	button.remove_meta(_K_SHAKE_X)
	var parent := button.get_parent() as Container
	if parent != null:
		parent.queue_sort()


## Anel que abre e some (desenhado por código; 1 arco por quadro enquanto vivo).
class Ring extends Control:
	var color := Color.WHITE
	var r0 := 40.0
	var r1 := 80.0
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var c := color
		c.a = 1.0 - t
		draw_arc(size / 2.0, lerpf(r0, r1, t), 0.0, TAU, 40, c, lerpf(7.0, 1.5, t), true)
