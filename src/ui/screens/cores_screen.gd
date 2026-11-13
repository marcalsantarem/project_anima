class_name CoresScreen
extends Control
## Tela do destino Núcleos do hangar (T-207, BRF-155; docs/ui.md §8c, arte §11.10, assets/ui/README.md).
## Topo com Voltar, título e saldo de Moeda; árvore 3 × 4 (molduras por estado, selos "n/máx", ligações
## `Line2D` acesas quando o pré-requisito está cumprido); painel de detalhe com Comprar e Redistribuir
## (com confirmação). A lógica é do `MetaTalents`; a tela só chama a API e salva pelo `Backend`.
## Dados por `setup(profile, tree, save)` (testes) ou, sem setup, do `SceneFlow` ao entrar na árvore.
## Teclado: Input Actions de UI (`ui_up/down/left/right` navegam, `ui_accept` num nó vai ao Comprar).

signal back_requested
## Compra ou respec aplicados (e salvos).
signal profile_changed

enum NodeState { LOCKED, NORMAL, OWNED, MAX }

## Chaves de tradução (Loc.t).
const TXT_BACK := "COMMON_BACK"
const TXT_TITLE := "HANGAR_TAB_CORES"
const TXT_MAX := "COMMON_MAX"
const TXT_BUY := "CORES_BUY"
const TXT_CHIP := "CORES_CHIP"
const TXT_LEVEL := "CORES_LEVEL"
const TXT_NOW := "CORES_EFFECT_NOW"
const TXT_NEXT := "CORES_EFFECT_NEXT"
const TXT_NONE := "CORES_EFFECT_NONE"
const TXT_MAXED := "CORES_MAXED"
const TXT_NO_COINS := "CORES_NO_COINS"
const TXT_NEEDS := "CORES_NEEDS"
const TXT_NEEDS_SEP := "CORES_NEEDS_SEP"
const TXT_FEATURE := "CORES_FEATURE_LOCKED"
const TXT_RESPEC := "CORES_RESPEC"
const TXT_RESPEC_ASK := "CORES_RESPEC_ASK"
const TXT_CONFIRM := "CORES_CONFIRM"
const TXT_CANCEL := "CORES_CANCEL"

const BASE_W := 375.0
const HOLO_BG := Color("#021423")
const HOLO_TEXT := Color("#E6FFFF")
const HOLO_TEXT2 := Color("#9FF6FF")
const HOLO_MUTED := Color("#7FA3B8")
const HOLO_INK := Color("#03202E")
const CHIP_LOCKED := Color("#5F7A92")
const WARN := Color("#FFB86B")
const BRANCH_COLORS := {&"attack": Color("#FF9F43"), &"defense": Color("#4F8DFF"), &"economy": Color("#E07BFF")}
## Atributos com valor aditivo puro (o resto é percentual, em fração).
const FLAT_STATS: Array[StringName] = [&"stat_pierce", &"stat_start_particles"]

## Geometria da árvore em px do viewport 720 (README: colunas 150/375/600, passo de linha 200).
const COL_X: Array[float] = [150.0, 375.0, 600.0]
const TREE_W := 720.0
const HEADER_H := 48.0
const ROW0_Y := HEADER_H + 64.0
const ROW_STEP := 200.0
const BTN := 128.0 ## alvo de toque do nó (moldura 112 centrada)
const FRAME := 112.0
const ICON := 64.0
const CHIP := Vector2(68.0, 28.0)
const ROUTE_DX := 112.0 ## meio passo: rota por fora da ligação que cortaria um nó
const ROUTE_DY := 92.0 ## abaixo do selo
const TREE_H := ROW0_Y + 3.0 * ROW_STEP + ROUTE_DY + 16.0
const LINK_W := 24.0

## Topo (a 1x, como o "Em breve").
const PILL_W := 104.0
const PILL_H := 56.0
const TOUCH := 64.0
const BAR_H := 110.0
const BACK_ICON := 18.0
const BTN_H := 104.0 ## botões do painel (px do viewport, >= 88)

