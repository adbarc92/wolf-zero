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

		# Skip if dodging (handled by dodge system)
		if dodge_data and dodge_data.is_dodging:
			_apply_dodge_movement(entity_id, pos, vel, dodge_data, delta)
			continue

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
			_update_platformer_timers(platformer, collision, delta)

		# Apply friction when no input
		if input and input.move_direction == 0:
			_apply_friction(vel, delta)

		# Update position
		pos.x += vel.x * delta
		pos.y += vel.y * delta

		# Sync with Godot node if present
		_sync_node_position(entity_id, pos)


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


func _apply_dodge_movement(entity_id: int, pos: Dictionary, vel: Dictionary, dodge: Dictionary, delta: float) -> void:
	var input = get_component(entity_id, "input_state")
	var direction = input.facing if input else 1

	pos.x += direction * dodge.dodge_speed * delta
	vel.x = direction * dodge.dodge_speed
	vel.y = 0  # No vertical movement during dodge

	_sync_node_position(entity_id, pos)


func _apply_dash_movement(entity_id: int, pos: Dictionary, vel: Dictionary, platformer: Dictionary, input: Dictionary, delta: float) -> void:
	var direction = input.facing if input else 1

	pos.x += direction * platformer.dash_speed * delta
	vel.x = direction * platformer.dash_speed
	vel.y = 0  # No vertical movement during dash

	_sync_node_position(entity_id, pos)


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


func _sync_node_position(entity_id: int, pos: Dictionary) -> void:
	var node = get_node(entity_id)
	if node and node is Node2D:
		node.position = Vector2(pos.x, pos.y)
