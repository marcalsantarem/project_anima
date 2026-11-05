class_name FxDirector
extends Node
## Liga os sinais da Arena aos efeitos do FxPool (docs/vfx.md, T-130). Só visual: nunca altera
## a partida. Tolera sinais ausentes (conecta só os que a arena expõe). Não depende de match/:
## a arena é tratada como Node genérico. Posições recebidas = âncoras no chão, no espaço local
## da arena; são convertidas para o espaço local do pool.

const DEATH_COLORS := {
	&"enemy_runner": Color("#FF8A3D"),
	&"enemy_tank": Color("#E8344E"),
	&"enemy_shooter": Color("#FF3DB4"),
	&"enemy_swarm": Color("#9B5CFF"),
}
const DEATH_SIZES := {&"enemy_tank": 1.4, &"enemy_swarm": 0.7}
const BOSS_COLOR := Color("#C040F5")
const CORE_HIT_COLOR := Color("#E8344E")
const NO_COLOR := Color(0, 0, 0, 0)
const DEATH_CAUSE_CONTACT := 1 ## Enemy.DeathCause.CONTACT (repetido: fx/ não depende de match/)
const BOSS_DEATH_SIZE := 3.0
const BOSS_WINDUP_COLOR := Color("#E8344E") ## aviso do golpe: vermelho (decisão 47, ogro)
## Tempos do chefe e do meteoro repetidos dos dados (fx/ não depende de match/ nem de data/).
const BOSS_LAUNCH_TIME := 0.6 ## BossData.launch_time
const BOSS_STUN_TIME := 2.0 ## BossData.stun_time
const METEOR_FALL_HEIGHT := 360.0 ## SkillData.fall_height do skill_meteor
const METEOR_BASE_RADIUS := 160.0 ## raio do skill_meteor: tamanho 1 da explosão
const BOSS_DEATH_EXPLOSION_SIZE := 1.8

## Sinal da arena → método deste nó. Conectados só se existirem.
const SIGNALS := {
	&"projectile_fired": &"_on_projectile_fired",
	&"projectile_hit": &"_on_projectile_hit",
	&"enemy_died": &"_on_enemy_died",
	&"particles_gained": &"_on_particles_gained",
	&"skill_cast": &"_on_skill_cast",
	&"skill_fizzled": &"_on_skill_fizzled",
	&"skill_used": &"_on_skill_used",
	&"skill_ready": &"_on_skill_ready",
	## Pedido ao AG01 (ainda não existe): início da queda do meteoro, para o rastro acompanhar a
	## queda. Sem ele, o rastro aparece no impacto, já se desfazendo (fallback).
	&"skill_fall_started": &"_on_skill_fall_started",
	&"boss_telegraph_started": &"_on_boss_telegraph_started",
	&"boss_launched": &"_on_boss_launched",
	&"boss_defeated": &"_on_boss_defeated",
	&"core_hp_changed": &"_on_core_hp_changed",
	&"upgrade_changed": &"_on_upgrade_changed",
}

@export var pool: FxPool
## Âncora do Núcleo/Anima (espaço da arena) quando a arena não tem um filho "Anima".
@export var core_anchor := Vector2(360, 690)

## Modo de efeitos reduzidos (T-132): repassado ao pool (metade das gotas, sem flash, explosão sem
## brasas/fumaça). Aqui corta rastros (tiro, meteoro, voo do chefe), fumaça da cratera, brilho do
## wind-up e poeiras. Mantém a leitura: aviso do golpe no chão, onda do golpe, estrelas do
## atordoamento, explosão e anel do meteoro (o aviso do meteoro é desenhado pelo match/).
var reduced_effects := false:
	set(value):
		reduced_effects = value
		if pool:
			pool.reduced_effects = value

var _arena: Node2D
var _core_node: Node2D
var _connected: Array[StringName] = []
var _last_core_hp := -1
var _last_boss_at := Vector2.ZERO
var _has_boss_at := false
var _upgrade_levels := {}
var _boss_strike_pending := false
var _windup_fx: FxEffect
var _stun_fx: FxEffect


