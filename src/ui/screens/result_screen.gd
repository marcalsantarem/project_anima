class_name ResultScreen
extends Control
## Resultado da partida, holográfico (T-191, BRF-115; docs/ui.md §8).
## Contrato: show_result(result: MatchResult) (antes ou depois de entrar na árvore); sinais
## `play_again_requested` ("Jogar de novo") e `title_requested` ("Voltar", T-155).
## `set_reward(summary: Dictionary)` (T-187): chaves xp, coins, first_win_bonus, levels_gained, slots_unlocked,
## level_before, xp_before, xp_to_next_before, level_after, xp_after, xp_to_next_after (0 = teto), result_outcome.
## Sem `set_reward` não há seção de recompensa. A animação (contagem, barra, subidas) usa tempo real
## (decisão 59), pula com um toque e não bloqueia os botões; `reduced_effects` vai direto ao estado final.
## Botão "Enviar log" (T-269): envia `set_log(doc)` (ou o último log salvo). Sem visualizador (BRF-136).

signal play_again_requested
signal title_requested

const TXT_VICTORY := "VITÓRIA"
const TXT_DEFEAT := "DERROTA"
const TXT_WAVE := "ONDA %d/%d  ·  %s"
const TXT_ENEMIES := "Inimigos: %d"
const TXT_PARTICLES := "Partículas: %s"
const TXT_REWARDS := "RECOMPENSAS"
const TXT_XP := "XP"
const TXT_COIN := "MOEDA"
const TXT_FIRST_WIN := "1ª VITÓRIA DO DIA  (+BÔNUS)"
const TXT_LEVEL := "NÍVEL %d"
const TXT_LEVEL_UP := "NÍVEL %d!"
const TXT_LEVEL_FROM_TO := "NÍVEL %d → %d"
const TXT_XP_PROGRESS := "%s / %s XP"
const TXT_MAX := "MAX"
const TXT_SLOT := "SLOT %d LIBERADO"
const TXT_SLOT_SUB := "Disponível na próxima partida"
const TXT_PLAY := "Jogar de novo"
const TXT_BACK := "Voltar"

const BG_ART := preload("res://assets/backgrounds/result_tech_bg_dim.webp")
const T_PANEL := preload("res://assets/ui/ui_holo_panel.png")
const T_PANEL_GOLD := preload("res://assets/ui/ui_holo_panel_gold.png")
const T_PILL := preload("res://assets/ui/ui_holo_pill.png")
const T_PRIMARY := preload("res://assets/ui/ui_holo_btn_primary_normal.png")
const T_PRIMARY_DOWN := preload("res://assets/ui/ui_holo_btn_primary_pressed.png")
const T_SECONDARY := preload("res://assets/ui/ui_holo_btn_secondary_normal.png")
const T_SECONDARY_DOWN := preload("res://assets/ui/ui_holo_btn_secondary_pressed.png")
const T_SECONDARY_OFF := preload("res://assets/ui/ui_holo_btn_secondary_disabled.png")
const T_BAR_TRACK := preload("res://assets/ui/ui_holo_bar_track.png")
const T_BAR_FILL := preload("res://assets/ui/ui_holo_bar_fill.png")
const T_BAR_TIP := preload("res://assets/ui/ui_holo_bar_tip.png")
const T_BADGE := preload("res://assets/ui/ui_holo_level_badge.png")
const T_RING := preload("res://assets/ui/ui_holo_level_ring.png")
const T_SLOT := preload("res://assets/ui/ui_holo_slot_ready.png")
const T_UNLOCK := preload("res://assets/ui/ui_icon_unlock_holo.png")
const T_XP := preload("res://assets/ui/ui_icon_xp.png")

const HOLO_TEXT := Color("#E6FFFF")
const HOLO_TEXT2 := Color("#9FF6FF")
const HOLO_MUTED := Color("#7FA3B8")
const HOLO_VIOLET := Color("#B9A5FF")
const HOLO_INK := Color("#03202E")
const GLOW := Color(0.18, 0.85, 1.0, 0.35)

