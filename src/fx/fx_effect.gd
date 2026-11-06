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
	EXPLOSION, ## bola de fogo + chamas + brasas + fumaça curta (meteoro, morte do chefe)
	PUFF, ## nuvem de gotas que se espalham no chão e sobem (poeira, fumaça, "puf")
	TRAVEL, ## rastro que segue de 0 até `target` em `travel_time`; depois a cauda some no fim
	ORBIT, ## gotas girando em elipse acima da âncora (estrelas do atordoamento)
	GLOW, ## brilho que cresce sobre o corpo até o fim (wind-up), com flash final
}

## Achatamento do chão em 3/4 (igual a GroundPlane.Y_SCALE; fx/ não depende de match/).
const Y_SCALE := 0.75
const OUTLINE_DARKEN := 0.55 ## contorno = tom da própria cor −55% (docs/arte.md, variação A)
const FLASH_COLOR := Color("#FFFFFF")
const SMOKE_COLOR := Color("#6E6470")

@export var style: Style = Style.BURST
@export var duration := 0.25
@export var radius := 24.0 ## raio no chão, em px (antes de `size`)
@export var dot_count := 4 ## gotas por efeito (metade no modo reduzido)
@export var height := 24.0 ## altura do desenho acima da âncora, em px
@export var fill := false ## GROUND_RING: telegraph (preenche até o fim)
@export var default_color := Color("#2FE6D2")
@export var outline_width := 4.0
## Contorno fixo da paleta do tipo (usado com a cor padrão); alfa 0 = cor −55%.
@export var outline_color := Color(0, 0, 0, 0)
## Brilho/faísca das gotas do SPARKLE; cabeça do TRAVEL; brasas da EXPLOSION; brilho do ORBIT.
@export var highlight_color := Color("#FFFFFF")
## Segunda cor: miolo do fogo (EXPLOSION) e estrelas do TRAVEL.
@export var secondary_color := Color("#FFE066")
## BURST: raio do flash branco (× raio) e janela do flash (fração da duração).
@export var flash_scale := 0.55
@export var flash_window := 0.3
## TRAVEL: tempo do percurso (o resto da duração é a cauda sumindo), arco (px) e aceleração.
@export var travel_time := 0.3
@export var arc := 0.0
@export var accelerate := false
## TRAVEL: estrelas girando em volta da cabeça (lançamento do chefe).
@export var stars := 0

var active := false
var elapsed := 0.0
var reduced := false
var color := Color.WHITE
var size_scale := 1.0
## STREAK: direção (normalizada) na tela. Definida por quem chama, após o play() do pool.
var direction := Vector2.UP
## Atraso antes de aparecer (s). Definido por quem chama, após o play() (ex.: pouso do chefe).
var delay := 0.0
## TRAVEL: fim do percurso, relativo à âncora. Definido por quem chama, após o play().
var target := Vector2.ZERO
var _outline := Color.BLACK
var _scene_duration := -1.0
var _scene_travel_time := -1.0
var _angle_offset := 0.0


func _ready() -> void:
	if not active:
		visible = false
		set_process(false)


## Liga o efeito em `anchor`. `fx_color.a == 0` usa `default_color`.
func start(anchor: Vector2, fx_color: Color, fx_size: float, reduced_mode: bool) -> void:
	position = anchor
	color = default_color if fx_color.a == 0.0 else fx_color
	_outline = outline_color if outline_color.a > 0.0 and color == default_color else color.darkened(OUTLINE_DARKEN)
	size_scale = fx_size
	reduced = reduced_mode
	if _scene_duration < 0.0: # valores da cena; quem chama pode mudá-los por uso
		_scene_duration = duration
		_scene_travel_time = travel_time
	duration = _scene_duration
	travel_time = _scene_travel_time
	elapsed = 0.0
	delay = 0.0
	target = Vector2.ZERO
	direction = Vector2.UP
	_angle_offset = fposmod(anchor.x * 0.013 + anchor.y * 0.029, TAU) # variação sem RNG
	# Decalque no chão abaixo dos corpos; efeitos aéreos (voo, estrelas, brilho) acima deles.
	z_index = -1 if style == Style.GROUND_RING else (1 if style in [Style.TRAVEL, Style.ORBIT, Style.GLOW] else 0)
	active = true
	visible = true
	set_process(true)
	queue_redraw()


