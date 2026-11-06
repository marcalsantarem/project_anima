class_name FxPool
extends Node2D
## Pool de efeitos visuais (docs/vfx.md). Todas as instâncias são criadas em register() /
## setup_default(), antes da partida; play() só religa uma instância livre. Cheio: recicla a
## mais antiga do tipo (o limite nunca é ultrapassado). Só visual: não altera o estado do jogo.
## Coloque o pool como filho de um nó com y_sort_enabled (ex.: Arena): ele também ordena por Y,
## então os efeitos se ordenam junto com as entidades pela âncora no chão.

## Tipos da demo: id → [cena, instâncias]. Orçamento em docs/vfx.md.
const DEFAULT_TYPES := {
	&"fx_muzzle": [preload("res://src/fx/fx_muzzle.tscn"), 6],
	&"fx_trail": [preload("res://src/fx/fx_trail.tscn"), 8],
	&"fx_hit": [preload("res://src/fx/fx_hit.tscn"), 24],
	&"fx_death": [preload("res://src/fx/fx_death.tscn"), 16],
	&"fx_pickup": [preload("res://src/fx/fx_pickup.tscn"), 12],
	&"fx_upgrade": [preload("res://src/fx/fx_upgrade.tscn"), 2],
	&"fx_skill_cast": [preload("res://src/fx/fx_skill_cast.tscn"), 2],
	&"fx_telegraph": [preload("res://src/fx/fx_telegraph.tscn"), 6],
	&"fx_core_pulse": [preload("res://src/fx/fx_core_pulse.tscn"), 3],
	# T-131: meteoro e chefe (poucos ao mesmo tempo)
	&"fx_meteor_explosion": [preload("res://src/fx/fx_meteor_explosion.tscn"), 2],
	&"fx_meteor_trail": [preload("res://src/fx/fx_meteor_trail.tscn"), 2],
	&"fx_crater_smoke": [preload("res://src/fx/fx_crater_smoke.tscn"), 2],
	&"fx_fizzle": [preload("res://src/fx/fx_fizzle.tscn"), 2],
	&"fx_boss_windup": [preload("res://src/fx/fx_boss_windup.tscn"), 1],
	&"fx_boss_slam": [preload("res://src/fx/fx_boss_slam.tscn"), 2],
	&"fx_boss_wave": [preload("res://src/fx/fx_boss_wave.tscn"), 2],
	&"fx_boss_launch": [preload("res://src/fx/fx_boss_launch.tscn"), 1],
	&"fx_boss_land": [preload("res://src/fx/fx_boss_land.tscn"), 1],
	&"fx_boss_stun": [preload("res://src/fx/fx_boss_stun.tscn"), 1],
	# T-117: Módulo pronto / usado (no Anima)
	&"fx_module_ready": [preload("res://src/fx/fx_module_ready.tscn"), 2],
	&"fx_module_used": [preload("res://src/fx/fx_module_used.tscn"), 2],
}

## Modo de efeitos reduzidos (T-132): metade das gotas, sem flash, sem brasas/fumaça na explosão.
## O que não toca no reduzido (rastros, fumaça, brilhos) é decidido no FxDirector.
var reduced_effects := false

var _pools := {} # StringName → Array[FxEffect]


func _init() -> void:
	y_sort_enabled = true


func setup_default() -> void:
	for type: StringName in DEFAULT_TYPES:
		var entry: Array = DEFAULT_TYPES[type]
		register(type, entry[0], entry[1])


## Pré-cria `count` instâncias de `scene` (raiz FxEffect). Chamar fora da partida.
func register(type: StringName, scene: PackedScene, count: int) -> void:
	FxEffect.prepare_textures()
	var list: Array[FxEffect] = []
	if _pools.has(type):
		list = _pools[type]
	for i in count:
		var fx: FxEffect = scene.instantiate()
		fx.name = "%s_%d" % [type, list.size()]
		list.append(fx)
		add_child(fx)
	_pools[type] = list


## Toca o efeito `type` na âncora `anchor` (ponto no chão, coordenadas locais do pool).
## `color.a == 0` usa a cor padrão do tipo. Devolve a instância usada ou null se o tipo não existe.
func play(type: StringName, anchor: Vector2, color := Color(0, 0, 0, 0), size := 1.0) -> FxEffect:
	if not _pools.has(type) or (_pools[type] as Array).is_empty():
		push_warning("FxPool: tipo desconhecido %s" % type)
		return null
	var list: Array = _pools[type]
	var chosen: FxEffect = null
	for fx: FxEffect in list:
		if not fx.active:
			chosen = fx
			break
		if chosen == null or fx.elapsed > chosen.elapsed:
			chosen = fx
	if chosen.active:
		chosen.stop() # pool cheio: recicla a mais antiga
	chosen.start(anchor, color, size, reduced_effects)
	return chosen


func capacity(type: StringName) -> int:
	return (_pools[type] as Array).size() if _pools.has(type) else 0


func active_count(type: StringName) -> int:
	var n := 0
	if not _pools.has(type):
		return 0
	for fx: FxEffect in _pools[type]:
		if fx.active:
			n += 1
	return n


## Raio da cena do tipo (para converter um raio de gameplay em `size`). 0 se não existe.
func base_radius(type: StringName) -> float:
	if not _pools.has(type) or (_pools[type] as Array).is_empty():
		return 0.0
	return (_pools[type][0] as FxEffect).radius


func stop_all() -> void:
	for type: StringName in _pools:
		for fx: FxEffect in _pools[type]:
			fx.stop()
