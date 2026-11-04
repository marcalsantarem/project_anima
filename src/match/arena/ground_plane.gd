class_name GroundPlane
extends RefCounted
## Perspectiva 3/4 (docs/arte.md §3). `position` das entidades é o ponto de contato com o chão,
## em coordenadas de tela. A regra (alcance, raio, velocidade, colisão) vale no plano do chão:
## o eixo Y da tela é o Y do chão encolhido por Y_SCALE. Círculos no chão aparecem como elipses.

const Y_SCALE := 0.75
## Escala de um CollisionShape2D/desenho de chão: círculo no chão → elipse na tela.
const SHAPE_SCALE := Vector2(1.0, Y_SCALE)


static func to_ground(screen: Vector2) -> Vector2:
	return Vector2(screen.x, screen.y / Y_SCALE)


static func to_screen(ground: Vector2) -> Vector2:
	return Vector2(ground.x, ground.y * Y_SCALE)


static func distance_squared(a: Vector2, b: Vector2) -> float:
	return to_ground(b - a).length_squared()


static func distance(a: Vector2, b: Vector2) -> float:
	return to_ground(b - a).length()


## Anda até `ground_step` px no chão de `from` para `to` (tela), sem passar do alvo.
static func move_toward(from: Vector2, to: Vector2, ground_step: float) -> Vector2:
	return from + to_screen(to_ground(to - from).limit_length(ground_step))
