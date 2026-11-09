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

const DEBUG_BUTTON_SIZE := Vector2(228, 64)

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
	_root = ScreenKit.root(self, UiTokens.BG_DIM)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := ScreenKit.card(_root)
	col.add_child(ScreenKit.label("Pausado", &"LabelTitle"))
	_continue = ScreenKit.button("Continuar", true, close)
	col.add_child(_continue)
	col.add_child(ScreenKit.button("Recomeçar", false, _on_restart))
	menu_button = ScreenKit.button("Voltar ao menu", false, _on_menu)
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
	var b := ScreenKit.button("", false, cb)
	b.name = node_name
	b.custom_minimum_size = DEBUG_BUTTON_SIZE
	b.add_theme_font_size_override("font_size", UiTokens.FONT_CAPTION)
	return b


func _refresh_debug() -> void:
	_apply_debug_visibility()
	debug_toggle.text = "Debug: %s" % ("ligado" if DebugSettings.overlay_enabled() else "desligado")
	reduced_toggle.text = "Efeitos reduzidos: %s" % ("sim" if DebugSettings.reduced_effects() else "não")
