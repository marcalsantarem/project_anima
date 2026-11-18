class_name ModulesScreen
extends Control
## Tela do destino Módulos do hangar (T-216 e T-217, BRF-168; docs/ui.md §8b, arte §11.9).
## Topo (Voltar, título, saldo de Moeda), faixa com os 3 slots, lista dos 4 Módulos e detalhe com valores do
## nível atual e do próximo + EVOLUIR. Fluxo de equipar: toca no Módulo e depois no slot (de novo no slot
## ocupado pelo Módulo escolhido, esvazia). A lógica é do `MetaModules`; a tela só chama a API e salva pelo `Backend`.
## Dados por `setup(profile, catalog, slot_levels, save)` (testes) ou, sem setup, do `SceneFlow` ao entrar na árvore.

signal back_requested
## Evolução, equipar ou desequipar aplicados (e salvos).
signal profile_changed

enum ModState { LOCKED, NORMAL, NO_COINS, MAX }

## Chaves de tradução (Loc.t).
const TXT_BACK := "COMMON_BACK"
const TXT_TITLE := "HANGAR_TAB_MODULES"
const TXT_LOCK_LEVEL := "COMMON_LOCK_LEVEL"
const TXT_HINT := "MODULES_HINT"
const TXT_SLOT := "MODULES_SLOT"
const TXT_SLOT_EMPTY := "MODULES_SLOT_EMPTY"
const TXT_READY := "MODULES_READY"
const TXT_LEVEL := "MODULES_LEVEL"
const TXT_IN_SLOT := "MODULES_IN_SLOT"
const TXT_UPGRADE := "MODULES_UPGRADE"
const TXT_MAX := "MODULES_MAX"
const TXT_NO_COINS := "MODULES_NO_COINS"
const TXT_LOCKED := "MODULES_LOCKED"
const TXT_EQUIPPED := "MODULES_EQUIPPED"
const TXT_UNEQUIPPED := "MODULES_UNEQUIPPED"
const TXT_ERR_DUP := "MODULES_ERR_DUP"
const TXT_ERR_SLOT := "MODULES_ERR_SLOT"
const TXT_ERR_LOCKED := "MODULES_ERR_LOCKED"
const TXT_STAT_NOW := "MODULES_STAT_NOW"
const TXT_STAT_NEXT := "MODULES_STAT_NEXT"
const TXT_UNIT_S := "MODULES_UNIT_S"
const TXT_UNIT_PCT := "MODULES_UNIT_PCT"
const S_DAMAGE := "MODULES_STAT_DAMAGE"
const S_RADIUS := "MODULES_STAT_RADIUS"
const S_JUMP := "MODULES_STAT_JUMP"
const S_JUMPS := "MODULES_STAT_JUMPS"
const S_FALLOFF := "MODULES_STAT_FALLOFF"
const S_FREEZE := "MODULES_STAT_FREEZE"
const S_ABSORB := "MODULES_STAT_ABSORB"
const S_DURATION := "MODULES_STAT_DURATION"
const S_COOLDOWN := "MODULES_STAT_COOLDOWN"

## Nome, descrição e ícone de cada Módulo (por id do catálogo).
const INFO := {
	&"skill_meteor": {"name": "MODULE_METEOR_NAME", "desc": "MODULE_METEOR_DESC", "icon": "ui_icon_skill_meteor"},
	&"skill_shock": {"name": "MODULE_SHOCK_NAME", "desc": "MODULE_SHOCK_DESC", "icon": "ui_icon_skill_shock"},
	&"skill_freeze": {"name": "MODULE_FREEZE_NAME", "desc": "MODULE_FREEZE_DESC", "icon": "ui_icon_skill_freeze"},
	&"skill_shield": {"name": "MODULE_SHIELD_NAME", "desc": "MODULE_SHIELD_DESC", "icon": "ui_icon_skill_shield"},
}

