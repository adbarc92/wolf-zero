extends GutTest
const AI = preload("res://scripts/ecs/systems/ai_system.gd")

func test_blink_goes_to_far_side_of_player():
	assert_almost_eq(AI.blink_target_x(500.0, 300.0, 160.0), 660.0, 0.01)
	assert_almost_eq(AI.blink_target_x(500.0, 900.0, 160.0), 340.0, 0.01)
