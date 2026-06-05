extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_enemy_in_attack_state_damages_nearby_player():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var ai := AISystem.new(); ecs.register_system(ai)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	# Player at x=0
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "input_state", Components.input_state())
	ecs.add_component(p, "tag_player", Components.tag_player())

	# Enemy at x=20 (within the 60px attack range), already in attack state, targeting player
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(20, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "weapon", Components.weapon(10, 0.4))
	ecs.add_component(e, "health", Components.health(50))
	ecs.add_component(e, "enemy", Components.enemy("ronin_drone"))
	var ai_c = Components.ai("chase"); ai_c.state = "attack"; ai_c.attack_cooldown = 0.0
	ai_c.target_entity = p  # chase normally sets this; required for _process_attack to fire
	ecs.add_component(e, "ai", ai_c)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())

	var hp_before = ecs.get_component(p, "health").current
	ai.process(0.016)      # opens the enemy hitbox window + faces the player
	combat.process(0.016)  # resolves hitboxes

	assert_lt(ecs.get_component(p, "health").current, hp_before,
		"an attacking enemy in range damages the player")
