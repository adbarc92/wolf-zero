extends GutTest
## EchoSystem: the record -> activate -> playback lifecycle of the signature
## Holographic Echo. (Echo-vs-combat damage and aggro live in the integration tests.)

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _make_player(ecs) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "sprite", Components.sprite())
	ecs.add_component(e, "input_state", Components.input_state())
	ecs.add_component(e, "weapon", Components.weapon())
	ecs.add_component(e, "momentum", Components.momentum())
	ecs.add_component(e, "echo_data", Components.echo_data())
	ecs.add_component(e, "tag_player", Components.tag_player())
	return e


func _free_echo_nodes(ecs) -> void:
	# The echo render node is parentless in a headless test; free it by hand.
	for echo_id in ecs.get_entities_with("tag_echo"):
		var n = ecs.get_entity_node(echo_id)
		if n:
			n.free()


func test_recording_appends_a_frame_per_process():
	var ecs = _make_ecs()
	var sys = EchoSystem.new(); ecs.register_system(sys)
	var e = _make_player(ecs)
	var echo_data = ecs.get_component(e, "echo_data")

	sys.process(0.016)
	sys.process(0.016)
	sys.process(0.016)

	assert_eq(echo_data.recording.size(), 3, "one frame recorded per process while recording")


func test_recording_is_trimmed_to_max_record_time():
	var ecs = _make_ecs()
	var sys = EchoSystem.new(); ecs.register_system(sys)
	var e = _make_player(ecs)
	var echo_data = ecs.get_component(e, "echo_data")
	echo_data.max_record_time = 0.05  # int(0.05 * 60) = 3 frame cap

	for _i in range(8):
		sys.process(0.016)

	assert_eq(echo_data.recording.size(), 3, "ring buffer caps at max_record_time * 60 frames")


func test_recording_stops_when_not_recording():
	var ecs = _make_ecs()
	var sys = EchoSystem.new(); ecs.register_system(sys)
	var e = _make_player(ecs)
	var echo_data = ecs.get_component(e, "echo_data")
	echo_data.is_recording = false

	sys.process(0.016)

	assert_eq(echo_data.recording.size(), 0, "no frames captured when is_recording is false")


func test_activation_spends_a_charge():
	var ecs = _make_ecs()
	var momentum_sys = MomentumSystem.new(); ecs.register_system(momentum_sys)
	var sys = EchoSystem.new(); ecs.register_system(sys)
	var e = _make_player(ecs)
	var momentum = ecs.get_component(e, "momentum")
	var input = ecs.get_component(e, "input_state")

	# Build a small recording, bank a Charge, then press echo.
	sys.process(0.016)
	sys.process(0.016)
	momentum_sys.add_momentum(e, momentum.max)
	assert_eq(momentum.charges, 1, "a filled bar banked a Charge to spend")
	input.echo_pressed = true

	watch_signals(sys)
	sys.process(0.0)

	assert_eq(ecs.get_entities_with("echo_instance").size(), 1, "the Charge buys an Echo")
	assert_signal_emitted(sys, "echo_activated", "activation emits echo_activated")
	assert_eq(momentum.charges, 0, "and is gone from the pool")

	_free_echo_nodes(ecs)


func test_activation_is_refused_with_no_charges():
	var ecs = _make_ecs()
	ecs.register_system(MomentumSystem.new())
	var sys = EchoSystem.new(); ecs.register_system(sys)
	var e = _make_player(ecs)
	var input = ecs.get_component(e, "input_state")

	sys.process(0.016)
	sys.process(0.016)
	input.echo_pressed = true

	sys.process(0.0)

	assert_eq(ecs.get_entities_with("echo_instance").size(), 0,
		"an empty Charge pool is the only thing that can refuse an Echo")


func test_activation_has_no_cooldown_left_to_wait_out():
	var ecs = _make_ecs()
	var momentum_sys = MomentumSystem.new(); ecs.register_system(momentum_sys)
	var sys = EchoSystem.new(); ecs.register_system(sys)
	var e = _make_player(ecs)
	var momentum = ecs.get_component(e, "momentum")
	var input = ecs.get_component(e, "input_state")

	sys.process(0.016)
	sys.process(0.016)
	momentum_sys.add_momentum(e, momentum.max)
	momentum_sys.add_momentum(e, momentum.max)
	input.echo_pressed = true

	sys.process(0.0)
	sys.process(0.0)

	assert_eq(ecs.get_entities_with("echo_instance").size(), 2,
		"two Charges buy two Echoes back to back, with no cooldown between them")
	assert_false(ecs.get_component(e, "echo_data").has("cooldown"), "the cooldown field is gone")

	_free_echo_nodes(ecs)


func test_playback_reproduces_recorded_positions_then_self_destructs():
	var ecs = _make_ecs()
	var sys = EchoSystem.new(); ecs.register_system(sys)

	var echo_id = ecs.create_entity()  # no node -> no orphan on destroy
	ecs.add_component(echo_id, "position", Components.position(0, 0))
	ecs.add_component(echo_id, "velocity", Components.velocity())
	ecs.add_component(echo_id, "sprite", Components.sprite())
	ecs.add_component(echo_id, "weapon", Components.weapon())
	ecs.add_component(echo_id, "tag_echo", Components.tag_echo())

	var instance = Components.echo_instance()
	instance.duration = 1.0
	instance.recorded_actions = [
		EchoSystem.EchoFrame.new(Vector2(10, 20), Vector2.ZERO, "idle", 1, false, "none"),
		EchoSystem.EchoFrame.new(Vector2(30, 40), Vector2.ZERO, "run", 1, false, "none"),
	]
	ecs.add_component(echo_id, "echo_instance", instance)

	var pos = ecs.get_component(echo_id, "position")

	sys.process(0.0)   # progress 0 -> frame 0
	assert_almost_eq(pos.x, 10.0, 0.001, "playback starts at the first recorded frame")

	sys.process(0.6)   # progress 0.6 of 2 frames -> index 1
	assert_almost_eq(pos.x, 30.0, 0.001, "playback advances to the later recorded frame")

	sys.process(0.6)   # elapsed 1.2 >= duration -> echo ends
	assert_false(ecs.entity_exists(echo_id), "echo self-destructs once its duration elapses")
