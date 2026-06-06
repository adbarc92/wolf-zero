extends GutTest
const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func _w(attacking, atype="light", combo=1):
	return {"is_attacking": attacking, "attack_type": atype, "combo_current": combo}

func test_jump_fall_inbetween_near_apex():
	# airborne, small vertical speed => apex transition
	assert_eq(Anim.derive_clip({"x":0.0,"y":20.0},{"on_ground":false},_w(false),
		{"is_dodging":false},{"is_dashing":false}), "jump_fall_inbetween")

func test_fall_when_descending_fast():
	assert_eq(Anim.derive_clip({"x":0.0,"y":300.0},{"on_ground":false},_w(false),
		{"is_dodging":false},{"is_dashing":false}), "fall")

func test_crouch_attack():
	# crouching + attacking => crouch_attack (crouching is the 6th arg)
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},_w(true,"light",2),
		{"is_dodging":false},{"is_dashing":false}, true), "crouch_attack")

func test_no_movement_light_attack():
	# attacking, not crouching, ~no horizontal speed => nomove variant
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},_w(true,"light",3),
		{"is_dodging":false},{"is_dashing":false}), "light_3_nomove")

func test_moving_light_attack_lunges():
	assert_eq(Anim.derive_clip({"x":200.0,"y":0.0},{"on_ground":true},_w(true,"light",2),
		{"is_dodging":false},{"is_dashing":false}), "light_2")