## Botão "Enviar log": secundário e menor que os dois principais (alvo ≥ 44 px, BRF-063).
const LOGS_BUTTON_SIZE := Vector2(200, 64)
const COUNT_TIME := 1.0 ## contagem de XP e Moeda (s, tempo real)
const BAR_TIME := 1.0 ## barra sem subida de nível
const BAR_SEG_TIME := 0.7 ## cada trecho da barra quando há subida(s)
const PULSE_TIME := 0.5

## Efeitos reduzidos (T-132): sem animação nem pulsos; mostra o estado final direto.
var reduced_effects: bool = DebugSettings.reduced_effects()
## Estado exibido (para testes e VFX).
var shown_xp := 0
var shown_coins := 0
var shown_level := 0
var bar_frac := 0.0

var _result: MatchResult
var _reward: Dictionary = {}
var _title: Label
var _stats: Label
var _particles_label: Label
var _stats_tail: Label
var _log: Dictionary = {}
## Visualizador aberto, ou null.
var _uploader: LogUploader
var _send_button: Button
var _notice: Label

var _root: Control
var _reward_panel: Control
var _level_panel: Control
var _slots_box: VBoxContainer
var _xp_value: Label
var _coin_value: Label
var _seal: Control
var _badge_box: Control
var _badge_num: Label
var _ring: TextureRect
var _heading: Label
var _sub: Label
var _xp_text: Label
var _bar: Control
var _bar_fill: NinePatchRect
var _bar_tip: TextureRect
var _anim: Tween
var _anim_total := 0.0
var _last_seg := 0
var _pulse: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_root = ScreenKit.root(self)
	ScreenKit.set_page_color(Color("#021423"))
	# Fundo holográfico (T-277, decisão 60): atrás de tudo, cobrindo a tela (corta as bordas).
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = BG_ART
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)
	_root.move_child(bg, 1)
	_root.gui_input.connect(_on_root_input)
	var inset := ScreenKit.safe_area(get_viewport())
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", UiTokens.SPACE_M + 8)
	m.add_theme_constant_override("margin_right", UiTokens.SPACE_M + 8)
	m.add_theme_constant_override("margin_top", UiTokens.SPACE_L + int(inset.top))
	m.add_theme_constant_override("margin_bottom", UiTokens.SPACE_S + int(inset.bottom))
	_root.add_child(m)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTokens.SPACE_S)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)

	_title = _lbl("", 84, UiTokens.GOLD)
	_title.name = "Title"
	col.add_child(_title)
	_stats = _lbl("", UiTokens.FONT_BODY, HOLO_TEXT2)
	col.add_child(_stats)
	# Partículas da partida: estrela + texto, e inimigos.
	var summary := HBoxContainer.new()
	summary.alignment = BoxContainer.ALIGNMENT_CENTER
	summary.add_theme_constant_override("separation", UiTokens.SPACE_M)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(summary)
	var particles_row := HBoxContainer.new()
	particles_row.name = "ParticlesRow"
	particles_row.alignment = BoxContainer.ALIGNMENT_CENTER
	particles_row.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	particles_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particles_row.add_child(StarIcon.new(32))
	_particles_label = _lbl("", UiTokens.FONT_BODY, HOLO_TEXT)
	# Dentro de HBox, autowrap dá largura mínima 0 e quebra letra por letra (BRF-039): sem quebra aqui.
	_particles_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	particles_row.add_child(_particles_label)
	summary.add_child(particles_row)
	_stats_tail = _lbl("", UiTokens.FONT_BODY, HOLO_TEXT)
	_stats_tail.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary.add_child(_stats_tail)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	col.add_child(scroll)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", UiTokens.SPACE_S)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)
	_build_reward_panel(content)
	_build_level_panel(content)
	_slots_box = VBoxContainer.new()
	_slots_box.name = "Slots"
	_slots_box.add_theme_constant_override("separation", UiTokens.SPACE_M)
	_slots_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_slots_box)

	var play := _button(TXT_PLAY, true, func() -> void: play_again_requested.emit())
	play.name = "PlayAgain"
	col.add_child(play)
	var back := _button(TXT_BACK, false, func() -> void: title_requested.emit())
	back.name = "BackToTitle"
	col.add_child(back)
	# Teclado: foco inicial no principal; setas/Tab levam ao secundário e a action de aceitar confirma.
	play.focus_neighbor_bottom = play.get_path_to(back)
	var small_row := HBoxContainer.new()
	small_row.name = "SmallRow"
	small_row.alignment = BoxContainer.ALIGNMENT_CENTER
	small_row.add_theme_constant_override("separation", UiTokens.SPACE_S)
	col.add_child(small_row)
	if LogUploader.ENABLED:
		_uploader = LogUploader.new()
		add_child(_uploader)
		_uploader.state_changed.connect(_on_upload_state)
		_send_button = _button(LogUploader.TXT_SEND, false, send_log)
		_send_button.name = "SendLog"
		_send_button.custom_minimum_size = LOGS_BUTTON_SIZE
		_send_button.add_theme_font_size_override("font_size", UiTokens.FONT_CAPTION)
		small_row.add_child(_send_button)
		_notice = _lbl(LogUploader.TXT_NOTICE, UiTokens.FONT_CAPTION - 2, HOLO_MUTED)
		_notice.name = "SendNotice"
		col.add_child(_notice)
		_send_button.focus_neighbor_top = _send_button.get_path_to(back)
		back.focus_neighbor_bottom = back.get_path_to(_send_button)
	back.focus_neighbor_top = back.get_path_to(play)
	play.call_deferred(&"grab_focus")
	ScreenKit.fade_in(_root)
	_refresh()


