class_name BossTelegraph
extends Node2D
## Aviso simples desenhado por código: contorno + preenchimento que cresce até o ataque.
## CIRCLE em volta do chefe (anel, invocação) ou CONE na direção do leque. VFX final: AG09.

enum Shape { CIRCLE, CONE }

const OUTLINE_WIDTH := 3.0
const CONE_POINTS := 12

var color := Color(1.0, 0.3, 0.25, 0.8)
var shape: Shape = Shape.CIRCLE
var radius := 120.0 ## px
var direction := Vector2.UP ## na tela (CONE)
var spread := 0.0 ## rad (CONE)
var progress := 0.0 ## 0..1

var _points := PackedVector2Array()


func _ready() -> void:
	_points.resize(CONE_POINTS + 2)
	visible = false


func show_warning(p_shape: Shape, p_radius: float, p_direction: Vector2, p_spread: float) -> void:
	shape = p_shape
	radius = p_radius
	direction = p_direction
	spread = p_spread
	progress = 0.0
	visible = true
	queue_redraw()


func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func hide_warning() -> void:
	visible = false


func _draw() -> void:
	var fill := Color(color, color.a * 0.35)
	if shape == Shape.CIRCLE:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, OUTLINE_WIDTH)
		draw_circle(Vector2.ZERO, radius * progress, fill)
		return
	_cone(radius)
	draw_polyline(_points, color, OUTLINE_WIDTH)
	draw_line(_points[_points.size() - 1], Vector2.ZERO, color, OUTLINE_WIDTH)
	_cone(radius * progress)
	if progress > 0.0:
		draw_colored_polygon(_points, fill)


func _cone(r: float) -> void:
	var base := direction.angle()
	_points[0] = Vector2.ZERO
	for i in CONE_POINTS + 1:
		var a := base - spread * 0.5 + spread * i / CONE_POINTS
		_points[i + 1] = Vector2.from_angle(a) * r
