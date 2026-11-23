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
## Meteoros contra a horda (sem chefe vivo): lançados, com 0 acertos e anulados (skill_fizzled).
var horde_casts := 0
var horde_zero_hits := 0
var fizzles := 0
## true = usa os Módulos de todos os slots com regras simples (BRF-171); false = só o slot 1 ao ficar pronto.
var use_modules := false
## Usos por id de Módulo (só com use_modules).
var module_uses := {}

var _next := 0


func attach(p_arena: Arena) -> void:
	arena = p_arena
	arena.boss_spawned.connect(_on_boss_spawned)
	arena.particles_gained.connect(func(_at: Vector2, amount: int) -> void: particles_earned += amount)
	arena.enemy_died.connect(_on_enemy_died)
	arena.projectile_hit.connect(_on_projectile_hit)
	arena.skill_cast.connect(_on_skill_cast)
	if arena.has_signal(&"skill_fizzled"):
		arena.connect(&"skill_fizzled", func(_slot: int, _at: Vector2) -> void: fizzles += 1)
	arena.match_ended.connect(func(r: MatchResult) -> void:
		result = r
		match_ended_count += 1)
	arena.skills.skill_used.connect(func(slot: int) -> void:
		var b := arena.skills.get_behavior(slot)
		if b != null:
			module_uses[b.data.id] = module_uses.get(b.data.id, 0) + 1)
	arena.add_child(self)


func _physics_process(_delta: float) -> void:
	if arena.is_over or passive:
		return
	if use_modules:
		_use_modules()
	else:
		var slot := arena.skills.get_slot(1)
		if slot != null and slot.is_ready():
			arena.use_skill(1)
	_buy()


## Regras simples por Módulo (BRF-171): meteoro e choque quando há alvo (choque só em grupo ou chefe),
## congelamento com muitos inimigos perto do Núcleo ou chefe perto, escudo com o Núcleo abaixo de 60% ou chefe perto.
func _use_modules() -> void:
	for slot in range(1, arena.skills.slot_count() + 1):
		var s := arena.skills.get_slot(slot)
		if s == null or not s.is_ready():
			continue
		var data := arena.skills.get_behavior(slot).data
		var core := arena.anima.position
		var near := 0
		var boss_near := false
		var boss_alive := false
		for e in arena.active_enemies:
			if e.state == Enemy.State.DEAD:
				continue
			var d := GroundPlane.distance(core, e.position)
			if e is Boss:
				boss_alive = true
				boss_near = boss_near or d <= 350.0
			if d <= 250.0:
				near += 1
		match data.type:
			SkillData.Type.AREA:
				if data.effect_params.has("jumps"):
					var t := AreaSkill.densest_enemy(core, arena.active_enemies, data.target_range, data.radius)
					if t != null and (boss_alive or _neighbors(t, data.radius) >= 2):
						arena.use_skill(slot)
				else:
					arena.use_skill(slot)
			SkillData.Type.CONTROL:
				if near >= 4 or boss_near:
					if not arena.use_skill(slot, _closest_enemy_pos()):
						arena.use_skill(slot)
			SkillData.Type.DEFENSE:
				if float(arena.anima.core.current) / arena.anima.core.max_hp < 0.6 or boss_near:
					arena.use_skill(slot)


func _neighbors(t: Enemy, radius: float) -> int:
	var n := 0
	for e in arena.active_enemies:
		if e.state != Enemy.State.DEAD and GroundPlane.distance(t.position, e.position) <= radius:
			n += 1
	return n


func _closest_enemy_pos() -> Vector2:
	var best := Vector2.INF
	var best_d := INF
	for e in arena.active_enemies:
		if e.state == Enemy.State.DEAD:
			continue
		var d := GroundPlane.distance(arena.anima.position, e.position)
		if d < best_d:
			best_d = d
			best = e.position
	return best


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


func _on_skill_cast(slot: int, _at: Vector2, _radius: float) -> void:
	if reached_boss:
		return
	var b := arena.skills.get_behavior(slot) as AreaSkill
	if b == null:
		return
	horde_casts += 1
	if b.last_hits == 0:
		horde_zero_hits += 1


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
