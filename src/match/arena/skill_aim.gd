class_name SkillAim
extends Node2D
## Prévia da mira de um Módulo (T-177/T-178): raio no chão (elipse 0,75), contorno claro e
## preenchimento translúcido na cor do jogador. Só redesenha quando o ponto ou o raio mudam.

const FILL := Color(0.18, 0.9, 0.82, 0.22) ## accent #2FE6D2 translúcido
const EDGE := Color(0.85, 1.0, 0.98, 0.95) ## contorno claro
const EDGE_WIDTH := 4.0
const CENTER_DOT := 5.0

var radius := 0.0


func _ready() -> void:
	z_index = -1 # decalque no chão, abaixo dos corpos
	visible = false


func show_at(at: Vector2, p_radius: float) -> void:
	if visible and at == position and p_radius == radius:
		return
	position = at
	radius = p_radius
	visible = true
	queue_redraw()


func hide_aim() -> void:
	visible = false


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	draw_circle(Vector2.ZERO, radius, FILL)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, EDGE, EDGE_WIDTH, true)
	draw_circle(Vector2.ZERO, CENTER_DOT, EDGE)
