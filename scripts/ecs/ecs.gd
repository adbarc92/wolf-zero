extends Node
## ECS - Entity Component System Manager
##
## Core ECS implementation for Wolf-Zero. Manages entities, components, and systems.
## Entities are integer IDs, components are dictionaries, systems process entities.

signal entity_created(entity_id: int)
signal entity_destroyed(entity_id: int)
signal component_added(entity_id: int, component_type: String)
signal component_removed(entity_id: int, component_type: String)

## Next available entity ID
var _next_entity_id: int = 0

## All active entity IDs
var _entities: Array[int] = []

## Components stored as: { component_type: { entity_id: component_data } }
var _components: Dictionary = {}

## Registered systems in execution order
var _systems: Array[ECSSystem] = []

## Entity to node mapping (for hybrid approach with Godot nodes)
var _entity_nodes: Dictionary = {}  # entity_id -> Node

## Node to entity mapping
var _node_entities: Dictionary = {}  # Node -> entity_id


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	for system in _systems:
		if system.enabled:
			system.process(delta)


# =============================================================================
# ENTITY MANAGEMENT
# =============================================================================

## Create a new entity and return its ID
func create_entity() -> int:
	var entity_id = _next_entity_id
	_next_entity_id += 1
	_entities.append(entity_id)
	entity_created.emit(entity_id)
	return entity_id


## Create an entity linked to a Godot node (hybrid approach)
func create_entity_with_node(node: Node) -> int:
	var entity_id = create_entity()
	_entity_nodes[entity_id] = node
	_node_entities[node] = entity_id
	return entity_id


## Destroy an entity and all its components
func destroy_entity(entity_id: int) -> void:
	if entity_id not in _entities:
		return

	# Remove all components
	for component_type in _components.keys():
		if entity_id in _components[component_type]:
			_components[component_type].erase(entity_id)
			component_removed.emit(entity_id, component_type)

	# Remove node mapping
	if entity_id in _entity_nodes:
		var node = _entity_nodes[entity_id]
		_node_entities.erase(node)
		_entity_nodes.erase(entity_id)

	_entities.erase(entity_id)
	entity_destroyed.emit(entity_id)


## Check if entity exists
func entity_exists(entity_id: int) -> bool:
	return entity_id in _entities


## Get the node associated with an entity (if any)
func get_entity_node(entity_id: int) -> Node:
	return _entity_nodes.get(entity_id)


## Get the entity ID associated with a node (if any)
func get_node_entity(node: Node) -> int:
	return _node_entities.get(node, -1)


# =============================================================================
# COMPONENT MANAGEMENT
# =============================================================================

## Add a component to an entity
func add_component(entity_id: int, component_type: String, data: Dictionary = {}) -> Dictionary:
	if entity_id not in _entities:
		push_error("ECS: Cannot add component to non-existent entity %d" % entity_id)
		return {}

	if component_type not in _components:
		_components[component_type] = {}

	_components[component_type][entity_id] = data
	component_added.emit(entity_id, component_type)
	return data


## Remove a component from an entity
func remove_component(entity_id: int, component_type: String) -> void:
	if component_type in _components and entity_id in _components[component_type]:
		_components[component_type].erase(entity_id)
		component_removed.emit(entity_id, component_type)


## Get a component from an entity (returns null if not found)
func get_component(entity_id: int, component_type: String) -> Variant:
	if component_type in _components:
		return _components[component_type].get(entity_id)
	return null


## Check if entity has a component
func has_component(entity_id: int, component_type: String) -> bool:
	return component_type in _components and entity_id in _components[component_type]


## Check if entity has all specified components
func has_components(entity_id: int, component_types: Array[String]) -> bool:
	for component_type in component_types:
		if not has_component(entity_id, component_type):
			return false
	return true


## Get all entities with a specific component
func get_entities_with(component_type: String) -> Array[int]:
	if component_type not in _components:
		return []
	var result: Array[int] = []
	result.assign(_components[component_type].keys())
	return result


## Get all entities with ALL specified components
func get_entities_with_all(component_types: Array[String]) -> Array[int]:
	if component_types.is_empty():
		return []

	# Start with entities that have the first component
	var result = get_entities_with(component_types[0])

	# Filter by remaining components
	for i in range(1, component_types.size()):
		var component_type = component_types[i]
		result = result.filter(func(e): return has_component(e, component_type))

	return result


## Get all components for an entity
func get_all_components(entity_id: int) -> Dictionary:
	var result: Dictionary = {}
	for component_type in _components.keys():
		if entity_id in _components[component_type]:
			result[component_type] = _components[component_type][entity_id]
	return result


# =============================================================================
# SYSTEM MANAGEMENT
# =============================================================================

## Register a system (order matters - systems execute in registration order)
func register_system(system: ECSSystem) -> void:
	system.ecs = self
	_systems.append(system)
	system._on_registered()


## Unregister a system
func unregister_system(system: ECSSystem) -> void:
	system._on_unregistered()
	_systems.erase(system)


## Get a registered system by type
func get_system(system_class: GDScript) -> ECSSystem:
	for system in _systems:
		if system.get_script() == system_class:
			return system
	return null


## Enable/disable a system
func set_system_enabled(system_class: GDScript, enabled: bool) -> void:
	var system = get_system(system_class)
	if system:
		system.enabled = enabled


# =============================================================================
# UTILITY
# =============================================================================

## Clear all entities and components (useful for scene transitions)
func clear_all() -> void:
	for entity_id in _entities.duplicate():
		destroy_entity(entity_id)
	_entities.clear()
	_components.clear()
	_entity_nodes.clear()
	_node_entities.clear()
	_next_entity_id = 0


## Get debug info
func get_debug_info() -> Dictionary:
	return {
		"entity_count": _entities.size(),
		"component_types": _components.keys(),
		"system_count": _systems.size(),
		"systems": _systems.map(func(s): return s.get_script().resource_path.get_file())
	}