const BASE_W := 375.0
const HOLO_BG := Color("#021423")
const HOLO_TEXT := Color("#E6FFFF")
const HOLO_TEXT2 := Color("#9FF6FF")
const HOLO_MUTED := Color("#7FA3B8")
const HOLO_INK := Color("#03202E")
const WARN := Color("#FFB86B")

const PILL_W := 104.0
const PILL_H := 56.0
const TOUCH := 64.0
const BAR_H := 110.0
const BACK_ICON := 18.0
const BTN_H := 126.0 ## alvos do painel e da lista (px do viewport; >= 64 px de tela a 375x812, escala 0,52)
const ROW_ICON := 96.0

const ASSET_DIR := "res://assets/ui/"
const T_FRAME_READY := preload("res://assets/ui/ui_skill_frame_ready.png")
const T_FRAME_LOCKED := preload("res://assets/ui/ui_skill_frame_locked.png")
const T_LOCK := preload("res://assets/ui/ui_icon_lock_holo.png")
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
var catalog: ModuleCatalog
var slot_levels: PackedInt32Array = PackedInt32Array()
## `func(profile: PlayerProfile) -> bool`; vazio = `Backend.save_profile`.
var save_func: Callable
var selected: StringName = &""

var coins_label: Label
var upgrade_button: Button
var hint_label: Label
var detail_name: Label
var detail_sub: Label
var detail_desc: Label
var detail_need: Label
var slot_buttons: Array[Button] = []

var _built := false
var _rows: Dictionary = {}  # StringName -> Button
var _stat_labels: Array[Label] = []
var _column: VBoxContainer
var _top: HBoxContainer
var _back: Button
var _coin_pill: PanelContainer
var _coin_icon: TextureRect
var _title: Label
var _slots_row: HBoxContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _panel: PanelContainer
var _detail_frame: TextureRect
var _detail_icon: TextureRect
var _stats: GridContainer
var _gap: Control
var _bold: Font
var _margins: Array[MarginContainer] = []


## Dados da tela (antes de entrar na árvore; nos testes). Sem `save`, salva pelo `Backend`.
func setup(p: PlayerProfile, cat: ModuleCatalog, slots: PackedInt32Array, save: Callable = Callable()) -> void:
	profile = p
	catalog = cat
	slot_levels = slots
	save_func = save
	if _built:
		_rebuild_rows()
		refresh()


func _ready() -> void:
	var flow := _flow()
	if profile == null and flow != null:
		var p: Variant = flow.get(&"profile")
		profile = (p if p != null else flow.call(&"load_profile")) as PlayerProfile
	if catalog == null and flow != null:
		catalog = flow.get(&"module_catalog") as ModuleCatalog
		slot_levels = (flow.get(&"progression") as ProgressionData).slot_unlock_levels
	_bold = ScreenKit.THEME.get_font(&"font", &"LabelDisplay")
	_build()
	_built = true
	_rebuild_rows()
	refresh()
	get_viewport().size_changed.connect(_layout)
	visibility_changed.connect(_on_visibility_changed)
	_layout()


# --- Estado (estático, testável) ---------------------------------------------------------------

static func module_state(p: PlayerProfile, cat: ModuleCatalog, id: StringName) -> ModState:
	if not MetaModules.unlocked(p, cat, id):
		return ModState.LOCKED
	match MetaModules.can_upgrade(p, cat, id):
		MetaModules.Reason.MAX:
			return ModState.MAX
		MetaModules.Reason.NO_COINS:
			return ModState.NO_COINS
	return ModState.NORMAL


## Estado do slot (1-based): `&"locked"` (com `level` da conta), `&"empty"` ou `&"filled"`.
static func slot_state(p: PlayerProfile, cat: ModuleCatalog, slots: PackedInt32Array, slot: int) -> StringName:
	if slot > MatchConfig.slots_unlocked(p.level, slots):
		return &"locked"
	return &"empty" if MetaModules.equipped(p, cat, slots)[slot - 1] == &"" else &"filled"


