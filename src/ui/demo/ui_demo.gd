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
	col.add_child(_label("HP do Núcleo", &"LabelCaption"))
	_core_bar = UiBar.new()
	_core_bar.color_mode = UiBar.ColorMode.CORE_HP
	_core_bar.set_value(_core_hp, CORE_MAX)
	col.add_child(_core_bar)

	col.add_child(_label("Chefe", &"LabelCaption"))
	_boss_bar = UiBar.new()
	_boss_bar.color_mode = UiBar.ColorMode.FIXED
	_boss_bar.fill_color = UiTokens.BOSS_HP
	_boss_bar.custom_minimum_size.y = 24
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

	var hud := _label("Wave 3/10    ● 125", &"LabelHud")
	col.add_child(hud)

	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	spacer.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	var skills_row := HBoxContainer.new()
	skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_row.add_theme_constant_override("separation", 52)
	col.add_child(skills_row)
	var icons := [SkillButton.Icon.CIRCLE, SkillButton.Icon.DIAMOND, SkillButton.Icon.HEX]
	for i in 3:
		var sb := SkillButton.new()
		sb.slot = i + 1
		sb.icon = icons[i]
		skills_row.add_child(sb)
		_skills.append(sb)


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
