extends GutTest
const Boss = preload("res://scripts/ecs/systems/boss_system.gd")

func test_perilous_spec_is_unblockable():
	assert_true(Boss.pattern_spec("perilous").get("unblockable", false))

func test_phase_two_pool_includes_perilous():
	assert_true(Boss.patterns_for_phase(2).has("perilous"))
	assert_false(Boss.patterns_for_phase(1).has("perilous"), "phase 1 has no perilous")