const ASSET_DIR := "res://assets/ui/"
const T_NODE := preload("res://assets/ui/ui_talent_node.png")
const T_NODE_SELECTED := preload("res://assets/ui/ui_talent_node_selected.png")
const T_NODE_OWNED := preload("res://assets/ui/ui_talent_node_owned.png")
const T_NODE_MAX := preload("res://assets/ui/ui_talent_node_max.png")
const T_NODE_LOCKED := preload("res://assets/ui/ui_talent_node_locked.png")
const T_CHIP := preload("res://assets/ui/ui_talent_level_chip.png")
const T_LINK_ON := preload("res://assets/ui/ui_talent_link_h_on.png")
const T_LINK_OFF := preload("res://assets/ui/ui_talent_link_h_off.png")
const T_COIN := preload("res://assets/ui/ui_icon_coin_small.png")
const T_PILL := preload("res://assets/ui/ui_holo_pill.png")
const T_PANEL := preload("res://assets/ui/ui_holo_panel.png")
const T_PRIMARY := preload("res://assets/ui/ui_holo_btn_primary_normal.png")
const T_PRIMARY_DOWN := preload("res://assets/ui/ui_holo_btn_primary_pressed.png")
const T_SECONDARY := preload("res://assets/ui/ui_holo_btn_secondary_normal.png")
const T_SECONDARY_DOWN := preload("res://assets/ui/ui_holo_btn_secondary_pressed.png")
const T_SECONDARY_OFF := preload("res://assets/ui/ui_holo_btn_secondary_disabled.png")
const T_BACK := preload("res://assets/ui/ui_icon_back.png")

var profile: PlayerProfile
var tree: TalentTree
## `func(profile: PlayerProfile) -> bool`; vazio = `Backend.save_profile`.
var save_func: Callable
var selected: StringName = &""

var coins_label: Label
var buy_button: Button
var respec_button: Button
var detail_name: Label
var detail_sub: Label
var detail_desc: Label
var detail_effect: Label
var detail_need: Label
var confirm_box: Control
var confirm_label: Label
var confirm_button: Button

var _built := false
var _nodes: Dictionary = {}  # StringName -> Button
var _links: Array[Dictionary] = []  # {from, to, need, line}
var _column: VBoxContainer
var _top: HBoxContainer
var _back: Button
var _coin_pill: PanelContainer
var _coin_icon: TextureRect
var _title: Label
var _scroll: ScrollContainer
var _tree_root: Control
var _branch_labels: Array[Label] = []
var _panel: PanelContainer
var _detail_frame: TextureRect
var _detail_icon: TextureRect
var _gap: Control
var _confirm_panel: PanelContainer
var _cancel_button: Button
var _bold: Font
var _margins: Array[MarginContainer] = []


## Dados da tela (antes de entrar na árvore; nos testes). Sem `save`, salva pelo `Backend`.
func setup(p: PlayerProfile, t: TalentTree, save: Callable = Callable()) -> void:
	profile = p
	tree = t
	save_func = save
	if _built:
		_rebuild_tree()
		refresh()


func _ready() -> void:
	var flow := _flow()
	if profile == null and flow != null:
		var p: Variant = flow.get(&"profile")
		profile = (p if p != null else flow.call(&"load_profile")) as PlayerProfile
	if tree == null and flow != null:
		tree = flow.get(&"talent_tree") as TalentTree
	_bold = ScreenKit.THEME.get_font(&"font", &"LabelDisplay")
	_build()
	_built = true
	_rebuild_tree()
	refresh()
	get_viewport().size_changed.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()
	_focus_selected.call_deferred()


# --- Estado (estático, testável) ---------------------------------------------------------------

static func node_state(p: PlayerProfile, t: TalentTree, id: StringName) -> NodeState:
	var data := t.get_talent(id)
	var lv := MetaTalents.level(p, id)
	if data != null and lv >= data.max_level():
		return NodeState.MAX
	if lv >= 1:
		return NodeState.OWNED
	if not MetaTalents.prereq_status(p, t, id).is_empty():
		return NodeState.LOCKED
	return NodeState.NORMAL


