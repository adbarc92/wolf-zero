extends GutTest
## MomentumSystem: decay timing, threshold crossings, and Echo gating.
## (Routing of attack-gained momentum is covered by test_momentum_routing.gd.)

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _entity_with_momentum(ecs) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "momentum", Components.momentum())
	return e


func test_decay_drains_at_decay_rate_once_delay_elapsed():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	m.current = 50.0
	m.decay_timer = 0.0  # delay already elapsed

	sys.process(1.0)

	# decay_rate defaults to 5.0/sec
	assert_almost_eq(m.current, 45.0, 0.001, "drains decay_rate * delta once the delay is up")


func test_decay_timer_blocks_decay_until_it_expires():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	m.current = 50.0
	m.decay_timer = 2.0

	sys.process(1.0)

	assert_almost_eq(m.current, 50.0, 0.001, "no decay while decay_timer > 0")
	assert_almost_eq(m.decay_timer, 1.0, 0.001, "decay_timer counts down by delta")


func test_add_momentum_clamps_to_max_and_resets_decay_delay():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")

	sys.add_momentum(e, 30.0)
	assert_almost_eq(m.current, 30.0, 0.001, "gain applied")
	assert_almost_eq(m.decay_timer, m.decay_delay, 0.001, "gain refreshes the decay delay")

	sys.add_momentum(e, 1000.0)
	assert_almost_eq(m.current, m.max, 0.001, "clamped to max")


func test_crossing_echo_threshold_upward_emits_threshold_reached():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	watch_signals(sys)

	# threshold_echo defaults to 25.0; start at 0 and cross it.
	sys.add_momentum(e, 25.0)

	assert_signal_emitted_with_parameters(sys, "threshold_reached", [e, "echo"])


func test_decaying_below_threshold_emits_threshold_lost():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	m.current = 30.0       # above echo threshold (25)
	m.decay_timer = 0.0
	watch_signals(sys)

	sys.process(1.2)       # 30 - 5*1.2 = 24.0, below 25

	assert_lt(m.current, 25.0, "decayed below the echo threshold")
	assert_signal_emitted_with_parameters(sys, "threshold_lost", [e, "echo"])


func test_can_activate_tracks_echo_threshold():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = ecs.create_entity()
	ecs.add_component(e, "momentum", Components.momentum())
	ecs.add_component(e, "echo_data", Components.echo_data())
	var m = ecs.get_component(e, "momentum")
	var echo = ecs.get_component(e, "echo_data")

	m.current = 10.0; m.decay_timer = 99.0
	sys.process(0.0)
	assert_false(echo.can_activate, "below threshold: Echo cannot activate")

	m.current = 25.0
	sys.process(0.0)
	assert_true(echo.can_activate, "at/above threshold: Echo can activate")
