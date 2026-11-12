extends Node
## Autoload `SceneFlow`: Título → Menu → Partida (Arena + HUD + Pausa) → Resultado → Menu ou Partida.
## Ao fim da partida, fecha a recompensa no perfil (`MetaFlow.settle`) e salva pelo `Backend` (T-187).
##
## Contrato da cena de partida (nó raiz):
## - `setup(config: MatchConfig)`, chamado antes de entrar na árvore;
## - sinal `match_ended(result: MatchResult)`, emitido uma vez.
## Montagem com a UI: ver `docs/ui.md` §10c.

signal scene_changed(scene_path: String)
## Hangar (T-200): destino atual mudou (inclusive ao entrar no hangar, sempre em Jogar).
signal hangar_tab_changed(id: StringName)
## Hangar: tela de um destino foi criada (1ª visita), para quem precisar configurá-la.
signal hangar_tab_instanced(id: StringName, screen: Control)

const TITLE_SCENE := "res://src/ui/screens/title_screen.tscn"
const MENU_SCENE := "res://src/ui/screens/menu_screen.tscn"
const RESULT_SCENE := "res://src/ui/screens/result_screen.tscn"
const COMING_SOON_SCENE := "res://src/ui/screens/coming_soon_screen.tscn"
## Barra de destinos do hangar (T-201). Se existir, entra no `HangarHost` acima do `content`.
const HANGAR_BAR_SCENE := "res://src/ui/hangar/hangar_bar.tscn"
const PROGRESSION_PATH := "res://data/meta/progression_m2.tres"
const REWARDS_PATH := "res://data/meta/rewards_m2.tres"
const HUD_SCENE := "res://src/ui/hud/hud.tscn"
const PAUSE_SCENE := "res://src/ui/screens/pause_screen.tscn"
## Nome do nó raiz que agrupa Arena, HUD e Pausa.
const MATCH_ROOT_NAME := &"Match"
const ARENA_NODE_NAME := &"Arena"
const FX_POOL_NODE_NAME := &"FxPool"
const FX_DIRECTOR_NODE_NAME := &"FxDirector"
const RECORDER_NODE_NAME := &"MatchRecorder"

## Último resultado recebido.
var last_result: MatchResult
## Config da partida atual, reutilizada em "Recomeçar" e "Jogar de novo".
var last_config: MatchConfig
## Log da última partida (MatchRecorder, docs/debug.md), entregue ao Resultado.
var last_log: Dictionary = {}
## Perfil da conta, carregado pelo `Backend` no Boot (ou na 1ª necessidade).
var profile: PlayerProfile
## Resumo da recompensa da última partida (`{}` no modo de estresse). Chaves em `docs/arquitetura.md`.
var last_summary: Dictionary = {}
## Cenas das telas (trocáveis nos testes por telas dummy).
var title_scene_path := TITLE_SCENE
var menu_scene_path := MENU_SCENE
var result_scene_path := RESULT_SCENE
## Hangar (T-200): placeholder dos destinos sem tela e barra opcional (T-201; ausente = sem barra).
var coming_soon_scene_path := COMING_SOON_SCENE
var hangar_bar_scene_path := HANGAR_BAR_SCENE
var hangar_nav := HangarNav.new()
var _hangar: HangarHost
## Só testes: data fixa ("YYYY-MM-DD") no lugar da data local do sistema.
var today_override := ""
var progression: ProgressionData = load(PROGRESSION_PATH)
var rewards: RewardData = load(REWARDS_PATH)
var _changing := false
var _recorder: MatchRecorder


## Boot: carrega o perfil (falha = perfil novo, tratado no provedor) e abre o Título. Com o modo de
## estresse pedido (`?debug=1&stress=N,M`), vai direto para a partida.
func boot() -> void:
	load_profile()
	if StressMode.requested() != Vector2i.ZERO:
		start_match()
	else:
		go_to_title()


func load_profile() -> PlayerProfile:
	profile = Backend.load_profile()
	if profile == null:
		profile = PlayerProfile.new()
	return profile


func _ensure_profile() -> PlayerProfile:
	return profile if profile != null else load_profile()


