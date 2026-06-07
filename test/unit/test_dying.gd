extends GutTest
const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_dead_clip_wins():
	# Positional args: vel, collision, weapon, dodge, platformer,
	# crouching, hurt, on_wall, climbing, dead. dead is the 10th arg.
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},
		{"is_attacking":true,"attack_type":"light","combo_current":2},
		{"is_dodging":false},{"is_dashing":false}, false, false, false, false, true), "death")
