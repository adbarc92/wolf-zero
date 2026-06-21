extends GutTest

func test_arena_activates_when_player_passes_trigger():
	var L := LevelTwo.new()
	assert_eq(L.arena_to_activate(100.0, []), -1)
	assert_eq(L.arena_to_activate(1450.0, []), 0)
	assert_eq(L.arena_to_activate(2650.0, [0]), 1)
	assert_eq(L.arena_to_activate(9999.0, [0, 1, 2, 3]), 4)
	assert_eq(L.arena_to_activate(9999.0, [0, 1, 2, 3, 4]), -1)


func test_level_is_won_only_after_final_arena_cleared_and_past_goal():
	var L := LevelTwo.new()
	# Past the goal but final arena not cleared -> not won.
	assert_false(L.is_level_won(L.goal_x + 10.0, false))
	# Final arena cleared but short of the goal -> not won.
	assert_false(L.is_level_won(L.goal_x - 10.0, true))
	# Both conditions met -> won.
	assert_true(L.is_level_won(L.goal_x + 10.0, true))
