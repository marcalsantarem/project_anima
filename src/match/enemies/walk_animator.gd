class_name WalkAnimator
extends RefCounted
## Passos procedurais (T-167): balanço vertical, inclinação lateral alternada, squash/stretch no
## apoio do pé e sombra pulsando, no ritmo da distância andada (passos = distância / step_length).
## Só visual: mexe no corpo (Sprite2D com âncora nos pés) e na sombra; não aloca por quadro.
## Parâmetros em EnemyData (walk_*). Quadros opcionais (walk_frames) trocam a cada passo.

const SHADOW_PULSE := 0.12 ## a sombra encolhe até 12% no alto do passo

var body: Sprite2D
var shadow: Node2D
var data: EnemyData
## Fase do passo em rad: cada passo = PI (meio ciclo do seno).
var phase := 0.0
var walking := false

var _rest_texture: Texture2D


func _init(p_body: Sprite2D, p_shadow: Node2D, p_data: EnemyData) -> void:
	body = p_body
	shadow = p_shadow
	data = p_data
	_rest_texture = body.texture if body else null


func enabled() -> bool:
	return data.walk_bob > 0.0 and data.walk_step_length > 0.0


## Avança a fase pelos px andados no chão e aplica a pose. moved <= 0 = parado (pose neutra).
func step(moved: float) -> void:
	if moved <= 0.0:
		rest()
		return
	walking = true
	phase = fmod(phase + PI * moved / data.walk_step_length, TAU * 2.0)
	var lift := absf(sin(phase)) ## 0 no apoio do pé, 1 no alto do passo
	var plant := 1.0 - lift
	body.position.y = -data.walk_bob * lift
	if not data.walk_full: # inimigos comuns: só o balanço (cada propriedade mexida custa)
		return
	body.rotation = deg_to_rad(data.walk_tilt_deg) * sin(phase)
	body.scale = SpriteArt.SCALE * Vector2(1.0 + data.walk_squash * plant, 1.0 - data.walk_squash * plant)
	if shadow:
		shadow.scale = Vector2.ONE * (1.0 - SHADOW_PULSE * lift)
	if not data.walk_frames.is_empty():
		var i := int(phase / (PI * 0.5)) % data.walk_frames.size()
		var tex: Texture2D = data.walk_frames[i]
		if tex != null and body.texture != tex:
			body.texture = tex


## Pose neutra (parado, atacando, lançado ou atordoado). Não mexe na textura do estado,
## só devolve a de repouso se um quadro de caminhada estava em uso.
func rest() -> void:
	if not walking:
		return
	walking = false
	phase = 0.0
	body.position = Vector2.ZERO
	body.rotation = 0.0
	body.scale = SpriteArt.SCALE
	if shadow:
		shadow.scale = Vector2.ONE
	if not data.walk_frames.is_empty() and data.walk_frames.has(body.texture):
		body.texture = _rest_texture
