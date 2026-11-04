extends Node
## Cena de teste: Arena + HUD juntos (T-112). A ligação ao SceneFlow é da T-122.
## `preview_boss`: mostra a barra "Boss" (T-152) com vida falsa caindo, sem esperar o chefe da onda final.

const ARENA_SCENE := preload("res://src/match/arena/arena.tscn")
const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")
const PREVIEW_BOSS_MAX := 2500
const PREVIEW_BOSS_HIT := 180

@export var preview_boss := true

var arena: Node
var hud: Hud
var _boss_hp := PREVIEW_BOSS_MAX


func _ready() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	arena = ARENA_SCENE.instantiate()
	arena.setup(MatchConfig.new())
	hud.bind(arena) # antes de entrar na árvore: pega os valores iniciais
	add_child(arena)
	if preview_boss:
		hud._on_boss_spawned(&"boss_preview")
		hud._on_boss_hp_changed(_boss_hp, PREVIEW_BOSS_MAX)
		var timer := Timer.new()
		timer.wait_time = 1.0
		timer.autostart = true
		timer.timeout.connect(_preview_hit)
		add_child(timer)


func _preview_hit() -> void:
	_boss_hp -= PREVIEW_BOSS_HIT
	if _boss_hp <= 0:
		_boss_hp = PREVIEW_BOSS_MAX
	hud._on_boss_hp_changed(_boss_hp, PREVIEW_BOSS_MAX)
