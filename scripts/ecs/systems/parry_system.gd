class_name ParrySystem
extends ECSSystem
## Manages the parry window: opens it on press (off cooldown), counts it down,
## and bills a window that closes without having absorbed anything.
##
## The negate/reflect/stagger itself happens in CombatSystem when a parrying
## target is hit. CombatSystem also sets `connected`, which is what tells a real
## parry from a whiff here.

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
				_close_window(entity_id, parry)
		elif input.parry_pressed and parry.cooldown <= 0.0:
			parry.is_parrying = true
			parry.parry_timer = parry.parry_window
			parry.cooldown = parry.cooldown_duration
			parry.connected = false
			parry_opened.emit(entity_id)

		parry.is_blocking = input.parry_held and not parry.is_parrying


## A window that ran its full length without absorbing a hit was a whiff, and
## costs Momentum. Landing a parry is free and pays out; mashing is what bleeds
## you, and mashing on a near-empty bar Breaks you.
##
## A landed parry clears `is_parrying` in CombatSystem, so it never reaches this
## path at all — `connected` is checked anyway so the rule does not depend on
## that side effect holding.
func _close_window(entity_id: int, parry: Dictionary) -> void:
	if parry.get("connected", false):
		return
	var momentum_system = ecs.get_system(MomentumSystem)
	if momentum_system:
		momentum_system.spend_momentum(entity_id, parry.get("whiff_cost", 0.0))
