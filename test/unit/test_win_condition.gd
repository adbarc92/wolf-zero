extends GutTest

const Main = preload("res://scripts/main/main.gd")

func test_win_when_no_enemies_remain():
	assert_true(Main._is_victory(0), "zero living enemies = victory")
	assert_false(Main._is_victory(1), "enemies remaining = not yet")
