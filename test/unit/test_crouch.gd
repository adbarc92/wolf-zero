extends GutTest

const Anim = preload("res://scripts/ecs/systems/animation_system.gd")
var ECSScript = preload("res://scripts/ecs/ecs.gd")

# --- Animation derivation ---

func test_crouch_still():
	var clip = Anim.derive_clip(
		{"x": 0.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false}, true)
	assert_eq(clip, "crouch", "grounded + crouching + still = crouch")

func test_crouch_walk():
	var clip = Anim.derive_clip(
		{"x": 100.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false}, true)
	assert_eq(clip, "crouch_walk", "grounded + crouching + moving = crouch_walk")

func test_crouch_default_off_keeps_run():
	# Existing 5-arg callers (crouching defaults false) are unaffected.
	var clip = Anim.derive_clip(
		{"x": 100.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(clip, "run", "without the crouch flag, movement is still run")

# --- Movement: crouch slows you ---

func test_crouch_slows_horizontal_speed():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var move := MovementSystem.new(); move.ecs = ecs

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	var col = Components.collision(); col.on_ground = true
	ecs.add_component(e, "collision", col)
	ecs.add_component(e, "platformer", Components.platformer())
	var input = Components.input_state(); input.move_direction = 1.0
	ecs.add_component(e, "input_state", input)

	# Crouch-walk: run several frames and compare top speed vs an uncrouched run.
	input.crouch_pressed = true
	for i in range(20):
		move.process(1.0 / 60.0)
	var crouch_speed = abs(ecs.get_component(e, "velocity").x)

	var max_speed = ecs.get_component(e, "velocity").max_speed
	assert_lt(crouch_speed, max_speed, "crouch-walk is slower than full run speed")
	assert_gt(crouch_speed, 0.0, "crouch-walk still moves")
