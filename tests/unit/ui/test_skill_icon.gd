extends GutTest
## BRF-050: ícone do slot 1 = meteoro (decisão 37); o padrão do botão também é o meteoro.

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")


func _hud(paths: Array[String] = []) -> Hud:
	var hud: Hud = HUD_SCENE.instantiate()
	if not paths.is_empty():
		hud.slot_icon_paths = paths
	add_child_autofree(hud)
	return hud


func test_slot1_uses_meteor_icon() -> void:
	var hud := _hud()
	var tex := hud._skill(1)._icon_texture()
	assert_not_null(tex)
	assert_eq(tex.resource_path, UiArt.SKILL_METEOR_PATH)


func test_missing_path_falls_back_to_meteor() -> void:
	var hud := _hud(["res://assets/ui/nao_existe.png", "", ""])
	assert_eq(hud._skill(1)._icon_texture().resource_path, UiArt.SKILL_METEOR_PATH)


func test_set_slot_icon_and_reset() -> void:
	var hud := _hud()
	var tex := PlaceholderTexture2D.new()
	hud.set_slot_icon(1, tex)
	assert_eq(hud._skill(1)._icon_texture(), tex)
	hud.set_slot_icon(1, null)
	assert_eq(hud._skill(1)._icon_texture().resource_path, UiArt.SKILL_METEOR_PATH)


func test_skill_data_icon_is_the_same_png() -> void:
	# Contrato com o AG01: SkillData.icon do meteoro aponta para o mesmo PNG do HUD.
	var data: Resource = load("res://data/skills/skill_meteor.tres")
	assert_eq(data.get("icon").resource_path, UiArt.SKILL_METEOR_PATH)
