class_name Arena
extends Node2D
## Raiz da partida. Recebe setup(config), roda as ondas da fase e emite match_ended uma vez.
## Perspectiva 3/4: Anima, inimigos e projéteis são ordenados por Y (âncora no chão); a regra
## de distância e colisão vale no plano do chão (ver GroundPlane).

signal core_hp_changed(current: int, max_hp: int)
signal wave_changed(current: int, total: int)
signal particles_changed(total: int)
signal match_ended(result: MatchResult)
signal skill_used(slot: int)
signal cooldown_changed(slot: int, remaining: float, total: float)
signal skill_ready(slot: int)
signal boss_spawned(id: StringName)
signal boss_hp_changed(current: int, max_hp: int)
signal boss_defeated
## Estado de um upgrade da partida. next_cost = -1 no nível máximo (contrato em docs/gameplay.md).
signal upgrade_changed(id: StringName, level: int, max_level: int, next_cost: int)
## Sinais para VFX/áudio (docs/vfx.md). Posições = âncora no chão, em coordenadas de tela da Arena;
## raios em px no chão (GroundPlane). Nenhum é emitido por quadro: só nos eventos.
signal projectile_fired(from: Vector2, dir: Vector2) ## tiro do Anima; dir em tela, normalizada
signal projectile_hit(at: Vector2, target_kind: StringName) ## &"enemy" | &"boss" | &"core"
signal enemy_died(at: Vector2, archetype_id: StringName, cause: int) ## cause = Enemy.DeathCause
signal particles_gained(at: Vector2, amount: int)
signal skill_cast(slot: int, at: Vector2, radius: float)
signal skill_fizzled(slot: int, at: Vector2) ## meteoro anulado (sem inimigo no raio); cooldown devolvido
signal boss_telegraph_started(pattern_id: StringName, duration: float, at: Vector2, radius: float)
## Defesa do chefe (escudo na frente da vida; ARQUIVADA, decisão 42). Só é emitido por chefes com
## defense_max > 0 (o boss_warden não emite). Início e a cada mudança.
signal boss_defense_changed(current: int, max_defense: int)
## Chefe lançado (meteoro; ou defesa arquivada esgotada): de `from` até `to` (âncora no chão, tela).
signal boss_launched(from: Vector2, to: Vector2)

## Upgrades da partida, na ordem da fileira do HUD.
const UPGRADE_IDS: Array[StringName] = [
	&"upgrade_atk_power", &"upgrade_atk_spd", &"upgrade_defense", &"upgrade_max_hp", &"upgrade_cooldown",
]

const ENEMY_SCENE := preload("res://src/match/enemies/enemy.tscn")
const BOSS_SCENE := preload("res://src/match/enemies/boss/boss.tscn")

## Folga além da borda da TELA no spawn, somada ao tamanho do desenho do inimigo
## (spawn_margin_for: nenhum inimigo nasce visível).
@export var spawn_margin: float = 32.0
## Arena = do topo da tela até o início da bandeja inferior do HUD (o HUD de cima fica
## sobreposto ao fundo). Altura da bandeja, sem safe area = Hud.TRAY_HEIGHT (docs/ui.md §4.4);
## o match não conhece a UI: quem monta a partida pode chamar set_bottom_inset(hud.tray_height()).
@export var arena_bottom_inset: float = 282.0
## Topo da área livre (abaixo do HUD de cima) = Hud.TOP_INSET, FIXO (decisão 43): a barra "Boss"
## não desloca o Anima. O Anima fica no centro da área livre (free_rect).
@export var arena_top_inset: float = 164.0
## Desligável para testes e debug (spawn só manual).
@export var waves_enabled := true
@export var enemy_projectile_pool_size: int = 128
@export var enemy_projectile: ProjectileData ## tipo padrão do pool inimigo

var config: MatchConfig
## Se nulo no _ready, é carregada de data/waves/<config.stage_id>.tres.
var stage: StageData
var waves: WaveRunner
var is_over := false
var particles := 0 ## moeda da partida: começa em 0 e zera a cada partida
var enemies_killed := 0
var elapsed := 0.0
## Níveis dos upgrades desta partida (novo a cada partida).
var upgrades: MatchUpgrades
## Inimigos vivos; compartilhado com a mira do Anima.
var active_enemies: Array[Enemy] = []

var _rng := RandomNumberGenerator.new()

