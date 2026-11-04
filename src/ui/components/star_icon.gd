class_name StarIcon
extends Control
## Ícone de Partículas (moeda da partida): estrela de 4 pontas dourada com contorno.
## Provisório até a arte da T-128; para trocar por textura, defina `texture`.

@export var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
@export var outline_width := 6.0


func _init(min_size: float = 36.0) -> void:
	custom_minimum_size = Vector2(min_size, min_size)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if texture:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return
	var ctr := size * 0.5
	var s := minf(size.x, size.y) * 0.5
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI * 0.5
		pts.append(ctr + Vector2(cos(a), sin(a)) * (s if i % 2 == 0 else s * 0.38))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, UiTokens.INK, outline_width, true)
	draw_colored_polygon(pts, UiTokens.PARTICLES)
