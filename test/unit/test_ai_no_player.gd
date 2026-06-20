extends GutTest
## AISystem must not crash when no player entity exists (e.g. between level
## clear and respawn). player_pos is null in that window; regression guard for
## the typed-parameter fault in _process_idle/_process_chase/_can_detect_player.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs


func test_idle_enemy_with_no_player_does_not_crash_and_patrols():
	var ecs = _make_ecs()
	var sys = AISystem.new(); ecs.register_system(sys)

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "enemy", Components.enemy())
	var ai = Components.ai("patrol")
	ai.state = "idle"
	ai.patrol_points = [Vector2(-100, 0), Vector2(100, 0)]
	ecs.add_component(e, "ai", ai)
	# Note: no tag_player entity -> player_pos is null inside the system.

	sys.process(0.016)  # would fault if player_pos hit a typed Dictionary param

	assert_true(ecs.entity_exists(e), "enemy survives an AI tick with no player present")
	assert_eq(ai.state, "patrol", "idle enemy with patrol points falls through to patrol")


func test_chasing_enemy_with_no_player_drops_to_idle():
	var ecs = _make_ecs()
	var sys = AISystem.new(); ecs.register_system(sys)

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "enemy", Components.enemy())
	var ai = Components.ai("chase")
	ai.state = "chase"
	ai.target_entity = 999  # nonexistent / despawned target
	ecs.add_component(e, "ai", ai)

	sys.process(0.016)

	assert_eq(ai.state, "idle", "chase with a dead target reverts to idle without crashing")