## Efeito acumulado no nível dado, em texto ("+8%", "−4%", "+6"); nível 0 = "nenhum".
static func effect_text(data: TalentData, level: int) -> String:
	if level <= 0:
		return Loc.t(TXT_NONE)
	var v := data.value_at(level)
	if data.stat in FLAT_STATS:
		return "+%d" % roundi(v)
	var pct := roundi(v * 100.0)
	return ("−%d%%" if data.mode == TalentData.Mode.REDUCTION_PCT else "+%d%%") % pct


## Texto do motivo de não poder comprar ("" se pode).
static func reason_text(p: PlayerProfile, t: TalentTree, id: StringName) -> String:
	match MetaTalents.can_buy(p, t, id):
		MetaTalents.Reason.OK:
			return ""
		MetaTalents.Reason.MAX:
			return Loc.t(TXT_MAXED)
		MetaTalents.Reason.FEATURE_LOCKED:
			return Loc.t(TXT_FEATURE, {"level": MetaTalents.NUCLEI_LEVEL})
		MetaTalents.Reason.NO_COINS:
			return Loc.t(TXT_NO_COINS, {"coins": MenuScreen.format_number(MetaTalents.next_cost(p, t, id) - p.coins)})
		MetaTalents.Reason.LOCKED_PREREQ:
			var parts := PackedStringArray()
			for miss: Dictionary in MetaTalents.prereq_status(p, t, id):
				var pd := t.get_talent(StringName(miss["id"]))
				var pname := Loc.t(pd.name_key) if pd != null else String(miss["id"])
				parts.append(Loc.t(TXT_NEEDS, {"name": pname, "level": int(miss["need"])}))
			return Loc.t(TXT_NEEDS_SEP).join(parts)
	return ""


static func has_any_talent(p: PlayerProfile, t: TalentTree) -> bool:
	for data in t.talents:
		if MetaTalents.level(p, data.id) > 0:
			return true
	return false


static func node_center(grid: Vector2i) -> Vector2:
	return Vector2(COL_X[clampi(grid.x, 0, COL_X.size() - 1)], ROW0_Y + float(grid.y) * ROW_STEP)


