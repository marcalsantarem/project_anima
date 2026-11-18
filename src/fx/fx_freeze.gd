class_name FxFreeze
extends FxEffect
## Congelamento (T-215): onda de gelo no raio + película e cristais sobre cada inimigo parado
## + estilhaços quando descongela. Chefe (só lento): brilho de lentidão. Um único nó por uso;
## lê `position`/`frozen_left`/`slow_left` dos inimigos por duck typing (fx/ não depende de match/).
## Só visual. Sem alocação por quadro (arrays pré-dimensionados).

const MAX_ENEMIES := 20
const WAVE_TIME := 0.5
const SHATTER_TIME := 0.3
const ICE := Color("#7FE8FF")
const ICE_LIGHT := Color("#D8F8FF")
const ICE_OUTLINE := Color("#1D5F8A")

var _enemies: Array = []
var _center := Vector2.ZERO ## âncora da onda no espaço da arena (para posicionar os inimigos)
var _last := PackedVector2Array()
var _state := PackedByteArray() ## 0 = parado/lento, 1 = descongelou (estilhaços), 2 = fim
var _thaw_at := PackedFloat32Array()
var _slow_only := PackedByteArray()


func _init() -> void:
	_last.resize(MAX_ENEMIES)
	_state.resize(MAX_ENEMIES)
	_thaw_at.resize(MAX_ENEMIES)
	_slow_only.resize(MAX_ENEMIES)


func start(anchor: Vector2, fx_color: Color, fx_size: float, reduced_mode: bool) -> void:
	_enemies.clear()
	super(anchor, fx_color, fx_size, reduced_mode)


## `center` = ponto do impacto no espaço da arena; `list` = inimigos atingidos (no máx. MAX_ENEMIES).
func set_enemies(center: Vector2, list: Array) -> void:
	_center = center
	_enemies.clear()
	for e: Object in list:
		if _enemies.size() >= MAX_ENEMIES:
			break
		var i := _enemies.size()
		_enemies.append(e)
		_state[i] = 0
		_slow_only[i] = 1 if float(e.get("frozen_left")) <= 0.0 else 0
		_last[i] = Vector2(e.get("position")) - center


func _draw() -> void:
	if not active or elapsed < delay:
		return
	var t := elapsed - delay
	if t < WAVE_TIME:
		_draw_wave(t / WAVE_TIME)
	for i in _enemies.size():
		_draw_enemy(i, t)


func _draw_wave(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 2.0)
	var a := 1.0 - smoothstep(0.4, 1.0, p)
	_dot(Vector2.ZERO, r * e, Color(ICE, 0.2 * a), Y_SCALE)
	_ring(Vector2.ZERO, r * e, 9.0, Color(ICE_OUTLINE, a), Y_SCALE)
	_ring(Vector2.ZERO, r * e, 5.0, Color(ICE, a), Y_SCALE)
	_ring(Vector2.ZERO, r * e * 0.6, 4.0, Color(ICE_LIGHT, a * 0.8), Y_SCALE)


func _draw_enemy(i: int, t: float) -> void:
	if _state[i] == 2:
		return
	var e: Object = _enemies[i]
	var alive := is_instance_valid(e)
	var frozen := alive and float(e.get("frozen_left")) > 0.0
	var slowed := alive and float(e.get("slow_left")) > 0.0
	var base := _last[i]
	if frozen or (_slow_only[i] == 1 and slowed):
		base = Vector2(e.get("position")) - _center
		_last[i] = base
		if _slow_only[i] == 1:
			var pulse := 0.8 + 0.2 * sin(t * 12.0)
			_dot(base + Vector2(0, -26), 40.0 * pulse, Color(ICE, 0.22))
			_ring(base + Vector2(0, -26), 40.0 * pulse, 4.0, Color(ICE, 0.6))
			return
		var pop := clampf(t / 0.2, 0.0, 1.0)
		var c := base + Vector2(0, -22)
		_dot(c, 34.0 * pop, Color(ICE, 0.35))
		_ring(c, 34.0 * pop, 5.0, Color(ICE_OUTLINE, 0.9))
		if reduced:
			return
		for k in 3: # cristais: 3 gotas claras com contorno, saindo do corpo
			var off := Vector2((k - 1) * 17.0, -30.0 - (14.0 if k == 1 else 0.0))
			_dot(base + off * pop, 9.0 * pop + 2.5, ICE_OUTLINE)
			_dot(base + off * pop, 9.0 * pop, ICE_LIGHT if k == 1 else ICE)
		return
	if _slow_only[i] == 1:
		_state[i] = 2
		return
	# Descongelou (ou o inimigo morreu congelado): estilhaços curtos no último ponto.
	if _state[i] == 0:
		_state[i] = 1
		_thaw_at[i] = t
	var q := (t - _thaw_at[i]) / SHATTER_TIME
	if q >= 1.0 or reduced:
		_state[i] = 2
		return
	var a := 1.0 - q
	for k in 5:
		var ang := _angle_offset + TAU * k / 5.0
		var pos := base + Vector2(0, -22) + Vector2(cos(ang), sin(ang) * Y_SCALE) * (14.0 + 34.0 * q)
		_dot(pos, 7.0 * a + 1.0, Color(ICE_LIGHT, a))
