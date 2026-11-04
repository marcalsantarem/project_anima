extends SceneTree
## Gera anima_theme.tres a partir de UiTokens (estilo cartoon, T-145) e da arte de UiArt (T-138).
## Uso: godot --headless --path . -s res://src/ui/theme/build_theme.gd

const OUTPUT := "res://src/ui/theme/anima_theme.tres"
const PILL_RADIUS := 40


func _init() -> void:
	var err := ResourceSaver.save(build(), OUTPUT)
	if err != OK:
		push_error("Falha ao salvar %s: %s" % [OUTPUT, error_string(err)])
	else:
		print("Tema salvo em ", OUTPUT)
	quit(err)


static func build() -> Theme:
	var theme := Theme.new()
	var regular := _font_weight(UiTokens.FONT_WEIGHT_REGULAR)
	var bold := _font_weight(UiTokens.FONT_WEIGHT_BOLD)
	theme.default_font = regular
	theme.default_font_size = UiTokens.FONT_BODY

	# Label: texto claro com contorno escuro (legível sobre a arena clara e os painéis).
	theme.set_color("font_color", "Label", UiTokens.TEXT_PRIMARY)
	theme.set_color("font_outline_color", "Label", UiTokens.INK)
	theme.set_constant("outline_size", "Label", UiTokens.TEXT_OUTLINE)
	_label_variation(theme, "LabelDisplay", bold, UiTokens.FONT_DISPLAY, UiTokens.TEXT_PRIMARY, UiTokens.TEXT_OUTLINE + 6)
	_label_variation(theme, "LabelTitle", bold, UiTokens.FONT_TITLE, UiTokens.TEXT_PRIMARY, UiTokens.TEXT_OUTLINE + 2)
	_label_variation(theme, "LabelHud", bold, UiTokens.FONT_HUD, UiTokens.TEXT_PRIMARY, UiTokens.TEXT_OUTLINE)
	_label_variation(theme, "LabelCaption", bold, UiTokens.FONT_CAPTION, UiTokens.TEXT_SECONDARY, UiTokens.TEXT_OUTLINE - 2)
	# Texto escuro sem contorno, para fundos claros.
	_label_variation(theme, "LabelOnLight", bold, UiTokens.FONT_BODY, UiTokens.TEXT_ON_LIGHT, 0)

	# Button (secundário = padrão): claro, texto escuro.
	_button(theme, "Button", UiTokens.SURFACE, UiTokens.TEXT_ON_LIGHT)
	theme.set_font("font", "Button", bold)
	theme.set_type_variation("ButtonPrimary", "Button")
	_button(theme, "ButtonPrimary", UiTokens.ACCENT, UiTokens.TEXT_ON_LIGHT)
	# Botão principal com a arte 9-patch (T-138). O secundário (branco) não tem arte: fica no StyleBoxFlat.
	theme.set_stylebox("normal", "ButtonPrimary", UiArt.button_big(false))
	theme.set_stylebox("hover", "ButtonPrimary", UiArt.button_big(false))
	theme.set_stylebox("pressed", "ButtonPrimary", UiArt.button_big(true))
	theme.set_stylebox("hover_pressed", "ButtonPrimary", UiArt.button_big(true))
	var primary_off := UiArt.button_big(false)
	primary_off.modulate_color = Color(0.7, 0.7, 0.75, 0.8)
	theme.set_stylebox("disabled", "ButtonPrimary", primary_off)

	# Painéis com moldura
	theme.set_stylebox("panel", "PanelContainer", UiArt.panel()) # arte ui_panel (T-138)
	theme.set_type_variation("PanelPill", "PanelContainer")
	theme.set_stylebox("panel", "PanelPill", _pill(UiTokens.BG_PANEL))
	theme.set_type_variation("PanelPillLight", "PanelContainer")
	theme.set_stylebox("panel", "PanelPillLight", _pill(UiTokens.SURFACE))
	theme.set_type_variation("PanelTray", "PanelContainer")
	var tray := StyleBoxFlat.new()
	tray.bg_color = UiTokens.BG_PANEL_ALT
	tray.border_color = UiTokens.INK
	tray.border_width_top = UiTokens.BORDER
	theme.set_stylebox("panel", "PanelTray", tray)

	# Fontes extras para componentes desenhados à mão (SkillButton, UiBar)
	theme.set_font("font_bold", "SkillButton", bold)
	theme.set_font_size("font_size", "SkillButton", UiTokens.FONT_TITLE)
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


static func _label_variation(theme: Theme, type_name: StringName, font: Font, size: int, color: Color, outline: int) -> void:
	theme.set_type_variation(type_name, "Label")
	theme.set_font("font", type_name, font)
	theme.set_font_size("font_size", type_name, size)
	theme.set_color("font_color", type_name, color)
	theme.set_constant("outline_size", type_name, outline)


static func _button(theme: Theme, type_name: StringName, bg: Color, fg: Color) -> void:
	theme.set_stylebox("normal", type_name, UiTokens.cartoon_box(bg))
	theme.set_stylebox("hover", type_name, UiTokens.cartoon_box(bg.lightened(0.12)))
	# Pressionado: afunda (sem sombra de base, conteúdo desce o mesmo tanto).
	var pressed := UiTokens.cartoon_box(bg.darkened(0.12), UiTokens.RADIUS_M, 0)
	pressed.expand_margin_top = -UiTokens.SHADOW_BASE
	pressed.content_margin_top += UiTokens.SHADOW_BASE
	theme.set_stylebox("pressed", type_name, pressed)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = UiTokens.ACCENT
	focus.set_border_width_all(UiTokens.BORDER_FOCUS)
	focus.set_corner_radius_all(UiTokens.RADIUS_M + 4)
	focus.set_expand_margin_all(UiTokens.BORDER_FOCUS + 2)
	theme.set_stylebox("focus", type_name, focus)
	theme.set_stylebox("disabled", type_name, UiTokens.cartoon_box(UiTokens.LOCKED))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, type_name, fg)
	theme.set_color("font_disabled_color", type_name, UiTokens.INK.lightened(0.35))
	theme.set_constant("outline_size", type_name, 0)


static func _pill(bg: Color) -> StyleBoxFlat:
	var sb := UiTokens.cartoon_box(bg, PILL_RADIUS)
	sb.content_margin_top = UiTokens.SPACE_XS
	sb.content_margin_bottom = UiTokens.SPACE_XS
	return sb
