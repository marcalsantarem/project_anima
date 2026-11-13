class_name ProjectilePool
extends Node2D
## Pool fixo de projéteis. Tudo é instanciado em build(); disparar não aloca.
## Repassa `fired`/`hit` de todos os projéteis (ligados uma vez, no build).

signal projectile_fired(from: Vector2, dir: Vector2)
signal projectile_hit(at: Vector2, target_kind: StringName)

@export var projectile_scene: PackedScene = preload("res://src/match/projectiles/projectile.tscn")

var _items: Array[Projectile] = []
var _free: Array[Projectile] = []


func build(size: int, data: ProjectileData, extra_pierce: int = 0) -> void:
	for i in size:
		var p: Projectile = projectile_scene.instantiate()
		add_child(p)
		p.configure(data, extra_pierce)
		p.expired.connect(_on_expired)
		p.fired.connect(projectile_fired.emit)
		p.hit.connect(projectile_hit.emit)
		_items.append(p)
		_free.append(p)


func size() -> int:
	return _items.size()


func active_count() -> int:
	return _items.size() - _free.size()


## Devolve um projétil livre ou null se o pool estiver esgotado.
func acquire() -> Projectile:
	if _free.is_empty():
		return null
	return _free.pop_back()


func release(p: Projectile) -> void:
	if p.active:
		p.park()
	if not _free.has(p):
		_free.append(p)


func _on_expired(p: Projectile) -> void:
	release(p)