func go_to_title() -> void:
	if _changing:
		return
	var title := _instantiate(title_scene_path)
	title.start_requested.connect(go_to_menu, CONNECT_ONE_SHOT)
	_swap(title, title_scene_path)


## Hangar (T-200): monta o `HangarHost` sempre no destino Jogar (também na volta da Partida/Resultado).
## Jogar = o menu: recebe a `view` do perfil por `setup(view)`; `play_pressed` → partida com o perfil.
## Sem a cena do menu, vai direto para a partida. `scene_changed` emite `menu_scene_path` (música do Menu).
func go_to_menu() -> void:
	if _changing:
		return
	if not ResourceLoader.exists(menu_scene_path):
		push_warning("SceneFlow: menu ausente (%s); indo direto para a partida" % menu_scene_path)
		start_match(build_match_config())
		return
	hangar_nav.reset()
	hangar_nav.paths[HangarNav.PLAY] = menu_scene_path
	_hangar = HangarHost.new()
	_hangar.show_screen(HangarNav.PLAY, _make_tab.bind(HangarNav.PLAY))
	if ResourceLoader.exists(hangar_bar_scene_path):
		_hangar.add_child(_instantiate(hangar_bar_scene_path))
	_swap(_hangar, menu_scene_path)
	hangar_tab_changed.emit(HangarNav.PLAY)


## Destino atual do hangar (`HangarNav.PLAY` etc.).
var current_tab: StringName:
	get:
		return hangar_nav.current


## Abre o destino `id` do hangar (carrega a tela na 1ª visita; depois reaproveita a instância em cache).
## Retorna `false` se o id é inválido, se já é o atual ou se o hangar não está aberto.
func open_hangar_tab(id: StringName) -> bool:
	if not _hangar_open() or not hangar_nav.open(id):
		return false
	_show_current_tab()
	return true


## Volta ao destino anterior (ou a Jogar). Retorna `false` se já está em Jogar sem histórico.
func hangar_back() -> bool:
	if not _hangar_open() or not hangar_nav.back():
		return false
	_show_current_tab()
	return true


## Tela em cache do destino (ou `null`). Para a barra do T-201 e para os testes.
func hangar_tab_node(id: StringName) -> Control:
	return _hangar.screen(id) if _hangar_open() else null


func _hangar_open() -> bool:
	return is_instance_valid(_hangar) and not _hangar.is_queued_for_deletion()


func _show_current_tab() -> void:
	var id := hangar_nav.current
	_hangar.show_screen(id, _make_tab.bind(id))
	hangar_tab_changed.emit(id)


## Cria a tela do destino. Cena ausente → placeholder "Em breve". Telas com `back_requested` → `hangar_back`.
func _make_tab(id: StringName) -> Control:
	var path := hangar_nav.scene_path(id)
	var node: Control
	if path != "" and ResourceLoader.exists(path):
		node = _instantiate(path)
	else:
		node = _instantiate(coming_soon_scene_path)
		if node.has_method(&"setup_title"):
			node.setup_title(HangarNav.title_of(id))
	node.name = String(id).to_pascal_case()
	if id == HangarNav.PLAY:
		node.setup(menu_view(_ensure_profile(), progression))
		node.play_pressed.connect(func() -> void: start_match(build_match_config()), CONNECT_ONE_SHOT)
	if node.has_signal(&"back_requested"):
		node.connect(&"back_requested", hangar_back)
	hangar_tab_instanced.emit(id, node)
	return node


## Dados do menu: {level, xp, xp_to_next (0 no teto), coins, is_max}.
static func menu_view(p: PlayerProfile, prog: ProgressionData) -> Dictionary:
	return {"level": p.level, "xp": p.xp, "xp_to_next": xp_to_next_of(p.level, prog),
		"coins": p.coins, "is_max": p.level >= prog.max_level}


## XP para sair do nível dado; 0 no teto.
static func xp_to_next_of(level: int, prog: ProgressionData) -> int:
	if level >= prog.max_level or level < 1 or level > prog.xp_to_next.size():
		return 0
	return prog.xp_to_next[level - 1]


## Config da partida a partir do perfil: slots de Módulo pelo nível da conta (T-188).
func build_match_config() -> MatchConfig:
	return MatchConfig.for_account(_ensure_profile().level, progression.slot_unlock_levels)


