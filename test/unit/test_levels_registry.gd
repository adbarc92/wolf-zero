extends GutTest
## The level abstraction: registry resolution + proof that any Level subclass
## inherits the arena-flow helpers (new levels only supply data, no flow code).

# A throwaway level to exercise the inherited helpers on a fresh subclass.
class FakeLevel extends Level:
	func _init() -> void:
		goal_x = 1000.0
	func arenas() -> Array:
		return [
			{"trigger_x": 100.0, "checkpoint": Vector2(90, 0), "enemies": [["ronin_drone", Vector2(120, 0)]]},
			{"trigger_x": 500.0, "checkpoint": Vector2(490, 0), "enemies": []},
		]


func test_registry_creates_known_level():
	var lvl = Levels.create("level_one")
	assert_true(lvl is LevelOne, "registry returns the requested level type")
	assert_true(lvl is Level, "every level shares the Level interface")


func test_registry_order_helpers():
	assert_eq(Levels.first(), "level_one")
	assert_true(Levels.order().has("level_one"))
	assert_eq(Levels.next_after("level_one"), "", "no level after the last one")
	assert_eq(Levels.next_after("bogus"), "", "unknown id has no successor")


func test_subclass_inherits_flow_helpers():
	var f = FakeLevel.new()
	assert_eq(f.arena_to_activate(50.0, []), -1, "before the first trigger")
	assert_eq(f.arena_to_activate(150.0, []), 0, "reaches the first arena")
	assert_eq(f.arena_to_activate(600.0, [0]), 1, "advances past an activated arena")
	assert_eq(f.roster_for(0).size(), 1, "roster comes from the subclass data")
	assert_eq(f.roster_for(9).size(), 0, "out-of-range arena -> empty roster")
	assert_false(f.is_level_won(1200.0, false), "win needs the final arena cleared")
	assert_true(f.is_level_won(1200.0, true), "won past the goal once cleared")
