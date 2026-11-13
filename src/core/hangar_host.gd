class_name HangarHost
extends Control
## Nó raiz do hangar (T-200, BRF-144), montado pelo `SceneFlow`. Guarda as telas filhas já visitadas
## em `content` (cache): só a atual fica visível e processando; as outras ficam ocultas e desligadas.
## Cada tela é carregada só na 1ª visita. O cache some quando o hangar sai da árvore (ida à partida).

const CONTENT_NODE_NAME := &"Content"

## Onde as telas filhas ficam. A barra do T-201 pode ajustar `offset_bottom` para não cobri-las.
var content: Control
var _screens: Dictionary = {}  # StringName -> Control


func _init() -> void:
	name = &"Hangar"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	content = Control.new()
	content.name = CONTENT_NODE_NAME
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)


func has_screen(id: StringName) -> bool:
	return _screens.has(id) and is_instance_valid(_screens[id])


## Tela em cache do destino, ou `null` se ainda não foi visitada.
func screen(id: StringName) -> Control:
	return _screens[id] if has_screen(id) else null


func cached_count() -> int:
	return _screens.size()


## Mostra `id`. Na 1ª visita chama `factory.call() -> Control` e guarda a instância.
## Retorna a tela mostrada.
func show_screen(id: StringName, factory: Callable) -> Control:
	var node := screen(id)
	if node == null:
		node = factory.call()
		_screens[id] = node
		content.add_child(node)
	for key: StringName in _screens:
		var s: Control = _screens[key]
		var on := key == id
		s.visible = on
		s.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	return node
