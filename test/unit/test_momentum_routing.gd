extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func test_light_attack_emits_momentum_changed():
	var ecs = _make_ecs()
	var momentum_sys = MomentumSystem.new()
	var combat_sys = CombatSystem.new()
	ecs.register_system(momentum_sys)
	ecs.register_system(combat_sys)

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "weapon", Components.weapon(15, 0.25))
	ecs.add_component(e, "health", Components.health(100))
	ecs.add_component(e, "momentum", Components.momentum())
	ecs.add_component(e, "input_state", Components.input_state())
	ecs.add_component(e, "tag_player", Components.tag_player())

	watch_signals(momentum_sys)
	var input = ecs.get_component(e, "input_state")
	input.attack_light = true

	combat_sys.process(0.016)

	assert_signal_emitted(momentum_sys, "momentum_changed",
		"combat momentum must go through MomentumSystem so the HUD updates")
	var momentum = ecs.get_component(e, "momentum")
	assert_eq(momentum.current, 5.0, "gain_attack (5.0) applied once")
