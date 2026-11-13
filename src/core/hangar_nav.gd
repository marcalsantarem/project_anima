class_name HangarNav
extends RefCounted
## Navegação do hangar (T-200, BRF-144): ids dos 5 destinos, mapa id → cena e histórico para "voltar".
## Lógica pura (sem cena): o `SceneFlow` usa e o `HangarHost` mostra. API pública em `docs/arquitetura.md`.

const PLAY := &"play"
const CORES := &"cores"
const MODULES := &"modules"
const COMPONENTS := &"components"
const SETTINGS := &"settings"
## Lista dos destinos válidos. A ordem visual da barra é `HangarBarLogic.ORDER` (src/ui/hangar/hangar_bar_logic.gd).
const TABS: Array[StringName] = [PLAY, CORES, MODULES, COMPONENTS, SETTINGS]
## Chaves de tradução dos títulos (docs/arquitetura.md, "Localização"); `title_of` devolve o texto.
const TITLES := {
	PLAY: "HANGAR_TAB_PLAY", CORES: "HANGAR_TAB_CORES", MODULES: "HANGAR_TAB_MODULES",
	COMPONENTS: "HANGAR_TAB_COMPONENTS", SETTINGS: "HANGAR_TITLE_SETTINGS",
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
	return Loc.t(TITLES[id]) if TITLES.has(id) else ""


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
