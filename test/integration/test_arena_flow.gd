extends GutTest

# Guards the gating logic that drives arena activation in main._process.
func test_arena_gating_sequence():
	var L := LevelOne.new()
	var activated := []
	var i0 = L.arena_to_activate(1350.0, activated)
	assert_eq(i0, 0, "enter arena 0")
	activated.append(i0)
	assert_eq(L.arena_to_activate(1400.0, activated), -1, "no re-activation while inside arena 0")
	assert_eq(L.arena_to_activate(2600.0, activated), 1, "advance to arena 1")
