extends GutTest

func test_arena_activates_when_player_passes_trigger():
	assert_eq(LevelOne.arena_to_activate(100.0, []), -1)
	assert_eq(LevelOne.arena_to_activate(1350.0, []), 0)
	assert_eq(LevelOne.arena_to_activate(2600.0, [0]), 1)
	assert_eq(LevelOne.arena_to_activate(9999.0, [0, 1, 2]), -1)
