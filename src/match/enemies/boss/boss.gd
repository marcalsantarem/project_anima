class_name Boss
extends Enemy
## Chefe ogro (decisão 39). Uma fase: anda até encostar no Núcleo (attack_range) e bate a cada
## attack_interval, com wind-up (aviso) de attack_windup. A defesa é um escudo na frente da vida:
## todo dano tira dela primeiro; ao zerar (ou ao levar meteoro), é lançado para longe do Núcleo,
## fica atordoado (o dano vai para a vida) e, no fim, a defesa volta cheia e ele anda de volta.

signal hp_changed(current: int, max_hp: int)
signal defense_changed(current: int, max_defense: int)
signal telegraph_started(pattern_id: StringName, duration: float)
signal attack_landed(damage: int)
signal launched(from: Vector2, to: Vector2)

enum Mode { ADVANCE, ATTACK, LAUNCHED, STUNNED }

const DEFENSE_COLOR := Color("#7F93AD") ## aço / cinza-azulado (não é ciano nem cor de vida)
const DEFENSE_BAR_WIDTH := 96.0 ## px
const WINDUP_FLASH := Color(1.0, 0.75, 0.7) ## tom do sprite no fim do wind-up

var boss_data: BossData
var mode: Mode = Mode.ADVANCE
var defense := 0
## Área visível onde o lançamento termina (posições de tela); definida pela arena. Vazia = sem limite.
var launch_bounds := Rect2()
var defense_bar: HealthBar

var _attack_left := 0.0 ## s até o golpe (no fim do intervalo)
var _winding := false
var _stun_left := 0.0
var _tween: Tween


func _ready() -> void:
	super()
	boss_data = data as BossData
	defense = boss_data.defense_max
	defense_bar = HealthBar.new()
	defense_bar.fixed_color = DEFENSE_COLOR
	defense_bar.configure(data.radius, sprite_top(), DEFENSE_BAR_WIDTH)
	add_child(defense_bar)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	match mode:
		Mode.ADVANCE:
			position = step_towards(position, target_position, data.speed, delta)
			if in_reach():
				_start_attack_cycle()
		Mode.ATTACK:
			tick_attack(delta)
		Mode.STUNNED:
			_stun_left -= delta
			if _stun_left <= 0.0:
				_recover()


func in_reach() -> bool:
	return GroundPlane.distance(position, target_position) <= data.attack_range


## Ciclo do golpe: espera → wind-up (aviso) → golpe. Público para testes.
func tick_attack(delta: float) -> void:
	_attack_left -= delta
	if not _winding and _attack_left <= boss_data.attack_windup:
		_winding = true
		_set_texture(boss_data.sprite_attack)
		telegraph_started.emit(boss_data.attack_id, boss_data.attack_windup)
	if _winding:
		var p := clampf(1.0 - _attack_left / maxf(boss_data.attack_windup, 0.001), 0.0, 1.0)
		_body.scale = SpriteArt.SCALE * (1.0 + boss_data.windup_scale * p)
		_body.modulate = Color.WHITE.lerp(WINDUP_FLASH, p)
	if _attack_left <= 0.0:
		attack_landed.emit(boss_data.attack_damage)
		_start_attack_cycle()


func take_damage(amount: int) -> void:
	if state == State.DEAD or amount <= 0:
		return
	if defense > 0:
		_set_defense(defense - amount) # o excedente não passa para a vida
		if defense == 0:
			launch()
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, data.hp)
	if hp == 0:
		die(DeathCause.KILLED)


## Meteoro: com defesa, zera e lança na hora (sem dano na vida); sem defesa, dano normal.
func take_skill_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	if defense > 0:
		_set_defense(0)
		launch()
		return
	take_damage(amount)


## Voa para longe do Núcleo, rumo à borda (launch_bounds), e fica atordoado no fim.
func launch() -> void:
	if state == State.DEAD or mode == Mode.LAUNCHED:
		return
	mode = Mode.LAUNCHED
	state = State.ATTACK # parado para a mira/meteoro (não avança)
	_end_windup()
	var from := position
	var to := launch_destination(from, target_position, boss_data.launch_distance, launch_bounds)
	launched.emit(from, to)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(self, ^"position", to, boss_data.launch_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_stun)


## Fim do voo: de `from`, para longe de `center`, `distance` px no chão, preso em `bounds`
## (bounds vazio = sem limite). Encosta na borda em vez de sair da área visível.
static func launch_destination(from: Vector2, center: Vector2, distance: float, bounds: Rect2) -> Vector2:
	var away := GroundPlane.to_ground(from - center)
	if away.length_squared() < 0.0001:
		away = Vector2.UP
	var to := from + GroundPlane.to_screen(away.normalized() * distance)
	if not bounds.has_area():
		return to
	return to.clamp(bounds.position, bounds.end)


func _stun() -> void:
	if state == State.DEAD:
		return
	mode = Mode.STUNNED
	_stun_left = boss_data.stun_time
	_set_texture(boss_data.sprite_stunned)


func _recover() -> void:
	_set_defense(boss_data.defense_max)
	_set_texture(data.sprite)
	mode = Mode.ADVANCE
	state = State.ADVANCE


func _start_attack_cycle() -> void:
	mode = Mode.ATTACK
	state = State.ATTACK
	_attack_left = boss_data.attack_interval
	_end_windup()


func _end_windup() -> void:
	_winding = false
	_body.scale = SpriteArt.SCALE
	_body.modulate = Color.WHITE
	if mode != Mode.STUNNED:
		_set_texture(data.sprite)


func _set_defense(value: int) -> void:
	defense = clampi(value, 0, boss_data.defense_max)
	defense_bar.set_ratio(float(defense) / maxf(boss_data.defense_max, 1.0))
	defense_changed.emit(defense, boss_data.defense_max)


func _set_texture(tex: Texture2D) -> void:
	if tex != null and _body.texture != tex:
		_body.texture = tex