static func slot_unlock_level(slots: PackedInt32Array, slot: int) -> int:
	return slots[slot - 1] if slot - 1 < slots.size() else 0


static func name_of(id: StringName) -> String:
	return Loc.t(str((INFO.get(id, {}) as Dictionary).get("name", String(id))))


static func icon_of(id: StringName) -> Texture2D:
	var path := ASSET_DIR + "%s.png" % str((INFO.get(id, {}) as Dictionary).get("icon", ""))
	return load(path) if ResourceLoader.exists(path) else null


## Texto do motivo de não poder evoluir ("" se pode ou se já está no máximo).
static func reason_text(p: PlayerProfile, cat: ModuleCatalog, id: StringName) -> String:
	match MetaModules.can_upgrade(p, cat, id):
		MetaModules.Reason.LOCKED:
			return Loc.t(TXT_LOCKED, {"level": cat.get_module(id).unlock_level})
		MetaModules.Reason.NO_COINS:
			return Loc.t(TXT_NO_COINS, {"coins": MenuScreen.format_number(MetaModules.next_cost(p, cat, id) - p.coins)})
	return ""


static func num(v: float) -> String:
	return str(roundi(v)) if is_equal_approx(v, roundf(v)) else ("%.1f" % v).replace(".", ",")


## Linhas de valores do nível `lv`: [{name, cur, next}] (`next` vazio no nível máximo).
static func stat_lines(m: ModuleLevelData, lv: int) -> Array[Dictionary]:
	var cur := _values(m.skill_at(lv), m.module_id)
	var nxt: Array = _values(m.skill_at(lv + 1), m.module_id) if lv < ModuleLevelData.MAX_LEVEL else []
	var out: Array[Dictionary] = []
	for i in cur.size():
		out.append({"name": Loc.t(cur[i][0]), "cur": cur[i][1], "next": nxt[i][1] if i < nxt.size() else ""})
	return out


static func _values(s: SkillData, id: StringName) -> Array:
	var out := []
	if s.damage > 0:
		out.append([S_DAMAGE, num(s.damage)])
	match id:
		&"skill_shock":
			out.append([S_JUMP, num(s.radius)])
			out.append([S_JUMPS, num(float(s.effect_params.get("jumps", 0)))])
			out.append([S_FALLOFF, Loc.t(TXT_UNIT_PCT, {"value": roundi(float(s.effect_params.get("falloff", 0.0)) * 100.0)})])
		&"skill_freeze":
			out.append([S_RADIUS, num(s.radius)])
			out.append([S_FREEZE, Loc.t(TXT_UNIT_S, {"value": num(s.duration)})])
		&"skill_shield":
			out.append([S_ABSORB, num(float(s.effect_params.get("absorb", 0)))])
			out.append([S_DURATION, Loc.t(TXT_UNIT_S, {"value": num(s.duration)})])
		_:
			out.append([S_RADIUS, num(s.radius)])
	out.append([S_COOLDOWN, Loc.t(TXT_UNIT_S, {"value": num(s.cooldown)})])
	return out


# --- Ações -------------------------------------------------------------------------------------

func select(id: StringName) -> void:
	if catalog == null or catalog.get_module(id) == null:
		return
	selected = id
	_set_hint("")
	refresh()


## Evolui o Módulo selecionado em 1 nível. Retorna `true` se evoluiu (e salvou).
func upgrade_selected() -> bool:
	if selected == &"":
		return false
	CoresFx.reduced_effects = DebugSettings.reduced_effects()
	var res := MetaModules.upgrade(profile, catalog, selected)
	if not bool(res["ok"]):
		if MetaModules.can_upgrade(profile, catalog, selected) != MetaModules.Reason.MAX:
			CoresFx.play_fail(upgrade_button)
		return false
	_after_change()
	CoresFx.play_buy(_rows.get(selected), HOLO_TEXT2)
	return true


