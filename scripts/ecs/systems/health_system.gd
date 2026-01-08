class_name HealthSystem
extends ECSSystem
## Manages health, invincibility frames, and death


signal health_changed(entity_id: int, current: int, max_hp: int)
signal invincibility_started(entity_id: int)
signal invincibility_ended(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["health"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var health = get_component(entity_id, "health")

		_process_invincibility(entity_id, health, delta)


func _process_invincibility(entity_id: int, health: Dictionary, delta: float) -> void:
	if not health.invincible:
		return

	health.invincibility_timer -= delta

	if health.invincibility_timer <= 0:
		health.invincible = false
		health.invincibility_timer = 0
		invincibility_ended.emit(entity_id)


## Heal an entity
func heal(entity_id: int, amount: int) -> void:
	var health = get_component(entity_id, "health")
	if not health:
		return

	var previous = health.current
	health.current = min(health.current + amount, health.max)

	if health.current != previous:
		health_changed.emit(entity_id, health.current, health.max)


## Set invincibility manually
func set_invincible(entity_id: int, duration: float) -> void:
	var health = get_component(entity_id, "health")
	if not health:
		return

	health.invincible = true
	health.invincibility_timer = duration
	invincibility_started.emit(entity_id)


## Check if entity is alive
func is_alive(entity_id: int) -> bool:
	var health = get_component(entity_id, "health")
	return health != null and health.current > 0


## Get health percentage (0-1)
func get_health_percent(entity_id: int) -> float:
	var health = get_component(entity_id, "health")
	if not health:
		return 0.0
	return float(health.current) / float(health.max)
