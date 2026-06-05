extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_floor(parent: Node) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 200)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1000, 40)
	cs.shape = shape
	floor_body.add_child(cs)
	parent.add_child(floor_body)

func _make_body(parent: Node) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.position = Vector2(0, 0)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body

func test_body_falls_and_lands_with_collision_readback():
	var root := Node2D.new()
	add_child_autofree(root)
	_make_floor(root)
	var body := _make_body(root)

	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var phys := PhysicsSyncSystem.new()
	phys.ecs = ecs

	var e = ecs.create_entity_with_node(body)
	ecs.add_component(e, "position", Components.position(0, 0))
	var vel = Components.velocity()
	vel.y = 400.0  # falling
	ecs.add_component(e, "velocity", vel)
	ecs.add_component(e, "collision", Components.collision(32, 64))

	for i in range(30):
		var v = ecs.get_component(e, "velocity")
		v.y += 1800.0 * (1.0 / 60.0)  # gravity, mimicking MovementSystem
		phys.process(1.0 / 60.0)
		await get_tree().physics_frame

	var collision = ecs.get_component(e, "collision")
	var pos = ecs.get_component(e, "position")
	assert_true(collision.on_ground, "body should land on the floor")
	assert_almost_eq(pos.y, body.position.y, 0.01, "position component synced from node")
