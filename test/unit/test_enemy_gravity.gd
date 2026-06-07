extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_gravity_applies_to_entity_with_platformer():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var move := MovementSystem.new()
	move.ecs = ecs

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "collision", Components.collision())
	ecs.add_component(e, "platformer", Components.platformer())

	move.process(1.0 / 60.0)

	var vel = ecs.get_component(e, "velocity")
	assert_gt(vel.y, 0.0, "an airborne entity with a platformer accrues downward velocity")
