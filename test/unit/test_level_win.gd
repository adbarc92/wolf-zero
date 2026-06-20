extends GutTest

func test_win_requires_goal_and_final_arena_cleared():
	var L := LevelOne.new()
	assert_false(L.is_level_won(5000.0, false), "not won until final arena cleared")
	assert_false(L.is_level_won(1000.0, true), "not won before the goal")
	assert_true(L.is_level_won(5000.0, true), "won past goal with final arena cleared")
