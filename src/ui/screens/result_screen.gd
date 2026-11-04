class_name ResultScreen
extends Control
## Resultado da partida (docs/ui.md §8).
## Contrato: show_result(result: MatchResult) (antes ou depois de entrar na árvore); sinais
## `play_again_requested` ("Jogar de novo") e `title_requested` ("Voltar ao título", T-155).

signal play_again_requested
signal title_requested

var _result: MatchResult
var _title: Label
var _stats: Label
var _particles_label: Label
var _stats_tail: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self)
	var col := ScreenKit.card(root, UiTokens.SPACE_L)
	_title = ScreenKit.label("", &"LabelDisplay")
	col.add_child(_title)
	_stats = ScreenKit.label("", &"LabelHud")
	col.add_child(_stats)
	# Partículas da partida: estrela + texto.
	var particles_row := HBoxContainer.new()
	particles_row.name = "ParticlesRow"
	particles_row.alignment = BoxContainer.ALIGNMENT_CENTER
	particles_row.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	particles_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particles_row.add_child(StarIcon.new(32))
	_particles_label = ScreenKit.label("", &"LabelHud")
	# Dentro de HBox, autowrap dá largura mínima 0 e quebra letra por letra (BRF-039): sem quebra aqui.
	_particles_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	particles_row.add_child(_particles_label)
	col.add_child(particles_row)
	_stats_tail = ScreenKit.label("", &"LabelHud")
	col.add_child(_stats_tail)
	var play := ScreenKit.button("Jogar de novo", true, func() -> void: play_again_requested.emit())
	play.name = "PlayAgain"
	col.add_child(play)
	var back := ScreenKit.button("Voltar ao título", false, func() -> void: title_requested.emit())
	back.name = "BackToTitle"
	col.add_child(back)
	# Teclado: foco inicial no principal; setas/Tab levam ao secundário e a action de aceitar confirma.
	play.focus_neighbor_bottom = play.get_path_to(back)
	back.focus_neighbor_top = back.get_path_to(play)
	play.call_deferred(&"grab_focus")
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
		_particles_label.text = ""
		_stats_tail.text = ""
		return
	var won := _result.outcome == MatchResult.Outcome.VICTORY
	_title.text = "Vitória" if won else "Derrota"
	_title.add_theme_color_override("font_color", UiTokens.GOLD if won else UiTokens.DANGER)
	_stats.text = "Onda %d/%d" % [_result.wave_reached, _result.waves_total]
	_particles_label.text = "Partículas: %s" % UiTokens.format_int(_result.particles)
	_stats_tail.text = "Inimigos: %d\nTempo: %s" % [
		_result.enemies_killed, ScreenKit.format_time(_result.duration_s)]
