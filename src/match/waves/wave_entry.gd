class_name WaveEntry
extends Resource
## Um grupo de inimigos dentro de uma onda.

enum SpawnEdge { TOP, BOTTOM, LEFT, RIGHT, RANDOM }

@export var enemy: EnemyData
@export var count: int = 1
@export var interval: float = 1.0 ## s entre spawns do grupo
@export var spawn_edge: SpawnEdge = SpawnEdge.RANDOM
@export var start_delay: float = 0.0 ## s desde o início da onda
