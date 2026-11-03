extends SceneTree
## Gera anima_theme.tres a partir de UiTokens.
## Uso: godot --headless --path . -s res://src/ui/theme/build_theme.gd

const OUTPUT := "res://src/ui/theme/anima_theme.tres"


func _init() -> void:
	var err := ResourceSaver.save(build(), OUTPUT)
	if err != OK:
		push_error("Falha ao salvar %s: %s" % [OUTPUT, error_string(err)])
	else:
		print("Tema salvo em ", OUTPUT)
	quit(err)


static func build() -> Theme:
	var theme := Theme.new()
	var regular := _font_weight(400)
	var bold := _font_weight(700)
	theme.default_font = regular
	theme.default_font_size = UiTokens.FONT_BODY

	# Label
	theme.set_color("font_color", "Label", UiTokens.TEXT_PRIMARY)
	_label_variation(theme, "LabelDisplay", bold, UiTokens.FONT_DISPLAY, UiTokens.TEXT_PRIMARY)
	_label_variation(theme, "LabelTitle", bold, UiTokens.FONT_TITLE, UiTokens.TEXT_PRIMARY)
	_label_variation(theme, "LabelHud", bold, UiTokens.FONT_HUD, UiTokens.TEXT_PRIMARY)
	_label_variation(theme, "LabelCaption", regular, UiTokens.FONT_CAPTION, UiTokens.TEXT_SECONDARY)

	# Button (secundário = padrão)
	_button(theme, "Button", UiTokens.BG_PANEL_ALT, UiTokens.TEXT_PRIMARY, UiTokens.LINE)
	theme.set_font("font", "Button", bold)
	# ButtonPrimary
	theme.set_type_variation("ButtonPrimary", "Button")
	_button(theme, "ButtonPrimary", UiTokens.ACCENT, UiTokens.BG_VOID, UiTokens.ACCENT)

	# Painel
	theme.set_stylebox("panel", "PanelContainer", _box(UiTokens.BG_PANEL, UiTokens.LINE, UiTokens.RADIUS_M, UiTokens.BORDER))

	# Fontes extras para componentes desenhados à mão (SkillButton, UiBar)
	theme.set_font("font_bold", "SkillButton", bold)
	theme.set_font_size("font_size", "SkillButton", UiTokens.FONT_HUD)
	theme.set_font_size("caption_size", "SkillButton", UiTokens.FONT_CAPTION)
	theme.set_font("font", "UiBar", bold)
	theme.set_font_size("font_size", "UiBar", UiTokens.FONT_CAPTION)
	return theme


static func _font_weight(weight: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load(UiTokens.FONT_PATH)
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight}
	# Algarismos tabulares: números do HUD não "tremem" ao mudar.
	fv.opentype_features = {ts.name_to_tag("tnum"): 1}
	return fv


static func _label_variation(theme: Theme, type_name: StringName, font: Font, size: int, color: Color) -> void:
	theme.set_type_variation(type_name, "Label")
	theme.set_font("font", type_name, font)
	theme.set_font_size("font_size", type_name, size)
	theme.set_color("font_color", type_name, color)


static func _button(theme: Theme, type_name: StringName, bg: Color, fg: Color, border: Color) -> void:
	theme.set_stylebox("normal", type_name, _box(bg, border, UiTokens.RADIUS_M, UiTokens.BORDER))
	theme.set_stylebox("hover", type_name, _box(bg.lightened(0.08), border, UiTokens.RADIUS_M, UiTokens.BORDER))
	theme.set_stylebox("pressed", type_name, _box(bg.darkened(0.15), border, UiTokens.RADIUS_M, UiTokens.BORDER))
	theme.set_stylebox("focus", type_name, _box(Color.TRANSPARENT, UiTokens.ACCENT, UiTokens.RADIUS_M, UiTokens.BORDER_FOCUS))
	theme.set_stylebox("disabled", type_name, _box(UiTokens.BG_PANEL_ALT.darkened(0.3), UiTokens.LINE, UiTokens.RADIUS_M, UiTokens.BORDER))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, type_name, fg)
	theme.set_color("font_disabled_color", type_name, UiTokens.TEXT_SECONDARY)


static func _box(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = UiTokens.SPACE_M
	sb.content_margin_right = UiTokens.SPACE_M
	sb.content_margin_top = UiTokens.SPACE_S
	sb.content_margin_bottom = UiTokens.SPACE_S
	sb.anti_aliasing = true
	return sb
