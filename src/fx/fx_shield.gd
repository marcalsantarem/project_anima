class_name FxShield
extends FxEffect
## Escudo do Núcleo (T-215): domo holográfico hexagonal em volta do Anima durante o escudo.
## `ripple(ratio)` = ondulação a cada dano absorvido; `end(broken)` = quebra em estilhaços ou some
## suave. Só visual. Sem alocação por quadro.

const SHIELD := Color("#4DA3FF")
const SHIELD_LIGHT := Color("#B8DCFF")
const SHIELD_OUTLINE := Color("#1B3F8C")
const LOW := Color("#FF7A7A")
const DOME_H := 120.0
const RIPPLE_TIME := 0.4
const MAX_RIPPLES := 3
const BREAK_TIME := 0.5
const FADE_TIME := 0.3
const SHARDS := 8

var _base := PackedVector2Array()
var _top := PackedVector2Array()
var _ripple_age := PackedFloat32Array()
var _ripple_ang := PackedFloat32Array()
var _ripple_n := 0
var _ratio := 1.0
var _end_t := -1.0
var _broken := false


func _init() -> void:
	_base.resize(7)
	_top.resize(7)
	_ripple_age.resize(MAX_RIPPLES)
	_ripple_ang.resize(MAX_RIPPLES)


func start(anchor: Vector2, fx_color: Color, fx_size: float, reduced_mode: bool) -> void:
	super(anchor, fx_color, fx_size, reduced_mode)
	_ripple_n = 0
	_ratio = 1.0
	_end_t = -1.0
	_broken = false


## Dano absorvido: ondulação num ponto da cúpula (ângulo variado, sem RNG). `ratio` = absorção restante (0..1).
func ripple(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	if reduced or _end_t >= 0.0:
		return
	var i := _ripple_n % MAX_RIPPLES
	_ripple_age[i] = elapsed
	_ripple_ang[i] = fposmod(_angle_offset + _ripple_n * 2.4, TAU)
	_ripple_n += 1


## Fim do escudo: quebrou (estilhaços) ou acabou o tempo (some suave).
func end(is_broken: bool) -> void:
	if not active or _end_t >= 0.0:
		return
	_end_t = elapsed
	_broken = is_broken
	delay = 0.0
	duration = elapsed + (0.1 if reduced else (BREAK_TIME if is_broken else FADE_TIME))


func _draw() -> void:
	if not active:
		return
	var rx := radius * size_scale
	var ry := rx * Y_SCALE
	var a := 1.0
	if _end_t >= 0.0:
		var q := elapsed - _end_t
		if _broken:
			_draw_shards(rx, ry, q / BREAK_TIME)
			if q > 0.08:
				return
			a = 1.0 - q / 0.08
		else:
			a = 1.0 - clampf(q / FADE_TIME, 0.0, 1.0)
	var grow := clampf(elapsed / 0.2, 0.0, 1.0)
	var col := SHIELD.lerp(LOW, (1.0 - _ratio) * 0.5)
	var shimmer := 1.0 if reduced else 0.85 + 0.15 * sin(elapsed * 6.0)
	_hex(_base, rx * grow, ry * grow, 0.0)
	_hex(_top, rx * 0.62 * grow, ry * 0.62 * grow, -DOME_H * grow)
	_dot(Vector2(0, -DOME_H * 0.45 * grow), rx * grow, Color(col, 0.2 * a * shimmer), 1.1)
	for k in 6:
		draw_line(_base[k], _top[k], Color(col, 0.55 * a * shimmer), 2.0)
	draw_polyline(_base, Color(SHIELD_OUTLINE, a), outline_width + 2.0)
	draw_polyline(_base, Color(col, a * shimmer), outline_width - 1.0)
	draw_polyline(_top, Color(SHIELD_OUTLINE, a * 0.8), 5.0)
	draw_polyline(_top, Color(SHIELD_LIGHT, a * shimmer), 2.5)
	if reduced or _end_t >= 0.0:
		return
	for i in mini(_ripple_n, MAX_RIPPLES):
		var age := (elapsed - _ripple_age[i]) / RIPPLE_TIME
		if age < 0.0 or age >= 1.0:
			continue
		var pos := Vector2(cos(_ripple_ang[i]) * rx * 0.8, -DOME_H * 0.5 + sin(_ripple_ang[i]) * ry * 0.8)
		var k := 1.0 - age
		_dot(pos, 16.0 * k, Color(SHIELD_LIGHT, 0.8 * k))
		_ring(pos, 12.0 + 50.0 * age, 6.0, Color(SHIELD_LIGHT, k))


func _hex(arr: PackedVector2Array, rx: float, ry: float, y: float) -> void:
	for k in 7:
		var ang := TAU * (k % 6) / 6.0
		arr[k] = Vector2(cos(ang) * rx, sin(ang) * ry + y)


func _draw_shards(rx: float, ry: float, q: float) -> void:
	if reduced or q >= 1.0:
		return
	var a := 1.0 - q
	for k in SHARDS:
		var ang := TAU * k / SHARDS + 0.4
		var from := Vector2(cos(ang) * rx, -DOME_H * 0.4 + sin(ang) * ry)
		var pos := from * (1.0 + 0.5 * q) + Vector2(0, 40.0 * q * q)
		_dot(pos, 14.0 * a + 3.0, Color(SHIELD_OUTLINE, a))
		_dot(pos, 14.0 * a, Color(SHIELD_LIGHT if k % 2 == 0 else SHIELD, a))
