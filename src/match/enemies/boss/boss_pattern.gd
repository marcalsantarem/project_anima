class_name BossPattern
extends Resource
## Um padrão de ataque do chefe. Fica dentro do BossData (data/enemies/boss_*.tres).

enum Kind {
	FAN, ## leque de projéteis mirado no Núcleo
	RING, ## anel de projéteis em volta do chefe
	SUMMON, ## invoca inimigos perto do chefe
}

@export var id: StringName
@export var kind: Kind = Kind.FAN
## Peso de sorteio por fase (índice 0 = fase 1). Peso 0 = não usado na fase.
@export var weights: PackedFloat32Array = PackedFloat32Array([1.0])
@export var telegraph: float = 1.0 ## s de aviso antes do efeito
@export var telegraph_radius: float = 140.0 ## px do desenho do aviso
@export var projectile_count: int = 5 ## FAN e RING
@export var spread_deg: float = 40.0 ## FAN: abertura total do leque
@export var summon: EnemyData ## SUMMON
@export var summon_count: int = 4
@export var summon_radius: float = 70.0 ## px em volta do chefe (no chão)


func weight_for(phase: int) -> float:
	if weights.is_empty():
		return 0.0
	return weights[clampi(phase, 0, weights.size() - 1)]
