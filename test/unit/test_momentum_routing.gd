extends GutTest
## Momentum is built by LANDING attacks, not by swinging, and the gain is routed
## through MomentumSystem so the HUD and the Charge pool see it.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _make_attacker(ecs) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "weapon", Components.weapon(15, 0.25))
	ecs.add_component(e, "health", Components.health(100))
	ecs.add_component(e, "momentum", Components.momentum())
	ecs.add_component(e, "input_state", Components.input_state())
	ecs.add_component(e, "tag_player", Components.tag_player())
	return e

func _make_target(ecs) -> int:
	var t = ecs.create_entity()
	ecs.add_component(t, "position", Components.position(20, 0))
	ecs.add_component(t, "velocity", Components.velocity())
	ecs.add_component(t, "collision", Components.collision(32, 64))
	ecs.add_component(t, "health", Components.health(200))
	ecs.add_component(t, "enemy", Components.enemy("ronin_drone"))
	ecs.add_component(t, "tag_enemy", Components.tag_enemy())
	return t


func test_landing_an_attack_emits_momentum_changed():
	var ecs = _make_ecs()
	var momentum_sys = MomentumSystem.new()
	var combat_sys = CombatSystem.new()
	ecs.register_system(momentum_sys)
	ecs.register_system(combat_sys)

	var e = _make_attacker(ecs)
	_make_target(ecs)
	ecs.get_component(e, "weapon").hitbox_active = true

	watch_signals(momentum_sys)
	combat_sys.process(0.016)

	assert_signal_emitted(momentum_sys, "momentum_changed",
		"combat momentum must go through MomentumSystem so the HUD updates")
	var momentum = ecs.get_component(e, "momentum")
	assert_eq(momentum.current, 5.0, "gain_attack (5.0) applied once")


func test_swinging_at_nothing_builds_no_momentum():
	var ecs = _make_ecs()
	var momentum_sys = MomentumSystem.new()
	var combat_sys = CombatSystem.new()
	ecs.register_system(momentum_sys)
	ecs.register_system(combat_sys)

	var e = _make_attacker(ecs)
	ecs.get_component(e, "input_state").attack_light = true

	combat_sys.process(0.016)

	assert_eq(ecs.get_component(e, "momentum").current, 0.0,
		"aggression funds defence only when it connects")
