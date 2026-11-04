class_name FxEffect
extends Node2D
## Efeito visual reutilizável (docs/vfx.md). Desenhado por código (_draw), sem textura e sem
## alocar por quadro. Só visual: nunca altera o estado da partida. Criado uma vez pelo FxPool,
## ligado com start() e desligado sozinho ao fim (finished).
## `position` = âncora no chão (coordenadas de tela, como as entidades em 3/4).

signal finished(effect: FxEffect)

enum Style {
	BURST, ## flash + anel + gotas radiais, acima da âncora (impacto, morte, disparo)
	GROUND_RING, ## decalque elíptico no chão (telegraph com fill, onda de choque sem fill)
	SPARKLE, ## gotas subindo + anel curto (coleta, compra)
	STREAK, ## traço curto ao longo de `direction` (rastro do disparo), acima da âncora
}

## Achatamento do chão em 3/4 (igual a GroundPlane.Y_SCALE; fx/ não depende de match/).
const Y_SCALE := 0.75
const OUTLINE_DARKEN := 0.55 ## contorno = tom da própria cor −55% (docs/arte.md, variação A)
const FLASH_COLOR := Color("#FFFFFF")

@export var style: Style = Style.BURST
@export var duration := 0.25
@export var radius := 24.0 ## raio no chão, em px (antes de `size`)
@export var dot_count := 4 ## gotas por efeito (metade no modo reduzido)
@export var height := 24.0 ## altura do desenho acima da âncora, em px
@export var fill := false ## GROUND_RING: telegraph (preenche até o fim)
@export var default_color := Color("#2FE6D2")
@export var outline_width := 4.0

var active := false
var elapsed := 0.0
var reduced := false
var color := Color.WHITE
var size_scale := 1.0
## STREAK: direção (normalizada) na tela. Definida por quem chama, após o play() do pool.
var direction := Vector2.UP
var _outline := Color.BLACK
var _angle_offset := 0.0


func _ready() -> void:
	if not active:
		visible = false
		set_process(false)


## Liga o efeito em `anchor`. `fx_color.a == 0` usa `default_color`.
func start(anchor: Vector2, fx_color: Color, fx_size: float, reduced_mode: bool) -> void:
	position = anchor
	color = default_color if fx_color.a == 0.0 else fx_color
	_outline = color.darkened(OUTLINE_DARKEN)
	size_scale = fx_size
	reduced = reduced_mode
	elapsed = 0.0
	_angle_offset = fposmod(anchor.x * 0.013 + anchor.y * 0.029, TAU) # variação sem RNG
	z_index = -1 if style == Style.GROUND_RING else 0
	active = true
	visible = true
	set_process(true)
	queue_redraw()


func advance(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if elapsed >= duration:
		stop()
	else:
		queue_redraw()


func stop() -> void:
	if not active:
		return
	active = false
	visible = false
	set_process(false)
	finished.emit(self)


func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0) if duration > 0.0 else 1.0


func dots_to_draw() -> int:
	return int(ceil(dot_count * 0.5)) if reduced else dot_count


func _process(delta: float) -> void:
	advance(delta)


func _draw() -> void:
	if not active:
		return
	var p := progress()
	match style:
		Style.BURST:
			_draw_burst(p)
		Style.GROUND_RING:
			_draw_ground_ring(p)
		Style.SPARKLE:
			_draw_sparkle(p)
		Style.STREAK:
			_draw_streak(p)


func _draw_burst(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 3.0) # ease-out
	var center := Vector2(0, -height * size_scale)
	if not reduced and p < 0.3:
		var f := 1.0 - p / 0.3
		_dot(center, r * 0.55 * f, Color(FLASH_COLOR, f))
	var a := _fade(p)
	_ring(center, maxf(r * e, 1.0), outline_width * (1.0 - p) + 3.0, Color(_outline, a))
	_ring(center, maxf(r * e, 1.0), outline_width * (1.0 - p) + 1.0, Color(color, a))
	var n := dots_to_draw()
	var dot := r * 0.3 * (1.0 - p * 0.6)
	for i in n:
		var ang := _angle_offset + TAU * i / n
		var pos := center + Vector2(cos(ang), sin(ang) * Y_SCALE) * r * 1.15 * e
		_dot(pos, dot + 2.0, Color(_outline, a))
		_dot(pos, dot, Color(color, a))


func _draw_ground_ring(p: float) -> void:
	var r := radius * size_scale
	if fill:
		# Telegraph: borda fixa no raio final + preenchimento crescendo até o impacto.
		_dot(Vector2.ZERO, r * p, Color(color, 0.18 + 0.17 * p), Y_SCALE)
		_ring(Vector2.ZERO, r, outline_width + 2.0, _outline, Y_SCALE)
		_ring(Vector2.ZERO, r, outline_width, color, Y_SCALE)
	else:
		var e := 1.0 - pow(1.0 - p, 2.0)
		var a := _fade(p)
		var rr := r * (0.35 + 0.65 * e)
		_ring(Vector2.ZERO, rr, outline_width * (1.0 + a) + 2.0, Color(_outline, a), Y_SCALE)
		_ring(Vector2.ZERO, rr, outline_width * (1.0 + a), Color(color, a), Y_SCALE)


