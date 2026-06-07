extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _entity(ecs):
	var e = ecs.create_entity()
	ecs.add_component(e, "parry", Components.parry())
	ecs.add_component(e, "input_state", Components.input_state())
	return e

func test_press_opens_window_then_closes():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var sys := ParrySystem.new(); sys.ecs = ecs
	var e = _entity(ecs)
	ecs.get_component(e, "input_state").parry_pressed = true

	sys.process(0.01)
	assert_true(ecs.get_component(e, "parry").is_parrying, "window opens on press")

	ecs.get_component(e, "input_state").parry_pressed = false
	sys.process(0.5)
	assert_false(ecs.get_component(e, "parry").is_parrying, "window closes after parry_window")

func test_cannot_reparry_during_cooldown():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var sys := ParrySystem.new(); sys.ecs = ecs
	var e = _entity(ecs)
	var input = ecs.get_component(e, "input_state")

	input.parry_pressed = true
	sys.process(0.01)            # opens the window (cooldown now 0.5)
	input.parry_pressed = false
	sys.process(0.3)             # window (0.2s) elapses; cooldown still ~0.19s
	assert_false(ecs.get_component(e, "parry").is_parrying, "window closed")
	input.parry_pressed = true
	sys.process(0.01)            # press again, but still on cooldown
	assert_false(ecs.get_component(e, "parry").is_parrying, "blocked by cooldown")
