class_name ECSSystem
extends RefCounted
## Base class for all ECS systems
##
## Systems contain logic that processes entities with specific components.
## Override _get_required_components() and process() to create a system.

## Reference to the ECS manager (set automatically on registration)
var ecs: Node = null

## Whether this system is currently processing
var enabled: bool = true


## Override to specify which components this system requires
func _get_required_components() -> Array[String]:
	return []


## Called when the system is registered with ECS
func _on_registered() -> void:
	pass


## Called when the system is unregistered from ECS
func _on_unregistered() -> void:
	pass


## Override to implement system logic. Called every physics frame.
func process(_delta: float) -> void:
	pass


## Helper: Get all entities this system should process
func get_entities() -> Array[int]:
	var required = _get_required_components()
	if required.is_empty():
		return []
	return ecs.get_entities_with_all(required)


## Helper: Get component data for an entity
func get_component(entity_id: int, component_type: String) -> Variant:
	return ecs.get_component(entity_id, component_type)


## Helper: Check if entity has component
func has_component(entity_id: int, component_type: String) -> bool:
	return ecs.has_component(entity_id, component_type)


## Helper: Get the Godot node for an entity (if hybrid approach used)
func get_node(entity_id: int) -> Node:
	return ecs.get_entity_node(entity_id)
