class_name MovementSystem
extends ECSSystem
## Handles entity movement, gravity, and platforming physics


func _get_required_components() -> Array[String]:
	return ["position", "velocity"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var pos = get_component(entity_id, "position")
		var vel = get_component(entity_id, "velocity")
		var collision = get_component(entity_id, "collision")
		var platformer = get_component(entity_id, "platformer")
		var input = get_component(entity_id, "input_state")
		var dodge_data = get_component(entity_id, "dodge")

		# Store previous position
		pos.previous_x = pos.x
		pos.previous_y = pos.y

		# Advance platformer timers EVERY frame — before any dodge/dash early-continue.
		# (dash duration/cooldown, jump buffer, wall-run live here; if this were skipped
		# during a dash the dash would never end.)
		if platformer:
			_update_platformer_timers(platformer, collision, delta)

		# Skip if dodging (handled by dodge system)
		if dodge_data and dodge_data.is_dodging:
			_apply_dodge_movement(entity_id, pos, vel, dodge_data, delta)
			continue

		# Dash trigger
		if platformer and input and input.dash_pressed and platformer.has_dash \
				and not platformer.is_dashing and platformer.dash_cooldown <= 0:
			platformer.is_dashing = true
			platformer.dash_duration = 0.2
			platformer.dash_cooldown = 0.6

		# Skip if dashing
		if platformer and platformer.is_dashing:
			_apply_dash_movement(entity_id, pos, vel, platformer, input, delta)
			continue

		# Apply input-based horizontal movement
		if input:
			_apply_input_movement(vel, input, delta)

		# Apply gravity
		if platformer:
			_apply_gravity(vel, platformer, collision, delta)

		# Wall slide / climb
		if platformer and collision and collision.on_wall and not collision.on_ground:
			var climbing: bool = input != null and input.jump_pressed and platformer.wall_run_timer > 0.0
			vel.y = wall_adjust_velocity_y(vel.y, true, climbing, 120.0)

		# Apply friction when no input
		if input and input.move_direction == 0:
			_apply_friction(vel, delta)


## Adjust vertical velocity for wall interactions.
## on_wall: touching a wall and airborne. climbing: holding the climb input with time left.
static func wall_adjust_velocity_y(vy: float, on_wall: bool, climbing: bool, slide_speed: float) -> float:
	if not on_wall:
		return vy
	if climbing:
		return -slide_speed * 1.5
	return min(vy, slide_speed)


func _apply_input_movement(vel: Dictionary, input: Dictionary, delta: float) -> void:
	var target_speed = input.move_direction * vel.max_speed

	if input.move_direction != 0:
		# Accelerate toward target speed
		if abs(vel.x) < abs(target_speed):
			vel.x = move_toward(vel.x, target_speed, vel.acceleration * delta)
		else:
			vel.x = target_speed


func _apply_gravity(vel: Dictionary, platformer: Dictionary, collision: Dictionary, delta: float) -> void:
	if collision and collision.on_ground:
		# Reset jumps when grounded
		platformer.jumps_remaining = platformer.jumps_max
		platformer.is_jumping = false

		# Coyote time
		platformer.coyote_timer = platformer.coyote_time
	else:
		# Apply gravity
		vel.y += platformer.gravity * delta
		vel.y = min(vel.y, platformer.max_fall_speed)

		# Coyote time countdown
		platformer.coyote_timer = max(0, platformer.coyote_timer - delta)


func _apply_friction(vel: Dictionary, delta: float) -> void:
	vel.x = move_toward(vel.x, 0, vel.friction * delta)


func _apply_dodge_movement(entity_id: int, _pos: Dictionary, vel: Dictionary, dodge: Dictionary, _delta: float) -> void:
	var input = get_component(entity_id, "input_state")
	var direction = input.facing if input else 1
	vel.x = direction * dodge.dodge_speed
	vel.y = 0  # No vertical movement during dodge


func _apply_dash_movement(entity_id: int, _pos: Dictionary, vel: Dictionary, platformer: Dictionary, _input: Dictionary, _delta: float) -> void:
	var input = get_component(entity_id, "input_state")
	var direction = input.facing if input else 1
	vel.x = direction * platformer.dash_speed
	vel.y = 0  # No vertical movement during dash


func _update_platformer_timers(platformer: Dictionary, collision: Dictionary, delta: float) -> void:
	# Jump buffer
	platformer.jump_buffer_timer = max(0, platformer.jump_buffer_timer - delta)

	# Dash cooldown
	if platformer.dash_cooldown > 0:
		platformer.dash_cooldown = max(0, platformer.dash_cooldown - delta)

	# Dash duration
	if platformer.is_dashing:
		platformer.dash_duration -= delta
		if platformer.dash_duration <= 0:
			platformer.is_dashing = false
			platformer.dash_duration = 0.2  # Reset

	# Wall run
	if collision and collision.on_wall and not collision.on_ground:
		if platformer.can_wall_run and platformer.wall_run_timer > 0:
			platformer.wall_run_timer -= delta
	else:
		platformer.wall_run_timer = platformer.wall_run_duration


