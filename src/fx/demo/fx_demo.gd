extends Node2D
## Demonstração do FxPool (T-129): dispara os efeitos básicos em loop sobre um piso creme.
## Clique ou toque alterna o modo de efeitos reduzidos. Não depende de match/.

const FLOOR := Color("#F6E9CF")
const CENTER := Vector2(360, 640)
const DEATH_COLORS: Array[Color] = [Color("#FF8A3D"), Color("#E8344E"), Color("#FF3DB4"), Color("#9B5CFF")]

var pool: FxPool
var _t := 0.0
var _step := 0


func _ready() -> void:
	var floor_rect := ColorRect.new() # z -10 como o piso da arena: decalques (z -1) ficam por cima
	floor_rect.color = FLOOR
	floor_rect.size = Vector2(720, 1280)
	floor_rect.z_index = -10
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_rect)
	pool = FxPool.new()
	add_child(pool)
	pool.setup_default()


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.15:
		return
	_t = 0.0
	_fire(_step)
	_step += 1


func _fire(i: int) -> void:
	var ang := i * 0.9
	var far := CENTER + Vector2(cos(ang) * 250, sin(ang) * 250 * 0.75)
	pool.play(&"fx_muzzle", CENTER)
	pool.play(&"fx_hit", far)
	if i % 2 == 0:
		pool.play(&"fx_death", far + Vector2(-60, 40), DEATH_COLORS[(i / 2) % DEATH_COLORS.size()])
		pool.play(&"fx_pickup", far + Vector2(40, -30))
	if i % 7 == 0:
		pool.play(&"fx_telegraph", Vector2(360, 300))
		pool.play(&"fx_upgrade", CENTER)
	if i % 9 == 0:
		pool.play(&"fx_skill_cast", CENTER)
	if i % 5 == 0:
		pool.play(&"fx_core_pulse", CENTER)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pool.reduced_effects = not pool.reduced_effects


func _draw() -> void:
	# Marcador do Anima: base elíptica + cristal ciano (só referência de escala).
	draw_set_transform(CENTER, 0.0, Vector2(1, 0.75))
	draw_circle(Vector2.ZERO, 46, Color("#6B4E8C", 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(CENTER + Vector2(0, -40), 26, Color("#2FE6D2").darkened(0.55))
	draw_circle(CENTER + Vector2(0, -40), 22, Color("#2FE6D2"))
