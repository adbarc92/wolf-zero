extends CharacterBody2D
## Player Controller - Bridges ECS with Godot's physics
##
## This script syncs the ECS entity with Godot's CharacterBody2D physics.
## It handles collision detection and reports back to ECS components.

var entity_id: int = -1


func _ready() -> void:
	# Get entity ID from ECS
	entity_id = ECS.get_node_entity(self)
	if entity_id < 0:
		push_error("PlayerController: No entity ID found for this node")


func _physics_process(_delta: float) -> void:
	if entity_id < 0:
		return

	# Get velocity from ECS
	var vel = ECS.get_component(entity_id, "velocity")
	if not vel:
		return

	# Apply velocity to CharacterBody2D
	velocity = Vector2(vel.x, vel.y)

	# Use Godot's physics
	move_and_slide()

	# Update ECS components with physics results
	_update_position()
	_update_collision()
	_sync_velocity()


func _update_position() -> void:
	var pos = ECS.get_component(entity_id, "position")
	if pos:
		pos.x = position.x
		pos.y = position.y


func _update_collision() -> void:
	var collision = ECS.get_component(entity_id, "collision")
	if not collision:
		return

	collision.on_ground = is_on_floor()
	collision.on_wall = is_on_wall()
	collision.on_ceiling = is_on_ceiling()

	# Determine wall direction
	if collision.on_wall:
		var wall_normal = get_wall_normal()
		collision.wall_direction = -int(sign(wall_normal.x))
	else:
		collision.wall_direction = 0


func _sync_velocity() -> void:
	var vel = ECS.get_component(entity_id, "velocity")
	if vel:
		# Update ECS velocity with actual velocity after collisions
		vel.x = velocity.x
		vel.y = velocity.y