## Toque no slot (1-based): esvazia se ele já tem o Módulo escolhido; senão equipa o escolhido (troca se ocupado).
## Retorna `true` se mudou o equipamento. O motivo de uma recusa aparece na linha de aviso.
func press_slot(slot: int) -> bool:
	if slot < 1 or slot > MatchConfig.SLOT_COUNT:
		return false
	if slot_state(profile, catalog, slot_levels, slot) == &"locked":
		_set_hint(Loc.t(TXT_ERR_SLOT, {"level": slot_unlock_level(slot_levels, slot)}), true)
		CoresFx.play_fail(slot_buttons[slot - 1])
		return false
	var cur := MetaModules.equipped(profile, catalog, slot_levels)
	if selected != &"" and cur[slot - 1] == selected:
		MetaModules.unequip(profile, catalog, slot_levels, slot)
		_after_change()
		_set_hint(Loc.t(TXT_UNEQUIPPED, {"slot": slot}))
		return true
	match MetaModules.equip(profile, catalog, slot_levels, slot, selected):
		MetaModules.EquipReason.OK:
			_after_change()
			_set_hint(Loc.t(TXT_EQUIPPED, {"name": name_of(selected), "slot": slot}))
			return true
		MetaModules.EquipReason.ALREADY_EQUIPPED:
			_set_hint(Loc.t(TXT_ERR_DUP, {"name": name_of(selected), "slot": cur.find(selected) + 1}), true)
		MetaModules.EquipReason.LOCKED:
			_set_hint(Loc.t(TXT_ERR_LOCKED, {"name": name_of(selected), "level": catalog.get_module(selected).unlock_level}), true)
	CoresFx.play_fail(slot_buttons[slot - 1])
	return false


func _set_hint(text: String, warn: bool = false) -> void:
	if hint_label == null:
		return
	hint_label.text = text if text != "" else Loc.t(TXT_HINT)
	hint_label.add_theme_color_override("font_color", WARN if warn else HOLO_MUTED)


func _after_change() -> void:
	var ok := false
	if save_func.is_valid():
		ok = bool(save_func.call(profile))
	else:
		var backend := get_node_or_null(^"/root/Backend")
		ok = backend != null and bool(backend.call(&"save_profile", profile))
	if not ok:
		push_warning("ModulesScreen: falha ao salvar o perfil")
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
	if not _built or profile == null or catalog == null:
		return
	coins_label.text = MenuScreen.format_number(profile.coins)
	var eq := MetaModules.equipped(profile, catalog, slot_levels)
	for i in slot_buttons.size():
		_apply_slot(i + 1, eq[i])
	for id: StringName in _rows:
		_apply_row(id, _rows[id], eq.find(id) + 1)
	_apply_detail()


func _apply_slot(slot: int, id: StringName) -> void:
	var b := slot_buttons[slot - 1]
	var st := slot_state(profile, catalog, slot_levels, slot)
	var head := Loc.t(TXT_SLOT, {"slot": slot})
	match st:
		&"locked":
			b.text = "%s\n%s" % [head, Loc.t(TXT_LOCK_LEVEL, {"level": slot_unlock_level(slot_levels, slot)})]
			b.icon = T_LOCK
			_style_slot(b, T_SECONDARY_OFF, T_SECONDARY_OFF, HOLO_MUTED)
		&"empty":
			b.text = "%s\n%s" % [head, Loc.t(TXT_SLOT_EMPTY)]
			b.icon = null
			_style_slot(b, T_SECONDARY, T_SECONDARY_DOWN, HOLO_TEXT2)
		_:
			b.text = "%s\n%s" % [head, name_of(id)]
			b.icon = icon_of(id)
			_style_slot(b, T_PRIMARY, T_PRIMARY_DOWN, HOLO_INK)


