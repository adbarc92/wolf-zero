extends GutTest
const SM = preload("res://scripts/ui/screen_manager.gd")

func test_screen_text_per_state():
	assert_true(SM.screen_text(GameState.State.MENU, 3).contains("Begin"))
	assert_true(SM.screen_text(GameState.State.PAUSED, 3).contains("Resume"))
	assert_true(SM.screen_text(GameState.State.VICTORY, 3).contains("VICTORY"))
	assert_true(SM.screen_text(GameState.State.GAME_OVER, 3).contains("DEFEAT"))
	assert_eq(SM.screen_text(GameState.State.PLAYING, 3), "", "no overlay while playing")
