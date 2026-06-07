class_name ParrySystem
extends ECSSystem
## Manages the parry window: opens it on press (off cooldown), counts it down.
## The actual negate/reflect/stagger happens in CombatSystem when a parrying
## target is hit.

signal parry_opened(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["parry", "input_state"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var parry = get_component(entity_id, "parry")
		var input = get_component(entity_id, "input_state")

		if parry.cooldown > 0.0:
			parry.cooldown = max(0.0, parry.cooldown - delta)

		if parry.is_parrying:
			parry.parry_timer -= delta
			if parry.parry_timer <= 0.0:
				parry.is_parrying = false
		elif input.parry_pressed and parry.cooldown <= 0.0:
			parry.is_parrying = true
			parry.parry_timer = parry.parry_window
			parry.cooldown = parry.cooldown_duration
			parry_opened.emit(entity_id)
