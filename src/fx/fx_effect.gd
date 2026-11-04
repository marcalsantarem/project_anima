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


func _draw_burst(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 3.0) # ease-out
	var center := Vector2(0, -height * size_scale)
	if not reduced and p < 0.3:
		var f := 1.0 - p / 0.3
		draw_circle(center, r * 0.55 * f, Color(FLASH_COLOR, f))
	var a := _fade(p)
	draw_arc(center, maxf(r * e, 1.0), 0.0, TAU, 20, Color(_outline, a), outline_width * (1.0 - p) + 3.0)
	draw_arc(center, maxf(r * e, 1.0), 0.0, TAU, 20, Color(color, a), outline_width * (1.0 - p) + 1.0)
	var n := dots_to_draw()
	var dot := r * 0.3 * (1.0 - p * 0.6)
	for i in n:
		var ang := _angle_offset + TAU * i / n
		var pos := center + Vector2(cos(ang), sin(ang) * Y_SCALE) * r * 1.15 * e
		draw_circle(pos, dot + 2.0, Color(_outline, a))
		draw_circle(pos, dot, Color(color, a))


func _draw_ground_ring(p: float) -> void:
	var r := radius * size_scale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, Y_SCALE))
	if fill:
		# Telegraph: borda fixa no raio final + preenchimento crescendo até o impacto.
		draw_circle(Vector2.ZERO, r * p, Color(color, 0.18 + 0.17 * p))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, _outline, outline_width + 2.0)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, color, outline_width)
	else:
		var e := 1.0 - pow(1.0 - p, 2.0)
		var a := _fade(p)
		var rr := r * (0.35 + 0.65 * e)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(_outline, a), outline_width * (1.0 + a) + 2.0)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 40, Color(color, a), outline_width * (1.0 + a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sparkle(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 2.0)
	var a := _fade(p)
	var base := Vector2(0, -height * size_scale * 0.4)
	if p < 0.4:
		var rp := p / 0.4
		draw_arc(base, r * (0.4 + 0.6 * rp), 0.0, TAU, 20, Color(color, 1.0 - rp), outline_width)
	var n := dots_to_draw()
	var dot := r * 0.28
	for i in n:
		var ang := _angle_offset + TAU * i / n
		var rise := height * size_scale * e * (0.7 + 0.3 * float(i % 2))
		var pos := base + Vector2(cos(ang) * r * 0.8 * e, sin(ang) * r * 0.3 - rise)
		draw_circle(pos, dot + 2.0, Color(_outline, a))
		draw_circle(pos, dot, Color(color, a))
		draw_circle(pos + Vector2(-dot * 0.3, -dot * 0.3), dot * 0.35, Color(FLASH_COLOR, a))


## Opaco até a metade, some no fim (forma sólida e legível, estilo cartoon).
func _fade(p: float) -> float:
	return 1.0 - smoothstep(0.5, 1.0, p)
