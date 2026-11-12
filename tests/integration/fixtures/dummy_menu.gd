extends Control
## Menu dummy dos testes do SceneFlow (contrato da T-190: `setup(view)` e `play_pressed`).

signal play_pressed

var view: Dictionary = {}


func setup(v: Dictionary) -> void:
	view = v
