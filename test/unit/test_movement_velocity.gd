extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _entity_with_dodge(ecs):
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "collision", Components.collision())
	ecs.add_component(e, "platformer", Components.platformer())
	ecs.add_component(e, "dodge", Components.dodge())
	ecs.add_component(e, "input_state", Components.input_state())
	return e

func test_dodge_sets_velocity_not_position():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var move_sys = MovementSystem.new()
	move_sys.ecs = ecs

	var e = _entity_with_dodge(ecs)
	var dodge = ecs.get_component(e, "dodge")
	var input = ecs.get_component(e, "input_state")
	dodge.is_dodging = true
	input.facing = 1
	var pos = ecs.get_component(e, "position")
	var start_x = pos.x

	move_sys.process(0.016)

	var vel = ecs.get_component(e, "velocity")
	assert_almost_eq(vel.x, dodge.dodge_speed, 0.01, "dodge sets horizontal velocity to dodge_speed")
	assert_eq(pos.x, start_x, "dodge must NOT integrate position directly (PhysicsSync owns that)")
