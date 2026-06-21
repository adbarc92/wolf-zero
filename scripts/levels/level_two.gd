class_name LevelTwo
extends Level
## The second vertical-slice level (Tetsu Spire). Provides geometry + arena data;
## the flow helpers (arena_to_activate / is_level_won / roster_for) are inherited
## from Level. Mirrors LevelOne's structure exactly — only the data differs.
##
## Difficulty intent: longer than Level One, denser rosters, introduces the
## elite_oni archetype, and stacks a twin-boss climax (Crimson Ronin into the
## final Oni Warlord). All numbers are SANE starting points and need on-device
## balance tuning (see brief).


func _init() -> void:
	spawn = Vector2(200, 540)
	floor_y = 600.0
	extent_x = 6400.0
	goal_x = 6150.0
	display_name = "Tetsu Spire"


## Solid geometry as rects [Vector2 center, Vector2 size].
func platforms() -> Array:
	return [
		[Vector2(extent_x / 2.0, floor_y + 16), Vector2(extent_x, 32)],
		[Vector2(650, 470), Vector2(160, 20)],
		[Vector2(950, 390), Vector2(140, 20)],
		[Vector2(1250, 470), Vector2(160, 20)],
		[Vector2(2200, 430), Vector2(40, 320)],
		[Vector2(3050, 450), Vector2(200, 20)],
		[Vector2(3400, 360), Vector2(160, 20)],
		[Vector2(4600, 430), Vector2(40, 320)],
		[Vector2(5200, 460), Vector2(200, 20)],
	]


## Ordered arenas: trigger_x, checkpoint Vector2, enemy roster [ [type, Vector2], ... ].
func arenas() -> Array:
	return [
		{"trigger_x": 1400.0, "checkpoint": Vector2(1350, 540), "enemies": [
			["ronin_drone", Vector2(1700, 540)], ["ronin_drone", Vector2(1900, 540)],
			["cyber_ashigaru", Vector2(2100, 430)]]},
		{"trigger_x": 2600.0, "checkpoint": Vector2(2550, 540), "enemies": [
			["cyber_ashigaru", Vector2(3050, 450)], ["shinobi_ghost", Vector2(2900, 540)],
			["ronin_drone", Vector2(3150, 540)], ["tech_priest", Vector2(2750, 540)],
			["oni_mech", Vector2(3300, 540)]]},
		{"trigger_x": 3700.0, "checkpoint": Vector2(3650, 540), "enemies": [
			["elite_oni", Vector2(4050, 540)], ["shinobi_ghost", Vector2(3900, 540)],
			["tech_priest", Vector2(3800, 540)]]},
		{"trigger_x": 4900.0, "checkpoint": Vector2(4850, 540), "enemies": [
			["crimson_ronin", Vector2(5250, 540)]]},
		{"trigger_x": 5700.0, "checkpoint": Vector2(5650, 540), "enemies": [
			["oni_warlord", Vector2(6000, 540)]]},
	]
