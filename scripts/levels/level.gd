class_name Level
extends RefCounted
## Base contract for a playable level. Concrete levels (see LevelOne) override the
## data methods/metrics; the arena-flow helpers below are pure and shared, so
## main.gd can drive any level through this interface without knowing its type.

## World metrics — override in subclasses (via _init or by setting these).
var spawn: Vector2 = Vector2(200, 540)
var floor_y: float = 600.0
var extent_x: float = 5200.0
var goal_x: float = 4950.0
var display_name: String = "Level"


## Solid geometry as rects [Vector2 center, Vector2 size]. Override.
func platforms() -> Array:
	return []


## Ordered arenas: { trigger_x: float, checkpoint: Vector2,
## enemies: [[type: String, Vector2], ...] }. Override.
func arenas() -> Array:
	return []


# =============================================================================
# PURE FLOW HELPERS (shared; operate on arenas()/goal_x)
# =============================================================================

## Enemy roster for a given arena index, or empty if out of range.
func roster_for(index: int) -> Array:
	var defs := arenas()
	if index < 0 or index >= defs.size():
		return []
	return defs[index].enemies


## Index of the first not-yet-activated arena the player has reached, else -1.
func arena_to_activate(player_x: float, activated: Array) -> int:
	var defs := arenas()
	for i in range(defs.size()):
		if not activated.has(i) and player_x >= defs[i].trigger_x:
			return i
	return -1


## Win when the player passes the goal AND the final arena has been cleared.
func is_level_won(player_x: float, final_arena_cleared: bool) -> bool:
	return final_arena_cleared and player_x >= goal_x
