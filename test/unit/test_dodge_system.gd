extends GutTest
## DodgeSystem: the roll, its cooldown gate, and the invincibility window.
##
## Dodge carries real design weight — it is the only answer to a perilous
## (unblockable) attack, so the i-frame window and the cooldown that limits it
## are balance-critical numbers worth pinning down.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

const FRAME := 1.0 / 60.0

var ecs
var dodge_system: DodgeSystem
var entity: int


func before_each():
	# Not in the tree: these tests step the system frame by frame themselves.
	ecs = ECSScript.new()
	autofree(ecs)
	dodge_system = DodgeSystem.new()
	dodge_system.ecs = ecs

	entity = ecs.create_entity()
	ecs.add_component(entity, "dodge", Components.dodge())
	ecs.add_component(entity, "input_state", Components.input_state())
	ecs.add_component(entity, "health", Components.health())


## Advance the system by `seconds`, in 60Hz steps.
func _advance(seconds: float) -> void:
	var frames := int(round(seconds / FRAME))
	for _i in range(frames):
		dodge_system.process(FRAME)


func _dodge() -> Dictionary:
	return ecs.get_component(entity, "dodge")


func _health() -> Dictionary:
	return ecs.get_component(entity, "health")


func _press_dodge(pressed: bool) -> void:
	ecs.get_component(entity, "input_state").dodge_pressed = pressed


# =============================================================================
# STARTING A DODGE
# =============================================================================

func test_idle_entity_does_not_dodge():
	_advance(0.2)
	assert_false(_dodge().is_dodging, "no input, no dodge")


func test_dodge_input_starts_a_dodge():
	_press_dodge(true)
	dodge_system.process(FRAME)
	assert_true(_dodge().is_dodging, "pressing dodge starts the roll")


func test_starting_a_dodge_puts_it_on_cooldown_immediately():
	_press_dodge(true)
	dodge_system.process(FRAME)
	# The cooldown tick runs before the start check, so the full duration
	# survives the frame the dodge begins on.
	assert_almost_eq(_dodge().dodge_cooldown, 0.5, 0.001,
		"cooldown is armed at full duration on the frame the dodge starts")


func test_dodge_start_emits_its_signal():
	watch_signals(dodge_system)
	_press_dodge(true)
	dodge_system.process(FRAME)
	assert_signal_emitted_with_parameters(dodge_system, "dodge_started", [entity])


func test_holding_dodge_does_not_restart_an_active_dodge():
	_press_dodge(true)
	dodge_system.process(FRAME)
	var timer_after_one_frame = _dodge().dodge_timer

	dodge_system.process(FRAME)

	assert_gt(_dodge().dodge_timer, timer_after_one_frame,
		"the timer keeps running rather than resetting to 0")


# =============================================================================
# INVINCIBILITY WINDOW
# =============================================================================

func test_no_i_frames_at_the_very_start_of_the_roll():
	# i_frame_start is 0.05 — the first frames are deliberately vulnerable.
	_press_dodge(true)
	dodge_system.process(FRAME)
	assert_false(_health().invincible, "startup frames are not invincible")


func test_i_frames_are_active_in_the_middle_of_the_roll():
	_press_dodge(true)
	_advance(0.15)
	assert_true(_health().invincible, "mid-roll is invincible")


func test_i_frames_end_before_the_roll_does():
	# i_frame_end is 0.25, dodge_duration 0.3: recovery frames are vulnerable.
	_press_dodge(true)
	_advance(0.28)
	assert_true(_dodge().is_dodging, "still rolling")
	assert_false(_health().invincible, "but no longer invincible")


func test_dodge_does_not_clear_invincibility_granted_by_damage():
	# A hurt entity's invincibility_timer outranks the dodge window, otherwise a
	# dodge during hitstun would strip the player's post-hit protection.
	_press_dodge(true)
	_advance(0.15)
	var health = _health()
	health.invincibility_timer = 0.4

	_advance(0.12)

	assert_true(health.invincible,
		"damage invincibility survives the end of the i-frame window")


# =============================================================================
# ENDING A DODGE
# =============================================================================

func test_dodge_ends_after_its_duration():
	_press_dodge(true)
	_advance(0.3)
	assert_false(_dodge().is_dodging, "roll is over")
	assert_eq(_dodge().dodge_timer, 0.0, "timer is reset for the next roll")


func test_dodge_end_clears_invincibility_and_emits():
	watch_signals(dodge_system)
	_press_dodge(true)
	_advance(0.3)

	assert_false(_health().invincible, "invincibility does not leak past the roll")
	assert_signal_emitted_with_parameters(dodge_system, "dodge_ended", [entity])


# =============================================================================
# COOLDOWN GATE
# =============================================================================

func test_cannot_dodge_again_while_on_cooldown():
	_press_dodge(true)
	_advance(0.3)
	assert_false(_dodge().is_dodging, "first roll finished")

	# 0.3s elapsed against a 0.5s cooldown, and dodge is still held.
	_advance(0.1)
	assert_false(_dodge().is_dodging, "cooldown blocks the immediate re-roll")


func test_can_dodge_again_once_the_cooldown_expires():
	_press_dodge(true)
	_advance(0.3)
	_advance(0.25)
	assert_true(_dodge().is_dodging, "a new roll starts once the cooldown clears")


func test_cooldown_never_goes_negative():
	_press_dodge(true)
	dodge_system.process(FRAME)
	_press_dodge(false)
	_advance(2.0)
	# assert_almost_eq, not assert_eq: max(0, <float>) returns an *int* 0 in
	# GDScript, so the floored cooldown changes type on the way down.
	assert_almost_eq(float(_dodge().dodge_cooldown), 0.0, 0.0001, "cooldown floors at zero")


# =============================================================================
# MOMENTUM
# =============================================================================

func test_dodging_does_not_build_momentum():
	ecs.register_system(MomentumSystem.new())
	var momentum = Components.momentum()
	ecs.add_component(entity, "momentum", momentum)

	_press_dodge(true)
	dodge_system.process(FRAME)

	assert_eq(momentum.current, 0.0,
		"only parries and landed attacks build Momentum; a dodge is already paid in i-frames")


func test_dodging_without_a_momentum_component_is_harmless():
	ecs.register_system(MomentumSystem.new())

	_press_dodge(true)
	dodge_system.process(FRAME)

	assert_true(_dodge().is_dodging, "the roll still happens with no momentum to award")


# =============================================================================
# COMPONENT REQUIREMENTS
# =============================================================================

func test_system_requires_dodge_and_input_state():
	assert_eq(dodge_system._get_required_components(), ["dodge", "input_state"],
		"an entity needs both to be processed")

# NOTE: a health component is *not* in the required list and _process_dodge()
# guards with `if health:`, implying it is optional — but the parameter is typed
# `Dictionary`, so a dodging entity without health throws every frame. No live
# archetype hits this (only the player gets a dodge component, and it has
# health), so it is left as-is rather than fixed under a test-only change.
