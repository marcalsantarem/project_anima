class_name BossData
extends EnemyData
## Chefe ogro (decisões 39 e 42): uma fase, um golpe corpo a corpo; o meteoro lança e atordoa.
## A defesa (escudo na frente da vida) está arquivada: defense_max = 0 a desliga.
## Herdado do EnemyData: hp, speed, attack_range (distância no chão do centro do Núcleo onde para
## para bater), particle_drop, radius e arte. Valores em data/enemies/boss_*.tres.

@export_group("Golpe")
@export var attack_interval: float = 1.5 ## s entre golpes (inclui o wind-up)
@export var attack_windup: float = 0.5 ## s de aviso antes do golpe
@export var attack_damage: int = 25 ## dano ao Núcleo por golpe
@export var attack_id: StringName = &"boss_slam" ## pattern_id do boss_telegraph_started
@export var telegraph_radius: float = 110.0 ## px no chão (área do aviso, para o VFX)
@export var windup_scale: float = 0.12 ## crescimento do sprite no fim do wind-up (só visual)

@export_group("Lançamento")
@export var launch_distance: float = 600.0 ## px no chão, para longe do Núcleo (limitado à arena)
@export var launch_time: float = 0.6 ## s de voo
@export var stun_time: float = 2.0 ## s atordoado depois do voo (sem atacar)
@export var relaunch_immunity: float = 1.0 ## s depois de acordar em que o meteoro não o lança de novo

@export_group("Defesa (arquivada)")
## 0 = desligada (sem barra, escudo nem sinal). > 0 liga o escudo; volta cheio ao acordar.
@export var defense_max: int = 0

@export_group("Arte do estado")
## Opcionais (mesmo canvas e âncora do `sprite`): wind-up do golpe e atordoado.
@export var sprite_attack: Texture2D
@export var sprite_stunned: Texture2D
