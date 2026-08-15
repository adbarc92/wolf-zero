extends GutTest
## Whiffed parries cost Momentum; landed ones do not.
##
## Blocking already spends Momentum, so without this a mashed parry would be
## strictly cheaper than defending properly — the precise option would be free
## and the safe option expensive, which inverts the whole economy.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

const FRAME := 1.0 / 60.0

var ecs
var parry_system: ParrySystem
var momentum_system: MomentumSystem
var entity: int


func before_each():
	ecs = ECSScript.new()
	autofree(ecs)
	momentum_system = MomentumSystem.new()
	ecs.register_system(momentum_system)
	parry_system = ParrySystem.new()
	parry_system.ecs = ecs

	entity = ecs.create_entity()
	ecs.add_component(entity, "parry", Components.parry())
	ecs.add_component(entity, "input_state", Components.input_state())
	var mom = Components.momentum()
	mom.current = 100.0
	ecs.add_component(entity, "momentum", mom)


func _parry() -> Dictionary:
	return ecs.get_component(entity, "parry")


func _momentum() -> Dictionary:
	return ecs.get_component(entity, "momentum")


func _in_state() -> Dictionary:
	return ecs.get_component(entity, "input_state")


## Tap parry once and let the window run its full length.
func _tap_and_expire() -> void:
	_in_state().parry_pressed = true
	parry_system.process(FRAME)
	_in_state().parry_pressed = false
	for _i in range(int(round(_parry().parry_window / FRAME)) + 2):
		parry_system.process(FRAME)


# =============================================================================
# WHIFFING COSTS
# =============================================================================

func test_a_whiffed_parry_spends_momentum():
	var before: float = _momentum().current

	_tap_and_expire()

	assert_almost_eq(_momentum().current, before - _parry().whiff_cost, 0.01,
		"a window that absorbed nothing costs whiff_cost")


func test_the_window_still_closes_after_a_whiff():
	_tap_and_expire()
	assert_false(_parry().is_parrying, "window closed")


func test_an_open_window_has_not_been_charged_yet():
	_in_state().parry_pressed = true
	parry_system.process(FRAME)
	var before: float = _momentum().current

	# Still inside the 0.2s window.
	parry_system.process(FRAME)

	assert_almost_eq(_momentum().current, before, 0.01,
		"nothing is billed while the window is still open")


# =============================================================================
# LANDING A PARRY IS FREE
# =============================================================================

func test_a_connected_parry_costs_nothing():
	_in_state().parry_pressed = true
	parry_system.process(FRAME)
	_in_state().parry_pressed = false

	# CombatSystem marks the window as having done its job.
	_parry().connected = true
	var before: float = _momentum().current

	for _i in range(int(round(_parry().parry_window / FRAME)) + 2):
		parry_system.process(FRAME)

	assert_almost_eq(_momentum().current, before, 0.01,
		"landing a parry is free — only whiffs are billed")


func test_connected_resets_when_a_new_window_opens():
	_in_state().parry_pressed = true
	parry_system.process(FRAME)
	_parry().connected = true
	_in_state().parry_pressed = false

	# Let it close (free), clear the cooldown, then open a fresh window.
	for _i in range(int(round(_parry().parry_window / FRAME)) + 2):
		parry_system.process(FRAME)
	_parry().cooldown = 0.0

	_in_state().parry_pressed = true
	parry_system.process(FRAME)

	assert_false(_parry().connected, "a new window starts unconnected")


# =============================================================================
# MASHING
# =============================================================================

func test_repeated_whiffs_drain_the_bar():
	var before: float = _momentum().current

	for _i in range(3):
		_tap_and_expire()
		_parry().cooldown = 0.0

	assert_almost_eq(_momentum().current, before - (3.0 * _parry().whiff_cost), 0.01,
		"each whiff bills again — mashing bleeds you")


func test_mashing_an_empty_bar_breaks_you():
	_momentum().current = _parry().whiff_cost

	_tap_and_expire()

	assert_true(momentum_system.is_broken(entity),
		"spending the last of the bar on a whiff Breaks you")


func test_momentum_never_goes_negative_on_a_whiff():
	_momentum().current = 1.0

	_tap_and_expire()

	assert_gte(_momentum().current, 0.0, "a whiff cannot push the bar below zero")


# =============================================================================
# INTERACTION WITH BLOCKING
# =============================================================================

func test_holding_blocks_once_the_parry_window_closes():
	# Holding gives one parry attempt, then settles into a block.
	_in_state().parry_pressed = true
	_in_state().parry_held = true
	parry_system.process(FRAME)
	_in_state().parry_pressed = false

	assert_false(_parry().is_blocking, "not blocking during the parry window")

	for _i in range(int(round(_parry().parry_window / FRAME)) + 2):
		parry_system.process(FRAME)

	assert_true(_parry().is_blocking, "holding settles into a block afterwards")
