class_name Boss
extends Enemy
## Chefe: entra, para a data.attack_range do centro e alterna padrões sorteados por peso da fase.
## Cada padrão tem aviso (telegraph) antes do efeito. Projéteis vêm do pool inimigo da arena.

signal hp_changed(current: int, max_hp: int)
signal phase_changed(phase: int) ## 0-based
signal telegraph_started(pattern_id: StringName, duration: float)
signal pattern_executed(pattern_id: StringName)
signal summon_requested(enemy_data: EnemyData, at: Vector2)

enum Action { WAIT, TELEGRAPH }

var boss_data: BossData
var phase := 0
var action: Action = Action.WAIT
var current_pattern: BossPattern
var rng := RandomNumberGenerator.new()

var _action_left := 0.0
var _telegraph: BossTelegraph


func _ready() -> void:
	super()
	boss_data = data as BossData
	_telegraph = BossTelegraph.new()
	add_child(_telegraph)
	move_child(_telegraph, 0) # atrás do corpo


func _physics_process(delta: float) -> void:
	match state:
		State.ADVANCE:
			position = step_towards(position, target_position, data.speed, delta)
			if GroundPlane.distance(position, target_position) <= data.attack_range:
				state = State.ATTACK
				_wait()
		State.ATTACK:
			tick_patterns(delta)


## Avança o ciclo espera → aviso → efeito. Público para testes.
func tick_patterns(delta: float) -> void:
	_action_left -= delta
	if action == Action.TELEGRAPH:
		_telegraph.set_progress(1.0 - _action_left / maxf(current_pattern.telegraph, 0.001))
	if _action_left > 0.0:
		return
	if action == Action.WAIT:
		_begin_telegraph()
	else:
		_execute(current_pattern)
		_wait()


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, data.hp)
	if hp == 0:
		die(DeathCause.KILLED)
		return
	var new_phase := boss_data.phase_for(float(hp) / data.hp)
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)


## Sorteio por peso da fase atual; null se nenhum padrão vale na fase.
func pick_pattern() -> BossPattern:
	var total := 0.0
	for p in boss_data.patterns:
		total += p.weight_for(phase)
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for p in boss_data.patterns:
		var w := p.weight_for(phase)
		if w > 0.0 and roll < w:
			return p
		roll -= w
	return null


func _wait() -> void:
	action = Action.WAIT
	_action_left = boss_data.interval_for(phase)
	_telegraph.hide_warning()


func _begin_telegraph() -> void:
	current_pattern = pick_pattern()
	if current_pattern == null:
		_wait()
		return
	action = Action.TELEGRAPH
	_action_left = current_pattern.telegraph
	var shape := BossTelegraph.Shape.CONE if current_pattern.kind == BossPattern.Kind.FAN else BossTelegraph.Shape.CIRCLE
	_telegraph.show_warning(shape, current_pattern.telegraph_radius, target_position - position, deg_to_rad(current_pattern.spread_deg))
	telegraph_started.emit(current_pattern.id, current_pattern.telegraph)


func _execute(p: BossPattern) -> void:
	match p.kind:
		BossPattern.Kind.FAN:
			var aim := GroundPlane.to_ground(target_position - position).normalized()
			var spread := deg_to_rad(p.spread_deg)
			for i in p.projectile_count:
				var t := 0.5 if p.projectile_count == 1 else float(i) / (p.projectile_count - 1)
				_fire_ground(aim.rotated(-spread * 0.5 + spread * t))
		BossPattern.Kind.RING:
			var offset := rng.randf() * TAU
			for i in p.projectile_count:
				_fire_ground(Vector2.from_angle(offset + TAU * i / p.projectile_count))
		BossPattern.Kind.SUMMON:
			for i in p.summon_count:
				var around := Vector2.from_angle(TAU * i / maxi(p.summon_count, 1)) * p.summon_radius
				summon_requested.emit(p.summon, position + GroundPlane.to_screen(around))
	pattern_executed.emit(p.id)


func _fire_ground(ground_dir: Vector2) -> void:
	if projectile_pool == null:
		return
	var proj := projectile_pool.acquire()
	if proj == null:
		return
	proj.fire(position, GroundPlane.to_screen(ground_dir), boss_data.projectile_range, data.projectile)
