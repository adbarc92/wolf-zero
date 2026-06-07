extends GutTest
const AI = preload("res://scripts/ecs/systems/ai_system.gd")

func test_support_heal_clamps_to_max():
	assert_eq(AI.support_heal(20, 50, 12), 32)
	assert_eq(AI.support_heal(45, 50, 12), 50, "never exceeds max")
