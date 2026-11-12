class_name HangarNav
extends RefCounted
## Navegação do hangar (T-200, BRF-144): ids dos 5 destinos, mapa id → cena e histórico para "voltar".
## Lógica pura (sem cena): o `SceneFlow` usa e o `HangarHost` mostra. API pública em `docs/arquitetura.md`.

const PLAY := &"play"
const CORES := &"cores"
const MODULES := &"modules"
const COMPONENTS := &"components"
const SETTINGS := &"settings"
## Ordem dos destinos (a barra do T-201 segue esta ordem).
const TABS: Array[StringName] = [PLAY, CORES, MODULES, COMPONENTS, SETTINGS]
const TITLES := {
	PLAY: "Jogar", CORES: "Núcleos", MODULES: "Módulos", COMPONENTS: "Componentes", SETTINGS: "Configurações",
}
## Cenas previstas. Enquanto não existirem, o `SceneFlow` abre o placeholder "Em breve".
## O `PLAY` é trocado pelo `SceneFlow.menu_scene_path`.
const DEFAULT_PATHS := {
	PLAY: "res://src/ui/screens/menu_screen.tscn",
	CORES: "res://src/ui/screens/cores_screen.tscn",
	MODULES: "res://src/ui/screens/modules_screen.tscn",
	COMPONENTS: "res://src/ui/screens/components_screen.tscn",
	SETTINGS: "res://src/ui/screens/settings_screen.tscn",
}
## Limite do histórico (sem duplicatas, então nunca passa de 4 na prática).
const HISTORY_MAX := 8

var paths: Dictionary = DEFAULT_PATHS.duplicate()
var current: StringName = PLAY
## Destinos anteriores (o último é o mais recente). Sem duplicatas e sem o `current`.
var history: Array[StringName] = []


static func is_valid(id: StringName) -> bool:
	return id in TABS


static func title_of(id: StringName) -> String:
	return TITLES.get(id, "")


func scene_path(id: StringName) -> String:
	return paths.get(id, "")


## Volta ao início (Jogar, sem histórico). Usado ao entrar no hangar.
func reset() -> void:
	current = PLAY
	history.clear()


## Vai para `id`. Retorna `true` se mudou. Jogar é a base: abrir Jogar limpa o histórico.
func open(id: StringName) -> bool:
	if not is_valid(id) or id == current:
		return false
	if id == PLAY:
		history.clear()
	else:
		history.erase(current)
		history.erase(id)
		history.append(current)
		if history.size() > HISTORY_MAX:
			history.pop_front()
	current = id
	return true


## Volta ao destino anterior (ou a Jogar se não houver). Retorna `false` se já está em Jogar sem histórico.
func back() -> bool:
	if history.is_empty():
		if current == PLAY:
			return false
		current = PLAY
		return true
	current = history.pop_back()
	return true
