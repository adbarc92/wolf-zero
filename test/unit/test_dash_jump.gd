extends GutTest
## Dash-jump: jumping out of a dash hands the dash's horizontal speed to the
## jump arc, Mega Man X style, instead of clamping back to run speed.
##
## Systems are stepped by hand in registration order (Jump before Movement),
## which is the order main.gd registers them in and which the mechanic relies on.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

const FRAME := 1.0 / 60.0

var ecs
var jump_system: JumpSystem
var move_system: MovementSystem
var entity: int


func before_each():
	ecs = ECSScript.new()
	autofree(ecs)
	jump_system = JumpSystem.new()
	jump_system.ecs = ecs
	move_system = MovementSystem.new()
	move_system.ecs = ecs

	entity = ecs.create_entity()
	ecs.add_component(entity, "position", Components.position(0, 0))
	ecs.add_component(entity, "velocity", Components.velocity())
	var col = Components.collision()
	col.on_ground = true
	ecs.add_component(entity, "collision", col)
	var plat = Components.platformer(-650)
	plat.has_dash = true
	ecs.add_component(entity, "platformer", plat)
	var input = Components.input_state()
	input.facing = 1
	ecs.add_component(entity, "input_state", input)


func _tick() -> void:
	jump_system.process(FRAME)
	move_system.process(FRAME)


func _plat() -> Dictionary:
	return ecs.get_component(entity, "platformer")


func _vel() -> Dictionary:
	return ecs.get_component(entity, "velocity")


func _in_state() -> Dictionary:
	return ecs.get_component(entity, "input_state")


func _collision() -> Dictionary:
	return ecs.get_component(entity, "collision")


## Dash on the ground, then leave the ground with a jump.
func _dash_then_jump() -> void:
	_in_state().dash_pressed = true
	_in_state().move_direction = 1.0
	_tick()
	assert_true(_plat().is_dashing, "precondition: the dash started")

	_in_state().jump_just_pressed = true
	_tick()
	_in_state().jump_just_pressed = false
	_collision().on_ground = false


## Tick until gravity has turned the jump around, so the entity is descending
## the way it would be on a real landing frame.
func _fall_until_descending() -> void:
	for _i in range(60):
		if _vel().y > 0.0:
			return
		_tick()
	fail_test("never started descending")


# =============================================================================
# ENTERING A DASH-JUMP
# =============================================================================

func test_jumping_mid_dash_converts_the_dash_into_a_dash_jump():
	_dash_then_jump()

	assert_false(_plat().is_dashing, "the dash itself is over")
	assert_true(_plat().dash_jumping, "and became a dash-jump")


func test_dash_jump_leaves_the_ground():
	_dash_then_jump()
	assert_lt(_vel().y, 0.0, "jump velocity survived the dash branch")


func test_dash_jump_keeps_dash_speed_rather_than_run_speed():
	_dash_then_jump()
	var vel = _vel()

	_in_state().move_direction = 1.0
	for _i in range(10):
		_tick()

	assert_almost_eq(vel.x, _plat().dash_speed, 1.0,
		"horizontal speed stays at dash speed through the arc")
	assert_gt(vel.x, vel.max_speed, "and is faster than a normal run")


func test_a_plain_jump_does_not_start_a_dash_jump():
	_in_state().jump_just_pressed = true
	_tick()

	assert_false(_plat().dash_jumping, "no dash was in progress")


# =============================================================================
# ENDING A DASH-JUMP
# =============================================================================

func test_landing_ends_the_dash_jump():
	_dash_then_jump()
	_in_state().move_direction = 1.0
	_fall_until_descending()
	assert_true(_plat().dash_jumping, "airborne, still carrying speed")

	_collision().on_ground = true
	_tick()

	assert_false(_plat().dash_jumping, "landing ends it")


func test_speed_returns_to_normal_after_landing():
	_dash_then_jump()
	_in_state().move_direction = 1.0
	_fall_until_descending()

	_collision().on_ground = true
	for _i in range(20):
		_tick()

	var vel = _vel()
	assert_almost_eq(vel.x, vel.max_speed, 1.0, "back to ordinary run speed")


func test_steering_the_other_way_ends_the_dash_jump():
	_dash_then_jump()
	_in_state().move_direction = 1.0
	_tick()

	_in_state().move_direction = -1.0
	_tick()

	assert_false(_plat().dash_jumping, "reversing gives up the momentum")


func test_releasing_the_stick_coasts_instead_of_braking():
	# In X you keep your dash-jump momentum with the stick neutral; only landing
	# or actively steering back gives it up.
	_dash_then_jump()
	_in_state().move_direction = 0.0

	for _i in range(10):
		_tick()

	assert_true(_plat().dash_jumping, "still dash-jumping with no input")
	assert_almost_eq(_vel().x, _plat().dash_speed, 1.0, "friction did not bleed it off")


# =============================================================================
# DASH NO LONGER SUPPRESSES GRAVITY
# =============================================================================

func test_dashing_off_a_ledge_falls():
	_in_state().dash_pressed = true
	_in_state().move_direction = 1.0
	_tick()
	_collision().on_ground = false

	for _i in range(5):
		_tick()

	assert_gt(_vel().y, 0.0, "a dash in mid-air is subject to gravity, not a hover")


func test_grounded_dash_still_runs_at_dash_speed():
	_in_state().dash_pressed = true
	_in_state().move_direction = 1.0
	_tick()

	assert_true(_plat().is_dashing, "dashing")
	assert_almost_eq(_vel().x, _plat().dash_speed, 1.0, "at dash speed")


# =============================================================================
# COOLDOWN IS DATA-DRIVEN
# =============================================================================

func test_dash_cooldown_comes_from_the_component():
	_plat().dash_cooldown_time = 0.05
	_in_state().dash_pressed = true
	_in_state().move_direction = 1.0
	_tick()

	assert_almost_eq(_plat().dash_cooldown, 0.05, 0.001,
		"the component value is used, not a hardcoded one")


func test_default_dash_cooldown_is_unchanged_for_non_player_entities():
	assert_almost_eq(Components.platformer().dash_cooldown_time, 0.6, 0.001,
		"the shared default keeps the old timing; only the player is retuned")
