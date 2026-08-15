extends GutTest
## MomentumSystem: decay timing, Charge banking, spending, and the Broken state.
## (Routing of hit-gained momentum is covered by test_momentum_routing.gd.)

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _entity_with_momentum(ecs) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "momentum", Components.momentum())
	return e


# =============================================================================
# DECAY
# =============================================================================

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


func test_idle_decay_to_zero_does_not_break():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	m.current = 2.0
	m.decay_timer = 0.0

	sys.process(1.0)

	assert_almost_eq(m.current, 0.0, 0.001, "decay floors at zero")
	assert_false(m.broken, "standing still is not the same as blocking with nothing left")


func test_enemy_momentum_starts_full_and_never_decays():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = ecs.create_entity()
	var m = Components.enemy_momentum()
	ecs.add_component(e, "momentum", m)
	m.decay_timer = 0.0

	assert_almost_eq(m.current, m.max, 0.001, "an enemy spawns composed")
	sys.process(5.0)
	assert_almost_eq(m.current, m.max, 0.001, "only the player's parries move it")


# =============================================================================
# BUILDING AND BANKING
# =============================================================================

func test_add_momentum_clamps_to_max_and_resets_decay_delay():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")

	sys.add_momentum(e, 30.0)
	assert_almost_eq(m.current, 30.0, 0.001, "gain applied")
	assert_almost_eq(m.decay_timer, m.decay_delay, 0.001, "gain refreshes the decay delay")

	sys.add_momentum(e, 1000.0)
	assert_almost_eq(m.current, m.bank_floor, 0.001, "overfilling banks and drops to the floor")


func test_filling_the_bar_banks_a_charge_and_resets_to_the_floor():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	watch_signals(sys)

	sys.add_momentum(e, m.max)

	assert_eq(m.charges, 1, "a full bar banks one Charge")
	assert_almost_eq(m.current, m.bank_floor, 0.001, "the bar resets to the floor, never to zero")
	assert_gt(m.bank_floor, 0.0, "the floor is a partial bar, not empty")
	assert_signal_emitted_with_parameters(sys, "charge_banked", [e, 1])
	assert_signal_emitted(sys, "momentum_changed", "banking still reports the new bar to the HUD")


func test_the_bar_can_be_banked_repeatedly_up_to_the_charge_cap():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")

	for _i in range(m.charges_max + 2):
		sys.add_momentum(e, m.max)

	assert_eq(m.charges, m.charges_max, "the pool is small and caps out")


func test_spend_charge_refuses_an_empty_pool():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	watch_signals(sys)

	assert_false(sys.spend_charge(e), "nothing banked, nothing to spend")

	sys.add_momentum(e, m.max)
	assert_true(sys.spend_charge(e), "a banked Charge can be spent")
	assert_eq(m.charges, 0, "spending takes one out of the pool")
	assert_signal_emitted_with_parameters(sys, "charge_spent", [e, 0])


# =============================================================================
# SPENDING AND BROKEN
# =============================================================================

func test_spend_momentum_takes_it_off_the_bar():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	m.current = 50.0

	var spent: float = sys.spend_momentum(e, 20.0)

	assert_almost_eq(spent, 20.0, 0.001, "reports what it took")
	assert_almost_eq(m.current, 30.0, 0.001, "bar drops by the spend")
	assert_false(m.broken, "still composed")


func test_spending_the_last_of_it_breaks_the_entity():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	m.current = 10.0
	watch_signals(sys)

	var spent: float = sys.spend_momentum(e, 25.0)

	assert_almost_eq(spent, 10.0, 0.001, "you cannot spend what you do not have")
	assert_true(m.broken, "spending to zero Breaks")
	assert_almost_eq(m.broken_timer, m.broken_duration, 0.001, "the opening is timed")
	assert_signal_emitted_with_parameters(sys, "entity_broken", [e])
	assert_true(sys.is_broken(e), "is_broken agrees")


func test_a_broken_entity_cannot_act_and_recovers_to_the_floor():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	ecs.add_component(e, "input_state", Components.input_state())
	ecs.add_component(e, "parry", Components.parry())
	ecs.add_component(e, "weapon", Components.weapon())
	var m = ecs.get_component(e, "momentum")
	var input = ecs.get_component(e, "input_state")
	var weapon = ecs.get_component(e, "weapon")
	sys.spend_momentum(e, 999.0)

	input.attack_light = true
	input.parry_held = true
	weapon.hitbox_active = true
	watch_signals(sys)
	sys.process(0.1)

	assert_false(input.attack_light, "a Broken combatant's inputs are dropped")
	assert_false(input.parry_held, "including defence")
	assert_false(weapon.hitbox_active, "and its attack is shut")
	assert_true(m.broken, "still Broken partway through the opening")

	sys.process(m.broken_duration)

	assert_false(m.broken, "the opening closes")
	assert_almost_eq(m.current, m.bank_floor, 0.001, "recovering hands back the floor, not zero")
	assert_signal_emitted_with_parameters(sys, "entity_recovered", [e])


func test_breaking_an_enemy_pins_its_ai_in_stagger():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = ecs.create_entity()
	ecs.add_component(e, "momentum", Components.enemy_momentum())
	ecs.add_component(e, "ai", Components.ai("chase"))
	ecs.get_component(e, "ai").state = "attack"

	sys.spend_momentum(e, 999.0)
	sys.process(0.1)

	assert_eq(ecs.get_component(e, "ai").state, "stagger", "Broken enemies are open, not attacking")


func test_building_momentum_is_refused_while_broken():
	var ecs = _make_ecs()
	var sys = MomentumSystem.new(); ecs.register_system(sys)
	var e = _entity_with_momentum(ecs)
	var m = ecs.get_component(e, "momentum")
	sys.spend_momentum(e, 999.0)

	sys.add_momentum(e, 50.0)

	assert_almost_eq(m.current, 0.0, 0.001, "you cannot build your way out of a Break early")


# =============================================================================
# NO THRESHOLDS
# =============================================================================

func test_the_momentum_component_carries_no_thresholds():
	var m = Components.momentum()
	for key in ["threshold_echo", "threshold_damage", "threshold_duration", "threshold_ultimate"]:
		assert_false(m.has(key), "%s is gone: a bar that oscillates cannot hold a threshold" % key)
