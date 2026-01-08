class_name JumpSystem
extends ECSSystem
## Handles jumping, wall jumping, and related platforming mechanics


signal jumped(entity_id: int)
signal wall_jumped(entity_id: int, direction: int)
signal double_jumped(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["platformer", "velocity", "input_state"]


func process(_delta: float) -> void:
	for entity_id in get_entities():
		var platformer = get_component(entity_id, "platformer")
		var vel = get_component(entity_id, "velocity")
		var input = get_component(entity_id, "input_state")
		var collision = get_component(entity_id, "collision")

		# Buffer jump input
		if input.jump_just_pressed:
			platformer.jump_buffer_timer = platformer.jump_buffer_time

		# Check for jump
		if platformer.jump_buffer_timer > 0:
			if _try_jump(entity_id, platformer, vel, collision):
				platformer.jump_buffer_timer = 0

		# Variable jump height (cut jump short on release)
		if not input.jump_pressed and vel.y < 0 and platformer.is_jumping:
			vel.y *= 0.5
			platformer.is_jumping = false


func _try_jump(entity_id: int, platformer: Dictionary, vel: Dictionary, collision: Dictionary) -> bool:
	# Ground jump (with coyote time)
	if collision and (collision.on_ground or platformer.coyote_timer > 0):
		_perform_jump(entity_id, platformer, vel)
		platformer.coyote_timer = 0
		jumped.emit(entity_id)
		return true

	# Wall jump
	if collision and collision.on_wall and platformer.can_wall_jump:
		_perform_wall_jump(entity_id, platformer, vel, collision)
		wall_jumped.emit(entity_id, -collision.wall_direction)
		return true

	# Air jump (double jump) - if unlocked and has jumps remaining
	if platformer.jumps_remaining > 0 and platformer.jumps_max > 1:
		platformer.jumps_remaining -= 1
		_perform_jump(entity_id, platformer, vel)
		double_jumped.emit(entity_id)
		return true

	return false


func _perform_jump(entity_id: int, platformer: Dictionary, vel: Dictionary) -> void:
	vel.y = platformer.jump_force
	platformer.is_jumping = true

	# Consume a jump if in air
	var collision = get_component(entity_id, "collision")
	if collision and not collision.on_ground:
		platformer.jumps_remaining = max(0, platformer.jumps_remaining - 1)


func _perform_wall_jump(entity_id: int, platformer: Dictionary, vel: Dictionary, collision: Dictionary) -> void:
	vel.y = platformer.jump_force
	vel.x = -collision.wall_direction * vel.max_speed * 0.8  # Push away from wall
	platformer.is_jumping = true
	platformer.jumps_remaining = platformer.jumps_max  # Reset jumps on wall jump
