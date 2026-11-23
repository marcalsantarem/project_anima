class_name FxShock
extends FxEffect
## Salto do Choque (T-215): arco elétrico irregular de `position` até `position + target`
## (amarelo, núcleo branco) e faísca no impacto. Cada salto dura `duration` (0,15 s); o atraso
## por índice vem de `delay`. Só visual. Sem alocação por quadro (pontos pré-dimensionados).

const BOLT_OUTLINE := Color("#8A5A00")
const POINTS := 8
const LIFT := 34.0 ## altura do arco acima do chão (corpo do Anima/inimigo)

var _pts := PackedVector2Array()


func _init() -> void:
	_pts.resize(POINTS)


func _draw() -> void:
	if not active or elapsed < delay:
		return
	var p := progress()
	var a := 1.0 - smoothstep(0.6, 1.0, p)
	var from := Vector2(0, -LIFT)
	var to := target + from
	_build(from, to, int(p * 3.0)) # a forma "pisca" 3 vezes no salto
	draw_polyline(_pts, Color(BOLT_OUTLINE, a), 11.0)
	draw_polyline(_pts, Color(color, a), 6.0)
	draw_polyline(_pts, Color(FLASH_COLOR, a), 2.0)
	if reduced:
		return
	_dot(to, 20.0 * (1.0 - p) + 3.0, Color(FLASH_COLOR, a))
	for k in 4:
		var ang := _angle_offset + TAU * k / 4.0
		_dot(to + Vector2(cos(ang), sin(ang) * Y_SCALE) * (10.0 + 26.0 * p), 5.0 * (1.0 - p) + 1.5, Color(color, a))


## Linha irregular determinística (sem RNG): deslocamentos perpendiculares por seno com semente do ponto.
func _build(from: Vector2, to: Vector2, variant: int) -> void:
	var d := to - from
	var n := d.orthogonal().normalized()
	var amp := clampf(d.length() * 0.12, 6.0, 20.0)
	for i in POINTS:
		var f := float(i) / (POINTS - 1)
		var off := 0.0
		if i > 0 and i < POINTS - 1:
			off = sin(_angle_offset * 7.0 + i * 12.9898 + variant * 4.1) * amp
		_pts[i] = from + d * f + n * off
