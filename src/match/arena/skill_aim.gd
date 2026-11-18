class_name SkillAim
extends Node2D
## Prévia da mira de um Módulo (T-177/T-178): raio no chão (elipse 0,75), contorno claro e
## preenchimento translúcido na cor do jogador. Só redesenha quando o ponto ou o raio mudam.

const FILL := Color(0.18, 0.9, 0.82, 0.22) ## accent #2FE6D2 translúcido
const ICE_FILL := Color(0.45, 0.8, 1.0, 0.25) ## gelo (congelamento)
const ICE_EDGE := Color(0.88, 0.97, 1.0, 0.95)
const EDGE := Color(0.85, 1.0, 0.98, 0.95) ## contorno claro
const EDGE_WIDTH := 4.0
const CENTER_DOT := 5.0

var radius := 0.0
var fill := FILL
var edge := EDGE


func _ready() -> void:
	z_index = -1 # decalque no chão, abaixo dos corpos
	visible = false


func show_at(at: Vector2, p_radius: float, p_fill: Color = FILL) -> void:
	if visible and at == position and p_radius == radius and p_fill == fill:
		return
	position = at
	radius = p_radius
	fill = p_fill
	edge = ICE_EDGE if p_fill == ICE_FILL else EDGE
	visible = true
	queue_redraw()


func hide_aim() -> void:
	visible = false


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, edge, EDGE_WIDTH, true)
	draw_circle(Vector2.ZERO, CENTER_DOT, edge)
