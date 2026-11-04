class_name ProjectileData
extends Resource
## Balanceamento de um tipo de projétil. Valores em data/projectiles/.

enum Shape { CIRCLE, DIAMOND }

@export var id: StringName
@export var speed: float = 900.0 ## px/s
@export var damage: int = 10
@export var radius: float = 6.0 ## px
@export var height: float = 24.0 ## px de voo acima da sombra (só desenho)
@export var pierce: int = 0 ## alvos extras atravessados
@export var color: Color = Color(0.3, 0.95, 1.0)
## Forma distinta para leitura: jogador = círculo, inimigo = losango.
@export var shape: Shape = Shape.CIRCLE
