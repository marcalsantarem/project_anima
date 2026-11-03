extends GutTest


func test_starts_full() -> void:
	var core := CoreHealth.new(100)
	assert_eq(core.current, 100)
	assert_false(core.is_depleted())


func test_damage_reduces_hp_and_emits() -> void:
	var core := CoreHealth.new(100)
	watch_signals(core)
	assert_eq(core.take_damage(5), 5)
	assert_eq(core.current, 95)
	assert_signal_emitted_with_parameters(core, "changed", [95, 100])


func test_damage_clamps_and_depletes_once() -> void:
	var core := CoreHealth.new(10)
	watch_signals(core)
	assert_eq(core.take_damage(25), 10)
	assert_eq(core.current, 0)
	assert_eq(core.take_damage(5), 0)
	assert_signal_emit_count(core, "depleted", 1)


func test_ignores_non_positive_damage() -> void:
	var core := CoreHealth.new(10)
	assert_eq(core.take_damage(0), 0)
	assert_eq(core.take_damage(-3), 0)
	assert_eq(core.current, 10)
