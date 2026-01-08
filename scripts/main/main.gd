extends Node
## Main game controller
##
## Initializes ECS systems and manages game flow.

@onready var game: Node2D = $Game
@onready var entities_node: Node2D = $Game/Entities
@onready var camera: Camera2D = $Game/Camera2D

var _player_entity_id: int = -1


func _ready() -> void:
	_initialize_ecs()
	_connect_signals()

	# Start with a test level (remove this later)
	call_deferred("_spawn_test_scene")


func _initialize_ecs() -> void:
	# Register all systems in execution order
	ECS.register_system(InputSystem.new())
	ECS.register_system(JumpSystem.new())
	ECS.register_system(DodgeSystem.new())
	ECS.register_system(MovementSystem.new())
	ECS.register_system(CombatSystem.new())
	ECS.register_system(MomentumSystem.new())
	ECS.register_system(EchoSystem.new())
	ECS.register_system(HealthSystem.new())
	ECS.register_system(AISystem.new())

	print("ECS initialized with %d systems" % ECS.get_debug_info().system_count)


func _connect_signals() -> void:
	# Connect combat system signals to game events
	var combat_system: CombatSystem = ECS.get_system(CombatSystem)
	if combat_system:
		combat_system.entity_damaged.connect(_on_entity_damaged)
		combat_system.entity_died.connect(_on_entity_died)

	# Connect momentum system signals
	var momentum_system: MomentumSystem = ECS.get_system(MomentumSystem)
	if momentum_system:
		momentum_system.momentum_changed.connect(_on_momentum_changed)
		momentum_system.threshold_reached.connect(_on_momentum_threshold_reached)

	# Connect echo system signals
	var echo_system: EchoSystem = ECS.get_system(EchoSystem)
	if echo_system:
		echo_system.echo_activated.connect(_on_echo_activated)
		echo_system.echo_ended.connect(_on_echo_ended)


func _spawn_test_scene() -> void:
	# Spawn player
	_player_entity_id = _spawn_player(Vector2(200, 400))
	GameState.player_entity_id = _player_entity_id

	# Spawn a test enemy
	_spawn_enemy(Vector2(600, 400), "ronin_drone")

	# Create test platforms
	_create_test_platforms()


func _spawn_player(position: Vector2) -> int:
	# Create player node (for rendering)
	var player_node = CharacterBody2D.new()
	player_node.name = "Player"
	player_node.position = position
	entities_node.add_child(player_node)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	collision.shape = shape
	collision.position = Vector2(0, 0)
	player_node.add_child(collision)

	# Add sprite placeholder
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	# Create a simple colored rectangle as placeholder
	var image = Image.create(32, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.8, 1.0))  # Cyan
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	player_node.add_child(sprite)

	# Create entity with ECS
	var entity_id = ECS.create_entity_with_node(player_node)

	# Add components
	ECS.add_component(entity_id, "position", Components.position(position.x, position.y))
	ECS.add_component(entity_id, "velocity", Components.velocity())
	ECS.add_component(entity_id, "collision", Components.collision(32, 64))
	ECS.add_component(entity_id, "sprite", Components.sprite())
	ECS.add_component(entity_id, "health", Components.health(100))
	ECS.add_component(entity_id, "weapon", Components.weapon(15, 0.25))
	ECS.add_component(entity_id, "momentum", Components.momentum())
	ECS.add_component(entity_id, "platformer", Components.platformer(-650))
	ECS.add_component(entity_id, "dodge", Components.dodge())
	ECS.add_component(entity_id, "input_state", Components.input_state())
	ECS.add_component(entity_id, "echo_data", Components.echo_data())
	ECS.add_component(entity_id, "tag_player", Components.tag_player())

	# Apply unlocked abilities from save
	var platformer = ECS.get_component(entity_id, "platformer")
	platformer.has_dash = GameState.player_data.has_dash
	platformer.has_grapple = GameState.player_data.has_grapple
	platformer.has_air_dash = GameState.player_data.has_air_dash

	# Apply echo upgrades
	var echo_data = ECS.get_component(entity_id, "echo_data")
	echo_data.max_record_time = GameState.player_data.echo_record_time
	echo_data.cooldown_duration = GameState.player_data.echo_cooldown

	GameEvents.player_spawned.emit(entity_id)
	print("Player spawned with entity ID: ", entity_id)

	return entity_id


