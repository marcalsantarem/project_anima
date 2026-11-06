class_name ResultScreen
extends Control
## Resultado da partida (docs/ui.md §8).
## Contrato: show_result(result: MatchResult) (antes ou depois de entrar na árvore); sinais
## `play_again_requested` ("Jogar de novo") e `title_requested` ("Voltar ao título", T-155).
## Botão secundário "Logs" (BRF-063): abre o LogViewer com `set_log(doc)` (ou o último log salvo).

signal play_again_requested
signal title_requested

## Botão "Logs": secundário e menor que os dois principais (alvo ≥ 44 px, BRF-063).
const LOGS_BUTTON_SIZE := Vector2(200, 64)

var _result: MatchResult
var _title: Label
var _stats: Label
var _particles_label: Label
var _stats_tail: Label
var _log: Dictionary = {}
var _logs_button: Button
## Visualizador aberto, ou null.
var viewer: LogViewer
var _uploader: LogUploader
var _send_button: Button
var _notice: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var root := ScreenKit.root(self)
	ScreenKit.set_page_color(UiTokens.BG_VOID)
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
	var small_row := HBoxContainer.new()
	small_row.name = "SmallRow"
	small_row.alignment = BoxContainer.ALIGNMENT_CENTER
	small_row.add_theme_constant_override("separation", UiTokens.SPACE_S)
	col.add_child(small_row)
	_logs_button = ScreenKit.button("Logs", false, open_logs)
	_logs_button.name = "Logs"
	_logs_button.custom_minimum_size = LOGS_BUTTON_SIZE
	_logs_button.add_theme_font_size_override("font_size", UiTokens.FONT_CAPTION)
	small_row.add_child(_logs_button)
	if LogUploader.ENABLED:
		_uploader = LogUploader.new()
		add_child(_uploader)
		_uploader.state_changed.connect(_on_upload_state)
		_send_button = ScreenKit.button(LogUploader.TXT_SEND, false, send_log)
		_send_button.name = "SendLog"
		_send_button.custom_minimum_size = LOGS_BUTTON_SIZE
		_send_button.add_theme_font_size_override("font_size", UiTokens.FONT_CAPTION)
		small_row.add_child(_send_button)
		_notice = ScreenKit.label(LogUploader.TXT_NOTICE, &"LabelCaption")
		_notice.name = "SendNotice"
		col.add_child(_notice)
		_logs_button.focus_neighbor_right = _logs_button.get_path_to(_send_button)
		_send_button.focus_neighbor_left = _send_button.get_path_to(_logs_button)
		_send_button.focus_neighbor_top = _send_button.get_path_to(back)
	back.focus_neighbor_top = back.get_path_to(play)
	back.focus_neighbor_bottom = back.get_path_to(_logs_button)
	_logs_button.focus_neighbor_top = _logs_button.get_path_to(back)
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


## Log da partida (MatchRecorder) para o botão "Logs".
func set_log(doc: Dictionary) -> void:
	_log = doc


## Botão "Enviar log" (T-269): envia o resultado e o log; sem reenvio depois de enviado.
func send_log() -> void:
	if _uploader == null:
		return
	var doc := _log if not _log.is_empty() else MatchRecorder.load_last()
	_uploader.send(_result, doc)


func _on_upload_state(s: int) -> void:
	if _send_button == null:
		return
	match s:
		LogUploader.State.SENDING:
			_send_button.text = LogUploader.TXT_SENDING
			_send_button.disabled = true
		LogUploader.State.SENT:
			_send_button.text = LogUploader.TXT_SENT
			_send_button.disabled = true
		LogUploader.State.FAILED:
			_send_button.text = LogUploader.TXT_FAILED
			_send_button.disabled = false
		_:
			_send_button.text = LogUploader.TXT_SEND
			_send_button.disabled = false


## Abre o visualizador por cima (não pausa nem mexe nos botões; ao fechar, o foco volta ao "Logs").
func open_logs() -> void:
	if viewer != null and is_instance_valid(viewer):
		return
	var doc := _log if not _log.is_empty() else MatchRecorder.load_last()
	viewer = LogViewer.open(self, doc)
	viewer.closed.connect(func() -> void:
		viewer = null
		if is_instance_valid(_logs_button):
			_logs_button.grab_focus())
