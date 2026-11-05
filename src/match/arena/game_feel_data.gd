class_name GameFeelData
extends Resource
## Game feel da partida (T-117): tremor de tela, hit-stop e números de dano. Valores em
## data/feel/game_feel.tres. Tremor em px (decaimento quadrático até 0 em `*_time` s).

const DEFAULT_PATH := "res://data/feel/game_feel.tres"

@export_group("Tremor")
@export var shake_meteor: float = 14.0 ## px; impacto do meteoro (forte)
@export var shake_meteor_time: float = 0.25
@export var shake_boss_hit: float = 9.0 ## golpe do ogro no Núcleo (médio)
@export var shake_boss_hit_time: float = 0.2
@export var shake_boss_death: float = 16.0 ## morte do chefe (forte)
@export var shake_boss_death_time: float = 0.4
@export var shake_core_big: float = 5.0 ## dano grande no Núcleo (leve)
@export var shake_core_big_time: float = 0.15
## Dano "grande" no Núcleo: perda de uma vez ≥ esta fração do HP máximo.
@export_range(0.0, 1.0) var core_big_hit_ratio: float = 0.1
## Fator do tremor com "Efeitos reduzidos".
@export_range(0.0, 1.0) var shake_reduced_scale: float = 0.3

@export_group("Hit-stop")
@export var hit_stop_meteor: float = 0.06 ## s (tempo real)
@export var hit_stop_boss_launch: float = 0.05
@export var hit_stop_boss_death: float = 0.08
## Engine.time_scale durante o hit-stop (0 = congela a simulação).
@export_range(0.0, 1.0) var hit_stop_time_scale: float = 0.0

@export_group("Números de dano")
@export var damage_font: Font
@export var damage_font_weight: int = 800
@export var damage_pool_size: int = 48
@export var damage_max_per_frame: int = 12 ## números novos por quadro de física (o resto é descartado)
@export var damage_lifetime: float = 0.6 ## s
@export var damage_rise: float = 56.0 ## px que o número sobe na vida toda
@export var damage_pop: float = 0.35 ## escala extra no nascimento (some em 15% da vida)
@export var damage_shot_size: int = 26
@export var damage_shot_color: Color = Color.WHITE
@export var damage_skill_size: int = 40
@export var damage_skill_color: Color = Color(1.0, 0.55, 0.12)
@export var damage_outline_size: int = 6
@export var damage_outline_color: Color = Color(0.08, 0.05, 0.12)
@export var damage_z_index: int = 20
