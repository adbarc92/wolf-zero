class_name DodgeSystem
extends ECSSystem
## Handles dodge/roll mechanics with invincibility frames


signal dodge_started(entity_id: int)
signal dodge_ended(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["dodge", "input_state"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var dodge = get_component(entity_id, "dodge")
		var input = get_component(entity_id, "input_state")
		var health = get_component(entity_id, "health")

		# Update cooldown
		if dodge.dodge_cooldown > 0:
			dodge.dodge_cooldown = max(0, dodge.dodge_cooldown - delta)

		# Check for dodge input
		if input.dodge_pressed and not dodge.is_dodging and dodge.dodge_cooldown <= 0:
			_start_dodge(entity_id, dodge)

		# Process active dodge
		if dodge.is_dodging:
			_process_dodge(entity_id, dodge, health, delta)


func _start_dodge(entity_id: int, dodge: Dictionary) -> void:
	dodge.is_dodging = true
	dodge.dodge_timer = 0.0
	dodge.dodge_cooldown = dodge.cooldown_duration

	# Add momentum for dodge
	var momentum_system = ecs.get_system(MomentumSystem)
	if momentum_system:
		var momentum = get_component(entity_id, "momentum")
		if momentum:
			momentum_system.add_momentum(entity_id, momentum.gain_dodge)

	dodge_started.emit(entity_id)


func _process_dodge(entity_id: int, dodge: Dictionary, health: Dictionary, delta: float) -> void:
	dodge.dodge_timer += delta

	# Handle invincibility frames
	if health:
		var in_i_frames = dodge.dodge_timer >= dodge.i_frame_start and dodge.dodge_timer <= dodge.i_frame_end
		if in_i_frames and not health.invincible:
			health.invincible = true
		elif not in_i_frames and health.invincible and dodge.is_dodging:
			# Only end invincibility if it was from dodge (not from damage)
			if health.invincibility_timer <= 0:
				health.invincible = false

	# End dodge
	if dodge.dodge_timer >= dodge.dodge_duration:
		dodge.is_dodging = false
		dodge.dodge_timer = 0.0
		if health:
			health.invincible = false
		dodge_ended.emit(entity_id)
