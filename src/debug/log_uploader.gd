class_name LogUploader
extends Node
## Envio do log de teste ao desenvolvedor (T-269; contrato em docs/logs-api.md, decisão 58).
## Nunca trava nem lança erro por falha de rede: o resultado vira o estado FAILED (pode tentar de novo).
## Depois de SENT não envia de novo. Contrato: `send(result, log_doc)`; sinal `state_changed(state)`.

signal state_changed(state: int)

enum State { IDLE, SENDING, SENT, FAILED }

## Desliga o botão e o envio no build final.
const ENABLED := true
## Chave de cliente (não é segredo; só barra robô). O AG05 lê de LOG_CLIENT_KEY; o AG10 alinha o valor.
const CLIENT_KEY := "anima-teste"
## Site de teste usado em PC/editor (na web vai para a mesma origem).
const SITE_URL := "https://projectanimagame.netlify.app"
## Motivo da última falha (para diagnóstico; vazio se não falhou).
var last_error := ""

const ENDPOINT := "/api/log"
const TIMEOUT_S := 8.0
const MAX_BYTES := 200 * 1024

## Textos concentrados (trocar por chaves de tradução quando a infra T-240 existir).
const TXT_SEND := "Enviar log"
const TXT_SENDING := "Enviando…"
const TXT_SENT := "Enviado ✔"
const TXT_FAILED := "Falhou. Tentar de novo"
const TXT_NOTICE := "Envia dados da partida (versão, aparelho e log) ao desenvolvedor."

var state: int = State.IDLE
var _http: HTTPRequest


## Corpo JSON do contrato. `res` pode ser null; `doc` é o log do MatchRecorder (pode ser vazio).
static func build_payload(res: MatchResult, doc: Dictionary, user_agent: String = "") -> Dictionary:
	var outcome = null
	var wave := 0
	var dur := 0.0
	if res != null:
		outcome = "victory" if res.outcome == MatchResult.Outcome.VICTORY else "defeat"
		wave = res.wave_reached
		dur = res.duration_s
	var b := BuildInfo.current()
	var text := "" if doc.is_empty() else LogReport.to_text(doc)
	return {
		"version": BuildInfo.version(),
		"build": BuildInfo.label(b),
		"platform": "web" if OS.has_feature("web") else OS.get_name().to_lower(),
		"user_agent": user_agent,
		"result": outcome,
		"wave": wave,
		"duration_s": dur,
		"log": text.left(MAX_BYTES - 2048),
	}


static func user_agent() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("navigator.userAgent", true))
	return "godot/%s %s" % [Engine.get_version_info().get("string", ""), OS.get_name()]


static func url() -> String:
	return ENDPOINT if OS.has_feature("web") else SITE_URL + ENDPOINT


## Mapeia a resposta HTTP para o estado final (201 = ok).
static func state_for(result: int, code: int) -> int:
	return State.SENT if result == HTTPRequest.RESULT_SUCCESS and code == 201 else State.FAILED


func send(res: MatchResult, doc: Dictionary) -> void:
	if not ENABLED or state == State.SENDING or state == State.SENT:
		return
	var body := JSON.stringify(build_payload(res, doc, user_agent()))
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_S
	add_child(_http)
	_http.request_completed.connect(_on_completed)
	last_error = ""
	var err := _http.request(url(), ["Content-Type: application/json", "X-Anima-Key: " + CLIENT_KEY],
		HTTPClient.METHOD_POST, body)
	if err != OK:
		last_error = "request erro %d" % err
		_set_state(State.FAILED)
		return
	_set_state(State.SENDING)


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	last_error = "" if state_for(result, code) == State.SENT else "rede %d, HTTP %d %s" % [result, code, body.get_string_from_utf8().left(80)]
	_set_state(state_for(result, code))
	if is_instance_valid(_http):
		_http.queue_free()
		_http = null


func _set_state(s: int) -> void:
	state = s
	state_changed.emit(s)
