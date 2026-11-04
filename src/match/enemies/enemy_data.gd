class_name EnemyData
extends Resource
## Balanceamento de um arquétipo de inimigo. Valores em data/enemies/.

@export var id: StringName
@export var hp: int = 1
@export var speed: float = 0.0 ## px/s
@export var contact_damage: int = 0
@export var attack_range: float = 0.0 ## px do alvo onde para e atira; 0 = ataque por contato
@export var fire_rate: float = 0.0 ## tiros/s
@export var projectile: ProjectileData ## só para quem atira
@export var target_priority: int = 0
@export var particle_drop: int = 0 ## Partículas ao ser abatido
@export var radius: float = 16.0 ## px
@export var group_min: int = 1 ## inimigos por spawn (enxame)
@export var group_max: int = 1
@export var group_spread: float = 0.0 ## px de espalhamento do grupo
@export var color: Color = Color(1.0, 0.45, 0.35)