func start_match(config: MatchConfig = null) -> void:
	if _changing:
		return
	if config == null:
		config = MatchConfig.new()
	last_config = config
	var match_root := Node.new()
	match_root.name = MATCH_ROOT_NAME
	var arena := _instantiate(config.match_scene_path)
	arena.name = ARENA_NODE_NAME
	arena.setup(config)
	var hud: Hud = _instantiate(HUD_SCENE)
	var pause: PauseScreen = _instantiate(PAUSE_SCENE)
	match_root.add_child(hud)
	match_root.add_child(pause)
	# `bind` antes de a arena entrar na árvore, para o HUD receber o estado inicial.
	hud.bind(arena)
	_link_slot_levels(hud, config)
	pause.bind(arena)
	pause.restart_requested.connect(func() -> void: start_match(config), CONNECT_ONE_SHOT)
	_connect_back_to_menu(pause)
	arena.match_ended.connect(_on_match_ended.bind(arena), CONNECT_ONE_SHOT)
	_link_bottom_inset(arena, hud)
	var director := _link_fx(arena, match_root)
	_link_reduced_effects(arena, director, pause)
	_link_debug(arena, hud, pause, match_root)
	match_root.add_child(arena)
	_swap(match_root, config.match_scene_path)


## Slots no HUD pelo nível da conta (T-188). Config sem conta (`account_level` 0) mantém o padrão do HUD.
func _link_slot_levels(hud: Hud, config: MatchConfig) -> void:
	if config.account_level <= 0:
		return
	hud.set_slot_unlock_levels(MatchConfig.hud_lock_levels(config.account_level, progression.slot_unlock_levels))
	hud.ready.connect(func() -> void:
		for slot in range(1, MatchConfig.SLOT_COUNT + 1):
			hud.set_slot_empty(slot, slot <= config.unlocked_slots and slot > maxi(config.slot_modules.size(), 1)),
		CONNECT_ONE_SHOT)


## Efeitos (docs/vfx.md §1.1): pool como filho direto da Arena (Y-sort com as entidades; decalques
## em z −1 acima do piso em z −10) e director no nó da partida, ligado depois do `_ready` da Arena.
## Instâncias pré-criadas aqui, fora da partida. Efeitos reduzidos: ver `_link_reduced_effects`.
func _link_fx(arena: Arena, match_root: Node) -> FxDirector:
	var pool := FxPool.new()
	pool.name = FX_POOL_NODE_NAME
	pool.setup_default()
	arena.add_child(pool)
	var director := FxDirector.new()
	director.name = FX_DIRECTOR_NODE_NAME
	director.pool = pool
	match_root.add_child(director)
	arena.ready.connect(func() -> void: director.bind(arena), CONNECT_ONE_SHOT)
	return director


## "Efeitos reduzidos" (T-132, BRF-080): valor salvo em DebugSettings aplicado ao criar a partida e
## de novo quando o interruptor da pausa muda (vale já na partida em curso).
func _link_reduced_effects(arena: Node, director: FxDirector, pause: PauseScreen) -> void:
	apply_reduced_effects(arena, director, DebugSettings.reduced_effects())
	pause.reduced_effects_changed.connect(func(on: bool) -> void: apply_reduced_effects(arena, director, on))


## Repassa para a Arena (AG01; só se ela já tiver a propriedade) e para o FxDirector (AG09, que repassa
## ao FxPool, de onde o MatchRecorder lê `reduced_effects`).
static func apply_reduced_effects(arena: Node, director: FxDirector, on: bool) -> void:
	if is_instance_valid(arena) and &"reduced_effects" in arena:
		arena.set(&"reduced_effects", on)
	if is_instance_valid(director):
		director.reduced_effects = on


## Debug (docs/debug.md): gravador sempre ligado e overlay (desligado por padrão), no nó da partida e
## antes da Arena entrar na árvore. A seed sorteada aqui fica no log (reproduzir com Arena.set_seed).
func _link_debug(arena: Node, hud: Hud, pause: PauseScreen, match_root: Node) -> void:
	var match_seed := randi()
	if arena.has_method(&"set_seed"):
		arena.set_seed(match_seed)
	_recorder = MatchRecorder.new()
	_recorder.name = RECORDER_NODE_NAME
	_recorder.attach(arena, hud, pause, match_seed)
	match_root.add_child(_recorder)
	var overlay := DebugOverlay.new()
	overlay.setup(_recorder, hud)
	match_root.add_child(overlay)