func _apply_row(id: StringName, b: Button, slot: int) -> void:
	var st := module_state(profile, catalog, id)
	var locked := st == ModState.LOCKED
	var lv := MetaModules.level(profile, catalog, id)
	b.get_node(^"H/IconBox/Frame").texture = T_FRAME_LOCKED if locked else T_FRAME_READY
	var icon: TextureRect = b.get_node(^"H/IconBox/Icon")
	icon.texture = icon_of(id)
	icon.modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
	(b.get_node(^"H/Texts/Name") as Label).text = name_of(id)
	var info := ""
	if not locked:
		info = Loc.t(TXT_LEVEL, {"level": lv, "max": ModuleLevelData.MAX_LEVEL})
		if slot > 0:
			info += " · " + Loc.t(TXT_IN_SLOT, {"slot": slot})
	(b.get_node(^"H/Texts/Info") as Label).text = info
	var state := b.get_node(^"H/State") as Label
	state.text = Loc.t(TXT_LOCK_LEVEL, {"level": catalog.get_module(id).unlock_level}) if locked else Loc.t(TXT_READY)
	state.add_theme_color_override("font_color", HOLO_MUTED if locked else HOLO_TEXT2)
	(b.get_node(^"Sel") as Control).visible = id == selected
	b.tooltip_text = name_of(id)


func _apply_detail() -> void:
	var m := catalog.get_module(selected)
	_panel.visible = m != null
	if m == null:
		return
	var st := module_state(profile, catalog, selected)
	var locked := st == ModState.LOCKED
	_detail_frame.texture = T_FRAME_LOCKED if locked else T_FRAME_READY
	_detail_icon.texture = icon_of(selected)
	_detail_icon.modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
	var info: Dictionary = INFO.get(selected, {})
	detail_name.text = name_of(selected)
	var lv := MetaModules.level(profile, catalog, selected)
	detail_sub.text = Loc.t(TXT_LOCK_LEVEL, {"level": m.unlock_level}) if locked else Loc.t(TXT_LEVEL, {"level": lv, "max": ModuleLevelData.MAX_LEVEL})
	detail_desc.text = Loc.t(str(info.get("desc", "")))
	var lines := stat_lines(m, maxi(lv, 1))
	for i in _stat_labels.size():
		var l := _stat_labels[i]
		l.visible = i < lines.size()
		if i < lines.size():
			var ln: Dictionary = lines[i]
			var next := str(ln["next"])
			var show_next := not locked and next != "" and next != str(ln["cur"])
			l.text = Loc.t(TXT_STAT_NEXT if show_next else TXT_STAT_NOW, {"name": ln["name"], "value": ln["cur"], "next": next})
	var reason := reason_text(profile, catalog, selected)
	detail_need.text = reason
	detail_need.visible = reason != ""
	match st:
		ModState.MAX:
			upgrade_button.text = Loc.t(TXT_MAX)
		_:
			upgrade_button.text = Loc.t(TXT_UPGRADE, {"cost": MenuScreen.format_number(MetaModules.next_cost(profile, catalog, selected) if not locked else m.cost_from(1))})
	upgrade_button.disabled = st == ModState.MAX or st == ModState.LOCKED or st == ModState.NO_COINS
	upgrade_button.focus_mode = FOCUS_NONE if upgrade_button.disabled else FOCUS_ALL


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		refresh()


