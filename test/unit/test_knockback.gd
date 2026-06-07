extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_hit_applies_knockback_away_from_attacker():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	var a = ecs.create_entity()
	ecs.add_component(a, "position", Components.position(0, 0))
	ecs.add_component(a, "weapon", Components.weapon(15, 0.25))
	ecs.add_component(a, "health", Components.health(100))
	ecs.add_component(a, "input_state", Components.input_state())
	ecs.add_component(a, "tag_player", Components.tag_player())
	ecs.get_component(a, "input_state").facing = 1
	var w = ecs.get_component(a, "weapon"); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "light"

	var t = ecs.create_entity()
	ecs.add_component(t, "position", Components.position(40, 0))
	ecs.add_component(t, "velocity", Components.velocity())
	ecs.add_component(t, "collision", Components.collision(32, 64))
	ecs.add_component(t, "health", Components.health(50))
	ecs.add_component(t, "tag_enemy", Components.tag_enemy())

	combat.process(0.016)

	assert_gt(ecs.get_component(t, "velocity").x, 0.0,
		"target is knocked to the right (away from a right-facing attacker)")