## Liga a base da Arena à altura da bandeja do HUD (com a safe area), também ao redimensionar.
## O match não conhece a UI: a ligação fica aqui. O HUD entra na árvore antes da Arena.
func _link_bottom_inset(arena: Arena, hud: Hud) -> void:
	var sync := func() -> void: arena.set_bottom_inset(hud.tray_height())
	hud.ready.connect(func() -> void:
		sync.call()
		hud.get_viewport().size_changed.connect(sync), CONNECT_ONE_SHOT)
	hud.tree_exiting.connect(func() -> void:
		var vp := hud.get_viewport()
		if vp != null and vp.size_changed.is_connected(sync):
			vp.size_changed.disconnect(sync), CONNECT_ONE_SHOT)


## Arena da partida em andamento, ou `null` fora da partida.
func current_arena() -> Node:
	var current := get_tree().current_scene
	if current == null or current.name != MATCH_ROOT_NAME:
		return null
	return current.get_node_or_null(NodePath(ARENA_NODE_NAME))


func _on_match_ended(result: MatchResult, arena: Node = null) -> void:
	last_result = result
	var stress := is_instance_valid(arena) and arena.get_node_or_null(^"StressMode") != null
	var screen := _instantiate(result_scene_path)
	screen.show_result(result)
	if _recorder != null and is_instance_valid(_recorder):
		_recorder.finish(result)
		last_log = _recorder.log_data
		stress = stress or _recorder.header.has("stress")
	last_summary = {} if stress else settle_and_save(result)
	if screen.has_method(&"set_log"):
		screen.set_log(last_log)
	if not last_summary.is_empty() and screen.has_method(&"set_reward"):
		screen.set_reward(last_summary)
	screen.play_again_requested.connect(func() -> void: start_match(build_match_config()), CONNECT_ONE_SHOT)
	_connect_back_to_menu(screen)
	_swap(screen, result_scene_path)


## "Voltar" (Resultado) e "Voltar ao título"/equivalente (Pausa) levam ao Menu. Aceita o sinal novo
## `menu_requested` ou o antigo `title_requested`.
func _connect_back_to_menu(node: Node) -> void:
	for sig: StringName in [&"menu_requested", &"title_requested"]:
		if node.has_signal(sig):
			node.connect(sig, go_to_menu, CONNECT_ONE_SHOT)
			return


## Fecha a partida no perfil e salva pelo `Backend`. Falha ao salvar só avisa no log (o fluxo segue).
## Retorna o `summary` do Resultado (chaves em `docs/arquitetura.md`).
func settle_and_save(result: MatchResult) -> Dictionary:
	var p := _ensure_profile()
	var level_before := p.level
	var xp_before := p.xp
	var today := today_override if today_override != "" else Time.get_date_string_from_system()
	var s := MetaFlow.settle(p, result, rewards, progression, today)
	if not Backend.save_profile(p):
		push_warning("SceneFlow: falha ao salvar o perfil; a recompensa vale só nesta sessão")
	var slots: Array[int] = []
	slots.assign(s["slots_unlocked"])
	return {
		"xp": int(s["xp"]), "coins": int(s["coins"]), "first_win_bonus": bool(s["first_win_bonus"]),
		"levels_gained": int(s["levels_gained"]), "slots_unlocked": slots,
		"level_before": level_before, "xp_before": xp_before,
		"xp_to_next_before": xp_to_next_of(level_before, progression),
		"level_after": p.level, "xp_after": p.xp, "xp_to_next_after": xp_to_next_of(p.level, progression),
		"result_outcome": "vitoria" if result.outcome == MatchResult.Outcome.VICTORY else "derrota",
	}


func _instantiate(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()


func _swap(node: Node, path: String) -> void:
	_changing = true
	get_tree().paused = false
	get_tree().change_scene_to_node.call_deferred(node)
	await get_tree().scene_changed
	_changing = false
	scene_changed.emit(path)
