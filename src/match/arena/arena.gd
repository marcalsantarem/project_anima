class_name Arena
extends Node2D
## Raiz da partida. Recebe setup(config), roda as ondas da fase e emite match_ended uma vez.

signal core_hp_changed(current: int, max_hp: int)
signal wave_changed(current: int, total: int)
signal coins_changed(amount: int)
signal match_ended(result: MatchResult)
signal skill_used(slot: int)
signal cooldown_changed(slot: int, remaining: float, total: float)
signal skill_ready(slot: int)

const ENEMY_SCENE := preload("res://src/match/enemies/enemy.tscn")

@export var spawn_margin: float = 64.0 ## px além da borda da tela
## Desligável para testes e debug (spawn só manual).
@export var waves_enabled := true
@export var enemy_projectile_pool_size: int = 128
@export var enemy_projectile: ProjectileData ## tipo padrão do pool inimigo

var config: MatchConfig
## Se nulo no _ready, é carregada de data/waves/<config.stage_id>.tres.
var stage: StageData
var waves: WaveRunner
var is_over := false
var coins := 0
var enemies_killed := 0
var elapsed := 0.0
## Inimigos vivos; compartilhado com a mira do Anima.
var active_enemies: Array[Enemy] = []

var _rng := RandomNumberGenerator.new()

@onready var anima: Anima = $Anima
@onready var projectiles: ProjectilePool = $Projectiles
@onready var enemy_projectiles: ProjectilePool = $EnemyProjectiles
@onready var skills: SkillController = $Skills
@onready var _enemies: Node2D = $Enemies


## Contrato do SceneFlow: chamado antes de entrar na árvore.
func setup(p_config: MatchConfig) -> void:
	config = p_config


func _ready() -> void:
	if config == null:
		config = MatchConfig.new()
	if stage == null:
		stage = load(StageData.path_for(config.stage_id))
	waves = WaveRunner.new(stage)
	waves.spawn_requested.connect(_on_spawn_requested)
	waves.wave_started.connect(func(c: int, t: int) -> void: wave_changed.emit(c, t))
	waves.stage_cleared.connect(func() -> void: _end(MatchResult.Outcome.VICTORY))

	projectiles.build(anima.data.projectile_pool_size, anima.data.projectile)
	enemy_projectiles.build(enemy_projectile_pool_size, enemy_projectile)
	anima.setup_attack(active_enemies, projectiles)
	anima.core_hp_changed.connect(func(c: int, m: int) -> void: core_hp_changed.emit(c, m))
	anima.core_depleted.connect(func() -> void: _end(MatchResult.Outcome.DEFEAT))
	skills.setup(SkillContext.new(anima, active_enemies))
	skills.skill_used.connect(func(slot: int) -> void: skill_used.emit(slot))
	skills.cooldown_changed.connect(func(slot: int, r: float, t: float) -> void: cooldown_changed.emit(slot, r, t))
	skills.skill_ready.connect(func(slot: int) -> void: skill_ready.emit(slot))
	get_viewport().size_changed.connect(_center_anima)
	_center_anima()

	core_hp_changed.emit(anima.core.current, anima.core.max_hp)
	coins_changed.emit(coins)
	if waves_enabled:
		waves.start()


func _physics_process(delta: float) -> void:
	if is_over:
		return
	elapsed += delta
	if waves_enabled:
		waves.tick(delta, active_enemies.size())


## Aciona a skill do slot (1-based). Para os botões de toque da UI.
func use_skill(slot: int) -> bool:
	return skills.use_skill(slot)


func spawn(enemy_data: EnemyData, edge: WaveEntry.SpawnEdge) -> Enemy:
	if edge == WaveEntry.SpawnEdge.RANDOM:
		edge = _rng.randi_range(WaveEntry.SpawnEdge.TOP, WaveEntry.SpawnEdge.RIGHT) as WaveEntry.SpawnEdge
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(enemy_data, edge_point(edge, arena_size(), spawn_margin, _rng.randf()), anima.position)
	enemy.projectile_pool = enemy_projectiles
	enemy.died.connect(_on_enemy_died)
	_enemies.add_child(enemy)
	active_enemies.append(enemy)
	return enemy


## Spawn de um grupo (group_min..group_max) espalhado em volta do mesmo ponto de borda.
func spawn_group(enemy_data: EnemyData, edge: WaveEntry.SpawnEdge) -> int:
	var n := _rng.randi_range(enemy_data.group_min, maxi(enemy_data.group_min, enemy_data.group_max))
	var leader := spawn(enemy_data, edge)
	for i in n - 1:
		var e := spawn(enemy_data, edge)
		e.position = leader.position + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * enemy_data.group_spread
	return n


func arena_size() -> Vector2:
	return get_viewport_rect().size


## Ponto fora da tela na borda indicada (não RANDOM). t (0..1) percorre a borda.
static func edge_point(edge: WaveEntry.SpawnEdge, size: Vector2, margin: float, t: float) -> Vector2:
	match edge:
		WaveEntry.SpawnEdge.TOP:
			return Vector2(size.x * t, -margin)
		WaveEntry.SpawnEdge.BOTTOM:
			return Vector2(size.x * t, size.y + margin)
		WaveEntry.SpawnEdge.LEFT:
			return Vector2(-margin, size.y * t)
		_:
			return Vector2(size.x + margin, size.y * t)


func _on_spawn_requested(enemy_data: EnemyData, edge: WaveEntry.SpawnEdge) -> void:
	spawn_group(enemy_data, edge)


func _on_enemy_died(enemy: Enemy, cause: Enemy.DeathCause) -> void:
	active_enemies.erase(enemy)
	if cause == Enemy.DeathCause.KILLED and not is_over:
		enemies_killed += 1
		coins += enemy.data.coin_drop
		coins_changed.emit(coins)


func _end(outcome: MatchResult.Outcome) -> void:
	if is_over:
		return
	is_over = true
	anima.auto_attack_enabled = false
	skills.enabled = false
	# Diferido: pode ocorrer dentro de um callback de física.
	_enemies.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	enemy_projectiles.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	var result := MatchResult.new()
	result.outcome = outcome
	result.wave_reached = waves.current_wave()
	result.waves_total = waves.total_waves()
	result.coins = coins
	result.enemies_killed = enemies_killed
	result.duration_s = elapsed
	match_ended.emit(result)


func _center_anima() -> void:
	anima.position = arena_size() / 2.0
