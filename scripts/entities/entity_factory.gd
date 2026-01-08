class_name EntityFactory
extends RefCounted
## Factory for creating common entity types with all required components
##
## Usage: var player_id = EntityFactory.create_player(ECS, position, parent_node)

# =============================================================================
# PLAYER
# =============================================================================

static func create_player(ecs: Node, position: Vector2, parent: Node2D) -> int:
	var node = _create_character_node("Player", position, Vector2(32, 64), Color(0.0, 0.8, 1.0))
	parent.add_child(node)

	var entity_id = ecs.create_entity_with_node(node)

	ecs.add_component(entity_id, "position", Components.position(position.x, position.y))
	ecs.add_component(entity_id, "velocity", Components.velocity())
	ecs.add_component(entity_id, "collision", Components.collision(32, 64))
	ecs.add_component(entity_id, "sprite", Components.sprite())
	ecs.add_component(entity_id, "health", Components.health(100))
	ecs.add_component(entity_id, "weapon", Components.weapon(15, 0.25))
	ecs.add_component(entity_id, "momentum", Components.momentum())
	ecs.add_component(entity_id, "platformer", Components.platformer(-650))
	ecs.add_component(entity_id, "dodge", Components.dodge())
	ecs.add_component(entity_id, "input_state", Components.input_state())
	ecs.add_component(entity_id, "echo_data", Components.echo_data())
	ecs.add_component(entity_id, "tag_player", Components.tag_player())

	return entity_id


# =============================================================================
# ENEMIES
# =============================================================================

static func create_enemy_ronin_drone(ecs: Node, position: Vector2, parent: Node2D, is_solo: bool = true) -> int:
	var node = _create_character_node("RoninDrone", position, Vector2(32, 64), Color(1.0, 0.3, 0.2))
	parent.add_child(node)

	var entity_id = ecs.create_entity_with_node(node)

	ecs.add_component(entity_id, "position", Components.position(position.x, position.y))
	ecs.add_component(entity_id, "velocity", Components.velocity())
	ecs.add_component(entity_id, "collision", Components.collision(32, 64))
	ecs.add_component(entity_id, "sprite", Components.sprite())

	var base_health = 50 if not is_solo else int(50 * 0.85)
	ecs.add_component(entity_id, "health", Components.health(base_health))

	ecs.add_component(entity_id, "weapon", Components.weapon(10, 0.5))
	ecs.add_component(entity_id, "ai", Components.ai("patrol"))
	ecs.add_component(entity_id, "enemy", Components.enemy("ronin_drone"))
	ecs.add_component(entity_id, "tag_enemy", Components.tag_enemy())

	return entity_id


static func create_enemy_cyber_ashigaru(ecs: Node, position: Vector2, parent: Node2D, is_solo: bool = true) -> int:
	var node = _create_character_node("CyberAshigaru", position, Vector2(28, 56), Color(1.0, 0.5, 0.0))
	parent.add_child(node)

	var entity_id = ecs.create_entity_with_node(node)

	ecs.add_component(entity_id, "position", Components.position(position.x, position.y))
	ecs.add_component(entity_id, "velocity", Components.velocity())
	ecs.add_component(entity_id, "collision", Components.collision(28, 56))
	ecs.add_component(entity_id, "sprite", Components.sprite())

	var base_health = 30 if not is_solo else int(30 * 0.85)
	ecs.add_component(entity_id, "health", Components.health(base_health))

	ecs.add_component(entity_id, "weapon", Components.weapon(8, 0.8))  # Ranged, slower
	ecs.add_component(entity_id, "ai", Components.ai("patrol"))
	ecs.add_component(entity_id, "enemy", Components.enemy("cyber_ashigaru"))
	ecs.add_component(entity_id, "tag_enemy", Components.tag_enemy())

	# Ranged enemy has longer detection range
	var ai = ecs.get_component(entity_id, "ai")
	ai.detection_range = 400.0
	ai.attack_range = 250.0

	return entity_id


static func create_enemy_oni_mech(ecs: Node, position: Vector2, parent: Node2D, is_solo: bool = true) -> int:
	var node = _create_character_node("OniMech", position, Vector2(48, 80), Color(0.6, 0.1, 0.1))
	parent.add_child(node)

	var entity_id = ecs.create_entity_with_node(node)

	ecs.add_component(entity_id, "position", Components.position(position.x, position.y))

	var vel = Components.velocity()
	vel.max_speed = 200.0  # Slower
	ecs.add_component(entity_id, "velocity", vel)

	ecs.add_component(entity_id, "collision", Components.collision(48, 80))
	ecs.add_component(entity_id, "sprite", Components.sprite())

	var base_health = 150 if not is_solo else int(150 * 0.85)
	ecs.add_component(entity_id, "health", Components.health(base_health))

	ecs.add_component(entity_id, "weapon", Components.weapon(25, 1.0))  # High damage, slow
	ecs.add_component(entity_id, "ai", Components.ai("patrol"))

	var enemy = Components.enemy("oni_mech")
	enemy.has_armor = true
	enemy.armor_hits = 3
	enemy.telegraph_time = 0.8  # Longer telegraph
	ecs.add_component(entity_id, "enemy", enemy)

	ecs.add_component(entity_id, "tag_enemy", Components.tag_enemy())

	return entity_id


# =============================================================================
# ECHO
# =============================================================================

static func create_echo(ecs: Node, position: Vector2, parent: Node2D, owner_id: int, recorded_actions: Array) -> int:
	var node = _create_character_node("Echo", position, Vector2(32, 64), Color(0.0, 0.8, 1.0, 0.5))
	parent.add_child(node)

	var entity_id = ecs.create_entity_with_node(node)

	ecs.add_component(entity_id, "position", Components.position(position.x, position.y))
	ecs.add_component(entity_id, "velocity", Components.velocity())
	ecs.add_component(entity_id, "sprite", Components.sprite())
	ecs.add_component(entity_id, "tag_echo", Components.tag_echo())

	# Copy weapon stats from owner
	var owner_weapon = ecs.get_component(owner_id, "weapon")
	if owner_weapon:
		ecs.add_component(entity_id, "weapon", Components.weapon(owner_weapon.damage, owner_weapon.attack_speed))

	# Set up echo instance
	var instance = Components.echo_instance()
	instance.owner_entity = owner_id
	instance.recorded_actions = recorded_actions
	ecs.add_component(entity_id, "echo_instance", instance)

	return entity_id


# =============================================================================
# HELPERS
# =============================================================================

static func _create_character_node(node_name: String, position: Vector2, size: Vector2, color: Color) -> CharacterBody2D:
	var node = CharacterBody2D.new()
	node.name = node_name
	node.position = position

	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	node.add_child(collision)

	# Placeholder sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)
	node.add_child(sprite)

	return node
