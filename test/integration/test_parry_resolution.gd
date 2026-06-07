extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_parry_negates_damage_reflects_and_staggers():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "momentum", Components.momentum())
	ecs.add_component(p, "input_state", Components.input_state())
	var parry = Components.parry(); parry.is_parrying = true
	ecs.add_component(p, "parry", parry)
	ecs.add_component(p, "tag_player", Components.tag_player())

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(20, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "health", Components.health(50))
	var enemy = Components.enemy("ronin_drone"); enemy.facing = -1
	ecs.add_component(e, "enemy", enemy)
	var ai_c = Components.ai("chase"); ai_c.state = "attack"
	ecs.add_component(e, "ai", ai_c)
	var w = Components.weapon(12, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"
	ecs.add_component(e, "weapon", w)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())

	var player_hp = ecs.get_component(p, "health").current
	var enemy_hp = ecs.get_component(e, "health").current
	combat.process(0.016)

	assert_eq(ecs.get_component(p, "health").current, player_hp, "parry negates player damage")
	assert_lt(ecs.get_component(e, "health").current, enemy_hp, "parry reflects damage to attacker")
	assert_eq(ecs.get_component(e, "ai").state, "stagger", "attacker is staggered")
