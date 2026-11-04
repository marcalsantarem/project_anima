class_name SkillData
extends Resource
## Uma skill ativa. Valores em data/skills/. O comportamento vem do `type` (e da `delivery`, na área).

enum Type { AREA, CONTROL, DEFENSE }
## Como a área chega ao chão: INSTANT (efeito após `windup`) ou METEOR (telegraph + queda).
enum Delivery { INSTANT, METEOR }

@export var id: StringName
@export var type: Type = Type.AREA
@export var delivery: Delivery = Delivery.INSTANT
@export var cooldown: float = 10.0 ## s
@export var radius: float = 0.0 ## px no chão
@export var damage: int = 0
@export var duration: float = 0.0 ## s (controle/defesa)
@export var windup: float = 0.1 ## s de antecipação entre o acionamento e o efeito (INSTANT)
@export var target_range: float = 600.0 ## px; alcance da busca de alvo automática
@export var effect_params: Dictionary = {}
@export var fx_id: StringName
@export var sfx_id: StringName
## Ícone do botão do slot (opcional; a UI decide se usa).
@export var icon: Texture2D

@export_group("Meteoro")
@export var telegraph_time: float = 0.6 ## s do acionamento ao impacto (o círculo enche nesse tempo)
@export var fall_time: float = 0.35 ## s finais do telegraph em que o meteoro cai (<= telegraph_time)
@export var fall_height: float = 360.0 ## px de tela acima do alvo onde a queda começa
@export var crater_time: float = 0.5 ## s que a cratera/anel de impacto fica visível
## Texturas opcionais (PNG 2x, escala 0,5, âncora em px do PNG). Nulas = desenho provisório por código.
@export var meteor_texture: Texture2D
@export var meteor_anchor: Vector2
@export var crater_texture: Texture2D
@export var crater_anchor: Vector2