func show_result(result: MatchResult) -> void:
	_result = result
	if is_node_ready():
		_refresh()


## Recompensa da partida (ver chaves no cabeçalho). Dicionário vazio = sem seção de recompensa.
func set_reward(summary: Dictionary) -> void:
	_reward = summary
	if is_node_ready():
		_refresh()


func has_reward() -> bool:
	return not _reward.is_empty()


func is_animating() -> bool:
	return _anim != null and _anim.is_valid() and _anim.is_running()


## Pula a animação: vai direto ao estado final (sem pulsos).
func skip_animation() -> void:
	if _anim != null and _anim.is_valid():
		_anim.kill()
	_anim = null
	if has_reward():
		_apply(_anim_total, false)
		_show_slots()


func _refresh() -> void:
	if _anim != null and _anim.is_valid():
		_anim.kill()
	_anim = null
	if _result == null:
		_title.text = "—"
		_stats.text = ""
		_particles_label.text = ""
		_stats_tail.text = ""
	else:
		var won := _result.outcome == MatchResult.Outcome.VICTORY
		_title.text = TXT_VICTORY if won else TXT_DEFEAT
		_title.add_theme_color_override("font_color", UiTokens.GOLD if won else UiTokens.DANGER)
		_stats.text = TXT_WAVE % [_result.wave_reached, _result.waves_total, ScreenKit.format_time(_result.duration_s)]
		_particles_label.text = TXT_PARTICLES % UiTokens.format_int(_result.particles)
		_stats_tail.text = TXT_ENEMIES % _result.enemies_killed
	var has := has_reward()
	_reward_panel.visible = has
	_level_panel.visible = has
	for c in _slots_box.get_children():
		_slots_box.remove_child(c)
		c.queue_free()
	if not has:
		return
	_seal.visible = bool(_reward.get("first_win_bonus", false))
	_anim_total = _timeline_total()
	_last_seg = 0
	if reduced_effects or not is_inside_tree():
		_apply(_anim_total, false)
		_show_slots()
		return
	_apply(0.0, false)
	_anim = create_tween()
	_anim.set_ignore_time_scale(true) # decisão 59: velocidade do jogo não afeta o Resultado
	_anim.tween_method(func(t: float) -> void: _apply(t, true), 0.0, _anim_total, _anim_total)
	_anim.finished.connect(_show_slots)


# --- Linha do tempo da recompensa -------------------------------------------------------------

func _segments() -> int:
	return maxi(0, int(_reward.get("levels_gained", 0))) + 1


func _seg_time() -> float:
	return BAR_TIME if _segments() == 1 else BAR_SEG_TIME


func _timeline_total() -> float:
	return maxf(COUNT_TIME, _segments() * _seg_time())


static func _frac(xp: int, to_next: int) -> float:
	return 1.0 if to_next <= 0 else clampf(float(xp) / float(to_next), 0.0, 1.0)


