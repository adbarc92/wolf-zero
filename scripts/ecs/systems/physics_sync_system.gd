class_name PhysicsSyncSystem
extends ECSSystem
## Single physics authority. For each entity whose node is a CharacterBody2D
## (and is NOT a kinematic echo), pushes the velocity component onto the node,
## runs move_and_slide(), then reads position + collision flags back into ECS.


func _get_required_components() -> Array[String]:
	return ["velocity", "position", "collision"]


func process(_delta: float) -> void:
	for entity_id in get_entities():
		if has_component(entity_id, "tag_echo"):
			continue

		var node = get_node(entity_id)
		if not (node is CharacterBody2D):
			continue

		var vel = get_component(entity_id, "velocity")
		var pos = get_component(entity_id, "position")
		var collision = get_component(entity_id, "collision")

		node.velocity = Vector2(vel.x, vel.y)
		node.move_and_slide()

		pos.x = node.position.x
		pos.y = node.position.y
		vel.x = node.velocity.x
		vel.y = node.velocity.y

		collision.on_ground = node.is_on_floor()
		collision.on_wall = node.is_on_wall()
		collision.on_ceiling = node.is_on_ceiling()
		if collision.on_wall:
			collision.wall_direction = -int(sign(node.get_wall_normal().x))
		else:
			collision.wall_direction = 0