## Pontos da ligação pai → filho. Reta centro a centro; se pular uma coluna (a reta cortaria um nó),
## rota por fora pela esquerda e por baixo (README: quick_pulse → golden_core).
static func link_points(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	var a := node_center(from)
	var b := node_center(to)
	if absi(to.x - from.x) < 2:
		return PackedVector2Array([a, b])
	var xl := COL_X[0] - ROUTE_DX
	var yb := b.y + ROUTE_DY
	return PackedVector2Array([a, Vector2(xl, a.y), Vector2(xl, yb), Vector2(b.x, yb), b])


# --- Ações -------------------------------------------------------------------------------------

func select(id: StringName) -> void:
	if tree == null or tree.get_talent(id) == null:
		return
	selected = id
	refresh()


## Compra +1 nível do nó selecionado. Retorna `true` se comprou (e salvou).
func buy_selected() -> bool:
	if selected == &"":
		return false
	var res := MetaTalents.buy(profile, tree, selected)
	if not bool(res["ok"]):
		return false
	_after_change()
	return true


## Abre a confirmação do respec (nada acontece sem Núcleos comprados).
func request_respec() -> void:
	if not has_any_talent(profile, tree):
		return
	confirm_label.text = Loc.t(TXT_RESPEC_ASK, {"coins": MenuScreen.format_number(MetaTalents.spent_coins(profile, tree))})
	confirm_box.visible = true
	_cancel_button.grab_focus()


func cancel_respec() -> void:
	confirm_box.visible = false
	if respec_button.focus_mode != FOCUS_NONE and not respec_button.disabled:
		respec_button.grab_focus()
	else:
		_focus_selected()


## Aplica o respec (100% de reembolso) e salva. Retorna o reembolso.
func confirm_respec() -> int:
	confirm_box.visible = false
	var refund := MetaTalents.respec(profile, tree)
	_after_change()
	_focus_selected()
	return refund


func _after_change() -> void:
	var ok := false
	if save_func.is_valid():
		ok = bool(save_func.call(profile))
	else:
		var backend := get_node_or_null(^"/root/Backend")
		ok = backend != null and bool(backend.call(&"save_profile", profile))
	if not ok:
		push_warning("CoresScreen: falha ao salvar o perfil")
	refresh()
	_sync_menu()
	profile_changed.emit()


## Mantém o saldo do Jogar (em cache no hangar) igual ao perfil.
func _sync_menu() -> void:
	var flow := _flow()
	if flow == null or flow.get(&"profile") != profile:
		return
	var menu := flow.call(&"hangar_tab_node", HangarNav.PLAY) as Control
	if menu != null and menu.has_method(&"setup"):
		menu.call(&"setup", flow.call(&"menu_view", profile, flow.get(&"progression")))


## Autoloads por caminho (o identificador global não existe ao compilar sob `-s`).
func _flow() -> Node:
	return get_node_or_null(^"/root/SceneFlow") if is_inside_tree() else null


# --- Atualização -------------------------------------------------------------------------------

func refresh() -> void:
	if not _built or profile == null or tree == null:
		return
	coins_label.text = MenuScreen.format_number(profile.coins)
	for id: StringName in _nodes:
		_apply_node(id, _nodes[id])
	for link in _links:
		var parent_lv := MetaTalents.level(profile, link["from"])
		(link["line"] as Line2D).texture = T_LINK_ON if parent_lv >= int(link["need"]) else T_LINK_OFF
	respec_button.disabled = not has_any_talent(profile, tree)
	_apply_detail()


func _apply_node(id: StringName, b: Button) -> void:
	var data := tree.get_talent(id)
	var st := node_state(profile, tree, id)
	var frame: TextureRect = b.get_node(^"Frame")
	frame.texture = T_NODE_SELECTED if id == selected else _frame_tex(st)
	var icon: TextureRect = b.get_node(^"Icon")
	icon.texture = _icon_tex(data, st == NodeState.LOCKED)
	var chip_label: Label = b.get_node(^"Chip/Text")
	chip_label.text = Loc.t(TXT_CHIP, {"level": MetaTalents.level(profile, id), "max": data.max_level()})
	chip_label.add_theme_color_override("font_color", CHIP_LOCKED if st == NodeState.LOCKED else HOLO_TEXT)
	b.tooltip_text = Loc.t(data.name_key)


func _apply_detail() -> void:
	var data := tree.get_talent(selected)
	_panel.visible = data != null
	if data == null:
		return
	var st := node_state(profile, tree, selected)
	var lv := MetaTalents.level(profile, selected)
	_detail_frame.texture = _frame_tex(st)
	_detail_icon.texture = _icon_tex(data, st == NodeState.LOCKED)
	detail_name.text = Loc.t(data.name_key)
	var branch_key: String = str(tree.branch_name_keys.get(String(data.branch), ""))
	detail_sub.text = Loc.t(TXT_LEVEL, {"branch": Loc.t(branch_key).to_upper(), "level": lv, "max": data.max_level()})
	detail_sub.add_theme_color_override("font_color", BRANCH_COLORS.get(data.branch, HOLO_TEXT2) as Color)
	detail_desc.text = Loc.t(data.desc_key)
	var effect := Loc.t(TXT_NOW, {"value": effect_text(data, lv)})
	if lv < data.max_level():
		effect += "  ·  " + Loc.t(TXT_NEXT, {"value": effect_text(data, lv + 1)})
	detail_effect.text = effect
	var reason := reason_text(profile, tree, selected)
	detail_need.text = reason
	var maxed := lv >= data.max_level()
	buy_button.text = Loc.t(TXT_MAX) if maxed else Loc.t(TXT_BUY, {"cost": MenuScreen.format_number(MetaTalents.next_cost(profile, tree, selected))})
	buy_button.disabled = reason != ""
	buy_button.focus_mode = FOCUS_NONE if buy_button.disabled else FOCUS_ALL


func _frame_tex(st: NodeState) -> Texture2D:
	match st:
		NodeState.LOCKED:
			return T_NODE_LOCKED
		NodeState.OWNED:
			return T_NODE_OWNED
		NodeState.MAX:
			return T_NODE_MAX
	return T_NODE


static func _icon_tex(data: TalentData, off: bool) -> Texture2D:
	var path := ASSET_DIR + "ui_icon_%s%s.png" % [String(data.id), "_off" if off else ""]
	if ResourceLoader.exists(path):
		return load(path)
	return data.icon


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		refresh()
		_focus_selected.call_deferred()


func _focus_selected() -> void:
	if not is_inside_tree() or not is_visible_in_tree() or confirm_box.visible:
		return
	var b: Button = _nodes.get(selected) as Button
	if b != null:
		b.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if confirm_box.visible and is_visible_in_tree() and event.is_action_pressed(&"ui_cancel"):
		cancel_respec()
		get_viewport().set_input_as_handled()


# --- Montagem ----------------------------------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = HOLO_BG
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.set_anchors_preset(PRESET_FULL_RECT)
	_column.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_column)

	_top = HBoxContainer.new()
	_top.name = "TopBar"
	_top.mouse_filter = MOUSE_FILTER_IGNORE
	_column.add_child(_side_margin(_top))
	_back = Button.new()
	_back.name = "Back"
	_back.text = Loc.t(TXT_BACK)
	_back.icon = T_BACK
	_back.focus_mode = FOCUS_NONE
	_back.pressed.connect(back_requested.emit)
	_style_text_button(_back, HOLO_TEXT)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := _tex_box(T_PILL, 20.0)
		if state == "pressed":
			sb.modulate_color = Color(0.8, 0.9, 1.0)
		_back.add_theme_stylebox_override(state, sb)
	_back.add_theme_color_override("icon_normal_color", HOLO_TEXT)
	_top.add_child(_back)
	_title = _label(Loc.t(TXT_TITLE), HOLO_TEXT, true)
	_title.name = "Title"
	_title.size_flags_horizontal = SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top.add_child(_title)
	_coin_pill = PanelContainer.new()
	_coin_pill.name = "Coins"
	_coin_pill.mouse_filter = MOUSE_FILTER_IGNORE
	_coin_pill.add_theme_stylebox_override("panel", _tex_box(T_PILL, 20.0))
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.mouse_filter = MOUSE_FILTER_IGNORE
	_coin_pill.add_child(coin_row)
	_coin_icon = TextureRect.new()
	_coin_icon.texture = T_COIN
	_coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_coin_icon.mouse_filter = MOUSE_FILTER_IGNORE
	coin_row.add_child(_coin_icon)
	coins_label = _label("", Color("#FFE27A"), true)
	coins_label.name = "CoinsLabel"
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_row.add_child(coins_label)
	_top.add_child(_coin_pill)

	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_column.add_child(_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.mouse_filter = MOUSE_FILTER_IGNORE
	_scroll.add_child(center)
	_tree_root = Control.new()
	_tree_root.name = "Tree"
	_tree_root.custom_minimum_size = Vector2(TREE_W, TREE_H)
	_tree_root.mouse_filter = MOUSE_FILTER_IGNORE
	center.add_child(_tree_root)

	_panel = PanelContainer.new()
	_panel.name = "Detail"
	var psb := _tex_box(T_PANEL, 48.0)
	psb.set_content_margin_all(24.0)
	_panel.add_theme_stylebox_override("panel", psb)
	_column.add_child(_side_margin(_panel))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	box.add_child(head)
	var icon_box := Control.new()
	icon_box.custom_minimum_size = Vector2(FRAME, FRAME)
	icon_box.mouse_filter = MOUSE_FILTER_IGNORE
	head.add_child(icon_box)
	_detail_frame = _rect(Vector2.ZERO, Vector2(FRAME, FRAME))
	icon_box.add_child(_detail_frame)
	_detail_icon = _rect(Vector2((FRAME - ICON) / 2.0, (FRAME - ICON) / 2.0 - 4.0), Vector2(ICON, ICON))
	icon_box.add_child(_detail_icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 2)
	head.add_child(texts)
	detail_name = _label("", HOLO_TEXT, true)
	detail_name.name = "DetailName"
	texts.add_child(detail_name)
	detail_sub = _label("", HOLO_TEXT2, true)
	detail_sub.name = "DetailSub"
	texts.add_child(detail_sub)
	detail_desc = _label("", HOLO_TEXT2, false)
	detail_desc.name = "DetailDesc"
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(detail_desc)
	detail_effect = _label("", HOLO_TEXT, false)
	detail_effect.name = "DetailEffect"
	box.add_child(detail_effect)
	detail_need = _label("", WARN, false)
	detail_need.name = "DetailNeed"
	detail_need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_need)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	respec_button = Button.new()
	respec_button.name = "Respec"
	respec_button.text = Loc.t(TXT_RESPEC)
	respec_button.pressed.connect(request_respec)
	_style_secondary(respec_button)
	row.add_child(respec_button)
	buy_button = Button.new()
	buy_button.name = "Buy"
	buy_button.size_flags_horizontal = SIZE_EXPAND_FILL
	buy_button.pressed.connect(buy_selected)
	_style_primary(buy_button)
	row.add_child(buy_button)

	_gap = Control.new()
	_gap.name = "BarGap"
	_gap.mouse_filter = MOUSE_FILTER_IGNORE
	_column.add_child(_gap)

	_build_confirm()


