extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_chasing_enemy_retargets_to_nearby_echo():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var ai := AISystem.new(); ecs.register_system(ai)

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(500, 0))
	ecs.add_component(p, "tag_player", Components.tag_player())

	var en = ecs.create_entity()
	ecs.add_component(en, "position", Components.position(0, 0))
	ecs.add_component(en, "velocity", Components.velocity())
	var ai_c = Components.ai("chase"); ai_c.state = "chase"; ai_c.target_entity = p
	ecs.add_component(en, "ai", ai_c)
	ecs.add_component(en, "tag_enemy", Components.tag_enemy())

	var echo = ecs.create_entity()
	ecs.add_component(echo, "position", Components.position(50, 0))
	ecs.add_component(echo, "tag_echo", Components.tag_echo())

	ai.process(0.016)

	assert_eq(ecs.get_component(en, "ai").target_entity, echo,
		"a chasing enemy retargets to a much closer echo")
