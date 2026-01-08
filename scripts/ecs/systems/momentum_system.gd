class_name MomentumSystem
extends ECSSystem
## Manages the momentum gauge: decay, thresholds, and effects


signal momentum_changed(entity_id: int, current: float, max_val: float)
signal threshold_reached(entity_id: int, threshold_name: String)
signal threshold_lost(entity_id: int, threshold_name: String)


func _get_required_components() -> Array[String]:
	return ["momentum"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var momentum = get_component(entity_id, "momentum")
		var previous = momentum.current

		_process_decay(momentum, delta)
		_check_thresholds(entity_id, momentum, previous)

		# Update Echo availability
		var echo_data = get_component(entity_id, "echo_data")
		if echo_data:
			echo_data.can_activate = momentum.current >= momentum.threshold_echo


func _process_decay(momentum: Dictionary, delta: float) -> void:
	# Decay timer counts down
	if momentum.decay_timer > 0:
		momentum.decay_timer -= delta
		return

	# Apply decay
	if momentum.current > 0:
		momentum.current = max(0, momentum.current - momentum.decay_rate * delta)


func _check_thresholds(entity_id: int, momentum: Dictionary, previous: float) -> void:
	var current = momentum.current

	# Check each threshold for crossing
	_check_threshold(entity_id, "echo", momentum.threshold_echo, previous, current)
	_check_threshold(entity_id, "damage", momentum.threshold_damage, previous, current)
	_check_threshold(entity_id, "duration", momentum.threshold_duration, previous, current)
	_check_threshold(entity_id, "ultimate", momentum.threshold_ultimate, previous, current)

	# Emit change signal
	if current != previous:
		momentum_changed.emit(entity_id, current, momentum.max)


func _check_threshold(entity_id: int, name: String, threshold: float, previous: float, current: float) -> void:
	# Crossed upward
	if previous < threshold and current >= threshold:
		threshold_reached.emit(entity_id, name)
	# Crossed downward
	elif previous >= threshold and current < threshold:
		threshold_lost.emit(entity_id, name)


## Add momentum to an entity (called by other systems)
func add_momentum(entity_id: int, amount: float) -> void:
	var momentum = get_component(entity_id, "momentum")
	if not momentum:
		return

	var previous = momentum.current
	momentum.current = min(momentum.current + amount, momentum.max)
	momentum.decay_timer = momentum.decay_delay

	_check_thresholds(entity_id, momentum, previous)
	momentum_changed.emit(entity_id, momentum.current, momentum.max)


## Consume all momentum (for ultimate attack)
func consume_all(entity_id: int) -> float:
	var momentum = get_component(entity_id, "momentum")
	if not momentum:
		return 0.0

	var amount = momentum.current
	var previous = momentum.current
	momentum.current = 0

	_check_thresholds(entity_id, momentum, previous)
	momentum_changed.emit(entity_id, 0, momentum.max)

	return amount


## Get current momentum percentage (0-1)
func get_momentum_percent(entity_id: int) -> float:
	var momentum = get_component(entity_id, "momentum")
	if not momentum:
		return 0.0
	return momentum.current / momentum.max
