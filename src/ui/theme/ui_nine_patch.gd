@tool
class_name UiNinePatch
extends StyleBox
## 9-patch para a arte em 2x de assets/ui/ (T-138). O StyleBoxTexture desenha as bordas no tamanho do PNG;
## este desenha a textura inteira em escala `art_scale` (0,5 = 1x), com as bordas nítidas e sem distorcer.
## Margens em px do PNG (2x), como no README; content_margin_* em px da tela (1x).

@export var texture: Texture2D
@export var margin_left := 0.0
@export var margin_top := 0.0
@export var margin_right := 0.0
@export var margin_bottom := 0.0
@export var art_scale := 0.5
@export var modulate_color := Color.WHITE
@export var draw_center := true


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var k := art_scale
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D(0.0, Vector2(k, k), 0.0, rect.position))
	RenderingServer.canvas_item_add_nine_patch(to_canvas_item, Rect2(Vector2.ZERO, rect.size / k),
		Rect2(Vector2.ZERO, texture.get_size()), texture.get_rid(),
		Vector2(margin_left, margin_top), Vector2(margin_right, margin_bottom),
		RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH, draw_center, modulate_color)
	RenderingServer.canvas_item_add_set_transform(to_canvas_item, Transform2D())
