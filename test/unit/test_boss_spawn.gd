extends GutTest

func test_final_arena_is_the_boss():
	var arenas = LevelOne.arenas()
	var last = arenas[arenas.size() - 1]
	assert_eq(last.enemies[0][0], "crimson_ronin", "final arena spawns the boss")
