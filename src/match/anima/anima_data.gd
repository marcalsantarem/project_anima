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

@export_group("Arte")
## PNG 2x; âncoras em px do PNG (assets/sprites/README.md).
@export var base_sprite: Texture2D
@export var base_anchor: Vector2
@export var crystal_sprite: Texture2D
@export var crystal_anchor: Vector2
@export var crystal_height: float = 110.0 ## px (1x) do centro do cristal acima da âncora da base
@export var crystal_bob_amplitude: float = 5.0 ## px
@export var crystal_bob_period: float = 2.4 ## s
@export var orbit_sprite: Texture2D
@export var orbit_anchor: Vector2
@export var orbit_count: int = 3
@export var orbit_radii: Vector2 = Vector2(29.0, 12.0) ## semieixos da elipse (px 1x)
@export var orbit_period: float = 3.0 ## s por volta
