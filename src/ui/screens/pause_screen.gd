class_name PauseScreen
extends CanvasLayer
## Overlay de pausa (docs/ui.md §8). Funciona com o jogo pausado (process_mode ALWAYS).
## Entrada: SÓ a action `pause` (Esc e o botão do HUD, que injeta a action). Não ouve `Hud.pause_requested`.
## Também pausa sozinha ao perder o foco (aba/app); a volta não retoma, o jogador toca em Continuar.
## Contrato: open(), close(), bind(arena) (desliga no match_ended), sinais `resumed`, `restart_requested`
## e `reduced_effects_changed(on)` (o SceneFlow aplica na partida em curso; estado em DebugSettings).

signal resumed
signal restart_requested
## "Voltar ao menu": o SceneFlow troca a cena (abandono, sem recompensa).
signal menu_requested
signal reduced_effects_changed(on: bool)

const DEBUG_BUTTON_SIZE := Vector2(228, 88)
## Estilo holográfico (T-293, BRF-133; docs/arte.md §11).
const T_PANEL := preload("res://assets/ui/ui_holo_panel.png")
const T_PRIMARY := preload("res://assets/ui/ui_holo_btn_primary_normal.png")
const T_PRIMARY_DOWN := preload("res://assets/ui/ui_holo_btn_primary_pressed.png")
const T_SECONDARY := preload("res://assets/ui/ui_holo_btn_secondary_normal.png")
const T_SECONDARY_DOWN := preload("res://assets/ui/ui_holo_btn_secondary_pressed.png")
const VEIL := Color(0.008, 0.078, 0.137, 0.78) # HOLO_BG a 78%

var enabled := true
var _root: Control
var _continue: Button
var menu_button: Button
## Interruptor "Debug" (overlay de debug, BRF-063; estado em DebugSettings).
var debug_toggle: Button
## Interruptor "Efeitos reduzidos" (T-132, BRF-080), ao lado do "Debug".
var reduced_toggle: Button
var _js_visibility_cb: JavaScriptObject
## Linha discreta `v<versão> · <sha>` (T-165).
var version_label: Label


func _ready() -> void:
	layer = 20
	process_mode = PROCESS_MODE_ALWAYS
	_root = ScreenKit.root(self, VEIL)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := _holo_card(_root)
	var title := ScreenKit.label("PAUSADO", &"LabelTitle", UiTokens.HOLO_TEXT)
	_outline(title)
	col.add_child(title)
	_continue = _holo_button("Continuar", true, close)
	col.add_child(_continue)
	col.add_child(_holo_button("Recomeçar", false, _on_restart))
	menu_button = _holo_button("Voltar ao menu", false, _on_menu)
	menu_button.name = "MenuButton"
	col.add_child(menu_button)
	var toggles := HBoxContainer.new()
	toggles.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	col.add_child(toggles)
	reduced_toggle = _toggle_button("ReducedEffectsToggle", _on_reduced_toggled)
	toggles.add_child(reduced_toggle)
	debug_toggle = _toggle_button("DebugToggle", _on_debug_toggled)
	toggles.add_child(debug_toggle)
	_refresh_debug()
	_add_version_label()
	_root.visible = false
	_listen_web_visibility()


## Versão e build em letra pequena no canto inferior direito (T-165), acima da safe area.
func _add_version_label() -> void:
	version_label = ScreenKit.version_label()
	_root.add_child(version_label)
	_place_version_label()


## A safe area muda com a barra do Safari: reposiciona a cada abertura.
func _place_version_label() -> void:
	ScreenKit.place_corner_label(version_label, get_viewport())


func bind(arena: Node) -> void:
	if arena.has_signal(&"match_ended"):
		arena.match_ended.connect(_on_match_ended, CONNECT_ONE_SHOT)


func _on_match_ended(_result) -> void:
	enabled = false
	close()


func is_open() -> bool:
	return _root.visible


func open() -> void:
	if not enabled or is_open():
		return
	get_tree().paused = true
	_root.visible = true
	_refresh_debug()
	_place_version_label()
	ScreenKit.fade_in(_root)


## O "Debug" só aparece com `?debug` na URL (web); fora da web, sempre (BRF-103).
func _apply_debug_visibility() -> void:
	debug_toggle.visible = DebugSettings.debug_ui_available()