## Estado da tela em `t` segundos da animação (função pura de t; `fx` liga os pulsos).
func _apply(t: float, fx: bool) -> void:
	var f := clampf(t / COUNT_TIME, 0.0, 1.0)
	f = 1.0 - (1.0 - f) * (1.0 - f)
	shown_xp = roundi(int(_reward.get("xp", 0)) * f)
	shown_coins = roundi(int(_reward.get("coins", 0)) * f)
	_xp_value.text = "+" + UiTokens.format_int(shown_xp)
	_coin_value.text = "+" + UiTokens.format_int(shown_coins)

	var n := _segments()
	var seg_t := _seg_time()
	var seg := mini(int(t / seg_t), n - 1)
	var local := clampf((t - seg * seg_t) / seg_t, 0.0, 1.0)
	local = 1.0 - (1.0 - local) * (1.0 - local)
	var lv0 := int(_reward.get("level_before", 1))
	var lv1 := int(_reward.get("level_after", lv0 + n - 1))
	var to0 := int(_reward.get("xp_to_next_before", 0))
	var to1 := int(_reward.get("xp_to_next_after", 0))
	var xp0 := int(_reward.get("xp_before", 0))
	var xp1 := int(_reward.get("xp_after", 0))
	var a := _frac(xp0, to0) if seg == 0 else 0.0
	var b := 1.0 if seg < n - 1 else (1.0 if to1 <= 0 else _frac(xp1, to1))
	var txt := ""
	if seg == n - 1 and to1 <= 0:
		txt = TXT_MAX
	elif seg == n - 1:
		var from_xp := 0.0 if n > 1 else float(xp0)
		txt = TXT_XP_PROGRESS % [UiTokens.format_int(roundi(lerpf(from_xp, xp1, local))), UiTokens.format_int(to1)]
	elif seg == 0:
		txt = TXT_XP_PROGRESS % [UiTokens.format_int(roundi(lerpf(xp0, to0, local))), UiTokens.format_int(to0)]
	var lv := mini(lv0 + seg, maxi(lv1, lv0))
	var gained := n > 1
	shown_level = lv
	_badge_num.text = str(lv)
	_heading.text = TXT_LEVEL_UP % lv if gained else TXT_LEVEL % lv
	_sub.visible = gained
	_sub.text = TXT_LEVEL_FROM_TO % [lv0, lv]
	_xp_text.text = txt
	_set_bar(lerpf(a, b, local))
	if fx and seg > _last_seg:
		_pulse_level(lv)
	_last_seg = seg


func _show_slots() -> void:
	if _slots_box.get_child_count() > 0 or not has_reward():
		return
	for slot in _reward.get("slots_unlocked", []):
		_slots_box.add_child(_slot_notice(int(slot)))
	if not reduced_effects and _anim != null:
		_slots_box.modulate.a = 0.0
		create_tween().set_ignore_time_scale(true).tween_property(_slots_box, "modulate:a", 1.0, UiTokens.ANIM_UI)
	else:
		_slots_box.modulate.a = 1.0


func _pulse_level(level: int) -> void:
	if reduced_effects:
		return
	_play_level_up_fx(level)
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_badge_box.pivot_offset = _badge_box.size * 0.5
	_ring.pivot_offset = _ring.size * 0.5
	_ring.modulate.a = 1.0
	_ring.rotation = 0.0
	_ring.scale = Vector2(0.8, 0.8)
	_badge_box.scale = Vector2(1.18, 1.18)
	_pulse = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_pulse.tween_property(_ring, "rotation", PI * 0.5, PULSE_TIME)
	_pulse.tween_property(_ring, "scale", Vector2(1.3, 1.3), PULSE_TIME)
	_pulse.tween_property(_ring, "modulate:a", 0.0, PULSE_TIME)
	_pulse.tween_property(_badge_box, "scale", Vector2.ONE, PULSE_TIME * 0.6)


## Ponto de extensão do VFX da subida de nível (AG09, passada seguinte). Vazio de propósito.
func _play_level_up_fx(_level: int) -> void:
	pass


func _on_root_input(event: InputEvent) -> void:
	if is_animating() and event is InputEventMouseButton and event.pressed:
		skip_animation()


