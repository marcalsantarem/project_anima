class_name TapScreen
extends Control
## Base das telas placeholder que avançam com um toque, clique ou `ui_accept`.
## Na web, esse primeiro gesto também destrava o áudio.

var _tapped := false


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed
	if pressed:
		_tap()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_tap()


func _tap() -> void:
	if _tapped:
		return
	_tapped = true
	_on_tap()


func _on_tap() -> void:
	pass
