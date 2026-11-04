class_name LogViewer
extends CanvasLayer
## Visualizador do log da partida (BRF-063 §2; docs/debug.md §5). Sobreposição de tela cheia, rolável
## por toque, com RESUMO, linha do tempo e amostras. Não pausa nem muda o estado da tela de baixo.
## Na web também mostra uma barra de botões NATIVOS do navegador (DOM), porque no iOS Safari download,
## área de transferência e nova aba só são garantidos dentro do gesto real do usuário.
## Contrato: `LogViewer.open(parent, doc)`; sinal `closed` (o nó se libera ao fechar).

signal closed

const LINES_PER_CHUNK := 60
const FONT_SIZE := 17
const BUTTON_SIZE := Vector2(150, 72)
const WEB_BAR_CSS_H := 120.0 ## px CSS reservados para a barra nativa no rodapé (com 2 linhas de botões)
const EXPORT_DIR := "user://logs/export/"
const JS_BAR := """(function(){
if (window.__animaLogBar) return;
var B = window.__animaLogBar = {json: '', txt: '', base: 'anima_log'};
var bar = document.createElement('div');
bar.id = 'anima-log-bar';
bar.style.cssText = 'position:fixed;left:0;right:0;bottom:0;z-index:9999;display:none;flex-wrap:wrap;gap:6px;justify-content:center;align-items:center;padding:8px 8px calc(8px + env(safe-area-inset-bottom));background:#3A2A55;color:#fff;font:600 15px -apple-system,system-ui,sans-serif;touch-action:manipulation;-webkit-user-select:text;user-select:text;';
var st = document.createElement('div');
st.style.cssText = 'flex-basis:100%;text-align:center;font-weight:400;font-size:13px;min-height:16px;';
var ta = document.createElement('textarea');
ta.readOnly = true;
ta.style.cssText = 'display:none;flex-basis:100%;height:35vh;font:12px ui-monospace,Menlo,monospace;-webkit-user-select:text;user-select:text;';
B.status = function(m){ st.textContent = m; };
function blob(kind){ return new Blob([kind === 'json' ? B.json : B.txt], {type: kind === 'json' ? 'application/json' : 'text/plain;charset=utf-8'}); }
function btn(label, fn){ var b = document.createElement('button'); b.textContent = label;
 b.style.cssText = 'min-height:44px;padding:0 12px;border-radius:12px;border:2px solid #2FE6D2;background:#5A4A9A;color:#fff;font:inherit;';
 b.addEventListener('click', function(ev){ ev.preventDefault(); try { fn(); } catch (e) { B.status('Erro: ' + e); } }); bar.appendChild(b); }
B.dl = function(kind){ var a = document.createElement('a'); a.href = URL.createObjectURL(blob(kind)); a.download = B.base + '.' + kind;
 document.body.appendChild(a); a.click(); setTimeout(function(){ URL.revokeObjectURL(a.href); a.remove(); }, 60000);
 B.status('Baixando ' + a.download + ' (iPhone: app Arquivos > Downloads).'); };
B.select = function(){ ta.value = B.txt + '\\n\\n=== JSON ===\\n' + B.json; ta.style.display = 'block'; ta.focus(); ta.setSelectionRange(0, ta.value.length);
 B.status('Texto selecionado: toque e segure > Copiar.'); };
B.copy = function(){ var t = B.txt + '\\n\\n=== JSON ===\\n' + B.json;
 if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(t).then(function(){ B.status('Copiado para a área de transferência.'); }, function(){ B.select(); }); }
 else { B.select(); } };
B.open = function(){ var w = window.open(URL.createObjectURL(blob('txt')), '_blank');
 if (!w) { B.status('O navegador bloqueou a nova aba: use Baixar ou Copiar.'); return false; }
 B.status('Aberto em outra aba.'); return true; };
btn('Baixar .txt', function(){ B.dl('txt'); });
btn('Baixar .json', function(){ B.dl('json'); });
btn('Copiar', B.copy);
btn('Abrir aba', B.open);
btn('Selecionar', B.select);
bar.appendChild(st);
bar.appendChild(ta);
document.body.appendChild(bar);
B.setData = function(json, txt, base){ B.json = json; B.txt = txt; B.base = base; };
B.show = function(){ bar.style.display = 'flex'; ta.style.display = 'none'; B.status('Botões do navegador: funcionam no iPhone.'); };
B.hide = function(){ bar.style.display = 'none'; ta.style.display = 'none'; };
})();"""

var doc: Dictionary = {}
## Texto legível (RESUMO + linha do tempo + amostras).
var text := ""
var json_text := ""
var status_label: Label
var body: VBoxContainer
var _root: Control
var _first_button: Button


static func open(parent: Node, p_doc: Dictionary) -> LogViewer:
	var v := LogViewer.new()
	v.doc = p_doc
	parent.add_child(v)
	return v


