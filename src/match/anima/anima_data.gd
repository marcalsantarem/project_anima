class_name AnimaData
extends Resource
## Balanceamento do Anima e do ataque automático. Valores em data/anima/.

@export var core_hp_max: int = 100
@export var hurtbox_radius: float = 40.0 ## px
@export var fire_rate: float = 2.0 ## tiros/s
@export var attack_range: float = 600.0 ## px; também é a distância máxima do projétil
@export var target_scan_interval: float = 0.1 ## s
@export var projectile_pool_size: int = 64
@export var projectile: ProjectileData
