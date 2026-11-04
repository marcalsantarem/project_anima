class_name BossData
extends EnemyData
## Chefe: fases por vida e padrões com peso e aviso. Valores em data/enemies/boss_*.tres.
## Herdado do EnemyData: hp, speed, attack_range (distância do centro onde para), projectile,
## particle_drop, radius e arte.

## Fração da vida abaixo da qual entra a próxima fase (decrescente). [0.6, 0.3] = 3 fases.
@export var phase_thresholds: PackedFloat32Array = PackedFloat32Array([0.6, 0.3])
## Pausa entre o fim de um padrão e o aviso do próximo, por fase.
@export var pattern_interval: PackedFloat32Array = PackedFloat32Array([3.0, 2.4, 1.8])
@export var patterns: Array[BossPattern] = []
@export var projectile_range: float = 700.0 ## px no chão percorridos pelos projéteis do chefe


func phase_count() -> int:
	return phase_thresholds.size() + 1


## Fase (0-based) para a fração de vida `hp_ratio` (0..1).
func phase_for(hp_ratio: float) -> int:
	var phase := 0
	for t in phase_thresholds:
		if hp_ratio < t:
			phase += 1
	return phase


func interval_for(phase: int) -> float:
	if pattern_interval.is_empty():
		return 0.0
	return pattern_interval[clampi(phase, 0, pattern_interval.size() - 1)]
