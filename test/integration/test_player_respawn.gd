extends GutTest

const Main = preload("res://scripts/main/main.gd")

func test_respawn_resets_health_and_position():
	var health = Components.health(100)
	health.current = 0
	var pos = Components.position(999, 999)
	Main._respawn_player_state(health, pos, Vector2(200, 400))
	assert_eq(health.current, health.max, "health restored to full")
	assert_eq(pos.x, 200.0)
	assert_eq(pos.y, 400.0)
