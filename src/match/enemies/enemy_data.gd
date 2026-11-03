class_name EnemyData
extends Resource
## Balanceamento de um arquétipo de inimigo. Valores em data/enemies/.

@export var id: StringName
@export var hp: int = 1
@export var speed: float = 0.0 ## px/s
@export var contact_damage: int = 0
@export var attack_range: float = 0.0 ## px; 0 = ataque por contato
@export var fire_rate: float = 0.0 ## tiros/s
@export var projectile_speed: float = 0.0 ## px/s
@export var projectile_damage: int = 0
@export var target_priority: int = 0
@export var coin_drop: int = 0
@export var radius: float = 16.0 ## px
