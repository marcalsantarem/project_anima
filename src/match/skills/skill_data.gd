class_name SkillData
extends Resource
## Uma skill ativa. Valores em data/skills/. O comportamento vem do `type`.

enum Type { AREA, CONTROL, DEFENSE }

@export var id: StringName
@export var type: Type = Type.AREA
@export var cooldown: float = 10.0 ## s
@export var radius: float = 0.0 ## px
@export var damage: int = 0
@export var duration: float = 0.0 ## s (controle/defesa)
@export var windup: float = 0.1 ## s de antecipação entre o acionamento e o efeito
@export var target_range: float = 600.0 ## px; alcance da busca de alvo automática
@export var effect_params: Dictionary = {}
@export var fx_id: StringName
@export var sfx_id: StringName
