class_name SimBot
extends Node
## Bot "médio" de balanceamento (BRF-051). Filho da Arena; joga sem mira nem posicionamento:
## - usa a skill do slot 1 assim que fica pronta (o alvo é automático);
## - compra upgrades em round-robin na ordem BUY_ORDER: espera ter Partículas para o próximo da
##   fila; o que está no máximo é pulado.
## Mede o que a simulação reporta (ver run_sim.gd e docs/gameplay.md "Simulação").

const BUY_ORDER: Array[StringName] = [
	&"upgrade_atk_power", &"upgrade_atk_spd", &"upgrade_max_hp", &"upgrade_defense", &"upgrade_cooldown",
]

var arena: Arena
## true = só observa (partida sem intervenção do jogador: nem skill nem upgrade).
var passive := false
var reached_boss := false
var boss_core_pct := 0.0 ## HP do Núcleo (0..1) quando o chefe entra
var boss_at := 0.0 ## s de partida quando o chefe entra
var particles_earned := 0
var upgrades_bought := 0
var result: MatchResult
var match_ended_count := 0
## Dano bruto no Núcleo por origem (id do arquétipo por contato; &"bolt_hits" = nº de tiros que acertaram).
var damage_by_source := {}

var _next := 0


func attach(p_arena: Arena) -> void:
	arena = p_arena
	arena.boss_spawned.connect(_on_boss_spawned)
	arena.particles_gained.connect(func(_at: Vector2, amount: int) -> void: particles_earned += amount)
	arena.enemy_died.connect(_on_enemy_died)
	arena.projectile_hit.connect(_on_projectile_hit)
	arena.match_ended.connect(func(r: MatchResult) -> void:
		result = r
		match_ended_count += 1)
	arena.add_child(self)


func _physics_process(_delta: float) -> void:
	if arena.is_over or passive:
		return
	var slot := arena.skills.get_slot(1)
	if slot != null and slot.is_ready():
		arena.use_skill(1)
	_buy()


func _buy() -> void:
	for i in BUY_ORDER.size():
		var id := BUY_ORDER[_next]
		if arena.upgrades.next_cost(id) < 0:
			_next = (_next + 1) % BUY_ORDER.size() # no máximo: pula
			continue
		if arena.buy_upgrade(id):
			upgrades_bought += 1
			_next = (_next + 1) % BUY_ORDER.size()
		return


func _on_boss_spawned(_id: StringName) -> void:
	if reached_boss:
		return
	reached_boss = true
	boss_at = arena.elapsed
	boss_core_pct = float(arena.anima.core.current) / arena.anima.core.max_hp


func _on_enemy_died(_at: Vector2, archetype_id: StringName, cause: int) -> void:
	if cause == Enemy.DeathCause.CONTACT:
		_tally(archetype_id, _contact_damage(archetype_id))


func _on_projectile_hit(_at: Vector2, target_kind: StringName) -> void:
	if target_kind == Projectile.TARGET_CORE:
		_tally(&"bolt_hits", 1)


func _contact_damage(archetype_id: StringName) -> int:
	for e in arena.active_enemies:
		if e.data.id == archetype_id:
			return e.data.contact_damage
	return load("res://data/enemies/%s.tres" % archetype_id).contact_damage


func _tally(source: StringName, amount: int) -> void:
	damage_by_source[source] = damage_by_source.get(source, 0) + amount