func advance(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if elapsed >= delay + duration:
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
	return clampf((elapsed - delay) / duration, 0.0, 1.0) if duration > 0.0 else 1.0


func dots_to_draw() -> int:
	return int(ceil(dot_count * 0.5)) if reduced else dot_count


func _process(delta: float) -> void:
	advance(delta)


func _draw() -> void:
	if not active or elapsed < delay:
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
		Style.EXPLOSION:
			_draw_explosion(p)
		Style.PUFF:
			_draw_puff(p)
		Style.TRAVEL:
			_draw_travel()
		Style.ORBIT:
			_draw_orbit(p)
		Style.GLOW:
			_draw_glow(p)


func _draw_burst(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 3.0) # ease-out
	var center := Vector2(0, -height * size_scale)
	if not reduced and p < flash_window:
		var f := 1.0 - p / flash_window
		_dot(center, r * flash_scale * f, Color(FLASH_COLOR, f))
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
		_dot(pos + Vector2(-dot * 0.3, -dot * 0.3), dot * 0.35, Color(highlight_color, a))


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


## Fogo: miolo amarelo que vira laranja, chamas em volta; brasas e fumaça só fora do reduzido.
func _draw_explosion(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 3.0)
	var center := Vector2(0, -height * size_scale)
	var a := _fade(p)
	if not reduced and p < 0.18:
		_dot(center, r * 0.75, Color(FLASH_COLOR, 1.0 - p / 0.18))
	var fire := secondary_color.lerp(color, clampf(p * 1.6, 0.0, 1.0))
	var n := dots_to_draw()
	var flame := r * 0.42 * (1.0 - p * 0.7)
	for i in n: # chamas: gotas grandes saindo do centro e subindo um pouco
		var ang := _angle_offset + TAU * i / n
		var pos := center + Vector2(cos(ang), sin(ang) * Y_SCALE) * r * 0.55 * e - Vector2(0, height * 0.4 * e)
		_dot(pos, flame + 3.0, Color(_outline, a))
		_dot(pos, flame, Color(fire, a))
	var core := r * 0.5 * (1.0 - p)
	_dot(center, core + 3.0, Color(_outline, a))
	_dot(center, core, Color(secondary_color, a))
	if reduced:
		return
	for i in n: # brasas: faíscas em arco
		var ang := _angle_offset + PI / n + TAU * i / n
		var pos := center + Vector2(cos(ang) * r * 1.4 * e, sin(ang) * r * 0.5 * e - r * 1.2 * (p - p * p))
		_dot(pos, 4.0 * (1.0 - p) + 1.5, Color(highlight_color, a))
	if p > 0.45: # fumaça curta: gotas cinza subindo
		var q := (p - 0.45) / 0.55
		for i in 3:
			var pos := center + Vector2((i - 1) * r * 0.45, -height * 0.6 - r * 0.9 * q)
			_dot(pos, r * (0.22 + 0.2 * q), Color(SMOKE_COLOR, 0.4 * (1.0 - q)))


## Poeira/fumaça: gotas que se espalham no chão (elipse) e sobem `height`, crescendo e sumindo.
func _draw_puff(p: float) -> void:
	var r := radius * size_scale
	var e := 1.0 - pow(1.0 - p, 2.0)
	var a := _fade(p)
	var n := dots_to_draw()
	var dot := r * 0.32 * (0.7 + 0.5 * e)
	for i in n:
		var ang := _angle_offset + TAU * i / n
		var spread := r * (0.3 + 0.7 * e)
		var rise := height * size_scale * e * (0.6 + 0.4 * float(i % 2))
		var pos := Vector2(cos(ang) * spread, sin(ang) * spread * Y_SCALE - rise)
		_dot(pos, dot + 2.0, Color(_outline, a * 0.8))
		_dot(pos, dot, Color(color, a))


## Rastro em percurso: cabeça (highlight) indo de 0 a `target`, gotas atrás encolhendo.
## Depois de `travel_time`, a cauda alcança o fim e some.
func _draw_travel() -> void:
	var t := elapsed - delay
	var n := maxi(dots_to_draw(), 1)
	var spacing := 0.09
	var head_h := 1.0
	var fade := 1.0
	if t < travel_time:
		head_h = t / maxf(travel_time, 0.001)
	else:
		var q := clampf((t - travel_time) / maxf(duration - travel_time, 0.001), 0.0, 1.0)
		spacing *= 1.0 - q
		fade = 1.0 - q
	var r := radius * size_scale
	for k in range(n, -1, -1):
		var h := head_h - k * spacing
		if h < 0.0:
			continue
		var s := 1.0 - float(k) / (n + 1)
		var pos := _travel_point(h)
		var c := highlight_color if k == 0 else color
		_dot(pos, r * s + 2.5, Color(_outline, fade * s))
		_dot(pos, r * s, Color(c, fade * (0.6 + 0.4 * s)))
	if stars > 0 and t < travel_time:
		var head := _travel_point(head_h)
		for i in stars:
			var ang := _angle_offset + t * 14.0 + TAU * i / stars
			var pos := head + Vector2(cos(ang) * r * 1.6, sin(ang) * r * 0.8 - r)
			_dot(pos, 6.5, secondary_color.darkened(OUTLINE_DARKEN))
			_dot(pos, 4.5, secondary_color)


func _travel_point(h: float) -> Vector2:
	var eh := h * h if accelerate else 1.0 - pow(1.0 - h, 2.0)
	return Vector2(0, -height * size_scale) + target * eh - Vector2(0, arc * 4.0 * eh * (1.0 - eh))


## Estrelas girando em elipse acima da âncora; entram e saem com escala.
func _draw_orbit(p: float) -> void:
	var r := radius * size_scale
	var center := Vector2(0, -height * size_scale)
	var grow := clampf(minf(p / 0.08, (1.0 - p) / 0.1), 0.0, 1.0)
	var n := dots_to_draw()
	var t := elapsed - delay
	for i in n:
		var ang := _angle_offset + t * 5.0 + TAU * i / n
		var s := 8.0 * grow * (0.75 + 0.25 * sin(ang)) # atrás = menor
		var pos := center + Vector2(cos(ang) * r, sin(ang) * r * 0.35)
		_dot(pos, s + 2.5, _outline)
		_dot(pos, s, color)
		_dot(pos + Vector2(-s * 0.3, -s * 0.3), s * 0.35, highlight_color)


## Brilho do wind-up: halo em camadas crescendo até o golpe e flash curto no fim.
func _draw_glow(p: float) -> void:
	var r := radius * size_scale
	var center := Vector2(0, -height * size_scale)
	var pulse := 0.85 + 0.15 * sin((elapsed - delay) * 30.0)
	for i in 3:
		var k := 1.0 - i * 0.28
		_dot(center, r * k * (0.7 + 0.3 * p) * pulse, Color(color, (0.08 + 0.14 * p) * (1.0 + i * 0.3)))
	if p > 0.8:
		var f := (p - 0.8) / 0.2
		_dot(center, r * 0.6 * f, Color(FLASH_COLOR, 0.5 * f))


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
