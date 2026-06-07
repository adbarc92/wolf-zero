extends GutTest
const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_hurt_overrides_movement():
	assert_eq(Anim.derive_clip({"x":100.0,"y":0.0},{"on_ground":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, true), "hit")

func test_wall_slide_when_on_wall_airborne():
	assert_eq(Anim.derive_clip({"x":0.0,"y":50.0},{"on_ground":false,"on_wall":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, false, true, false), "wall_slide")

func test_wall_climb_when_climbing():
	assert_eq(Anim.derive_clip({"x":0.0,"y":-50.0},{"on_ground":false,"on_wall":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, false, true, true), "wall_climb")

func test_existing_callers_unaffected():
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}), "idle")