func _draw_sparkle(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 2.0)
	var a := _fade(p)
	var base := Vector2(0, -height * size_scale * 0.4)
	if p < 0.4:
		var rp := p / 0.4
		_ring(base, r * (0.4 + 0.6 * rp), outline_width, Color(color, 1.0 - rp))
	var n := dots_to_draw()
	var dot := r * 0.28
	for i in n:
		var ang := _angle_offset + TAU * i / n
		var rise := height * size_scale * e * (0.7 + 0.3 * float(i % 2))
		var pos := base + Vector2(cos(ang) * r * 0.8 * e, sin(ang) * r * 0.3 - rise)
		_dot(pos, dot + 2.0, Color(_outline, a))
		_dot(pos, dot, Color(color, a))
		_dot(pos + Vector2(-dot * 0.3, -dot * 0.3), dot * 0.35, Color(FLASH_COLOR, a))


func _draw_streak(p: float) -> void:
	# Rastro: a frente avança rápido (ease-out) e a cauda alcança a frente até sumir.
	var length := radius * size_scale
	var base := Vector2(0, -height * size_scale)
	var head := base + direction * length * (1.0 - pow(1.0 - p, 3.0))
	var tail := base + direction * length * p * p
	var w := outline_width * (1.0 - p) + 2.0
	draw_line(tail, head, _outline, w + 4.0)
	draw_line(tail, head, color, w + 1.5)
	draw_line(tail, head, FLASH_COLOR if not reduced else color, maxf(w - 1.5, 1.0))
	_dot(head, w * 0.5 + 2.0, color)


# --- primitivas em textura ---------------------------------------------------------------
# draw_circle/draw_arc viram um polígono cada = 1 draw call por chamada no Compatibility.
# Retângulos com a mesma textura entram no mesmo lote: gotas e anéis usam um atlas branco
# gerado uma vez (sem arquivo) e tingido pela cor.

const _TEX_SIZE := 64
## Espessuras relativas (espessura / raio externo) do atlas, em progressão geométrica 0,03–0,53.
const _RING_STEPS := 12
const _RING_BASE := 0.03
const _RING_GROWTH := 1.3

## Atlas único (gota + anéis lado a lado): uma textura só, para tudo cair no mesmo lote.
static var _atlas: Texture2D


## Gera o atlas (uma vez). O FxPool chama ao registrar, fora da partida.
static func prepare_textures() -> void:
	if _atlas:
		return
	var img := Image.create(_TEX_SIZE * (_RING_STEPS + 1), _TEX_SIZE, false, Image.FORMAT_RGBA8)
	_paint(img, 0, 0.0)
	for i in _RING_STEPS:
		_paint(img, i + 1, _RING_BASE * pow(_RING_GROWTH, i))
	_atlas = ImageTexture.create_from_image(img)


## Pinta na célula `cell` um círculo branco suavizado; `ring_ratio` > 0 faz um anel.
static func _paint(img: Image, cell: int, ring_ratio: float) -> void:
	var c := (_TEX_SIZE - 1) * 0.5
	var outer := _TEX_SIZE * 0.5 - 1.0
	var inner := outer * (1.0 - ring_ratio)
	for y in _TEX_SIZE:
		for x in _TEX_SIZE:
			var d := Vector2(x - c, y - c).length()
			var a := clampf(outer - d + 0.5, 0.0, 1.0)
			if ring_ratio > 0.0:
				a = minf(a, clampf(d - inner + 0.5, 0.0, 1.0))
			img.set_pixel(cell * _TEX_SIZE + x, y, Color(1, 1, 1, a))


func _cell(at: Vector2, r: float, y_scale: float, cell: int, c: Color) -> void:
	prepare_textures()
	draw_texture_rect_region(_atlas, Rect2(at.x - r, at.y - r * y_scale, r * 2.0, r * 2.0 * y_scale),
			Rect2(cell * _TEX_SIZE, 0, _TEX_SIZE, _TEX_SIZE), c)


## Gota (círculo cheio) de raio `r`; `y_scale` < 1 achata em elipse no chão.
func _dot(at: Vector2, r: float, c: Color, y_scale := 1.0) -> void:
	if r > 0.0:
		_cell(at, r, y_scale, 0, c)


## Anel centrado no raio `r` com largura `w` (como draw_arc); usa a espessura mais próxima do atlas.
func _ring(at: Vector2, r: float, w: float, c: Color, y_scale := 1.0) -> void:
	var outer := r + w * 0.5
	var step := roundi(log(maxf(w / outer, 0.001) / _RING_BASE) / log(_RING_GROWTH))
	_cell(at, outer, y_scale, clampi(step, 0, _RING_STEPS - 1) + 1, c)


## Opaco até a metade, some no fim (forma sólida e legível, estilo cartoon).
func _fade(p: float) -> float:
	return 1.0 - smoothstep(0.5, 1.0, p)
