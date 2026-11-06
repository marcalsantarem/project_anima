class_name FocusMarker
extends Node2D
## Marcador do foco manual (T-176): anel pulsante no chão (elipse 0,75) sob o inimigo focado, na
## cor do jogador. Só visual: segue o alvo em _process e redesenha; escondido = sem processamento.

const COLOR := Color("#2FE6D2") ## accent (jogador), docs/arte.md
const WIDTH := 4.0
const MARGIN := 10.0 ## px além do raio do inimigo
const PULSE_PERIOD := 0.8 ## s
const PULSE_AMOUNT := 0.12 ## ±12% do raio
const TICK_COUNT := 4 ## marcas da retícula
const TICK_LENGTH := 10.0

var target: Enemy
var _time := 0.0


func _ready() -> void:
	z_index = -1 # decalque no chão, abaixo dos corpos
	visible = false
	set_process(false)


func follow(enemy: Enemy) -> void:
	target = enemy
	_time = 0.0
	visible = enemy != null
	set_process(visible)
	if visible:
		position = enemy.position
		queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		follow(null)
		return
	_time += delta
	position = target.position
	queue_redraw()


func radius() -> float:
	var base := (target.data.radius if is_instance_valid(target) else 0.0) + MARGIN
	return base * (1.0 + PULSE_AMOUNT * sin(_time * TAU / PULSE_PERIOD))


func _draw() -> void:
	if not is_instance_valid(target):
		return
	var r := radius()
	draw_set_transform(Vector2.ZERO, 0.0, GroundPlane.SHAPE_SCALE)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, COLOR, WIDTH, true)
	for i in TICK_COUNT:
		var dir := Vector2.from_angle(TAU * i / TICK_COUNT + PI * 0.25)
		draw_line(dir * (r + 2.0), dir * (r + 2.0 + TICK_LENGTH), COLOR, WIDTH, true)
