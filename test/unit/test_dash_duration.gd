extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _dashing_entity(ecs):
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "collision", Components.collision())
	ecs.add_component(e, "platformer", Components.platformer())
	ecs.add_component(e, "input_state", Components.input_state())
	var platformer = ecs.get_component(e, "platformer")
	platformer.is_dashing = true
	platformer.dash_duration = 0.2
	return e

func test_dash_ends_after_its_duration():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var move := MovementSystem.new()
	move.ecs = ecs
	var e = _dashing_entity(ecs)

	# Advance well past the 0.2s dash duration.
	move.process(0.1)
	move.process(0.1)
	move.process(0.1)

	assert_false(ecs.get_component(e, "platformer").is_dashing,
		"dash must end after its duration (regression: it used to run forever)")
