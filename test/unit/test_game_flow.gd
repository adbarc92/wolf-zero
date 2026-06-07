extends GutTest

func test_begin_run_sets_playing_and_full_lives():
	GameState.begin_run()
	assert_eq(GameState.current_state, GameState.State.PLAYING)
	assert_eq(GameState.lives, GameState.MAX_LIVES)

func test_lose_life_decrements_then_defeats_at_zero():
	GameState.begin_run()
	var defeated := false
	for i in range(GameState.MAX_LIVES):
		defeated = GameState.lose_life()
	assert_true(defeated, "defeated after losing all lives")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)

func test_win_sets_victory():
	GameState.begin_run()
	GameState.win_run()
	assert_eq(GameState.current_state, GameState.State.VICTORY)
