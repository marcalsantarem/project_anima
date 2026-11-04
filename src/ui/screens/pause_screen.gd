class_name PauseScreen
extends CanvasLayer
## Overlay de pausa (docs/ui.md §8). Funciona com o jogo pausado (process_mode ALWAYS).
## Entrada: SÓ a action `pause` (Esc e o botão do HUD, que injeta a action). Não ouve `Hud.pause_requested`.
## Também pausa sozinha ao perder o foco (aba/app); a volta não retoma, o jogador toca em Continuar.
## Contrato: open(), close(), bind(arena) (desliga no match_ended), sinais `resumed` e `restart_requested`.

signal resumed
signal restart_requested

var enabled := true
var _root: Control
var _continue: Button
var _js_visibility_cb: JavaScriptObject


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
	_root.visible = false
	_listen_web_visibility()


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
	ScreenKit.fade_in(_root)


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
