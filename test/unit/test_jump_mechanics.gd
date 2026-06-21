extends GutTest
## JumpSystem: ground jump, coyote time, the single-jump airborne block,
## wall jump, and variable jump height. These are the platforming-feel knobs.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _make_jumper(ecs) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "platformer", Components.platformer())
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "input_state", Components.input_state())
	ecs.add_component(e, "collision", Components.collision())
	return e


func test_ground_jump_applies_jump_force_and_emits():
	var ecs = _make_ecs()
	var sys = JumpSystem.new(); ecs.register_system(sys)
	var e = _make_jumper(ecs)
	ecs.get_component(e, "collision").on_ground = true
	var input = ecs.get_component(e, "input_state")
	input.jump_just_pressed = true
	input.jump_pressed = true  # held this frame, as real input would be
	var plat = ecs.get_component(e, "platformer")
	var vel = ecs.get_component(e, "velocity")
	watch_signals(sys)

	sys.process(0.016)

	assert_almost_eq(vel.y, plat.jump_force, 0.001, "ground jump applies jump_force")
	assert_signal_emitted(sys, "jumped", "a ground jump emits jumped")


func test_coyote_time_allows_a_jump_just_after_leaving_ground():
	var ecs = _make_ecs()
	var sys = JumpSystem.new(); ecs.register_system(sys)
	var e = _make_jumper(ecs)
	var plat = ecs.get_component(e, "platformer")
	var vel = ecs.get_component(e, "velocity")
	ecs.get_component(e, "collision").on_ground = false
	plat.coyote_timer = 0.05  # still within the grace window
	var input = ecs.get_component(e, "input_state")
	input.jump_just_pressed = true
	input.jump_pressed = true

	sys.process(0.016)

	assert_almost_eq(vel.y, plat.jump_force, 0.001, "jump succeeds during coyote time")
	assert_almost_eq(plat.coyote_timer, 0.0, 0.001, "coyote time is consumed by the jump")


func test_no_air_jump_for_single_jump_character():
	var ecs = _make_ecs()
	var sys = JumpSystem.new(); ecs.register_system(sys)
	var e = _make_jumper(ecs)
	# Airborne, no coyote, no wall, jumps_max == 1.
	ecs.get_component(e, "collision").on_ground = false
	ecs.get_component(e, "platformer").coyote_timer = 0.0
	ecs.get_component(e, "input_state").jump_just_pressed = true
	var vel = ecs.get_component(e, "velocity")

	sys.process(0.016)

	assert_almost_eq(vel.y, 0.0, 0.001, "no mid-air jump without coyote/wall and only one jump")


func test_wall_jump_pushes_away_and_reports_direction():
	var ecs = _make_ecs()
	var sys = JumpSystem.new(); ecs.register_system(sys)
	var e = _make_jumper(ecs)
	var plat = ecs.get_component(e, "platformer")
	var vel = ecs.get_component(e, "velocity")
	var col = ecs.get_component(e, "collision")
	col.on_ground = false
	plat.coyote_timer = 0.0
	col.on_wall = true
	col.wall_direction = 1  # wall on the right
	var input = ecs.get_component(e, "input_state")
	input.jump_just_pressed = true
	input.jump_pressed = true
	watch_signals(sys)

	sys.process(0.016)

	assert_almost_eq(vel.y, plat.jump_force, 0.001, "wall jump applies jump_force")
	# vel.x = -wall_direction * max_speed * 0.8 = -1 * 400 * 0.8
	assert_almost_eq(vel.x, -320.0, 0.001, "wall jump pushes away from the wall")
	assert_signal_emitted_with_parameters(sys, "wall_jumped", [e, -1])


func test_releasing_jump_while_rising_cuts_upward_velocity():
	var ecs = _make_ecs()
	var sys = JumpSystem.new(); ecs.register_system(sys)
	var e = _make_jumper(ecs)
	var plat = ecs.get_component(e, "platformer")
	var vel = ecs.get_component(e, "velocity")
	plat.is_jumping = true
	vel.y = -600.0
	var input = ecs.get_component(e, "input_state")
	input.jump_pressed = false        # released
	input.jump_just_pressed = false

	sys.process(0.016)

	assert_almost_eq(vel.y, -300.0, 0.001, "early release halves rising velocity (variable jump height)")
	assert_false(plat.is_jumping, "variable-height cut clears the is_jumping flag")
