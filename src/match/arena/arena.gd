class_name Arena
extends Node2D
## Raiz da partida (protótipo cinza). O spawn periódico é provisório: a T-105 o troca por WaveData.

signal core_hp_changed(current: int, max_hp: int)

enum Edge { TOP, BOTTOM, LEFT, RIGHT }

const ENEMY_SCENE := preload("res://src/match/enemies/enemy.tscn")

@export var spawn_enemy: EnemyData
@export var spawn_interval: float = 1.5 ## s
@export var spawn_margin: float = 64.0 ## px além da borda da tela

var is_over := false

var _spawn_timer := 0.0
var _rng := RandomNumberGenerator.new()

@onready var anima: Anima = $Anima
@onready var _enemies: Node2D = $Enemies


func _ready() -> void:
	anima.core_hp_changed.connect(func(c: int, m: int) -> void: core_hp_changed.emit(c, m))
	anima.core_depleted.connect(_on_core_depleted)
	get_viewport().size_changed.connect(_center_anima)
	_center_anima()
	core_hp_changed.emit(anima.core.current, anima.core.max_hp)


func _physics_process(delta: float) -> void:
	if is_over:
		return
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer -= spawn_interval
		spawn(spawn_enemy, _rng.randi_range(0, Edge.size() - 1) as Edge)


func spawn(enemy_data: EnemyData, edge: Edge) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(enemy_data, edge_point(edge, arena_size(), spawn_margin, _rng.randf()), anima.position)
	_enemies.add_child(enemy)
	return enemy


func arena_size() -> Vector2:
	return get_viewport_rect().size


## Ponto fora da tela na borda indicada. t (0..1) percorre a borda.
static func edge_point(edge: Edge, size: Vector2, margin: float, t: float) -> Vector2:
	match edge:
		Edge.TOP:
			return Vector2(size.x * t, -margin)
		Edge.BOTTOM:
			return Vector2(size.x * t, size.y + margin)
		Edge.LEFT:
			return Vector2(-margin, size.y * t)
		_:
			return Vector2(size.x + margin, size.y * t)


func _center_anima() -> void:
	anima.position = arena_size() / 2.0


func _on_core_depleted() -> void:
	is_over = true
