extends GutTest

func test_arena_roster_sizes():
	var L := LevelOne.new()
	assert_eq(L.roster_for(0).size(), 2, "arena 0 has two drones")
	assert_eq(L.roster_for(2).size(), 1, "elite arena has one enemy")
	assert_eq(L.roster_for(-1).size(), 0, "no arena -> empty roster")

func test_checkpoint_is_arena_start():
	var L := LevelOne.new()
	assert_eq(L.arenas()[0].checkpoint, Vector2(1250, 540))
