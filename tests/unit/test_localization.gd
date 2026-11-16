extends GutTest
## T-240 (BRF-147): chaves de tradução. Falha com chave usada que não existe no CSV, chave órfã (no CSV e
## sem uso em `src/`), tradução não registrada no project.godot e texto fixo nas cenas de `src/ui/`.

const CSV_PATH := "res://data/i18n/strings.csv"
const SRC_DIR := "res://src"
const KEY_FORMAT := r"^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$"
## Literal com cara de chave (MAIÚSCULAS_COM_SUBLINHADO) e chamada explícita `Loc.t("...")`.
const LITERAL_RE := r"(?<![&^\w])\"([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)\""
const CALL_RE := r"Loc\.t\(\s*\"([^\"]*)\""

var _table := {}


func before_all() -> void:
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(f, "CSV de traduções")
	if f == null:
		return
	var header := f.get_csv_line()
	assert_eq(Array(header), ["keys", "pt_BR"], "cabeçalho do CSV")
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		assert_false(_table.has(row[0]), "chave duplicada %s" % row[0])
		_table[row[0]] = row[1]


func _gd_files(dir: String, out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_gd_files(dir.path_join(sub), out)
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))


func _code_without_comments(path: String) -> String:
	var lines := PackedStringArray()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var t := line.strip_edges()
		if t.begins_with("#"):
			continue
		lines.append(line.split("##")[0])
	return "\n".join(lines)


func _prefixes() -> Dictionary:
	var p := {}
	for k: String in _table:
		p[k.get_slice("_", 0) + "_"] = true
	return p


func test_keys_are_well_formed() -> void:
	assert_gt(_table.size(), 0)
	var re := RegEx.create_from_string(KEY_FORMAT)
	for k: String in _table:
		assert_not_null(re.search(k), "formato da chave %s" % k)
		assert_ne(String(_table[k]), "", "texto vazio em %s" % k)


func test_translation_is_registered_in_pt_br() -> void:
	assert_true(CSV_PATH.get_basename() + ".pt_BR.translation" in Array(
		ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())))
	assert_eq(ProjectSettings.get_setting("internationalization/locale/fallback"), "pt_BR")
	assert_eq(TranslationServer.get_locale(), Loc.DEFAULT_LOCALE)
	for k: String in _table:
		assert_eq(Loc.t(k), _table[k], "tradução de %s" % k)


func test_placeholders_are_replaced() -> void:
	assert_eq(Loc.t("HUD_WAVE", {"current": 2, "total": 5}), "ONDA 2/5")
	assert_eq(Loc.t("COMMON_LOCK_LEVEL", {"level": 8}), "NV 8")


func test_used_keys_exist_and_none_is_orphan() -> void:
	var files: Array[String] = []
	_gd_files(SRC_DIR, files)
	var literal := RegEx.create_from_string(LITERAL_RE)
	var call := RegEx.create_from_string(CALL_RE)
	var prefixes := _prefixes()
	var used := {}
	for tres in DirAccess.get_files_at("res://data/talents"):  # T-203: chaves usadas só pelos dados dos Núcleos
		if tres.ends_with(".tres"):
			for m in literal.search_all(FileAccess.get_file_as_string("res://data/talents/" + tres)):
				used[m.get_string(1)] = true
	for path in files:
		var code := _code_without_comments(path)
		for m in call.search_all(code):
			assert_true(_table.has(m.get_string(1)), "Loc.t com chave inexistente %s em %s" % [m.get_string(1), path])
		for m in literal.search_all(code):
			var k := m.get_string(1)
			used[k] = true
			if prefixes.has(k.get_slice("_", 0) + "_"):
				assert_true(_table.has(k), "chave inexistente %s em %s" % [k, path])
	for k: String in _table:
		assert_true(used.has(k), "chave órfã %s" % k)


func test_ui_scenes_have_no_fixed_text() -> void:
	var re := RegEx.create_from_string(r"(?m)^text = \"([^\"]*[A-Za-zÀ-ú][^\"]*)\"")
	var stack: Array[String] = ["res://src/ui"]
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			if sub != "demo":
				stack.append(dir.path_join(sub))
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".tscn"):
				var m := re.search(FileAccess.get_file_as_string(dir.path_join(file)))
				assert_null(m, "texto fixo em %s" % dir.path_join(file))