## Conecta os sinais existentes em `arena`. Devolve os nomes conectados.
func bind(arena: Node) -> Array[StringName]:
	unbind()
	_arena = arena as Node2D
	_core_node = arena.get_node_or_null(^"Anima") as Node2D
	_last_core_hp = -1
	_has_boss_at = false
	_boss_strike_pending = false
	_windup_fx = null
	_stun_fx = null
	_upgrade_levels.clear()
	for sig: StringName in SIGNALS:
		if arena.has_signal(sig):
			arena.connect(sig, Callable(self, SIGNALS[sig]))
			_connected.append(sig)
	if pool:
		pool.reduced_effects = reduced_effects
	return _connected


func unbind() -> void:
	if _arena and is_instance_valid(_arena):
		for sig: StringName in _connected:
			var c := Callable(self, SIGNALS[sig])
			if _arena.is_connected(sig, c):
				_arena.disconnect(sig, c)
	_connected.clear()
	_arena = null


func connected_signals() -> Array[StringName]:
	return _connected


func _exit_tree() -> void:
	unbind()


# --- reações -------------------------------------------------------------------------------

func _on_projectile_fired(from: Vector2, dir: Vector2) -> void:
	var at := _to_pool(from)
	_play(&"fx_muzzle", at)
	if reduced_effects or dir == Vector2.ZERO:
		return
	var trail := _play(&"fx_trail", at)
	if trail:
		trail.direction = dir.normalized()


func _on_projectile_hit(at: Vector2, target_kind: StringName) -> void:
	var p := _to_pool(at)
	match target_kind:
		&"boss":
			_last_boss_at = at
			_has_boss_at = true
			_play(&"fx_hit", p, BOSS_COLOR, 1.3)
		&"core", &"anima":
			_play(&"fx_hit", p, CORE_HIT_COLOR)
		_:
			_play(&"fx_hit", p)


func _on_enemy_died(at: Vector2, archetype_id: StringName, cause: int) -> void:
	var c: Color = DEATH_COLORS.get(archetype_id, BOSS_COLOR if String(archetype_id).begins_with("boss_") else NO_COLOR)
	var s: float = DEATH_SIZES.get(archetype_id, 1.0)
	if String(archetype_id).begins_with("boss_"):
		s = BOSS_DEATH_SIZE
	elif cause == DEATH_CAUSE_CONTACT:
		s *= 0.8 # chegou ao Núcleo: o pulso do Núcleo é o destaque
	_play(&"fx_death", _to_pool(at), c, s)


func _on_particles_gained(at: Vector2, amount: int) -> void:
	_play(&"fx_pickup", _to_pool(at), NO_COLOR, clampf(1.0 + 0.1 * (amount - 1), 1.0, 1.5)) # verde da cena


## Impacto do meteoro: onda no chão (quente) + explosão; cratera fumegando fora do reduzido.
func _on_skill_cast(_slot: int, at: Vector2, radius: float) -> void:
	var p := _to_pool(at)
	_play(&"fx_skill_cast", p, NO_COLOR, _radius_scale(&"fx_skill_cast", radius))
	_play(&"fx_meteor_explosion", p, NO_COLOR, radius / METEOR_BASE_RADIUS if radius > 0.0 else 1.0)
	if reduced_effects:
		return
	var smoke := _play(&"fx_crater_smoke", p, NO_COLOR, radius / METEOR_BASE_RADIUS if radius > 0.0 else 1.0)
	if smoke:
		smoke.delay = 0.12
	if not _connected.has(&"skill_fall_started"):
		# Fallback: sem o sinal da queda, o rastro aparece já na cauda, se desfazendo no impacto.
		var trail := _start_meteor_trail(p)
		if trail:
			trail.elapsed = trail.travel_time


func _on_skill_fall_started(_slot: int, at: Vector2, _fall_time: float) -> void:
	if not reduced_effects:
		_start_meteor_trail(_to_pool(at))


func _start_meteor_trail(p: Vector2) -> FxEffect:
	var trail := _play(&"fx_meteor_trail", p - Vector2(0, METEOR_FALL_HEIGHT))
	if trail:
		trail.target = Vector2(0, METEOR_FALL_HEIGHT)
	return trail


func _on_skill_fizzled(_slot: int, at: Vector2) -> void:
	_play(&"fx_fizzle", _to_pool(at))


## Módulo usado (T-117): flash no Anima.
func _on_skill_used(_slot: int) -> void:
	_play(&"fx_module_used", _to_pool(_core_anchor()))


