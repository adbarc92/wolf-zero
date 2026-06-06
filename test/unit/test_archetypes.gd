extends GutTest

const Main = preload("res://scripts/main/main.gd")

func test_archetype_table_has_the_roster():
	var a = Main.archetype("oni_mech")
	assert_true(a.has("health") and a.has("armor_hits"), "oni_mech has health + armor")
	assert_gt(a.armor_hits, 0, "oni is armored")
	assert_true(Main.archetype("cyber_ashigaru").is_ranged, "ashigaru is ranged")
	assert_gt(Main.archetype("elite_oni").health, Main.archetype("oni_mech").health,
		"elite is tougher than a normal oni")
