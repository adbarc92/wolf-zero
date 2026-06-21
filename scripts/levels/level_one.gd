class_name LevelOne
extends Level
## The vertical-slice level (Neo Edo). Provides geometry + arena data; the flow
## helpers (arena_to_activate / is_level_won / roster_for) are inherited from Level.


func _init() -> void:
	spawn = Vector2(200, 540)
	floor_y = 600.0
	extent_x = 5200.0
	goal_x = 4950.0
	display_name = "Neo Edo"


## Solid geometry as rects [Vector2 center, Vector2 size].
func platforms() -> Array:
	return [
		[Vector2(extent_x / 2.0, floor_y + 16), Vector2(extent_x, 32)],
		[Vector2(700, 470), Vector2(180, 20)],
		[Vector2(1050, 400), Vector2(160, 20)],
		[Vector2(1700, 430), Vector2(40, 320)],
		[Vector2(2750, 470), Vector2(200, 20)],
	]


## Ordered arenas: trigger_x, checkpoint Vector2, enemy roster [ [type, Vector2], ... ].
func arenas() -> Array:
	return [
		{"trigger_x": 1300.0, "checkpoint": Vector2(1250, 540), "enemies": [
			["ronin_drone", Vector2(1600, 540)], ["ronin_drone", Vector2(1850, 540)]]},
		{"trigger_x": 2500.0, "checkpoint": Vector2(2450, 540), "enemies": [
			["cyber_ashigaru", Vector2(2750, 430)], ["ronin_drone", Vector2(2950, 540)],
			["shinobi_ghost", Vector2(2850, 540)], ["tech_priest", Vector2(2600, 540)]]},
		{"trigger_x": 3300.0, "checkpoint": Vector2(3250, 540), "enemies": [
			["crimson_ronin", Vector2(3650, 540)]]},
		{"trigger_x": 4050.0, "checkpoint": Vector2(4000, 540), "enemies": [
			["oni_warlord", Vector2(4450, 540)]]},
	]
