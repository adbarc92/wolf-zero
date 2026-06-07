extends GutTest
const Main = preload("res://scripts/main/main.gd")

func test_enemies_hit_harder():
	assert_gte(Main.archetype("ronin_drone").damage, 16, "drones hit hard enough that defense matters")
	assert_gte(Main.archetype("oni_mech").damage, 26)
	assert_gte(Main.archetype("elite_oni").damage, 34)
