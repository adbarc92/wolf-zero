extends GutTest
const HUDScript = preload("res://scripts/ui/hud.gd")

func test_lives_text():
	assert_eq(HUDScript.lives_text(3), "LIVES  3")
	assert_eq(HUDScript.lives_text(0), "LIVES  0")
