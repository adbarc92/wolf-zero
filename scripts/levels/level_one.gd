class_name LevelOne
extends RefCounted
## Static data + pure flow helpers for the vertical-slice level.

const SPAWN := Vector2(200, 540)
const GOAL_X := 3950.0
const FLOOR_Y := 600.0
const EXTENT_X := 4200.0

## Solid geometry as rects [Vector2 center, Vector2 size].
static func platforms() -> Array:
	return [
		[Vector2(2100, FLOOR_Y + 16), Vector2(EXTENT_X, 32)],
		[Vector2(700, 470), Vector2(180, 20)],
		[Vector2(1050, 400), Vector2(160, 20)],
		[Vector2(1700, 430), Vector2(40, 320)],
		[Vector2(2750, 470), Vector2(200, 20)],
	]

## Ordered arenas: trigger_x, checkpoint Vector2, enemy roster [ [type, Vector2], ... ].
static func arenas() -> Array:
	return [
		{"trigger_x": 1300.0, "checkpoint": Vector2(1250, 540), "enemies": [
			["ronin_drone", Vector2(1600, 540)], ["ronin_drone", Vector2(1850, 540)]]},
		{"trigger_x": 2500.0, "checkpoint": Vector2(2450, 540), "enemies": [
			["cyber_ashigaru", Vector2(2750, 430)], ["ronin_drone", Vector2(2950, 540)],
			["shinobi_ghost", Vector2(2850, 540)], ["tech_priest", Vector2(2600, 540)]]},
		{"trigger_x": 3300.0, "checkpoint": Vector2(3250, 540), "enemies": [
			["crimson_ronin", Vector2(3650, 540)]]},
	]

## Enemy roster for a given arena index, or empty if out of range.
static func roster_for(index: int) -> Array:
	var defs := arenas()
	if index < 0 or index >= defs.size():
		return []
	return defs[index].enemies

## Index of the first not-yet-activated arena the player has reached, else -1.
static func arena_to_activate(player_x: float, activated: Array) -> int:
	var defs := arenas()
	for i in range(defs.size()):
		if not activated.has(i) and player_x >= defs[i].trigger_x:
			return i
	return -1


## Win when the player passes the goal AND the final arena has been cleared.
static func is_level_won(player_x: float, final_arena_cleared: bool) -> bool:
	return final_arena_cleared and player_x >= GOAL_X
