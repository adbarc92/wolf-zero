extends GutTest

const Combat = preload("res://scripts/ecs/systems/combat_system.gd")

func test_facing_from_input_state_when_present():
	assert_eq(Combat.resolve_facing({"facing": -1}, {"x": 0.0}, {"facing": 1}), -1,
		"input_state.facing wins when present")

func test_facing_from_velocity_when_no_input():
	assert_eq(Combat.resolve_facing(null, {"x": -50.0}, {"facing": 1}), -1,
		"derive from velocity sign")

func test_facing_falls_back_to_enemy_facing_when_still():
	assert_eq(Combat.resolve_facing(null, {"x": 0.0}, {"facing": -1}), -1,
		"stationary input-less attacker keeps stored facing")