# --- Peças --------------------------------------------------------------------------------------

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := ScreenKit.label(text, &"LabelHud", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", GLOW)
	l.add_theme_constant_override("outline_size", 4 if size >= 40 else 0)
	return l


static func _tex_box(tex: Texture2D, margin: int, content: Vector2 = Vector2.ZERO, expand: int = 0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.set_texture_margin_all(margin)
	sb.set_expand_margin_all(expand)
	sb.content_margin_left = content.x
	sb.content_margin_right = content.x
	sb.content_margin_top = content.y
	sb.content_margin_bottom = content.y
	return sb


func _panel(parent: Control, tex: Texture2D = T_PANEL, expand: int = 0) -> VBoxContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _tex_box(tex, 48, Vector2(UiTokens.SPACE_M, UiTokens.SPACE_S), expand))
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	return v


func _button(text: String, primary: bool, cb: Callable) -> Button:
	var b := ScreenKit.button(text, primary, cb)
	var normal: StyleBoxTexture
	var down: StyleBoxTexture
	if primary:
		b.custom_minimum_size = Vector2(440, 120)
		normal = StyleBoxTexture.new()
		normal.texture = T_PRIMARY
		normal.set_texture_margin_all(48)
		normal.texture_margin_top = 56
		normal.texture_margin_bottom = 56
		normal.set_expand_margin_all(16)
		down = normal.duplicate()
		down.texture = T_PRIMARY_DOWN
		down.content_margin_top = 6
	else:
		b.custom_minimum_size = Vector2(360, UiTokens.TOUCH_MIN)
		normal = _tex_box(T_SECONDARY, 24)
		down = _tex_box(T_SECONDARY_DOWN, 24)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("disabled", _tex_box(T_SECONDARY_OFF, 24))
	var ink := HOLO_INK if primary else HOLO_TEXT
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, ink)
	b.add_theme_color_override("font_disabled_color", Color("#5F7A92"))
	b.add_theme_constant_override("outline_size", 0)
	b.add_theme_font_size_override("font_size", 34 if primary else UiTokens.FONT_HUD)
	b.text = text.to_upper()
	return b


func _build_reward_panel(parent: Control) -> void:
	var v := _panel(parent)
	_reward_panel = v.get_parent()
	_reward_panel.name = "RewardPanel"
	v.add_child(_lbl(TXT_REWARDS, UiTokens.FONT_CAPTION + 2, HOLO_TEXT2))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UiTokens.SPACE_M)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row)
	_xp_value = _reward_cell(row, TXT_XP, HOLO_VIOLET, _icon(T_XP, 76))
	_coin_value = _reward_cell(row, TXT_COIN, UiTokens.GOLD, _coin_icon())
	var seal := PanelContainer.new()
	seal.name = "FirstWinSeal"
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.add_theme_stylebox_override("panel", _tex_box(T_PILL, 20, Vector2(UiTokens.SPACE_S, 4)))
	seal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var seal_label := _lbl(TXT_FIRST_WIN, UiTokens.FONT_CAPTION, UiTokens.GOLD)
	seal_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	seal.add_child(seal_label)
	v.add_child(seal)
	_seal = seal


func _coin_icon() -> TextureRect:
	var t := TextureRect.new()
	t.name = "CoinIcon"
	t.texture = load("res://assets/ui/ui_icon_coin.png")
	t.custom_minimum_size = Vector2(76, 76)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _reward_cell(row: HBoxContainer, caption: String, color: Color, icon: Control) -> Label:
	var cell := HBoxContainer.new()
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", UiTokens.SPACE_S)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(cell)
	cell.add_child(icon)
	var txt := VBoxContainer.new()
	txt.add_theme_constant_override("separation", 0)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(txt)
	var val := _lbl("+0", 56, Color("#FFE39A") if color == UiTokens.GOLD else HOLO_TEXT)
	val.autowrap_mode = TextServer.AUTOWRAP_OFF
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	txt.add_child(val)
	var cap := _lbl(caption, UiTokens.FONT_CAPTION, color)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	txt.add_child(cap)
	return val


