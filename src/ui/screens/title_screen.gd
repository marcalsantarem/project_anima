class_name TitleScreen
extends Control
## "Toque para começar" (docs/ui.md §8). É o primeiro gesto do usuário: na web, destrava o áudio.
## Contrato: emite `start_requested` uma vez, no primeiro toque, clique ou tecla.

signal start_requested

const PULSE_TIME := 0.8

var _started := false
var _hint: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self)
	var col := ScreenKit.column(root, UiTokens.SPACE_L)
	col.add_child(ScreenKit.label("Project: Anima", &"LabelTitle"))
	col.add_child(ScreenKit.label("Criado por Marçal Santarem", &"LabelCaption"))
	var gap := Control.new()
	gap.custom_minimum_size.y = UiTokens.SPACE_XL
	gap.mouse_filter = MOUSE_FILTER_IGNORE
	col.add_child(gap)
	_hint = ScreenKit.label("Toque para começar", &"", UiTokens.ACCENT)
	col.add_child(_hint)
	ScreenKit.fade_in(root)

	var pulse := create_tween().set_loops()
	pulse.tween_property(_hint, "modulate:a", 0.35, PULSE_TIME).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_hint, "modulate:a", 1.0, PULSE_TIME).set_trans(Tween.TRANS_SINE)


# _input: o gesto precisa ser tratado no mesmo evento do navegador para destravar o áudio.
func _input(event: InputEvent) -> void:
	if _started or not is_visible_in_tree():
		return
	var is_gesture: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if not is_gesture:
		return
	_started = true
	get_viewport().set_input_as_handled()
	_unlock_audio()
	start_requested.emit()


## O Godot retoma o AudioContext no gesto do usuário. Aqui só garantimos que o bus principal não ficou mudo.
func _unlock_audio() -> void:
	AudioServer.set_bus_mute(0, false)
