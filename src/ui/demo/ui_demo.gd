extends Control
## Cena de demonstração do tema e dos componentes (T-106).
## Simula o gameplay localmente: as skills emitem uso, cooldown (10×/s) e "pronta".

const COOLDOWNS := [10.0, 6.0, 8.0]
const SIGNAL_INTERVAL := 0.1
const CORE_MAX := 100
const BOSS_MAX := 500

var _core_hp := CORE_MAX
var _boss_hp := BOSS_MAX
var _core_bar: UiBar
var _boss_bar: UiBar
var _skills: Array[SkillButton] = []
var _remaining: Array[float] = [0.0, 0.0, 0.0]
var _signal_t := 0.0
var _disabled := false
var _locked := true
var _particles := 1250
var _upgrades: Array[UpgradeButton] = []
var _levels := {}
var _costs := {}
var _particles_label: Label
## Prévia simulada da mira por arrasto (T-178); na partida quem desenha é a Arena (show_skill_aim).
var _aim_marker: Control
var _aim_at := Vector2.ZERO


func _ready() -> void:
	theme = load("res://src/ui/theme/anima_theme.tres")
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UiTokens.BG_VOID
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UiTokens.MARGIN_SCREEN)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTokens.SPACE_M)
	margin.add_child(col)

	col.add_child(_label("Demo de UI", &"LabelTitle"))
	col.add_child(_label("Energia do Anima", &"LabelCaption"))
	_core_bar = UiBar.new()
	_core_bar.color_mode = UiBar.ColorMode.CORE_HP
	_core_bar.set_value(_core_hp, CORE_MAX)
	col.add_child(_core_bar)

	col.add_child(_label("Chefe", &"LabelCaption"))
	_boss_bar = UiBar.new()
	_boss_bar.color_mode = UiBar.ColorMode.FIXED
	_boss_bar.fill_color = UiTokens.BOSS_HP
	_boss_bar.title = "Boss"
	_boss_bar.track_height = Hud.BOSS_TRACK_HEIGHT
	_boss_bar.fill_time = Hud.BOSS_FILL_TIME
	_boss_bar.custom_minimum_size.y = Hud.BOSS_BAR_HEIGHT
	_boss_bar.set_value(_boss_hp, BOSS_MAX)
	col.add_child(_boss_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_S)
	col.add_child(row)
	row.add_child(_button("Dano", &"", _on_damage))
	row.add_child(_button("Curar", &"", _on_heal))
	row.add_child(_button("Bater no chefe", &"", _on_boss_hit))

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", UiTokens.SPACE_S)
	col.add_child(row2)
	row2.add_child(_button("Jogar de novo", &"ButtonPrimary", _on_reset))
	row2.add_child(_button("Desativar skills", &"", _on_toggle_disabled))
	row2.add_child(_button("Cadeados", &"", _on_toggle_locked))

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", UiTokens.SPACE_S)
	col.add_child(row3)
	row3.add_child(_button("+300 Partículas", &"", _on_add_particles))
	row3.add_child(_button("Zerar Partículas", &"", _on_zero_particles))

	var hud_row := HBoxContainer.new()
	hud_row.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	col.add_child(hud_row)
	hud_row.add_child(_label("ONDA 3/10", &"LabelHud"))
	hud_row.add_child(StarIcon.new(32))
	_particles_label = _label("", &"LabelHud")
	hud_row.add_child(_particles_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	spacer.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	# Fileira de upgrades (T-135), com upgrade_changed/particles_changed simulados como no mockup.
	var up_row := HBoxContainer.new()
	up_row.alignment = BoxContainer.ALIGNMENT_CENTER
	up_row.add_theme_constant_override("separation", UiTokens.UPGRADE_GAP)
	col.add_child(up_row)
	var start_levels := [2, 4, 1, 10, 3] # mockup: custos 120 / 340 / 1.400 / MAX / 260
	var start_costs := [120, 340, 1400, -1, 260]
	for i in UpgradeButton.IDS.size():
		var ub := UpgradeButton.new()
		ub.upgrade_id = UpgradeButton.IDS[i]
		ub.buy_requested.connect(_on_buy)
		up_row.add_child(ub)
		_upgrades.append(ub)
		_levels[ub.upgrade_id] = start_levels[i]
		_costs[ub.upgrade_id] = start_costs[i]
		_emit_upgrade(ub)
	_set_particles(_particles)

	var skills_row := HBoxContainer.new()
	skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_row.add_theme_constant_override("separation", UiTokens.SKILL_GAP)
	col.add_child(skills_row)
	var icons := [SkillButton.Icon.CIRCLE, SkillButton.Icon.DIAMOND, SkillButton.Icon.HEX]
	for i in 3:
		var sb := SkillButton.new()
		sb.slot = i + 1
		sb.icon = icons[i]
		sb.drag_aim = true
		sb.aim_moved.connect(_on_aim_moved)
		sb.aim_ended.connect(_on_aim_ended)
		skills_row.add_child(sb)
		_skills.append(sb)
	_apply_locks()
	_aim_marker = Control.new()
	_aim_marker.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_aim_marker.mouse_filter = MOUSE_FILTER_IGNORE
	_aim_marker.visible = false
	_aim_marker.draw.connect(_draw_aim)
	add_child(_aim_marker)


func _on_aim_moved(_slot: int, at: Vector2) -> void:
	_aim_at = at
	_aim_marker.visible = true
	_aim_marker.queue_redraw()


func _on_aim_ended(slot: int, _at: Vector2, cancelled: bool) -> void:
	_aim_marker.visible = false
	if not cancelled:
		_try_use(slot - 1)


func _draw_aim() -> void:
	_aim_marker.draw_set_transform(_aim_at, 0.0, Vector2(1.0, 0.75))
	_aim_marker.draw_circle(Vector2.ZERO, 90.0, Color(UiTokens.ACCENT, 0.25))
	_aim_marker.draw_arc(Vector2.ZERO, 90.0, 0.0, TAU, 48, UiTokens.ACCENT, 4.0, true)


## Simulado: custo × 1,5 por nível, MAX no nível 10. No jogo vem de data/upgrades/.
func _emit_upgrade(ub: UpgradeButton) -> void:
	ub.set_upgrade(_levels[ub.upgrade_id], 10, _costs[ub.upgrade_id])


func _set_particles(v: int) -> void:
	_particles = v
	_particles_label.text = UiTokens.format_int(v)
	for ub in _upgrades:
		ub.set_particles(v) # particles_changed(total)


func _on_buy(id: StringName) -> void:
	for ub in _upgrades:
		if ub.upgrade_id == id and ub.next_cost >= 0 and _particles >= ub.next_cost:
			var cost := ub.next_cost
			_levels[id] += 1
			_costs[id] = -1 if _levels[id] >= 10 else roundi(cost * 1.5)
			_set_particles(_particles - cost)
			_emit_upgrade(ub)


func _on_add_particles() -> void:
	_set_particles(_particles + 300)


func _on_zero_particles() -> void:
	_set_particles(0)


func _label(text: String, variation: StringName) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	return l


func _button(text: String, variation: StringName, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	b.size_flags_horizontal = SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	return b


# --- Gameplay simulado (no jogo real isso vem dos sinais do Match) ---

func _unhandled_input(event: InputEvent) -> void:
	for i in 3:
		if event.is_action_pressed(StringName("skill_%d" % (i + 1))):
			_try_use(i)


func _try_use(i: int) -> void:
	if _disabled or _remaining[i] > 0.0:
		return
	_remaining[i] = COOLDOWNS[i]
	_skills[i].on_used() # skill_used(slot)
	_skills[i].set_cooldown(_remaining[i], COOLDOWNS[i]) # cooldown_changed


func _process(delta: float) -> void:
	_signal_t += delta
	var emit := _signal_t >= SIGNAL_INTERVAL
	if emit:
		_signal_t = 0.0
	for i in 3:
		if _remaining[i] <= 0.0:
			continue
		_remaining[i] = maxf(_remaining[i] - delta, 0.0)
		if _remaining[i] == 0.0:
			_skills[i].set_ready() # skill_ready(slot)
		elif emit:
			_skills[i].set_cooldown(_remaining[i], COOLDOWNS[i])


func _on_damage() -> void:
	_core_hp = maxi(_core_hp - 15, 0)
	_core_bar.set_value(_core_hp, CORE_MAX)


func _on_heal() -> void:
	_core_hp = mini(_core_hp + 20, CORE_MAX)
	_core_bar.set_value(_core_hp, CORE_MAX)


func _on_boss_hit() -> void:
	_boss_hp = maxi(_boss_hp - 60, 0)
	_boss_bar.set_value(_boss_hp, BOSS_MAX)


func _on_reset() -> void:
	_core_hp = CORE_MAX
	_boss_hp = BOSS_MAX
	_core_bar.set_value(_core_hp, CORE_MAX)
	_boss_bar.set_value(_boss_hp, BOSS_MAX)
	for i in 3:
		_remaining[i] = 0.0
		_skills[i].set_ready()


func _on_toggle_disabled() -> void:
	_disabled = not _disabled
	for sb in _skills:
		sb.set_disabled(_disabled)
	for ub in _upgrades:
		ub.set_disabled(_disabled)


## T-136: slots 2 e 3 bloqueados ("NV 7" / "NV 12"), como no padrão do HUD no M1.
func _on_toggle_locked() -> void:
	_locked = not _locked
	_apply_locks()


func _apply_locks() -> void:
	for i in 3:
		var level: int = Hud.M1_UNLOCK_LEVELS[i] if _locked else 0
		_skills[i].set_locked(level > 0, level)