func close() -> void:
	if not is_open():
		return
	_root.visible = false
	get_tree().paused = false
	resumed.emit()


func _on_restart() -> void:
	_root.visible = false
	get_tree().paused = false
	restart_requested.emit()


func _on_menu() -> void:
	_root.visible = false
	get_tree().paused = false
	menu_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if is_open():
			close()
		else:
			open()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		open()


## Na web, trocar de aba nem sempre gera FOCUS_OUT; o visibilitychange cobre esse caso.
func _listen_web_visibility() -> void:
	if not OS.has_feature("web"):
		return
	_js_visibility_cb = JavaScriptBridge.create_callback(_on_web_visibility)
	var document := JavaScriptBridge.get_interface("document")
	document.addEventListener("visibilitychange", _js_visibility_cb)


func _on_web_visibility(_args: Array) -> void:
	if JavaScriptBridge.eval("document.hidden", true):
		open()


func _on_debug_toggled() -> void:
	DebugSettings.toggle_overlay()
	_refresh_debug()


func _on_reduced_toggled() -> void:
	var on := not DebugSettings.reduced_effects()
	DebugSettings.set_reduced_effects(on)
	_refresh_debug()
	reduced_effects_changed.emit(on)


func _toggle_button(node_name: String, cb: Callable) -> Button:
	var b := _holo_button("", false, cb)
	b.name = node_name
	b.custom_minimum_size = DEBUG_BUTTON_SIZE
	b.add_theme_font_size_override("font_size", 20)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxTexture = (b.get_theme_stylebox(state) as StyleBoxTexture).duplicate()
		sb.content_margin_left = 4.0
		sb.content_margin_right = 4.0
		b.add_theme_stylebox_override(state, sb)
	return b


static func _outline(l: Control) -> void:
	l.add_theme_color_override("font_outline_color", UiTokens.HOLO_BG)
	l.add_theme_constant_override("outline_size", UiTokens.HOLO_OUTLINE)


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


## Painel holográfico centralizado (520 px, nunca mais largo que a tela) com uma coluna dentro.
static func _holo_card(parent: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "HoloPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _tex_box(T_PANEL, 48, Vector2(UiTokens.SPACE_M, UiTokens.SPACE_M)))
	center.add_child(panel)
	var fit := func() -> void:
		panel.custom_minimum_size.x = clampf(center.size.x - 2 * UiTokens.MARGIN_SCREEN, 0.0, ScreenKit.CARD_WIDTH)
	center.resized.connect(fit)
	fit.call()
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UiTokens.SPACE_M)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)
	return col


## Primário (Continuar): ciano com brilho; secundário: moldura ciano. Texto com contorno `HOLO_BG`.
static func _holo_button(text: String, primary: bool, cb: Callable) -> Button:
	var b := ScreenKit.button(text, primary, cb)
	var normal: StyleBoxTexture
	var down: StyleBoxTexture
	if primary:
		b.custom_minimum_size = Vector2(360, 112)
		normal = _tex_box(T_PRIMARY, 48, Vector2.ZERO, 16)
		normal.texture_margin_top = 56
		normal.texture_margin_bottom = 56
		down = normal.duplicate()
		down.texture = T_PRIMARY_DOWN
		down.content_margin_top = 6
	else:
		normal = _tex_box(T_SECONDARY, 24)
		down = _tex_box(T_SECONDARY_DOWN, 24)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_stylebox_override("disabled", normal)
	var ink := Color("#03202E") if primary else UiTokens.HOLO_TEXT
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(k, ink)
	if primary:
		b.add_theme_constant_override("outline_size", 0)
		b.add_theme_font_size_override("font_size", 34)
	else:
		_outline(b)
		b.add_theme_font_size_override("font_size", UiTokens.FONT_HUD)
	return b


func _refresh_debug() -> void:
	_apply_debug_visibility()
	debug_toggle.text = "Debug: %s" % ("ligado" if DebugSettings.overlay_enabled() else "desligado")
	reduced_toggle.text = "Efeitos reduzidos: %s" % ("sim" if DebugSettings.reduced_effects() else "não")