## Módulo pronto (T-117): brilho subindo no Anima.
func _on_skill_ready(_slot: int) -> void:
	_play(&"fx_module_ready", _to_pool(_core_anchor()))


## Wind-up do golpe: anel vermelho no chão (sempre) + brilho vermelho no ogro (fora do reduzido).
func _on_boss_telegraph_started(_pattern_id: StringName, duration: float, at: Vector2, radius: float) -> void:
	_last_boss_at = at
	_has_boss_at = true
	_boss_strike_pending = true
	var p := _to_pool(at)
	var fx := _play(&"fx_telegraph", p, BOSS_WINDUP_COLOR, _radius_scale(&"fx_telegraph", radius))
	if fx and duration > 0.0:
		fx.duration = duration
	if reduced_effects:
		return
	_windup_fx = _play(&"fx_boss_windup", p + Vector2(0, 1)) # +1: à frente do ogro no Y-sort
	if _windup_fx and duration > 0.0:
		_windup_fx.duration = duration


## Lançado pelo meteoro: voo com poeira e estrelas, poeira no pouso e estrelas do atordoamento.
func _on_boss_launched(from: Vector2, to: Vector2) -> void:
	_boss_strike_pending = false
	_stop(_windup_fx)
	_last_boss_at = to
	_has_boss_at = true
	var p_to := _to_pool(to)
	if not reduced_effects:
		var p_from := _to_pool(from)
		var fly := _play(&"fx_boss_launch", p_from)
		if fly:
			fly.target = p_to - p_from
		var land := _play(&"fx_boss_land", p_to)
		if land:
			land.delay = BOSS_LAUNCH_TIME
	_stun_fx = _play(&"fx_boss_stun", p_to + Vector2(0, 1))
	if _stun_fx:
		_stun_fx.delay = BOSS_LAUNCH_TIME
		_stun_fx.duration = BOSS_STUN_TIME


func _on_boss_defeated() -> void:
	_boss_strike_pending = false
	_stop(_windup_fx)
	_stop(_stun_fx)
	var p := _to_pool(_boss_anchor())
	_play(&"fx_death", p, BOSS_COLOR, BOSS_DEATH_SIZE)
	_play(&"fx_meteor_explosion", p, NO_COLOR, BOSS_DEATH_EXPLOSION_SIZE)


## Dano no Núcleo: pulso; se veio do golpe do chefe (wind-up pendente), onda + poeira no Núcleo.
func _on_core_hp_changed(current: int, _max_hp: int) -> void:
	if _last_core_hp >= 0 and current < _last_core_hp:
		var p := _to_pool(_core_anchor())
		_play(&"fx_core_pulse", p)
		if _boss_strike_pending:
			_boss_strike_pending = false
			_play(&"fx_boss_wave", p)
			if not reduced_effects:
				_play(&"fx_boss_slam", p)
	_last_core_hp = current


func _on_upgrade_changed(id: StringName, level: int, _max_level: int, _next_cost: int) -> void:
	if level > int(_upgrade_levels.get(id, 0)):
		_play(&"fx_upgrade", _to_pool(_core_anchor()))
	_upgrade_levels[id] = level


# --- apoio ---------------------------------------------------------------------------------

func _play(type: StringName, at: Vector2, color := NO_COLOR, size := 1.0) -> FxEffect:
	if pool == null or pool.capacity(type) == 0:
		return null
	return pool.play(type, at, color, size)


## Desliga um efeito guardado (se ainda for o mesmo uso; o pool pode tê-lo reciclado, sem dano).
func _stop(fx: FxEffect) -> void:
	if fx and is_instance_valid(fx) and fx.active:
		fx.stop()


## Espaço local da arena → espaço local do pool (identidade quando o pool é filho da arena).
func _to_pool(at: Vector2) -> Vector2:
	if pool == null or _arena == null or pool.get_parent() == _arena:
		return at
	return pool.to_local(_arena.to_global(at))


func _core_anchor() -> Vector2:
	return _core_node.position if _core_node and is_instance_valid(_core_node) else core_anchor


func _boss_anchor() -> Vector2:
	return _last_boss_at if _has_boss_at else _core_anchor() + Vector2(0, -360)


func _radius_scale(type: StringName, radius: float) -> float:
	var base := pool.base_radius(type) if pool else 0.0
	return radius / base if radius > 0.0 and base > 0.0 else 1.0