@onready var anima: Anima = $Anima
@onready var projectiles: ProjectilePool = $Projectiles
@onready var enemy_projectiles: ProjectilePool = $EnemyProjectiles
@onready var skills: SkillController = $Skills
@onready var _enemies: Node2D = $Enemies
@onready var _floor: ArenaFloor = $Floor


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

	upgrades = MatchUpgrades.from_ids(UPGRADE_IDS)
	anima.upgrades = upgrades
	projectiles.build(anima.data.projectile_pool_size, anima.data.projectile)
	enemy_projectiles.build(enemy_projectile_pool_size, enemy_projectile)
	projectiles.projectile_fired.connect(projectile_fired.emit)
	projectiles.projectile_hit.connect(projectile_hit.emit)
	enemy_projectiles.projectile_hit.connect(projectile_hit.emit)
	anima.setup_attack(active_enemies, projectiles)
	anima.core_hp_changed.connect(func(c: int, m: int) -> void: core_hp_changed.emit(c, m))
	anima.core_depleted.connect(func() -> void: _end(MatchResult.Outcome.DEFEAT))
	skills.setup(SkillContext.new(anima, active_enemies))
	skills.skill_used.connect(func(slot: int) -> void: skill_used.emit(slot))
	skills.cooldown_changed.connect(func(slot: int, r: float, t: float) -> void: cooldown_changed.emit(slot, r, t))
	skills.skill_ready.connect(func(slot: int) -> void: skill_ready.emit(slot))
	skills.skill_cast.connect(skill_cast.emit)
	skills.skill_fizzled.connect(skill_fizzled.emit)
	get_viewport().size_changed.connect(_layout)
	_layout()

	core_hp_changed.emit(anima.core.current, anima.core.max_hp)
	_emit_particles()
	for id in UPGRADE_IDS:
		_emit_upgrade(id)
	if waves_enabled:
		waves.start()


func _physics_process(delta: float) -> void:
	if is_over:
		return
	elapsed += delta
	if waves_enabled:
		waves.tick(delta, active_enemies.size())


## Fixa a seed do sorteio da partida (bordas RANDOM, grupos, chefe). Chamar antes de entrar
## na árvore ou antes do primeiro spawn: mesma seed = mesmos spawns (T-123).
func set_seed(value: int) -> void:
	_rng.seed = value


## Aciona a skill do slot (1-based). Para os botões de toque da UI.
func use_skill(slot: int) -> bool:
	return skills.use_skill(slot)


## Compra 1 nível do upgrade se houver Partículas e não estiver no máximo. Não pausa.
func buy_upgrade(id: StringName) -> bool:
	if is_over or not upgrades.can_buy(id, particles):
		return false
	var hp_before := upgrades.apply(MatchUpgrades.STAT_CORE_HP_MAX, anima.data.core_hp_max)
	particles -= upgrades.level_up(id)
	var hp_gain := roundi(upgrades.apply(MatchUpgrades.STAT_CORE_HP_MAX, anima.data.core_hp_max) - hp_before)
	if hp_gain > 0:
		anima.core.raise_max(hp_gain)
	skills.cooldown_scale = upgrades.apply(MatchUpgrades.STAT_COOLDOWN, 1.0)
	_emit_particles()
	_emit_upgrade(id)
	return true


func spawn(enemy_data: EnemyData, edge: WaveEntry.SpawnEdge) -> Enemy:
	if edge == WaveEntry.SpawnEdge.RANDOM:
		edge = _rng.randi_range(WaveEntry.SpawnEdge.TOP, WaveEntry.SpawnEdge.RIGHT) as WaveEntry.SpawnEdge
	var enemy: Enemy = (BOSS_SCENE if enemy_data is BossData else ENEMY_SCENE).instantiate()
	var margin := spawn_margin_for(enemy_data, spawn_margin, edge)
	enemy.setup(enemy_data, edge_point(edge, screen_rect(), margin, _rng.randf()), anima.position)
	enemy.projectile_pool = enemy_projectiles
	enemy.died.connect(_on_enemy_died)
	_enemies.add_child(enemy)
	active_enemies.append(enemy)
	if enemy is Boss:
		_bind_boss(enemy as Boss)
	return enemy


func _bind_boss(boss: Boss) -> void:
	boss.launch_bounds = boss_launch_bounds(boss)
	boss.hp_changed.connect(func(c: int, m: int) -> void: boss_hp_changed.emit(c, m))
	boss.defense_changed.connect(boss_defense_changed.emit)
	boss.launched.connect(boss_launched.emit)
	boss.attack_landed.connect(_on_boss_attack)
	boss.telegraph_started.connect(func(pattern_id: StringName, duration: float) -> void:
		boss_telegraph_started.emit(pattern_id, duration, boss.position, boss.boss_data.telegraph_radius))
	boss_spawned.emit(boss.data.id)
	boss_hp_changed.emit(boss.hp, boss.data.hp)
	if boss.has_defense(): # defesa arquivada (decisão 42): sem ela, o sinal não é emitido
		boss_defense_changed.emit(boss.defense, boss.boss_data.defense_max)


## Área visível onde o chefe pode cair ao ser lançado: a arena acima da bandeja, com folga para o
## corpo inteiro (laterais e base = raio; topo = altura do sprite).
func boss_launch_bounds(boss: Boss) -> Rect2:
	var r := boss.data.radius
	return arena_rect().grow_individual(-r, -boss.sprite_top(), -r, -r)


func _on_boss_attack(damage: int) -> void:
	if not is_over:
		anima.take_core_damage(damage)


