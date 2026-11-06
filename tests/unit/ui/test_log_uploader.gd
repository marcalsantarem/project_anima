extends GutTest
## LogUploader (T-269): payload do contrato e estados (resposta HTTP simulada).

const KEYS := ["version", "build", "platform", "user_agent", "result", "wave", "duration_s", "log"]


func _result(outcome: MatchResult.Outcome) -> MatchResult:
	var r := MatchResult.new()
	r.outcome = outcome
	r.wave_reached = 4
	r.duration_s = 61.5
	return r


func test_payload_has_contract_keys() -> void:
	var p := LogUploader.build_payload(_result(MatchResult.Outcome.VICTORY), {}, "ua")
	for k in KEYS:
		assert_true(p.has(k), k)
	assert_eq(p.result, "victory")
	assert_eq(p.wave, 4)
	assert_eq(p.duration_s, 61.5)
	assert_eq(p.user_agent, "ua")
	assert_eq(p.log, "")


func test_payload_defeat_and_null_result() -> void:
	assert_eq(LogUploader.build_payload(_result(MatchResult.Outcome.DEFEAT), {}).result, "defeat")
	var p := LogUploader.build_payload(null, {})
	assert_null(p.result)
	assert_eq(p.wave, 0)


func test_state_for_response() -> void:
	assert_eq(LogUploader.state_for(HTTPRequest.RESULT_SUCCESS, 201), LogUploader.State.SENT)
	assert_eq(LogUploader.state_for(HTTPRequest.RESULT_SUCCESS, 429), LogUploader.State.FAILED)
	assert_eq(LogUploader.state_for(HTTPRequest.RESULT_CANT_CONNECT, 0), LogUploader.State.FAILED)


func test_completed_sets_state_and_signals() -> void:
	var u: LogUploader = add_child_autofree(LogUploader.new())
	watch_signals(u)
	u._on_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	assert_eq(u.state, LogUploader.State.FAILED)
	u._on_completed(HTTPRequest.RESULT_SUCCESS, 201, PackedStringArray(), PackedByteArray())
	assert_eq(u.state, LogUploader.State.SENT)
	assert_signal_emit_count(u, "state_changed", 2)


func test_no_resend_after_sent() -> void:
	var u: LogUploader = add_child_autofree(LogUploader.new())
	u.state = LogUploader.State.SENT
	watch_signals(u)
	u.send(null, {})
	assert_signal_not_emitted(u, "state_changed")
	assert_eq(u.get_child_count(), 0)


func test_button_states_in_result_screen() -> void:
	var s: ResultScreen = add_child_autofree(ResultScreen.new())
	await get_tree().process_frame
	var b: Button = s.find_child("SendLog", true, false)
	assert_not_null(b)
	s._on_upload_state(LogUploader.State.SENDING)
	assert_true(b.disabled)
	s._on_upload_state(LogUploader.State.FAILED)
	assert_false(b.disabled)
	assert_eq(b.text, LogUploader.TXT_FAILED)
	s._on_upload_state(LogUploader.State.SENT)
	assert_true(b.disabled)
	assert_eq(b.text, LogUploader.TXT_SENT)


func test_state_for_status_matrix() -> void:
	for code in [400, 401, 413, 429, 500, 200]:
		assert_eq(LogUploader.state_for(HTTPRequest.RESULT_SUCCESS, code), LogUploader.State.FAILED, str(code))
	assert_eq(LogUploader.state_for(HTTPRequest.RESULT_TIMEOUT, 0), LogUploader.State.FAILED)
	assert_eq(LogUploader.state_for(HTTPRequest.RESULT_SUCCESS, 201), LogUploader.State.SENT)


func test_timeout_is_8s_and_failure_keeps_reason() -> void:
	assert_eq(LogUploader.TIMEOUT_S, 8.0)
	var u: LogUploader = add_child_autofree(LogUploader.new())
	u._on_completed(HTTPRequest.RESULT_TIMEOUT, 0, PackedStringArray(), PackedByteArray())
	assert_eq(u.state, LogUploader.State.FAILED)
	assert_ne(u.last_error, "")
	u._on_completed(HTTPRequest.RESULT_SUCCESS, 429, PackedStringArray(), "limite".to_utf8_buffer())
	assert_eq(u.state, LogUploader.State.FAILED)
	assert_true(u.last_error.contains("429"))


func test_no_resend_while_sending() -> void:
	var u: LogUploader = add_child_autofree(LogUploader.new())
	u.state = LogUploader.State.SENDING
	watch_signals(u)
	u.send(null, {})
	assert_signal_not_emitted(u, "state_changed")


func test_payload_log_capped() -> void:
	var p := LogUploader.build_payload(null, {})
	assert_lte(str(p.log).length(), LogUploader.MAX_BYTES - 2048)


func test_failure_keeps_result_screen_usable() -> void:
	var s: ResultScreen = add_child_autofree(ResultScreen.new())
	await get_tree().process_frame
	var b: Button = s.find_child("SendLog", true, false)
	s._uploader._on_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	assert_eq(b.text, LogUploader.TXT_FAILED)
	assert_false(b.disabled)
	for n in ["Logs"]:
		assert_false((s.find_child(n, true, false) as Button).disabled)
	# nova tentativa permitida após falha
	assert_ne(s._uploader.state, LogUploader.State.SENT)
