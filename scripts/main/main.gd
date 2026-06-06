extends Node
## Main game controller
##
## Initializes ECS systems and manages game flow.

const FK := "res://assets/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/"
const FK2 := "res://assets/FreeKnight_v1/Colour2/NoOutline/120x80_PNGSheets/"

@onready var game: Node2D = $Game
@onready var entities_node: Node2D = $Game/Entities
@onready var camera: Camera2D = $Game/Camera2D

var _player_entity_id: int = -1
var _player_spawn: Vector2
var _echo_was_ready: bool = false
var _arenas_activated: Array = []
var _arena_enemies: Dictionary = {}  # arena_index -> Array[entity_id]
var _current_arena: int = -1
var _won: bool = false


static func archetype(kind: String) -> Dictionary:
	match kind:
		"cyber_ashigaru":
			return {"health": 30, "damage": 8, "speed": 260.0, "armor_hits": 0,
				"is_ranged": true, "detection": 420.0, "attack_range": 320.0, "tint": Color(0.7, 1.0, 0.8)}
		"oni_mech":
			return {"health": 120, "damage": 20, "speed": 140.0, "armor_hits": 3,
				"is_ranged": false, "detection": 300.0, "attack_range": 60.0, "tint": Color(1.0, 0.6, 0.5)}
		"elite_oni":
			return {"health": 200, "damage": 26, "speed": 170.0, "armor_hits": 4,
				"is_ranged": false, "detection": 380.0, "attack_range": 64.0, "tint": Color(1.0, 0.3, 0.3)}
		_:
			return {"health": 50, "damage": 10, "speed": 200.0, "armor_hits": 0,
				"is_ranged": false, "detection": 300.0, "attack_range": 50.0, "tint": Color.WHITE}


func _ready() -> void:
	_initialize_ecs()
	_connect_signals()
	_setup_vfx_manager()
	_setup_parallax()

	# Dev-only on-screen input-action guide (F1 to toggle)
	if OS.is_debug_build():
		add_child(DebugOverlay.new())

	# Start with a test level (remove this later)
	call_deferred("_spawn_test_scene")


func _initialize_ecs() -> void:
	ECS.register_system(InputSystem.new())
	ECS.register_system(AISystem.new())
	ECS.register_system(ParrySystem.new())
	ECS.register_system(JumpSystem.new())
	ECS.register_system(DodgeSystem.new())
	ECS.register_system(MovementSystem.new())
	ECS.register_system(PhysicsSyncSystem.new())
	ECS.register_system(EchoSystem.new())
	ECS.register_system(CombatSystem.new())
	ECS.register_system(ProjectileSystem.new())
	ECS.register_system(MomentumSystem.new())
	ECS.register_system(HealthSystem.new())

	var anim := AnimationSystem.new()
	anim.frame_sets = {
		"player": _build_player_frames(),
		"enemy": _build_enemy_frames(),
	}
	ECS.register_system(anim)

	print("ECS initialized with %d systems" % ECS.get_debug_info().system_count)


