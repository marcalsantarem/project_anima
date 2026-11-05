extends GutTest
## Versão e build (T-165): parse do window.ANIMA_BUILD, com e sem dados.


func test_parse_with_data() -> void:
	var b := BuildInfo.parse({"sha": "abc1234", "sha_full": "abc1234def5678", "branch": "dev",
		"built_at": "2026-11-04T22:00:00Z", "run": 42.0})
	assert_false(b.local)
	assert_eq(b.sha, "abc1234")
	assert_eq(b.run, "42", "número do JSON sem .0")
	assert_eq(BuildInfo.label(b), "abc1234")
	assert_eq(BuildInfo.summary_line(b), "Build: abc1234 (dev) · 2026-11-04T22:00:00Z · exec #42")
	assert_eq(BuildInfo.pause_text(b, "0.1.0-demo"), "v0.1.0-demo · abc1234")


func test_parse_short_sha_from_full() -> void:
	var b := BuildInfo.parse({"sha_full": "abcdef0123456"})
	assert_eq(b.sha, "abcdef0")
	assert_false(b.local)


func test_parse_without_data_is_dev_local() -> void:
	for raw in [null, "", {}, [1], {"branch": "dev"}]:
		var b := BuildInfo.parse(raw)
		assert_true(b.local, "local para %s" % [raw])
		assert_eq(BuildInfo.label(b), "dev local")
		assert_eq(BuildInfo.summary_line(b), "Build: dev local")


func test_version_falls_back_to_constant() -> void:
	if str(ProjectSettings.get_setting("application/config/version", "")).is_empty():
		assert_eq(BuildInfo.version(), BuildInfo.DEFAULT_VERSION)
	else:
		assert_eq(BuildInfo.version(), str(ProjectSettings.get_setting("application/config/version")))


func test_current_off_web_is_local() -> void:
	assert_true(BuildInfo.current().local, "fora da web não há window.ANIMA_BUILD")


func test_report_text_has_build_line() -> void:
	var doc := {"header": {"build": {"sha": "abc1234", "branch": "dev", "built_at": "x", "run": "7"}},
		"summary": {}}
	var text := LogReport.to_text(doc)
	assert_string_contains(text, "Build: abc1234 (dev) · x · exec #7")
	assert_string_contains(LogReport.to_text({"header": {}}), "Build: dev local")


func test_version_label_is_discreet_and_ignores_touch() -> void:
	var l := ScreenKit.version_label()
	assert_eq(l.text, "v%s · dev local" % BuildInfo.version())
	assert_eq(l.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_lt(l.get_theme_color("font_color").a, 0.7)
	l.free()
