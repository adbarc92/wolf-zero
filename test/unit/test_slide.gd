extends GutTest
const Anim = preload("res://scripts/ecs/systems/animation_system.gd")
var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_slide_clip():
	# sliding is the final trailing arg
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, false, false, false, false, true), "slide")

func test_crouch_dash_triggers_slide_with_iframes():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var move := MovementSystem.new(); move.ecs = ecs
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	var col = Components.collision(); col.on_ground = true
	ecs.add_component(e, "collision", col)
	var plat = Components.platformer(); plat.has_dash = true
	ecs.add_component(e, "platformer", plat)
	ecs.add_component(e, "health", Components.health())
	var input = Components.input_state(); input.facing = 1
	input.dash_pressed = true; input.crouch_pressed = true
	ecs.add_component(e, "input_state", input)

	move.process(1.0 / 60.0)

	assert_true(ecs.get_component(e, "platformer").is_sliding, "crouch+dash starts a slide")
	assert_true(ecs.get_component(e, "health").invincible, "slide grants i-frames")
	assert_almost_eq(abs(ecs.get_component(e, "velocity").x), plat.slide_speed, 1.0, "slide moves at slide_speed")
	assert_false(ecs.get_component(e, "platformer").is_dashing, "a slide is not also a dash")