## Toque no EVOLUIR desabilitado (sem Moeda) → tremida.
func _on_upgrade_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if upgrade_button.disabled and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		upgrade_selected()


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

	# Faixa dos 3 slots + linha de aviso.
	_slots_row = HBoxContainer.new()
	_slots_row.name = "Slots"
	_slots_row.mouse_filter = MOUSE_FILTER_IGNORE
	_column.add_child(_side_margin(_slots_row))
	for i in MatchConfig.SLOT_COUNT:
		var sb := Button.new()
		sb.name = "Slot%d" % (i + 1)
		sb.size_flags_horizontal = SIZE_EXPAND_FILL
		sb.expand_icon = false
		sb.clip_text = true
		sb.pressed.connect(press_slot.bind(i + 1))
		_slots_row.add_child(sb)
		slot_buttons.append(sb)
	hint_label = _label(Loc.t(TXT_HINT), HOLO_MUTED, false)
	hint_label.name = "Hint"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(_side_margin(hint_label))

	# Lista dos Módulos (rola se não couber).
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_column.add_child(_scroll)
	var lm := MarginContainer.new()
	lm.size_flags_horizontal = SIZE_EXPAND_FILL
	lm.mouse_filter = MOUSE_FILTER_IGNORE
	_margins.append(lm)
	_scroll.add_child(lm)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.mouse_filter = MOUSE_FILTER_IGNORE
	lm.add_child(_list)

	# Detalhe.
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
	icon_box.custom_minimum_size = Vector2(ROW_ICON, ROW_ICON)
	icon_box.mouse_filter = MOUSE_FILTER_IGNORE
	head.add_child(icon_box)
	_detail_frame = _rect(Vector2.ZERO, Vector2(ROW_ICON, ROW_ICON))
	icon_box.add_child(_detail_frame)
	_detail_icon = _rect(Vector2.ONE * (ROW_ICON - 60.0) / 2.0, Vector2.ONE * 60.0)
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
	box.add_child(detail_desc)
	_stats = GridContainer.new()
	_stats.name = "Stats"
	_stats.columns = 2
	_stats.add_theme_constant_override("h_separation", 16)
	_stats.add_theme_constant_override("v_separation", 2)
	_stats.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_child(_stats)
	for i in 5:
		var sl := _label("", HOLO_TEXT, false)
		sl.name = "Stat%d" % i
		sl.size_flags_horizontal = SIZE_EXPAND_FILL
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_stats.add_child(sl)
		_stat_labels.append(sl)
	detail_need = _label("", WARN, false)
	detail_need.name = "DetailNeed"
	detail_need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_need)
	upgrade_button = Button.new()
	upgrade_button.name = "Upgrade"
	upgrade_button.pressed.connect(upgrade_selected)
	upgrade_button.gui_input.connect(_on_upgrade_input)
	_style_primary(upgrade_button)
	box.add_child(upgrade_button)

	_gap = Control.new()
	_gap.name = "BarGap"
	_gap.mouse_filter = MOUSE_FILTER_IGNORE
	_column.add_child(_gap)


## Recria as linhas da lista (só no setup; a troca de aba reaproveita a instância).
func _rebuild_rows() -> void:
	for c in _list.get_children():
		c.free()
	_rows.clear()
	if catalog == null:
		return
	for m in catalog.modules:
		var b := _make_row(m)
		_list.add_child(b)
		_rows[m.module_id] = b
	if selected == &"" or not _rows.has(selected):
		selected = catalog.modules[0].module_id if not catalog.modules.is_empty() else &""


