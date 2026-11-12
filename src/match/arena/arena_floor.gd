class_name ArenaFloor
extends Node2D
## Fundo da arena em tela cheia (BRF-040/041): chão repetido cobrindo a tela, degradê no topo e 4 pilares nos cantos da área livre (Y-sort com as entidades).
## Peças do AG08 em assets/backgrounds/ (PNG 2x, âncoras no README de assets/sprites/).
## Os nós são criados uma vez; layout() só reposiciona (chamado quando o viewport muda).

const FLOOR_Z_INDEX := -10 ## atrás de tudo (sombras e decalques usam z -1)
const PILLAR_SHADOW_RADIUS := 26.0 ## sombra ~60 px de largura (1x)

@export var tile_texture: Texture2D
@export var pillar_texture: Texture2D
@export var pillar_anchor: Vector2 = Vector2(64.0, 192.0)
@export var top_shade_texture: Texture2D ## opcional (nulo = sem degradê)
## Distância dos pilares às bordas da área livre (x: laterais; y: topo e base), em px 1x.
## A área livre começa abaixo do HUD de cima (Arena.free_rect).
@export var pillar_inset_x: float = 56.0
@export var pillar_inset_top: float = 96.0
@export var pillar_inset_bottom: float = 24.0

var _tile: Sprite2D
var _shade: Sprite2D
var _pillars: Array[Node2D] = []


func _ready() -> void:
	y_sort_enabled = true
	_tile = SpriteArt.make(tile_texture, Vector2.ZERO)
	_tile.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_tile.region_enabled = true
	_tile.z_index = FLOOR_Z_INDEX
	add_child(_tile)
	_shade = SpriteArt.make(top_shade_texture, Vector2.ZERO)
	_shade.z_index = FLOOR_Z_INDEX
	add_child(_shade)
	for i in 4:
		var p := Node2D.new()
		p.add_child(GroundShadow.new(PILLAR_SHADOW_RADIUS))
		p.add_child(SpriteArt.make(pillar_texture, pillar_anchor))
		add_child(p)
		_pillars.append(p)


## screen: tamanho do viewport; arena: área livre entre o HUD de cima e a bandeja (pilares);
## center: posição do Anima (sem uso desde o T-292: o selo `floor_ring` foi removido).
func layout(screen: Vector2, arena: Rect2, _center: Vector2) -> void:
	# Região em px do PNG (2x): o tile repete até cobrir a tela inteira.
	_tile.region_rect = Rect2(Vector2.ZERO, screen / SpriteArt.SCALE)
	if top_shade_texture != null:
		_shade.scale = Vector2(screen.x / top_shade_texture.get_width(), SpriteArt.SCALE.y)
	var corners := pillar_points(arena, pillar_inset_x, pillar_inset_top, pillar_inset_bottom)
	for i in _pillars.size():
		_pillars[i].position = corners[i]


## Pés dos 4 pilares: topo-esq., topo-dir., base-esq., base-dir.
static func pillar_points(arena: Rect2, inset_x: float, inset_top: float, inset_bottom: float) -> PackedVector2Array:
	var l := arena.position.x + inset_x
	var r := arena.end.x - inset_x
	var t := arena.position.y + inset_top
	var b := arena.end.y - inset_bottom
	return PackedVector2Array([Vector2(l, t), Vector2(r, t), Vector2(l, b), Vector2(r, b)])
