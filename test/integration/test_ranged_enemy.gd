extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_ranged_enemy_in_attack_state_spawns_a_projectile():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var ai := AISystem.new(); ecs.register_system(ai)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "tag_player", Components.tag_player())

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(200, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "weapon", Components.weapon(8, 0.5))
	var enemy = Components.enemy("cyber_ashigaru"); enemy.is_ranged = true
	ecs.add_component(e, "enemy", enemy)
	var ai_c = Components.ai("chase"); ai_c.state = "attack"; ai_c.target_entity = p
	ecs.add_component(e, "ai", ai_c)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())

	assert_eq(ecs.get_entities_with("tag_projectile").size(), 0, "no projectiles before")
	ai.process(0.016)
	assert_eq(ecs.get_entities_with("tag_projectile").size(), 1, "ranged enemy fired one projectile")

	# No scene container exists in this headless test, so the spawned projectile
	# node is parentless and won't be auto-freed — free it to avoid an orphan.
	for proj_id in ecs.get_entities_with("tag_projectile"):
		var n = ecs.get_entity_node(proj_id)
		if n:
			n.free()
