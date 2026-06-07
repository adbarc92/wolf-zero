extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_echo_damages_enemy_not_player():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "input_state", Components.input_state())
	ecs.add_component(p, "tag_player", Components.tag_player())

	var en = ecs.create_entity()
	ecs.add_component(en, "position", Components.position(40, 0))
	ecs.add_component(en, "velocity", Components.velocity())
	ecs.add_component(en, "collision", Components.collision(32, 64))
	ecs.add_component(en, "health", Components.health(50))
	ecs.add_component(en, "tag_enemy", Components.tag_enemy())

	var echo = ecs.create_entity()
	ecs.add_component(echo, "position", Components.position(20, 0))
	var v = Components.velocity(); v.x = 50.0
	ecs.add_component(echo, "velocity", v)
	ecs.add_component(echo, "tag_echo", Components.tag_echo())
	var w = Components.weapon(15, 0.25); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "light"
	ecs.add_component(echo, "weapon", w)

	var enemy_hp = ecs.get_component(en, "health").current
	var player_hp = ecs.get_component(p, "health").current
	combat.process(0.016)

	assert_lt(ecs.get_component(en, "health").current, enemy_hp, "echo damages the enemy")
	assert_eq(ecs.get_component(p, "health").current, player_hp, "echo does NOT damage the player")
