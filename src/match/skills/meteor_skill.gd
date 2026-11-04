class_name MeteorSkill
extends AreaSkill
## Meteoro de fogo (decisão 37): telegraph no chão que enche em `telegraph_time`; nos últimos
## `fall_time` o meteoro cai do alto; no impacto, dano em área no chão (`radius`, `damage`).
## Alvo: o inimigo mais denso ao alcance (senão o mais próximo), adiantado pela distância que ele
## anda até o impacto. Tudo é criado no _ready; a animação só move/redesenha nós existentes.

const TELEGRAPH_FILL := Color(1.0, 0.45, 0.15, 0.22)
const TELEGRAPH_EDGE := Color(1.0, 0.55, 0.2, 0.85)
const CRATER_COLOR := Color(0.18, 0.08, 0.06, 0.55)
const BLAST_COLOR := Color(1.0, 0.7, 0.25, 0.9)
const METEOR_CORE := Color(1.0, 0.85, 0.4)
const METEOR_RIM := Color(1.0, 0.35, 0.1)
const METEOR_DRAW_RADIUS := 22.0 ## px do desenho provisório
const SHADOW_COLOR := Color(0, 0, 0, 0.3)
const METEOR_Z := 2 ## relativo ao decalque (z -1): fica acima dos corpos
## Largura da cratera (1x) = 2 × raio × CRATER_FIT (assets/sprites/README.md).
const CRATER_FIT := 1.07

var _meteor: Node2D
var _meteor_sprite: Sprite2D
var _crater_sprite: Sprite2D


func _ready() -> void:
	super()
	if data.crater_texture != null:
		_crater_sprite = SpriteArt.make(data.crater_texture, data.crater_anchor)
		_crater_sprite.scale = SpriteArt.SCALE * crater_scale(data.crater_texture.get_width(), data.radius)
		_crater_sprite.visible = false
		add_child(_crater_sprite)
	_meteor = Node2D.new()
	_meteor.z_index = METEOR_Z
	_meteor.visible = false
	add_child(_meteor)
	if data.meteor_texture != null:
		_meteor_sprite = SpriteArt.make(data.meteor_texture, data.meteor_anchor)
		_meteor.add_child(_meteor_sprite)
	else:
		_meteor.draw.connect(_draw_meteor)


## Fator sobre a escala 0,5 para a cratera cobrir o raio (largura do PNG 2x em px).
static func crater_scale(png_width: float, radius: float) -> float:
	return 2.0 * radius * CRATER_FIT / (png_width * SpriteArt.SCALE.x)


## Ponto previsto do inimigo mais denso no instante do impacto (sem previsão se ele não anda).
func _pick_target() -> Vector2:
	var e := densest_enemy(context.anima.position, context.enemies, data.target_range, data.radius)
	if e == null:
		return context.anima.position
	return lead_point(e, data.telegraph_time)


static func lead_point(e: Enemy, time: float) -> Vector2:
	if e.state != Enemy.State.ADVANCE:
		return e.position
	return GroundPlane.move_toward(e.position, e.target_position, e.data.speed * time)


func _windup_time() -> float:
	return data.telegraph_time


func _fx_time() -> float:
	return data.crater_time


## 0 no acionamento, 1 no impacto.
func telegraph_progress() -> float:
	return clampf(1.0 - _windup_left / maxf(data.telegraph_time, 0.001), 0.0, 1.0)


## 0 no início da queda, 1 no impacto; < 0 antes de a queda começar.
func fall_progress() -> float:
	if _windup_left > data.fall_time:
		return -1.0
	return clampf(1.0 - _windup_left / maxf(data.fall_time, 0.001), 0.0, 1.0)


func activate() -> void:
	if _crater_sprite:
		_crater_sprite.visible = false
	super()
	_on_windup_tick()


func _on_windup_tick() -> void:
	var t := fall_progress()
	_meteor.visible = t >= 0.0 and _windup_left > 0.0
	if _meteor.visible:
		_meteor.position = Vector2(0.0, -data.fall_height * (1.0 - t * t)) # acelera na queda
		_meteor.queue_redraw()
	queue_redraw()


func _impact() -> void:
	_meteor.visible = false
	if _crater_sprite:
		_crater_sprite.visible = true
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	if _windup_left <= 0.0 and visible:
		queue_redraw() # anel de impacto se apaga


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	if _windup_left > 0.0:
		draw_circle(Vector2.ZERO, data.radius * telegraph_progress(), TELEGRAPH_FILL)
		draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 64, TELEGRAPH_EDGE, RING_WIDTH, true)
		var t := fall_progress()
		if t >= 0.0:
			draw_circle(Vector2.ZERO, METEOR_DRAW_RADIUS * (0.4 + 0.6 * t), SHADOW_COLOR)
		return
	var fade := clampf(_fx_left / maxf(data.crater_time, 0.001), 0.0, 1.0)
	if _crater_sprite == null:
		draw_circle(Vector2.ZERO, data.radius * 0.45, CRATER_COLOR * Color(1, 1, 1, fade))
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 64, BLAST_COLOR * Color(1, 1, 1, fade), RING_WIDTH * 2.0, true)


## Desenho provisório (sem textura): bola de fogo com contorno.
func _draw_meteor() -> void:
	_meteor.draw_circle(Vector2.ZERO, METEOR_DRAW_RADIUS, METEOR_RIM)
	_meteor.draw_circle(Vector2.ZERO, METEOR_DRAW_RADIUS * 0.6, METEOR_CORE)