func _spawn_enemy(position: Vector2, enemy_type: String) -> int:
	# Create enemy node
	var enemy_node = CharacterBody2D.new()
	enemy_node.name = "Enemy_" + str(ECS._next_entity_id)
	enemy_node.position = position
	entities_node.add_child(enemy_node)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	collision.shape = shape
	enemy_node.add_child(collision)

	# Add sprite placeholder (red)
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	var image = Image.create(32, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.3, 0.2))  # Red-orange
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	enemy_node.add_child(sprite)

	# Create entity
	var entity_id = ECS.create_entity_with_node(enemy_node)

	# Add components
	ECS.add_component(entity_id, "position", Components.position(position.x, position.y))
	ECS.add_component(entity_id, "velocity", Components.velocity())
	ECS.add_component(entity_id, "collision", Components.collision(32, 64))
	ECS.add_component(entity_id, "sprite", Components.sprite())

	# Adjust health for solo mode
	var base_health = 50
	if GameState.is_solo:
		base_health = int(base_health * 0.85)  # 15% reduction
	ECS.add_component(entity_id, "health", Components.health(base_health))

	ECS.add_component(entity_id, "weapon", Components.weapon(10, 0.5))
	ECS.add_component(entity_id, "ai", Components.ai("patrol"))
	ECS.add_component(entity_id, "enemy", Components.enemy(enemy_type))
	ECS.add_component(entity_id, "tag_enemy", Components.tag_enemy())

	# Set up patrol points
	var ai = ECS.get_component(entity_id, "ai")
	ai.patrol_points = [
		Vector2(position.x - 100, position.y),
		Vector2(position.x + 100, position.y),
	]

	print("Enemy spawned: ", enemy_type, " with entity ID: ", entity_id)
	return entity_id


func _create_test_platforms() -> void:
	# Create a simple floor platform
	var floor_node = StaticBody2D.new()
	floor_node.name = "Floor"
	floor_node.position = Vector2(960, 600)
	game.get_node("World").add_child(floor_node)

	var floor_collision = CollisionShape2D.new()
	var floor_shape = RectangleShape2D.new()
	floor_shape.size = Vector2(1920, 32)
	floor_collision.shape = floor_shape
	floor_node.add_child(floor_collision)

	# Visual
	var floor_sprite = ColorRect.new()
	floor_sprite.size = Vector2(1920, 32)
	floor_sprite.position = Vector2(-960, -16)
	floor_sprite.color = Color(0.2, 0.15, 0.3)  # Dark purple
	floor_node.add_child(floor_sprite)

	# Add some platforms
	_add_platform(Vector2(400, 450), Vector2(200, 20))
	_add_platform(Vector2(700, 350), Vector2(150, 20))
	_add_platform(Vector2(1000, 400), Vector2(180, 20))


func _add_platform(position: Vector2, size: Vector2) -> void:
	var platform = StaticBody2D.new()
	platform.position = position
	game.get_node("World").add_child(platform)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)

	var visual = ColorRect.new()
	visual.size = size
	visual.position = -size / 2
	visual.color = Color(0.3, 0.2, 0.4)
	platform.add_child(visual)


func _process(_delta: float) -> void:
	# Update camera to follow player
	if _player_entity_id >= 0:
		var player_pos = ECS.get_component(_player_entity_id, "position")
		if player_pos:
			camera.position = Vector2(player_pos.x, player_pos.y)


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_entity_damaged(entity_id: int, damage: int, current_hp: int) -> void:
	if entity_id == _player_entity_id:
		GameEvents.player_damaged.emit(damage, current_hp)
		GameEvents.ui_update_health.emit(current_hp, 100)
	else:
		GameEvents.enemy_damaged.emit(entity_id, damage)

	# Visual feedback
	var node = ECS.get_entity_node(entity_id)
	if node:
		var tween = create_tween()
		var sprite = node.get_node_or_null("Sprite")
		if sprite:
			tween.tween_property(sprite, "modulate", Color.RED, 0.05)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _on_entity_died(entity_id: int) -> void:
	if entity_id == _player_entity_id:
		GameEvents.player_died.emit()
		print("Player died!")
		# Handle player death (respawn, game over, etc.)
	else:
		var enemy = ECS.get_component(entity_id, "enemy")
		var enemy_type = enemy.type if enemy else "unknown"
		GameEvents.enemy_killed.emit(entity_id, enemy_type)

		# Give XP
		GameState.add_xp(25)
		GameState.add_currency("neon_yen", 10)

		# Destroy enemy
		var node = ECS.get_entity_node(entity_id)
		if node:
			node.queue_free()
		ECS.destroy_entity(entity_id)


func _on_momentum_changed(entity_id: int, current: float, max_val: float) -> void:
	if entity_id == _player_entity_id:
		GameEvents.momentum_changed.emit(current, max_val, current / max_val)
		GameEvents.ui_update_momentum.emit(current, max_val)


func _on_momentum_threshold_reached(entity_id: int, threshold_name: String) -> void:
	if entity_id == _player_entity_id:
		match threshold_name:
			"echo":
				GameEvents.momentum_threshold_echo_reached.emit()
			"damage":
				GameEvents.momentum_threshold_damage_reached.emit()
			"ultimate":
				GameEvents.momentum_threshold_ultimate_reached.emit()


func _on_echo_activated(_owner_id: int, _echo_entity_id: int) -> void:
	GameEvents.echo_activated.emit()
	print("Echo activated!")


func _on_echo_ended(_echo_entity_id: int) -> void:
	GameEvents.echo_ended.emit()