## Spawn de um grupo (group_min..group_max) espalhado em volta do mesmo ponto de borda.
func spawn_group(enemy_data: EnemyData, edge: WaveEntry.SpawnEdge) -> int:
	var n := _rng.randi_range(enemy_data.group_min, maxi(enemy_data.group_min, enemy_data.group_max))
	var leader := spawn(enemy_data, edge)
	for i in n - 1:
		var e := spawn(enemy_data, edge)
		e.position = leader.position + GroundPlane.to_screen(Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * enemy_data.group_spread)
	return n


func arena_size() -> Vector2:
	return get_viewport_rect().size


## Tela inteira: o spawn é por fora das bordas dela.
func screen_rect() -> Rect2:
	return Rect2(Vector2.ZERO, arena_size())


## Área jogável: do topo da tela até o início da bandeja inferior (limite do lançamento do chefe).
func arena_rect() -> Rect2:
	return rect_for(arena_size(), arena_bottom_inset)


## Área livre entre o HUD de cima e a bandeja. O Anima fica no centro dela (decisão 43).
func free_rect() -> Rect2:
	return free_rect_for(arena_size(), arena_top_inset, arena_bottom_inset)


static func free_rect_for(screen: Vector2, top_inset: float, bottom_inset: float) -> Rect2:
	var tray_top := maxf(screen.y - bottom_inset, 0.0)
	var top := minf(top_inset, tray_top)
	return Rect2(0.0, top, screen.x, tray_top - top)


## Altura da bandeja inferior (px da resolução base, com safe area). Recalcula o layout.
func set_bottom_inset(px: float) -> void:
	arena_bottom_inset = px
	if is_node_ready():
		_layout()


static func rect_for(screen: Vector2, bottom_inset: float) -> Rect2:
	return Rect2(0.0, 0.0, screen.x, maxf(screen.y - bottom_inset, 0.0))


## Folga do spawn além da borda da tela para o desenho inteiro do inimigo ficar fora dela:
## laterais = meia largura do maior desenho (corpo ou anel); base = altura acima da âncora;
## topo = raio (a sombra fica abaixo da âncora). px 1x.
static func spawn_margin_for(enemy_data: EnemyData, base: float, edge: WaveEntry.SpawnEdge) -> float:
	var half_w := 0.0
	var up := 0.0
	if enemy_data.sprite != null:
		half_w = enemy_data.sprite.get_width() * SpriteArt.SCALE.x * 0.5
		up = enemy_data.sprite_anchor.y * SpriteArt.SCALE.y
	if enemy_data.ring_sprite != null:
		half_w = maxf(half_w, enemy_data.ring_sprite.get_width() * SpriteArt.SCALE.x * 0.5)
	match edge:
		WaveEntry.SpawnEdge.LEFT, WaveEntry.SpawnEdge.RIGHT:
			return base + half_w
		WaveEntry.SpawnEdge.BOTTOM:
			return base + up
		_:
			return base + enemy_data.radius


## Ponto fora da arena na borda indicada (não RANDOM). t (0..1) percorre a borda.
static func edge_point(edge: WaveEntry.SpawnEdge, rect: Rect2, margin: float, t: float) -> Vector2:
	match edge:
		WaveEntry.SpawnEdge.TOP:
			return Vector2(rect.position.x + rect.size.x * t, rect.position.y - margin)
		WaveEntry.SpawnEdge.BOTTOM:
			return Vector2(rect.position.x + rect.size.x * t, rect.end.y + margin)
		WaveEntry.SpawnEdge.LEFT:
			return Vector2(rect.position.x - margin, rect.position.y + rect.size.y * t)
		_:
			return Vector2(rect.end.x + margin, rect.position.y + rect.size.y * t)


func _on_spawn_requested(enemy_data: EnemyData, edge: WaveEntry.SpawnEdge) -> void:
	spawn_group(enemy_data, edge)


func _on_enemy_died(enemy: Enemy, cause: Enemy.DeathCause) -> void:
	active_enemies.erase(enemy)
	enemy_died.emit(enemy.position, enemy.data.id, cause)
	if cause == Enemy.DeathCause.KILLED and not is_over:
		enemies_killed += 1
		particles += enemy.data.particle_drop
		_emit_particles()
		if enemy.data.particle_drop > 0:
			particles_gained.emit(enemy.position, enemy.data.particle_drop)
		if enemy is Boss:
			boss_defeated.emit()
			_end(MatchResult.Outcome.VICTORY)


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
	result.particles = particles
	result.enemies_killed = enemies_killed
	result.duration_s = elapsed
	match_ended.emit(result)


func _layout() -> void:
	var free := free_rect()
	anima.position = free.get_center()
	_floor.layout(arena_size(), free, anima.position)
	for e in active_enemies: # inimigos já em campo seguem o novo centro
		e.target_position = anima.position

func _emit_upgrade(id: StringName) -> void:
	upgrade_changed.emit(id, upgrades.level(id), upgrades.max_level(id), upgrades.next_cost(id))


func _emit_particles() -> void:
	particles_changed.emit(particles)