func _build_player_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	SpriteFramesBuilder.add_strip(sf, "idle", load(FK + "_Idle.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "run", load(FK + "_Run.png"), 120, 80, 14.0)
	SpriteFramesBuilder.add_strip(sf, "jump", load(FK + "_Jump.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "fall", load(FK + "_Fall.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "dash", load(FK + "_Dash.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "roll", load(FK + "_Roll.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "slide", load(FK + "_Slide.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_1", load(FK + "_Attack.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_2", load(FK + "_Attack2.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_3", load(FK + "_AttackCombo.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_4", load(FK + "_AttackCombo.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_5", load(FK + "_AttackCombo.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "hit", load(FK + "_Hit.png"), 120, 80, 12.0, false)
	SpriteFramesBuilder.add_strip(sf, "crouch", load(FK + "_Crouch.png"), 120, 80, 8.0)
	SpriteFramesBuilder.add_strip(sf, "crouch_walk", load(FK + "_CrouchWalk.png"), 120, 80, 12.0)
	SpriteFramesBuilder.add_strip(sf, "wall_slide", load(FK + "_WallSlide.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "wall_climb", load(FK + "_WallClimb.png"), 120, 80, 12.0)
	SpriteFramesBuilder.add_strip(sf, "death", load(FK + "_Death.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "jump_fall_inbetween", load(FK + "_JumpFallInbetween.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "turn_around", load(FK + "_TurnAround.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "crouch_transition", load(FK + "_CrouchTransition.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "crouch_attack", load(FK + "_CrouchAttack.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_1_nomove", load(FK + "_AttackNoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_2_nomove", load(FK + "_Attack2NoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_3_nomove", load(FK + "_AttackComboNoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_4_nomove", load(FK + "_AttackComboNoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_5_nomove", load(FK + "_AttackComboNoMovement.png"), 120, 80, 16.0, false)
	return sf


func _build_enemy_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	SpriteFramesBuilder.add_strip(sf, "idle", load(FK2 + "_Idle.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "run", load(FK2 + "_Run.png"), 120, 80, 12.0)
	SpriteFramesBuilder.add_strip(sf, "light_1", load(FK2 + "_Attack.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "slide", load(FK2 + "_Slide.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "hit", load(FK2 + "_Hit.png"), 120, 80, 12.0, false)
	SpriteFramesBuilder.add_strip(sf, "wall_slide", load(FK2 + "_WallSlide.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "wall_climb", load(FK2 + "_WallClimb.png"), 120, 80, 12.0)
	SpriteFramesBuilder.add_strip(sf, "death", load(FK2 + "_Death.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "jump_fall_inbetween", load(FK2 + "_JumpFallInbetween.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "turn_around", load(FK2 + "_TurnAround.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "crouch_transition", load(FK2 + "_CrouchTransition.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "crouch_attack", load(FK2 + "_CrouchAttack.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_1_nomove", load(FK2 + "_AttackNoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_2_nomove", load(FK2 + "_Attack2NoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_3_nomove", load(FK2 + "_AttackComboNoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_4_nomove", load(FK2 + "_AttackComboNoMovement.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_5_nomove", load(FK2 + "_AttackComboNoMovement.png"), 120, 80, 16.0, false)
	return sf


func _setup_vfx_manager() -> void:
	# Set camera for screen shake
	VFXManager.set_camera(camera)

	# Set effect container for spawning VFX
	VFXManager.set_effect_container(entities_node)


func _setup_parallax() -> void:
	var pbg := ParallaxBackground.new()
	pbg.name = "Parallax"
	_add_layer(pbg, "res://assets/MoonlitGraveyard/Background_0.png", 0.2, Vector2(2, 2))
	_add_layer(pbg, "res://assets/MoonlitGraveyard/Background_1.png", 0.5, Vector2(2, 2))
	add_child(pbg)


func _add_layer(pbg: ParallaxBackground, path: String, scroll_scale: float, scale_v: Vector2) -> void:
	var tex = load(path)
	if tex == null:
		push_warning("Parallax layer missing: " + path)
		return
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(scroll_scale, scroll_scale)
	layer.motion_mirroring = Vector2(tex.get_width() * scale_v.x, 0)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = scale_v
	spr.position = Vector2(0, 0)
	layer.add_child(spr)
	pbg.add_child(layer)


func _connect_signals() -> void:
	# Connect combat system signals to game events
	var combat_system: CombatSystem = ECS.get_system(CombatSystem)
	if combat_system:
		combat_system.entity_damaged.connect(_on_entity_damaged)
		combat_system.entity_died.connect(_on_entity_died)
		combat_system.parried.connect(_on_parried)

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
	_player_spawn = LevelOne.SPAWN
	_player_entity_id = _spawn_player(_player_spawn)
	GameState.player_entity_id = _player_entity_id
	_build_level()


func _build_level() -> void:
	for p in LevelOne.platforms():
		_add_platform(p[0], p[1])
	camera.limit_left = 0
	camera.limit_right = int(LevelOne.EXTENT_X)
	camera.limit_top = -400
	camera.limit_bottom = int(LevelOne.FLOOR_Y) + 120

	var goal := ColorRect.new()
	goal.size = Vector2(20, 300)
	goal.position = Vector2(LevelOne.GOAL_X, LevelOne.FLOOR_Y - 300)
	goal.color = Color(0.0, 0.9, 1.0, 0.6)
	game.get_node("World").add_child(goal)


func _spawn_player(position: Vector2) -> int:
	# Create player node (for rendering)
	var player_node = CharacterBody2D.new()
	player_node.name = "Player"
	player_node.position = position
	player_node.add_to_group("player")
	entities_node.add_child(player_node)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	collision.shape = shape
	collision.position = Vector2(0, 0)
	player_node.add_child(collision)

	# Visual is created by AnimationSystem (AnimatedSprite2D named "Anim").

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
	ECS.add_component(entity_id, "parry", Components.parry())
	ECS.add_component(entity_id, "input_state", Components.input_state())
	ECS.add_component(entity_id, "echo_data", Components.echo_data())
	ECS.add_component(entity_id, "tag_player", Components.tag_player())

	# Apply unlocked abilities from save
	var platformer = ECS.get_component(entity_id, "platformer")
	platformer.has_dash = GameState.player_data.has_dash
	platformer.has_grapple = GameState.player_data.has_grapple
	platformer.has_air_dash = GameState.player_data.has_air_dash
	platformer.has_dash = true  # Slice grants dash (P0)

	# Apply echo upgrades
	var echo_data = ECS.get_component(entity_id, "echo_data")
	echo_data.max_record_time = GameState.player_data.echo_record_time
	echo_data.cooldown_duration = GameState.player_data.echo_cooldown

	GameEvents.player_spawned.emit(entity_id)
	print("Player spawned with entity ID: ", entity_id)

	# Emit initial HUD values
	var health = ECS.get_component(entity_id, "health")
	GameEvents.ui_update_health.emit(health.current, health.max)

	var momentum = ECS.get_component(entity_id, "momentum")
	GameEvents.ui_update_momentum.emit(momentum.current, momentum.max)

	GameEvents.ui_update_echo_cooldown.emit(0.0, echo_data.cooldown_duration)

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

	# Visual is created by AnimationSystem (AnimatedSprite2D named "Anim").

	# Create entity
	var entity_id = ECS.create_entity_with_node(enemy_node)

	# Add components
	ECS.add_component(entity_id, "position", Components.position(position.x, position.y))
	ECS.add_component(entity_id, "velocity", Components.velocity())
	ECS.add_component(entity_id, "collision", Components.collision(32, 64))
	ECS.add_component(entity_id, "sprite", Components.sprite())
	ECS.get_component(entity_id, "sprite").frame_set = "enemy"

	# Apply archetype-driven setup
	var arch := archetype(enemy_type)
	var base_health = int(arch.health)
	if GameState.is_solo:
		base_health = int(base_health * 0.85)  # 15% reduction
	ECS.add_component(entity_id, "health", Components.health(base_health))
	ECS.add_component(entity_id, "weapon", Components.weapon(int(arch.damage), 0.5))
	ECS.add_component(entity_id, "platformer", Components.platformer())
	ECS.add_component(entity_id, "ai", Components.ai("patrol"))
	ECS.add_component(entity_id, "enemy", Components.enemy(enemy_type))
	ECS.add_component(entity_id, "tag_enemy", Components.tag_enemy())

	# Apply archetype values
	var avel = ECS.get_component(entity_id, "velocity"); avel.max_speed = arch.speed
	var aenemy = ECS.get_component(entity_id, "enemy")
	aenemy.is_ranged = arch.is_ranged
	aenemy.has_armor = arch.armor_hits > 0
	aenemy.armor_hits = arch.armor_hits
	var aai = ECS.get_component(entity_id, "ai")
	aai.detection_range = arch.detection
	aai.attack_range = arch.attack_range
	ECS.get_component(entity_id, "sprite").modulate = arch.tint

	# Set up patrol points
	var ai = ECS.get_component(entity_id, "ai")
	ai.patrol_points = [
		Vector2(position.x - 100, position.y),
		Vector2(position.x + 100, position.y),
	]

	print("Enemy spawned: ", enemy_type, " with entity ID: ", entity_id)
	return entity_id


func _activate_arena(index: int) -> void:
	_arenas_activated.append(index)
	_current_arena = index
	var arena = LevelOne.arenas()[index]
	_player_spawn = arena.checkpoint
	var ids: Array = []
	for spec in arena.enemies:
		ids.append(_spawn_enemy(spec[1], spec[0]))
	_arena_enemies[index] = ids


func _restore_arena(index: int) -> void:
	# Despawn any survivors from this arena.
	for eid in _arena_enemies.get(index, []):
		if ECS.entity_exists(eid):
			var n = ECS.get_entity_node(eid)
			if n:
				n.queue_free()
			ECS.destroy_entity(eid)
	# Re-spawn the roster.
	var arena = LevelOne.arenas()[index]
	var ids: Array = []
	for spec in arena.enemies:
		ids.append(_spawn_enemy(spec[1], spec[0]))
	_arena_enemies[index] = ids


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

	# Tall test wall
	_add_platform(Vector2(1700, 450), Vector2(40, 300))


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.current_state == GameState.State.PLAYING:
			GameState.pause_game()
		elif GameState.current_state == GameState.State.PAUSED:
			GameState.resume_game()


func _process(delta: float) -> void:
	_process_dying(delta)

	if _player_entity_id < 0:
		return

	# Update camera to follow player
	var player_pos = ECS.get_component(_player_entity_id, "position")
	if player_pos:
		camera.position = Vector2(player_pos.x, LevelOne.FLOOR_Y - 120)

		var px = ECS.get_component(_player_entity_id, "position").x
		var idx = LevelOne.arena_to_activate(px, _arenas_activated)
		if idx >= 0:
			_activate_arena(idx)

		var final_idx = LevelOne.arenas().size() - 1
		var final_cleared = _arenas_activated.has(final_idx) \
			and _arena_enemies.has(final_idx) \
			and _living_count(_arena_enemies[final_idx]) == 0
		if not _won and LevelOne.is_level_won(px, final_cleared):
			_won = true
			_show_victory()

	# Update echo cooldown HUD
	var echo_data = ECS.get_component(_player_entity_id, "echo_data")
	if echo_data:
		GameEvents.ui_update_echo_cooldown.emit(echo_data.cooldown, echo_data.cooldown_duration)

		# Emit echo ready/not ready events
		if echo_data.can_activate and echo_data.cooldown <= 0:
			if not _echo_was_ready:
				GameEvents.echo_ready.emit()
				_echo_was_ready = true
		else:
			if _echo_was_ready:
				GameEvents.echo_not_ready.emit()
				_echo_was_ready = false


# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_entity_damaged(entity_id: int, damage: int, current_hp: int) -> void:
	var health = ECS.get_component(entity_id, "health")
	var max_hp = health.max if health else 100

	if entity_id == _player_entity_id:
		GameEvents.player_damaged.emit(damage, current_hp)
		GameEvents.ui_update_health.emit(current_hp, max_hp)
	else:
		GameEvents.enemy_damaged.emit(entity_id, damage)

	# Show damage number
	var pos = ECS.get_component(entity_id, "position")
	if pos:
		GameEvents.ui_show_damage_number.emit(Vector2(pos.x, pos.y - 40), damage, false)

	# Visual feedback
	var node = ECS.get_entity_node(entity_id)
	if node:
		var tween = create_tween()
		var sprite = node.get_node_or_null("Anim")
		if sprite:
			tween.tween_property(sprite, "modulate", Color.RED, 0.05)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


static func _is_victory(living_enemy_count: int) -> bool:
	return living_enemy_count <= 0


func _living_count(ids: Array) -> int:
	var n := 0
	for eid in ids:
		if ECS.entity_exists(eid):
			n += 1
	return n


func _show_victory() -> void:
	if has_node("WinLayer"):
		return
	var layer := CanvasLayer.new()
	layer.name = "WinLayer"
	layer.layer = 50
	layer.add_child(WinLabel.new())
	add_child(layer)


static func _respawn_player_state(health: Dictionary, pos: Dictionary, spawn: Vector2) -> void:
	health.current = health.max
	health.invincible = false
	health.invincibility_timer = 0.0
	pos.x = spawn.x
	pos.y = spawn.y


func _on_entity_died(entity_id: int) -> void:
	if ECS.has_component(entity_id, "dying"):
		return  # already dying
	# Freeze the entity and play its death animation; despawn/respawn is deferred.
	ECS.add_component(entity_id, "dying", Components.dying())
	var vel = ECS.get_component(entity_id, "velocity")
	if vel:
		vel.x = 0.0
	var ai = ECS.get_component(entity_id, "ai")
	if ai:
		ai.state = "dead"  # AISystem has no "dead" case -> it idles; that's fine
	var weapon = ECS.get_component(entity_id, "weapon")
	if weapon:
		weapon.hitbox_active = false
	if entity_id == _player_entity_id:
		GameEvents.player_died.emit()


func _process_dying(delta: float) -> void:
	for eid in ECS.get_entities_with("dying"):
		var d = ECS.get_component(eid, "dying")
		d.timer -= delta
		if d.timer > 0.0:
			continue
		if eid == _player_entity_id:
			_finish_player_death(eid)
		else:
			_finish_enemy_death(eid)


func _finish_player_death(eid: int) -> void:
	ECS.remove_component(eid, "dying")
	var health = ECS.get_component(eid, "health")
	var pos = ECS.get_component(eid, "position")
	_respawn_player_state(health, pos, _player_spawn)
	var node = ECS.get_entity_node(eid)
	if node:
		node.position = _player_spawn
		if node is CharacterBody2D:
			node.velocity = Vector2.ZERO
	GameEvents.ui_update_health.emit(health.current, health.max)
	print("Player respawned")
	if _current_arena >= 0:
		_restore_arena(_current_arena)


func _finish_enemy_death(eid: int) -> void:
	var enemy = ECS.get_component(eid, "enemy")
	var enemy_type = enemy.type if enemy else "unknown"
	GameEvents.enemy_killed.emit(eid, enemy_type)

	# Give XP
	GameState.add_xp(25)
	GameState.add_currency("neon_yen", 10)

	# Destroy enemy (this also removes its dying component)
	var node = ECS.get_entity_node(eid)
	if node:
		node.queue_free()
	ECS.destroy_entity(eid)


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


func _on_parried(_defender_id: int, _attacker_id: int) -> void:
	print("Parry!")