func _icon(tex: Texture2D, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _build_level_panel(parent: Control) -> void:
	var v := _panel(parent)
	_level_panel = v.get_parent()
	_level_panel.name = "LevelPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_S)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row)
	_badge_box = Control.new()
	_badge_box.custom_minimum_size = Vector2(192, 192)
	_badge_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_badge_box)
	_ring = _icon(T_RING, 192)
	_ring.modulate.a = 0.0
	_badge_box.add_child(_ring)
	_ring.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var badge := _icon(T_BADGE, 0)
	badge.custom_minimum_size = Vector2.ZERO
	_badge_box.add_child(badge)
	badge.position = Vector2(32, 24)
	badge.size = Vector2(128, 144)
	_badge_num = _lbl("1", 60, HOLO_TEXT)
	_badge_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_box.add_child(_badge_num)
	_badge_num.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right)
	_heading = _lbl("", 46, HOLO_TEXT)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	right.add_child(_heading)
	_sub = _lbl("", UiTokens.FONT_CAPTION, HOLO_MUTED)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	right.add_child(_sub)
	_bar = Control.new()
	_bar.name = "XpBar"
	_bar.custom_minimum_size = Vector2(0, 28)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(_bar)
	var track := NinePatchRect.new()
	track.texture = T_BAR_TRACK
	_patch(track, 8)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(track)
	track.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_bar_fill = NinePatchRect.new()
	_bar_fill.texture = T_BAR_FILL
	_patch(_bar_fill, 6)
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_bar_fill)
	_bar_tip = TextureRect.new()
	_bar_tip.texture = T_BAR_TIP
	_bar_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_bar_tip)
	_bar.resized.connect(func() -> void: _set_bar(bar_frac))
	_xp_text = _lbl("", UiTokens.FONT_CAPTION + 2, HOLO_MUTED)
	_xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	right.add_child(_xp_text)


static func _patch(n: NinePatchRect, m: int) -> void:
	n.patch_margin_left = m
	n.patch_margin_right = m
	n.patch_margin_top = m
	n.patch_margin_bottom = m


func _set_bar(frac: float) -> void:
	bar_frac = frac
	var w := (_bar.size.x - 8.0) * frac
	_bar_fill.visible = w >= 12.0
	_bar_tip.visible = frac > 0.0
	_bar_fill.position = Vector2(4, 4)
	_bar_fill.size = Vector2(maxf(w, 12.0), _bar.size.y - 8.0)
	_bar_tip.size = Vector2(16, 40)
	_bar_tip.position = Vector2(4.0 + w - 8.0, (_bar.size.y - 40.0) * 0.5)


func _slot_notice(slot: int) -> Control:
	var holder := VBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := _panel(holder, T_PANEL_GOLD, 16)
	v.get_parent().name = "SlotNotice%d" % slot
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UiTokens.SPACE_M)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row)
	var box := Control.new()
	box.custom_minimum_size = Vector2(120, 120)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	var frame := _icon(T_SLOT, 120)
	box.add_child(frame)
	frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var lock := _icon(T_UNLOCK, 64)
	lock.custom_minimum_size = Vector2.ZERO
	box.add_child(lock)
	lock.position = Vector2(28, 28)
	lock.size = Vector2(64, 64)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(txt)
	var head := _lbl(TXT_SLOT % slot, 40, UiTokens.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	txt.add_child(head)
	var sub := _lbl(TXT_SLOT_SUB, UiTokens.FONT_CAPTION, HOLO_TEXT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	txt.add_child(sub)
	return holder


## Log da partida (MatchRecorder) para o botão "Enviar log".
func set_log(doc: Dictionary) -> void:
	_log = doc


## Botão "Enviar log" (T-269): envia o resultado e o log; sem reenvio depois de enviado.
func send_log() -> void:
	if _uploader == null:
		return
	var doc := _log if not _log.is_empty() else MatchRecorder.load_last()
	_uploader.send(_result, doc)


func _on_upload_state(s: int) -> void:
	if _send_button == null:
		return
	match s:
		LogUploader.State.SENDING:
			_send_button.text = LogUploader.TXT_SENDING
			_send_button.disabled = true
		LogUploader.State.SENT:
			_send_button.text = LogUploader.TXT_SENT
			_send_button.disabled = true
		LogUploader.State.FAILED:
			_send_button.text = LogUploader.TXT_FAILED
			if _notice != null and _uploader != null:
				_notice.text = LogUploader.TXT_NOTICE + "\n(" + _uploader.last_error + ")"
			_send_button.disabled = false
		_:
			_send_button.text = LogUploader.TXT_SEND
			_send_button.disabled = false

