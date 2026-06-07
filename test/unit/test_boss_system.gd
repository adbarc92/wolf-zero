extends GutTest
const Boss = preload("res://scripts/ecs/systems/boss_system.gd")

func test_phase_two_under_half_hp():
	assert_eq(Boss.phase_for_hp(300, 300), 1)
	assert_eq(Boss.phase_for_hp(151, 300), 1)
	assert_eq(Boss.phase_for_hp(150, 300), 2)
	assert_eq(Boss.phase_for_hp(1, 300), 2)

func test_pattern_pool_grows_in_phase_two():
	assert_eq(Boss.patterns_for_phase(1), ["slash"])
	var p2 = Boss.patterns_for_phase(2)
	assert_true(p2.has("slash") and p2.has("lunge") and p2.size() >= 2, "phase 2 adds patterns")

func test_pattern_spec_has_timings():
	var s = Boss.pattern_spec("slash")
	assert_true(s.has("telegraph") and s.has("active") and s.has("recover") and s.has("damage"))