func _make_row(m: ModuleLevelData) -> Button:
	var b := Button.new()
	b.name = String(m.module_id).to_pascal_case()
	b.focus_mode = FOCUS_ALL
	b.custom_minimum_size = Vector2(0, BTN_H)
	_style_secondary(b)
	var h := HBoxContainer.new()
	h.name = "H"
	h.set_anchors_preset(PRESET_FULL_RECT)
	h.offset_left = 20.0
	h.offset_right = -20.0
	h.offset_top = 8.0
	h.offset_bottom = -12.0
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = MOUSE_FILTER_IGNORE
	b.add_child(h)
	var ib := Control.new()
	ib.name = "IconBox"
	ib.custom_minimum_size = Vector2(ROW_ICON - 16.0, ROW_ICON - 16.0)
	ib.size_flags_vertical = SIZE_SHRINK_CENTER
	ib.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(ib)
	var fr := _rect(Vector2.ZERO, ib.custom_minimum_size)
	fr.name = "Frame"
	ib.add_child(fr)
	var ic := _rect(Vector2.ONE * 8.0, ib.custom_minimum_size - Vector2.ONE * 16.0)
	ic.name = "Icon"
	ib.add_child(ic)
	var texts := VBoxContainer.new()
	texts.name = "Texts"
	texts.size_flags_horizontal = SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = MOUSE_FILTER_IGNORE
	h.add_child(texts)
	var nm := _label("", HOLO_TEXT, true)
	nm.name = "Name"
	texts.add_child(nm)
	var info := _label("", HOLO_TEXT2, false)
	info.name = "Info"
	texts.add_child(info)
	var state := _label("", HOLO_TEXT2, true)
	state.name = "State"
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(state)
	var sel := Panel.new()
	sel.name = "Sel"
	sel.set_anchors_preset(PRESET_FULL_RECT)
	sel.mouse_filter = MOUSE_FILTER_IGNORE
	sel.add_theme_stylebox_override("panel", _focus_box())
	sel.visible = false
	b.add_child(sel)
	var id := m.module_id
	b.focus_entered.connect(select.bind(id))
	b.pressed.connect(select.bind(id))
	return b


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
	_title.add_theme_font_size_override("font_size", roundi(26.0 * k))
	_slots_row.add_theme_constant_override("separation", roundi(8.0 * k))
	for b in slot_buttons:
		b.custom_minimum_size.y = BTN_H
		b.add_theme_font_size_override("font_size", roundi(10.0 * k))
		b.add_theme_constant_override("icon_max_width", roundi(22.0 * k))
		b.add_theme_constant_override("h_separation", roundi(2.0 * k))
	hint_label.add_theme_font_size_override("font_size", roundi(11.5 * k))
	hint_label.custom_minimum_size.y = roundf(30.0 * k)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_list.add_theme_constant_override("separation", roundi(8.0 * k))
	_list.get_parent().add_theme_constant_override("margin_top", 8)
	_list.get_parent().add_theme_constant_override("margin_bottom", 8)
	for row: Button in _rows.values():
		row.add_theme_font_size_override("font_size", roundi(12.0 * k))
		(row.get_node(^"H/Texts/Name") as Label).add_theme_font_size_override("font_size", roundi(16.0 * k))
		(row.get_node(^"H/Texts/Info") as Label).add_theme_font_size_override("font_size", roundi(11.0 * k))
		(row.get_node(^"H/State") as Label).add_theme_font_size_override("font_size", roundi(11.0 * k))
	detail_name.add_theme_font_size_override("font_size", roundi(17.0 * k))
	detail_sub.add_theme_font_size_override("font_size", roundi(12.0 * k))
	detail_desc.add_theme_font_size_override("font_size", roundi(11.5 * k))
	detail_need.add_theme_font_size_override("font_size", roundi(11.5 * k))
	for l in _stat_labels:
		l.add_theme_font_size_override("font_size", roundi(11.5 * k))
	upgrade_button.custom_minimum_size.y = BTN_H
	upgrade_button.add_theme_font_size_override("font_size", roundi(15.0 * k))
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


func _style_slot(b: Button, normal_tex: Texture2D, down_tex: Texture2D, color: Color) -> void:
	var normal := _tex_box(normal_tex, 48.0 if normal_tex == T_PRIMARY else 24.0, 8.0 if normal_tex == T_PRIMARY else 0.0)
	var down := _tex_box(down_tex, 48.0 if normal_tex == T_PRIMARY else 24.0, 8.0 if normal_tex == T_PRIMARY else 0.0)
	for sb: StyleBoxTexture in [normal, down]:
		sb.content_margin_left = 4.0
		sb.content_margin_right = 4.0
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("focus", _focus_box())
	_style_text_button(b, color)


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
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", _tex_box(T_SECONDARY_OFF, 24.0))
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


## Contorno ciano: foco de teclado e seleção da linha.
static func _focus_box() -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.border_color = HOLO_TEXT
	f.set_border_width_all(3)
	f.set_corner_radius_all(16)
	f.set_expand_margin_all(4.0)
	return f
