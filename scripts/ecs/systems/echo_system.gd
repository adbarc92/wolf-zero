class_name EchoSystem
extends ECSSystem
## Handles Holographic Echo: recording player actions and playing them back


signal echo_activated(entity_id: int, echo_entity_id: int)
signal echo_ended(echo_entity_id: int)
signal recording_frame(entity_id: int)

## Frame data structure for recording
class EchoFrame:
	var position: Vector2
	var velocity: Vector2
	var animation: String
	var facing: int
	var is_attacking: bool
	var attack_type: String

	func _init(pos: Vector2, vel: Vector2, anim: String, face: int, attacking: bool, atk_type: String):
		position = pos
		velocity = vel
		animation = anim
		facing = face
		is_attacking = attacking
		attack_type = atk_type


func _get_required_components() -> Array[String]:
	return ["echo_data"]


func process(delta: float) -> void:
	_process_recording(delta)
	_process_cooldowns(delta)
	_process_activation()
	_process_playback(delta)


func _process_recording(delta: float) -> void:
	## Record player actions continuously
	for entity_id in ecs.get_entities_with_all(["echo_data", "tag_player"]):
		var echo_data = get_component(entity_id, "echo_data")
		if not echo_data.is_recording:
			continue

		var pos = get_component(entity_id, "position")
		var vel = get_component(entity_id, "velocity")
		var sprite = get_component(entity_id, "sprite")
		var input = get_component(entity_id, "input_state")
		var weapon = get_component(entity_id, "weapon")

		if not pos:
			continue

		# Create frame data
		var frame = EchoFrame.new(
			Vector2(pos.x, pos.y),
			Vector2(vel.x if vel else 0, vel.y if vel else 0),
			sprite.animation if sprite else "idle",
			input.facing if input else 1,
			weapon.is_attacking if weapon else false,
			weapon.attack_type if weapon else "none"
		)

		echo_data.recording.append(frame)

		# Trim recording to max time (assuming 60 FPS)
		var max_frames = int(echo_data.max_record_time * 60)
		while echo_data.recording.size() > max_frames:
			echo_data.recording.pop_front()

		recording_frame.emit(entity_id)


func _process_cooldowns(delta: float) -> void:
	for entity_id in get_entities():
		var echo_data = get_component(entity_id, "echo_data")
		if echo_data.cooldown > 0:
			echo_data.cooldown = max(0, echo_data.cooldown - delta)


func _process_activation() -> void:
	for entity_id in ecs.get_entities_with_all(["echo_data", "input_state", "tag_player"]):
		var echo_data = get_component(entity_id, "echo_data")
		var input = get_component(entity_id, "input_state")

		if not input.echo_pressed:
			continue

		# Check if can activate
		if not echo_data.can_activate:
			continue
		if echo_data.cooldown > 0:
			continue
		if echo_data.recording.is_empty():
			continue

		# Activate echo
		_spawn_echo(entity_id, echo_data)


func _spawn_echo(owner_id: int, echo_data: Dictionary) -> void:
	var pos = get_component(owner_id, "position")
	if not pos:
		return

	# Create echo entity
	var echo_id = ecs.create_entity()

	# Add components
	ecs.add_component(echo_id, "position", Components.position(pos.x, pos.y))
	ecs.add_component(echo_id, "velocity", Components.velocity())
	ecs.add_component(echo_id, "sprite", Components.sprite())
	ecs.add_component(echo_id, "tag_echo", Components.tag_echo())
	ecs.add_component(echo_id, "weapon", Components.weapon(
		get_component(owner_id, "weapon").damage if has_component(owner_id, "weapon") else 10
	))

	# Copy recording to echo instance
	var instance = Components.echo_instance()
	instance.owner_entity = owner_id
	instance.recorded_actions = echo_data.recording.duplicate()
	ecs.add_component(echo_id, "echo_instance", instance)

	# Start cooldown
	echo_data.cooldown = echo_data.cooldown_duration

	echo_activated.emit(owner_id, echo_id)


func _process_playback(delta: float) -> void:
	for echo_id in ecs.get_entities_with("echo_instance"):
		var instance = get_component(echo_id, "echo_instance")
		var pos = get_component(echo_id, "position")
		var vel = get_component(echo_id, "velocity")
		var sprite = get_component(echo_id, "sprite")
		var weapon = get_component(echo_id, "weapon")

		# Update elapsed time
		instance.elapsed += delta

		# Check if echo should end
		if instance.elapsed >= instance.duration:
			_destroy_echo(echo_id)
			continue

		# Calculate which frame to play
		var total_frames = instance.recorded_actions.size()
		if total_frames == 0:
			_destroy_echo(echo_id)
			continue

		var progress = instance.elapsed / instance.duration
		var frame_index = int(progress * total_frames)
		frame_index = min(frame_index, total_frames - 1)

		# Apply frame data
		var frame: EchoFrame = instance.recorded_actions[frame_index]
		pos.x = frame.position.x
		pos.y = frame.position.y
		vel.x = frame.velocity.x
		vel.y = frame.velocity.y

		if sprite:
			sprite.animation = frame.animation
			sprite.flip_h = frame.facing < 0
			sprite.modulate = Color(0.0, 0.8, 1.0, 0.6)  # Cyan, translucent

		if weapon:
			weapon.is_attacking = frame.is_attacking
			weapon.attack_type = frame.attack_type
			weapon.hitbox_active = frame.is_attacking

		# Sync node position
		var node = get_node(echo_id)
		if node and node is Node2D:
			node.position = Vector2(pos.x, pos.y)


func _destroy_echo(echo_id: int) -> void:
	echo_ended.emit(echo_id)

	# Destroy associated node if exists
	var node = get_node(echo_id)
	if node:
		node.queue_free()

	ecs.destroy_entity(echo_id)
