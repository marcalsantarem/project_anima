class_name ResultScreen
extends Control
## Resultado da partida (docs/ui.md §8).
## Contrato: show_result(result: MatchResult) (antes ou depois de entrar na árvore); sinal `play_again_requested`.

signal play_again_requested

var _result: MatchResult
var _title: Label
var _stats: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self)
	var col := ScreenKit.card(root, UiTokens.SPACE_L)
	_title = ScreenKit.label("", &"LabelDisplay")
	col.add_child(_title)
	_stats = ScreenKit.label("", &"LabelHud")
	col.add_child(_stats)
	col.add_child(ScreenKit.button("Jogar de novo", true, func() -> void: play_again_requested.emit()))
	ScreenKit.fade_in(root)
	_refresh()


func show_result(result: MatchResult) -> void:
	_result = result
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _result == null:
		_title.text = "—"
		_stats.text = ""
		return
	var won := _result.outcome == MatchResult.Outcome.VICTORY
	_title.text = "Vitória" if won else "Derrota"
	_title.add_theme_color_override("font_color", UiTokens.COIN if won else UiTokens.DANGER)
	_stats.text = "Onda %d/%d\nMoedas: %s\nInimigos: %d\nTempo: %s" % [
		_result.wave_reached, _result.waves_total, UiTokens.format_int(_result.coins),
		_result.enemies_killed, ScreenKit.format_time(_result.duration_s)]
