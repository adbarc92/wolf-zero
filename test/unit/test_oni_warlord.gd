extends GutTest
const Boss = preload("res://scripts/ecs/systems/boss_system.gd")

func test_final_arena_is_oni_warlord():
	var arenas = LevelOne.arenas()
	assert_eq(arenas[arenas.size() - 1].enemies[0][0], "oni_warlord")

func test_warlord_uses_perilous_from_phase_one():
	assert_true(Boss.patterns_for("oni_warlord", 1).has("perilous"))
