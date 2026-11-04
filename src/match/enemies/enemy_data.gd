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
## Barra pequena de vida sobre o inimigo (decisão 38). O chefe usa a barra de defesa no lugar.
@export var show_health_bar := true
## Arte (PNG 2x; âncora em px do PNG, no chão). Ver assets/sprites/README.md.
@export var sprite: Texture2D
@export var sprite_anchor: Vector2
## Anel opcional atrás do corpo (chefe): centro a ring_height px (1x) acima da âncora.
@export var ring_sprite: Texture2D
@export var ring_anchor: Vector2
@export var ring_height: float = 0.0
@export var ring_spin_speed: float = 0.0 ## rad/s
