extends GutTest
## BRF-058 / T-152: barra "Boss" no topo do HUD (decisão 39).

const HUD_SCENE := preload("res://src/ui/hud/hud.tscn")


class FakeArena extends Node:
	signal boss_spawned(id: StringName)
	signal boss_hp_changed(current: int, max_hp: int)
	signal boss_defeated
	signal match_ended(result)


func _make() -> Array:
	var hud: Hud = HUD_SCENE.instantiate()
	var arena := FakeArena.new()
	hud.bind(arena)
	add_child_autofree(hud)
	add_child_autofree(arena)
	return [hud, arena]


func test_hidden_until_boss_spawns_then_grows_top() -> void:
	var p := _make()
	var hud: Hud = p[0]
	var arena: FakeArena = p[1]
	await wait_process_frames(2)
	var row: Control = hud.get_node("Root/Top").find_child("BossRow", true, false)
	assert_false(row.visible, "oculta sem chefe")
	arena.boss_spawned.emit(&"boss_ogre")
	arena.boss_hp_changed.emit(2500, 2500)
	await wait_process_frames(2)
	assert_true(row.visible)
	var bar: UiBar = row.get_node("BossBar")
	assert_eq(bar.title, "Boss")
	assert_eq(bar.fill_color, UiTokens.BOSS_HP)
	assert_eq(hud.top_inset(), float(Hud.TOP_INSET + Hud.BOSS_BAR_INSET))
	assert_eq(hud.get_node("Root/Top").size.y, float(Hud.TOP_INSET + Hud.BOSS_BAR_INSET))


func test_hides_on_defeat_and_on_match_end() -> void:
	var p := _make()
	var hud: Hud = p[0]
	var arena: FakeArena = p[1]
	await wait_process_frames(1)
	var row: Control = hud.get_node("Root/Top").find_child("BossRow", true, false)
	arena.boss_spawned.emit(&"boss_ogre")
	arena.boss_defeated.emit()
	await wait_seconds(UiTokens.ANIM_UI + 0.1)
	assert_false(row.visible, "some com boss_defeated")
	assert_eq(hud.top_inset(), float(Hud.TOP_INSET))
	arena.boss_hp_changed.emit(100, 2500)
	await wait_process_frames(1)
	assert_true(row.visible, "boss_hp_changed também mostra")
	arena.match_ended.emit(null)
	await wait_seconds(UiTokens.ANIM_UI + 0.1)
	assert_false(row.visible, "some ao fim da partida")
