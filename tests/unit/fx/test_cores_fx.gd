extends GutTest
## T-208 (BRF-156): efeitos de UI dos Núcleos rodam, encerram (<= 0,6 s), liberam os nós temporários
## e, no modo reduzido, não criam partículas.

const ORANGE := Color("#FF9F43")

var root: Control


func before_each() -> void:
	CoresFx.reduced_effects = false
	root = Control.new()
	root.size = Vector2(720, 720)
	add_child_autofree(root)


func after_each() -> void:
	CoresFx.reduced_effects = false


func _node() -> Button:
	var b := Button.new()
	b.size = Vector2(128, 128)
	b.position = Vector2(100, 100)
	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.size = Vector2(112, 112)
	b.add_child(frame)
	var chip := Control.new()
	chip.name = "Chip"
	chip.position = Vector2(30, 100)
	chip.size = Vector2(68, 28)
	b.add_child(chip)
	root.add_child(b)
	return b


func _line() -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array([Vector2(0, 0), Vector2(0, 100), Vector2(200, 100)])
	root.add_child(l)
	return l


## Nós temporários (prefixo "Fx") e partículas na subárvore.
func _count(n: Node, particles_only := false) -> int:
	var c := 0
	for ch in n.get_children():
		if (ch is CPUParticles2D) if particles_only else ch.name.begins_with(CoresFx.TEMP_PREFIX):
			c += 1
		c += _count(ch, particles_only)
	return c


func _play_all() -> Array:
	var b := _node()
	var target := _node()
	var l := _line()
	var label := Label.new()
	label.text = "10"
	root.add_child(label)
	CoresFx.play_buy(b, ORANGE)
	CoresFx.play_max(b, PlaceholderTexture2D.new())
	CoresFx.play_unlock(l, target, ORANGE)
	CoresFx.play_respec([b, target], label, 10, 250, func(v: int) -> String: return str(v))
	CoresFx.play_fail(target)
	return [b, target, l, label]


func test_all_effects_run_end_and_free_nodes() -> void:
	var nodes := _play_all()
	assert_gt(_count(root), 0, "criou nós temporários")
	assert_gt(_count(root, true), 0, "criou partículas")
	var fail_x: float = (nodes[1] as Control).position.x
	await wait_seconds(0.75)
	assert_eq(_count(root), 0, "tudo liberado em <= 0,6 s (+ folga)")
	var b: Button = nodes[0]
	assert_eq(b.scale, Vector2.ONE)
	assert_eq(b.modulate, Color.WHITE)
	assert_eq((b.get_node(^"Chip") as Control).position.y, 100.0, "selo volta ao lugar")
	assert_eq((nodes[1] as Control).position.x, 100.0, "tremida volta ao lugar")
	assert_almost_eq(fail_x, 100.0, 8.1)
	assert_eq((nodes[3] as Label).text, "250", "contagem termina no saldo final")


func test_reduced_creates_no_particles_or_nodes() -> void:
	CoresFx.reduced_effects = true
	var nodes := _play_all()
	assert_eq(_count(root, true), 0, "sem partículas")
	assert_eq(_count(root), 0, "só a troca de estado")
	assert_eq((nodes[3] as Label).text, "10", "reduzido não anima o saldo (a tela já mostra o final)")
	await wait_seconds(0.4)
	assert_eq((nodes[1] as Control).modulate, Color.WHITE)


func test_count_stops_if_text_changes() -> void:
	var label := Label.new()
	label.text = "250"
	root.add_child(label)
	CoresFx.play_respec([], label, 10, 250, func(v: int) -> String: return str(v))
	await wait_process_frames(3)
	label.text = "180"
	await wait_seconds(0.6)
	assert_eq(label.text, "180", "outra mudança no saldo vence a contagem")


func test_ignores_nodes_outside_tree() -> void:
	var b := Button.new()
	CoresFx.play_buy(b, ORANGE)
	CoresFx.play_max(b, null)
	CoresFx.play_fail(b)
	var l := Line2D.new()
	CoresFx.play_unlock(l, null, ORANGE)
	assert_eq(b.get_child_count(), 0)
	b.free()
	l.free()


func test_cores_screen_hooks() -> void:
	var p := PlayerProfile.new()
	p.level = 3
	p.coins = 60
	var s: CoresScreen = preload("res://src/ui/screens/cores_screen.tscn").instantiate()
	s.setup(p, preload("res://data/talents/talent_tree.tres"), func(_p: PlayerProfile) -> bool: return true)
	add_child_autofree(s)
	await wait_process_frames(2)
	s.select(&"talent_sharp_core")
	assert_true(s.buy_selected())
	assert_gt(_count(s._nodes[&"talent_sharp_core"]), 0, "compra: pulso no nó")
	assert_gt(_count(s._tree_root), 0, "desbloqueio: trilho na ligação")
	var x := s.buy_button.position.x
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	s._on_buy_input(click)
	await wait_process_frames(3)
	assert_ne(s.buy_button.position.x, x, "sem Moeda: tremida no Comprar")
	await wait_seconds(0.75)
	assert_eq(s.buy_button.position.x, x)
	assert_eq(_count(s), 0)