func _ready() -> void:
	layer = 40
	process_mode = PROCESS_MODE_ALWAYS
	if not doc.has("summary") and not doc.is_empty():
		doc["summary"] = LogReport.summarize(doc)
	text = LogReport.to_text(doc) if not doc.is_empty() else "Nenhum log disponível."
	json_text = JSON.stringify(doc)
	_build()
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_BAR, true)
		var bar := JavaScriptBridge.get_interface("__animaLogBar")
		bar.setData(json_text, text, LogReport.file_base(doc))
		bar.show()


func _build() -> void:
	_root = ScreenKit.root(self, UiTokens.INK)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var safe := ScreenKit.safe_area(_root.get_viewport())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(safe.left) + UiTokens.SPACE_S)
	margin.add_theme_constant_override("margin_right", int(safe.right) + UiTokens.SPACE_S)
	margin.add_theme_constant_override("margin_top", int(safe.top) + UiTokens.SPACE_S)
	var bottom := int(safe.bottom) + UiTokens.SPACE_S
	if OS.has_feature("web"):
		bottom = int(WEB_BAR_CSS_H * float(safe.css_k)) + UiTokens.SPACE_S
	margin.add_theme_constant_override("margin_bottom", bottom)
	_root.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	margin.add_child(col)

	var title := ScreenKit.label("Logs da partida", &"LabelTitle")
	col.add_child(title)
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", UiTokens.SPACE_XS)
	row.add_theme_constant_override("v_separation", UiTokens.SPACE_XS)
	col.add_child(row)
	_first_button = _button(row, "Baixar", &"Download", download)
	_button(row, "Copiar", &"Copy", copy)
	_button(row, "Abrir em outra aba", &"OpenTab", open_in_tab)
	var close_b := _button(row, "Fechar", &"Close", close)
	close_b.theme_type_variation = &"ButtonPrimary"
	status_label = ScreenKit.label(_initial_status(), &"LabelCaption", UiTokens.TEXT_SECONDARY)
	status_label.name = "Status"
	col.add_child(status_label)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	col.add_child(scroll)
	body = VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 0)
	scroll.add_child(body)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "Courier New", "monospace"])
	var lines := text.split("\n")
	for i in range(0, lines.size(), LINES_PER_CHUNK):
		var l := Label.new()
		l.text = "\n".join(lines.slice(i, i + LINES_PER_CHUNK))
		l.add_theme_font_override("font", font)
		l.add_theme_font_size_override("font_size", FONT_SIZE)
		l.add_theme_color_override("font_color", UiTokens.TEXT_PRIMARY)
		l.add_theme_constant_override("outline_size", 0)
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		body.add_child(l)
	_first_button.call_deferred(&"grab_focus")


func _button(parent: Control, label: String, node_name: StringName, cb: Callable) -> Button:
	var b := ScreenKit.button(label, false, cb)
	b.name = node_name
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", UiTokens.FONT_CAPTION)
	parent.add_child(b)
	return b


func _initial_status() -> String:
	if OS.has_feature("web"):
		return "Se um botão daqui falhar no iPhone, use os botões do navegador no rodapé."
	return "Fora da web: Baixar grava em %s" % ProjectSettings.globalize_path(EXPORT_DIR)


func set_status(msg: String) -> void:
	status_label.text = msg


## Baixa `.json` e `.txt` (web) ou grava os dois em user://logs/export/ (PC/editor).
func download() -> void:
	var base := LogReport.file_base(doc)
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(json_text.to_utf8_buffer(), base + ".json", "application/json")
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), base + ".txt", "text/plain")
		set_status("Download pedido (%s.json e .txt). iPhone: app Arquivos > Downloads." % base)
		return
	var paths := save_files()
	set_status("Gravado em:\n%s\n%s" % paths)


## Grava `.json` e `.txt` em EXPORT_DIR; devolve os caminhos absolutos.
func save_files() -> Array:
	var base := LogReport.file_base(doc)
	DirAccess.make_dir_recursive_absolute(EXPORT_DIR)
	var out := []
	for pair in [[".json", json_text], [".txt", text]]:
		var path := EXPORT_DIR.path_join(base + pair[0])
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(pair[1])
			f.close()
		out.append(ProjectSettings.globalize_path(path))
	return out


func copy() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("__animaLogBar").copy()
		set_status("Copiando… se não der, toque em Copiar ou Selecionar no rodapé.")
		return
	DisplayServer.clipboard_set(text + "\n\n=== JSON ===\n" + json_text)
	set_status("Copiado para a área de transferência.")


func open_in_tab() -> void:
	if OS.has_feature("web"):
		var ok = JavaScriptBridge.get_interface("__animaLogBar").open()
		set_status("Aberto em outra aba." if ok else "O navegador bloqueou a nova aba: use Abrir aba no rodapé, Baixar ou Copiar.")
		return
	var paths := save_files()
	OS.shell_open(paths[1])
	set_status("Aberto: %s" % paths[1])


func close() -> void:
	if OS.has_feature("web"):
		var bar := JavaScriptBridge.get_interface("__animaLogBar")
		if bar != null:
			bar.hide()
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
