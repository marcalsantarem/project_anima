extends GutTest
## T-203: integridade dos dados da árvore de Núcleos (sem lógica de compra).

const TREE := "res://data/talents/talent_tree.tres"
const CSV_PATH := "res://data/i18n/strings.csv"


func _tree() -> TalentTree:
	return load(TREE) as TalentTree


func test_tree_loads_and_is_valid() -> void:
	var t := _tree()
	assert_not_null(t)
	assert_between(t.talents.size(), 10, 12)
	assert_eq(t.validate(), PackedStringArray())


func test_ids_unique_and_prereqs_exist() -> void:
	var t := _tree()
	var seen := {}
	for d in t.talents:
		assert_false(seen.has(d.id), "id duplicado %s" % d.id)
		seen[d.id] = true
		for p in d.prereq_ids:
			assert_not_null(t.get_talent(p), "%s: pré-requisito %s" % [d.id, p])


func test_costs_positive_and_total() -> void:
	var t := _tree()
	for d in t.talents:
		assert_gt(d.max_level(), 0)
		for c in d.costs:
			assert_gt(c, 0, d.id)
	assert_eq(t.total_cost(), 18355)


func test_roots_are_cheap() -> void:
	var t := _tree()
	for d in t.talents:
		if d.prereq_ids.is_empty():
			assert_lte(d.costs[0], 60, "raiz %s deve ser barata (1ª ou 2ª partida)" % d.id)


func test_text_keys_exist_in_csv() -> void:
	var keys := {}
	var f := FileAccess.open(CSV_PATH, FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 2 and row[0] != "":
			keys[row[0]] = true
	var t := _tree()
	for d in t.talents:
		assert_true(keys.has(d.name_key), d.name_key)
		assert_true(keys.has(d.desc_key), d.desc_key)
	for k in t.branch_name_keys.values():
		assert_true(keys.has(k), k)


func test_validate_detects_cycle_and_missing() -> void:
	var a := TalentData.new()
	a.id = &"talent_a"
	a.branch = &"x"
	a.name_key = "A"
	a.desc_key = "B"
	a.costs = PackedInt32Array([10])
	a.values = PackedFloat32Array([1.0])
	var b := a.duplicate() as TalentData
	b.id = &"talent_b"
	b.grid_pos = Vector2i(1, 0)
	a.prereq_ids = [&"talent_b"]
	a.prereq_levels = PackedInt32Array([1])
	b.prereq_ids = [&"talent_a"]
	b.prereq_levels = PackedInt32Array([1])
	var tree := TalentTree.new()
	tree.branch_name_keys = {"x": "K"}
	tree.talents = [a, b]
	assert_string_contains(" ".join(tree.validate()), "ciclo")
	a.prereq_ids = [&"talent_zzz"]
	assert_string_contains(" ".join(tree.validate()), "não existe")
