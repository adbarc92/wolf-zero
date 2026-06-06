extends GutTest

const Move = preload("res://scripts/ecs/systems/movement_system.gd")

func test_wall_slide_caps_fall_speed():
	assert_almost_eq(Move.wall_adjust_velocity_y(900.0, true, false, 120.0), 120.0, 0.01,
		"fast fall on a wall is capped to slide speed")

func test_no_wall_no_change():
	assert_almost_eq(Move.wall_adjust_velocity_y(900.0, false, false, 120.0), 900.0, 0.01,
		"off a wall, vertical velocity is unchanged")

func test_wall_climb_overrides_with_upward_velocity():
	assert_lt(Move.wall_adjust_velocity_y(50.0, true, true, 120.0), 0.0,
		"climbing produces upward (negative) velocity")