func _build_confirm() -> void:
	confirm_box = Control.new()
	confirm_box.name = "Confirm"
	confirm_box.set_anchors_preset(PRESET_FULL_RECT)
	confirm_box.visible = false
	add_child(confirm_box)
	var dim := ColorRect.new()
	dim.color = Color(HOLO_BG, 0.75)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.mouse_filter = MOUSE_FILTER_STOP
	confirm_box.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	confirm_box.add_child(center)
	_confirm_panel = PanelContainer.new()
	var psb := _tex_box(T_PANEL, 48.0)
	psb.set_content_margin_all(36.0)
	_confirm_panel.add_theme_stylebox_override("panel", psb)
	center.add_child(_confirm_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	_confirm_panel.add_child(box)
	confirm_label = _label("", HOLO_TEXT, true)
	confirm_label.name = "ConfirmText"
	confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(confirm_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	_cancel_button = Button.new()
	_cancel_button.name = "Cancel"
	_cancel_button.text = Loc.t(TXT_CANCEL)
	_cancel_button.size_flags_horizontal = SIZE_EXPAND_FILL
	_cancel_button.pressed.connect(cancel_respec)
	_style_secondary(_cancel_button)
	row.add_child(_cancel_button)
	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = Loc.t(TXT_CONFIRM)
	confirm_button.size_flags_horizontal = SIZE_EXPAND_FILL
	confirm_button.pressed.connect(func() -> void: confirm_respec())
	_style_primary(confirm_button)
	row.add_child(confirm_button)


## Recria os nós e ligações da árvore (só no setup; a troca de aba reaproveita a instância).
func _rebuild_tree() -> void:
	for c in _tree_root.get_children():
		c.free()
	_nodes.clear()
	_links.clear()
	_branch_labels.clear()
	if tree == null:
		return
	var branches: Array[StringName] = [&"", &"", &""]
	for data in tree.talents:
		if data.grid_pos.x >= 0 and data.grid_pos.x < 3:
			branches[data.grid_pos.x] = data.branch
	for i in 3:
		var key: String = str(tree.branch_name_keys.get(String(branches[i]), ""))
		var l := _label(Loc.t(key).to_upper() if key != "" else "", BRANCH_COLORS.get(branches[i], HOLO_TEXT2) as Color, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(COL_X[i] - 110.0, 0.0)
		l.size = Vector2(220.0, HEADER_H)
		_tree_root.add_child(l)
		_branch_labels.append(l)
	# Ligações primeiro (atrás dos nós).
	for data in tree.talents:
		for i in data.prereq_ids.size():
			var parent := tree.get_talent(data.prereq_ids[i])
			if parent == null:
				continue
			var line := Line2D.new()
			line.name = "Link_%s_%s" % [parent.id, data.id]
			line.points = link_points(parent.grid_pos, data.grid_pos)
			line.width = LINK_W
			line.texture = T_LINK_OFF
			line.texture_mode = Line2D.LINE_TEXTURE_TILE
			line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			line.joint_mode = Line2D.LINE_JOINT_SHARP
			line.begin_cap_mode = Line2D.LINE_CAP_NONE
			line.end_cap_mode = Line2D.LINE_CAP_NONE
			_tree_root.add_child(line)
			var need := data.prereq_levels[i] if i < data.prereq_levels.size() else 1
			_links.append({"from": parent.id, "to": data.id, "need": need, "line": line})
	for data in tree.talents:
		var b := _make_node(data)
		_tree_root.add_child(b)
		_nodes[data.id] = b
	if selected == &"" or not _nodes.has(selected):
		selected = tree.talents[0].id if not tree.talents.is_empty() else &""


func _make_node(data: TalentData) -> Button:
	var b := Button.new()
	b.name = String(data.id).to_pascal_case()
	b.flat = true
	b.focus_mode = FOCUS_ALL
	b.size = Vector2(BTN, BTN)
	b.custom_minimum_size = Vector2(BTN, BTN)
	b.position = node_center(data.grid_pos) - Vector2(BTN, BTN) / 2.0
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(state, empty)
	var off := (BTN - FRAME) / 2.0
	var frame := _rect(Vector2(off, off), Vector2(FRAME, FRAME))
	frame.name = "Frame"
	b.add_child(frame)
	var icon := _rect(Vector2((BTN - ICON) / 2.0, (BTN - ICON) / 2.0 - 4.0), Vector2(ICON, ICON))
	icon.name = "Icon"
	b.add_child(icon)
	var chip := NinePatchRect.new()
	chip.name = "Chip"
	chip.texture = T_CHIP
	chip.patch_margin_left = 12
	chip.patch_margin_right = 12
	chip.patch_margin_top = 12
	chip.patch_margin_bottom = 12
	chip.mouse_filter = MOUSE_FILTER_IGNORE
	chip.position = Vector2((BTN - CHIP.x) / 2.0, off + 8.0 + 96.0 - CHIP.y / 2.0)
	chip.size = CHIP
	b.add_child(chip)
	var text := _label("", HOLO_TEXT, true)
	text.name = "Text"
	text.set_anchors_preset(PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 20)
	chip.add_child(text)
	var id := data.id
	b.focus_entered.connect(select.bind(id))
	b.pressed.connect(select.bind(id))
	b.gui_input.connect(_on_node_input.bind(id))
	return b


## `ui_accept` num nó já selecionado leva o foco ao Comprar (se puder comprar).
func _on_node_input(event: InputEvent, id: StringName) -> void:
	if event.is_action_pressed(&"ui_accept") and not event.is_echo() and id == selected and not buy_button.disabled:
		buy_button.grab_focus()
		accept_event()


func _layout() -> void:
	if not _built:
		return
	var view := get_viewport_rect().size
	var k := minf(view.x, 720.0) / BASE_W
	var safe := ScreenKit.safe_area(get_viewport())
	var col_w := minf(view.x, 720.0)
	var x0 := (view.x - col_w) / 2.0
	_column.offset_left = x0
	_column.offset_right = -x0
	_column.offset_top = float(safe.top) + 8.0 * k
	_column.add_theme_constant_override("separation", roundi(8.0 * k))
	var side := 16.0 * k
	for m in _margins:
		m.add_theme_constant_override("margin_left", roundi(side))
		m.add_theme_constant_override("margin_right", roundi(side))
	_top.custom_minimum_size = Vector2(0, maxf(TOUCH, PILL_H * k))
	_top.add_theme_constant_override("separation", roundi(8.0 * k))
	_back.custom_minimum_size = Vector2(PILL_W * k, maxf(TOUCH, PILL_H * k))
	_coin_pill.custom_minimum_size = Vector2(PILL_W * k, maxf(TOUCH, PILL_H * k))
	_back.add_theme_font_size_override("font_size", roundi(16.0 * k))
	_back.add_theme_constant_override("icon_max_width", roundi(BACK_ICON * k))
	_back.add_theme_constant_override("h_separation", roundi(4.0 * k))
	_coin_icon.custom_minimum_size = Vector2.ONE * roundf(20.0 * k)
	coins_label.add_theme_font_size_override("font_size", roundi(17.0 * k))
	_title.add_theme_font_size_override("font_size", roundi(20.0 * k))
	for l in _branch_labels:
		l.add_theme_font_size_override("font_size", roundi(12.0 * k))
	detail_name.add_theme_font_size_override("font_size", roundi(17.0 * k))
	detail_sub.add_theme_font_size_override("font_size", roundi(11.0 * k))
	detail_desc.add_theme_font_size_override("font_size", roundi(11.5 * k))
	detail_effect.add_theme_font_size_override("font_size", roundi(11.5 * k))
	detail_need.add_theme_font_size_override("font_size", roundi(11.5 * k))
	for b: Button in [buy_button, respec_button, confirm_button, _cancel_button]:
		b.custom_minimum_size.y = BTN_H
		b.add_theme_font_size_override("font_size", roundi((15.0 if b == buy_button else 13.0) * k))
	respec_button.custom_minimum_size.x = 104.0 * k
	confirm_label.add_theme_font_size_override("font_size", roundi(15.0 * k))
	_confirm_panel.custom_minimum_size.x = col_w - 2.0 * side - 32.0
	_gap.custom_minimum_size = Vector2(0, maxf(BAR_H * k, 34.0 * k + float(safe.bottom) + 76.0 * k))


# --- Estilo ------------------------------------------------------------------------------------

func _label(text: String, color: Color, bold: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", color)
	if bold and _bold != null:
		l.add_theme_font_override("font", _bold)
	return l


func _side_margin(c: Control) -> MarginContainer:
	var m := MarginContainer.new()
	m.mouse_filter = MOUSE_FILTER_IGNORE
	m.add_child(c)
	_margins.append(m)
	return m


func _rect(pos: Vector2, sz: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = MOUSE_FILTER_IGNORE
	r.position = pos
	r.size = sz
	return r


static func _tex_box(tex: Texture2D, m: float, expand: float = 0.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(m)
	sb.set_expand_margin_all(expand)
	return sb


func _style_text_button(b: Button, color: Color) -> void:
	if _bold != null:
		b.add_theme_font_override("font", _bold)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, color)
	b.add_theme_color_override("font_disabled_color", HOLO_MUTED)
	b.add_theme_constant_override("outline_size", 0)


## Primário: face ciano (`ui_holo_btn_primary`); desabilitado usa a placa secundária apagada.
func _style_primary(b: Button) -> void:
	var normal := _tex_box(T_PRIMARY, 48.0, 8.0)
	var down := _tex_box(T_PRIMARY_DOWN, 48.0, 8.0)
	for sb: StyleBoxTexture in [normal, down]:
		sb.content_margin_left = 16.0
		sb.content_margin_right = 16.0
	normal.content_margin_top = 0.0
	normal.content_margin_bottom = 10.0
	down.content_margin_top = 5.0
	down.content_margin_bottom = 5.0
	var off := _tex_box(T_SECONDARY_OFF, 24.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", off)
	b.add_theme_stylebox_override("focus", _focus_box())
	_style_text_button(b, HOLO_INK)


func _style_secondary(b: Button) -> void:
	var normal := _tex_box(T_SECONDARY, 24.0)
	var down := _tex_box(T_SECONDARY_DOWN, 24.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", _tex_box(T_SECONDARY_OFF, 24.0))
	b.add_theme_stylebox_override("focus", _focus_box())
	_style_text_button(b, HOLO_TEXT)


## Foco de teclado visível nos botões do painel (os nós mostram a moldura `_selected`).
static func _focus_box() -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.border_color = HOLO_TEXT
	f.set_border_width_all(3)
	f.set_corner_radius_all(16)
	f.set_expand_margin_all(4.0)
	return f
