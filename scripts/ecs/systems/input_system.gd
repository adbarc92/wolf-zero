class_name InputSystem
extends ECSSystem
## Processes player input and updates input state components


func _get_required_components() -> Array[String]:
	return ["input_state", "tag_player"]


func process(_delta: float) -> void:
	for entity_id in get_entities():
		var input = get_component(entity_id, "input_state")

		_process_movement_input(input)
		_process_combat_input(input)
		_process_ability_input(input)
		_update_facing(input)


func _process_movement_input(input: Dictionary) -> void:
	# Horizontal movement
	input.move_direction = Input.get_axis("move_left", "move_right")

	# Jump
	input.jump_just_pressed = Input.is_action_just_pressed("jump")
	input.jump_pressed = Input.is_action_pressed("jump")


func _process_combat_input(input: Dictionary) -> void:
	# Light attack
	input.attack_light = Input.is_action_just_pressed("attack_light")

	# Heavy attack with direction
	input.attack_heavy = Input.is_action_just_pressed("attack_heavy")
	if input.attack_heavy:
		input.attack_direction = _get_attack_direction(input)

	# Dodge
	input.dodge_pressed = Input.is_action_just_pressed("dodge")


func _process_ability_input(input: Dictionary) -> void:
	# Echo activation
	input.echo_pressed = Input.is_action_just_pressed("echo_activate")


func _get_attack_direction(input: Dictionary) -> Vector2:
	var direction = Vector2.ZERO

	# Check for directional input
	if Input.is_action_pressed("move_left"):
		direction.x = -1
	elif Input.is_action_pressed("move_right"):
		direction.x = 1

	if Input.is_action_pressed("jump"):  # Up
		direction.y = -1
	# Could add crouch/down input here

	# Default to forward if no direction
	if direction == Vector2.ZERO:
		direction.x = input.facing

	return direction.normalized()


func _update_facing(input: Dictionary) -> void:
	# Update facing based on movement direction
	if input.move_direction > 0:
		input.facing = 1
	elif input.move_direction < 0:
		input.facing = -1
	# If no input, keep current facing
