class_name SpriteArt
extends RefCounted
## Regras de sprite do AG08 (assets/sprites/README.md): PNG em 2x, escala 0,5,
## centered = false, offset = -âncora (px do PNG). A posição do nó vira a âncora.

const SCALE := Vector2(0.5, 0.5)


## Cria o Sprite2D já configurado. texture nula = sprite vazio (sem desenho).
static func make(texture: Texture2D, anchor: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	apply(s, texture, anchor)
	return s


static func apply(s: Sprite2D, texture: Texture2D, anchor: Vector2) -> void:
	s.texture = texture
	s.centered = false
	s.offset = -anchor
	s.scale = SCALE
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
