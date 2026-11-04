class_name GroundShadow
extends Node2D
## Sombra no chão (elipse 0,75) sob a âncora da entidade. Fica abaixo de todos os corpos (z -1).

const COLOR := Color(0.0, 0.0, 0.0, 0.3)
## A sombra é o "tamanho real": 100–125% do diâmetro da colisão (docs/arte.md).
const SIZE_FACTOR := 1.15

var radius := 0.0:
	set(value):
		radius = value
		queue_redraw()


func _init(p_radius: float = 0.0) -> void:
	radius = p_radius
	z_index = -1


func _draw() -> void:
	if radius <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	draw_circle(Vector2.ZERO, radius * SIZE_FACTOR, COLOR)
