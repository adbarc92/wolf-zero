class_name AISystem
extends ECSSystem
## Basic enemy AI: detection, patrolling, chasing, attacking


signal enemy_detected_player(enemy_id: int, player_id: int)
signal enemy_lost_player(enemy_id: int)
signal enemy_attack_started(enemy_id: int)


func _get_required_components() -> Array[String]:
	return ["ai", "position"]


func process(delta: float) -> void:
	# Get player entity for detection
	var players = ecs.get_entities_with("tag_player")
	var player_id = players[0] if players.size() > 0 else -1
	var player_pos = ecs.get_component(player_id, "position") if player_id >= 0 else null

	for entity_id in get_entities():
		var ai = get_component(entity_id, "ai")
		var pos = get_component(entity_id, "position")
		var vel = get_component(entity_id, "velocity")
		var enemy = get_component(entity_id, "enemy")

		# Update cooldowns
		if ai.attack_cooldown > 0:
			ai.attack_cooldown -= delta

		# State machine
		match ai.state:
			"idle":
				_process_idle(entity_id, ai, pos, player_pos, player_id)
			"patrol":
				_process_patrol(entity_id, ai, pos, vel, delta)
			"chase":
				_process_chase(entity_id, ai, pos, vel, player_pos, player_id, delta)
			"attack":
				_process_attack(entity_id, ai, enemy, delta)
			"telegraph":
				_process_telegraph(entity_id, ai, enemy, delta)


func _process_idle(entity_id: int, ai: Dictionary, pos: Dictionary, player_pos: Dictionary, player_id: int) -> void:
	# Check for player detection
	if _can_detect_player(ai, pos, player_pos):
		ai.state = "chase"
		ai.target_entity = player_id
		enemy_detected_player.emit(entity_id, player_id)
		return

	# Transition to patrol if has patrol points
	if ai.patrol_points.size() > 0:
		ai.state = "patrol"


func _process_patrol(entity_id: int, ai: Dictionary, pos: Dictionary, vel: Dictionary, delta: float) -> void:
	# Check for player
	var players = ecs.get_entities_with("tag_player")
	if players.size() > 0:
		var player_pos = ecs.get_component(players[0], "position")
		if _can_detect_player(ai, pos, player_pos):
			ai.state = "chase"
			ai.target_entity = players[0]
			enemy_detected_player.emit(entity_id, players[0])
			return

	# Check for Echo distraction
	if ai.can_be_distracted:
		var echoes = ecs.get_entities_with("tag_echo")
		for echo_id in echoes:
			var echo_pos = ecs.get_component(echo_id, "position")
			if _can_detect_player(ai, pos, echo_pos):
				ai.state = "chase"
				ai.target_entity = echo_id
				return

	# Move toward current patrol point
	if ai.patrol_points.is_empty():
		ai.state = "idle"
		return

	var target: Vector2 = ai.patrol_points[ai.patrol_index]
	var distance = abs(target.x - pos.x)

	if distance < 10:
		# Reached patrol point, wait then move to next
		ai.wait_timer -= delta
		if ai.wait_timer <= 0:
			ai.patrol_index = (ai.patrol_index + 1) % ai.patrol_points.size()
			ai.wait_timer = 1.0  # Wait time at each point
		if vel:
			vel.x = 0
	else:
		# Move toward point
		var direction = sign(target.x - pos.x)
		if vel:
			vel.x = direction * vel.max_speed * 0.5  # Patrol at half speed


func _process_chase(entity_id: int, ai: Dictionary, pos: Dictionary, vel: Dictionary, player_pos: Dictionary, player_id: int, _delta: float) -> void:
	# Check if target still valid
	if ai.target_entity < 0 or not ecs.entity_exists(ai.target_entity):
		ai.state = "idle"
		ai.target_entity = -1
		enemy_lost_player.emit(entity_id)
		return

	var target_pos = ecs.get_component(ai.target_entity, "position")
	if not target_pos:
		ai.state = "idle"
		return

	# Check if lost player
	var distance = Vector2(target_pos.x - pos.x, target_pos.y - pos.y).length()
	if distance > ai.detection_range * 1.5:
		ai.state = "idle"
		ai.target_entity = -1
		enemy_lost_player.emit(entity_id)
		return

	# Check if in attack range
	if distance <= ai.attack_range and ai.attack_cooldown <= 0:
		ai.state = "telegraph"
		return

	# Move toward target
	var direction = sign(target_pos.x - pos.x)
	if vel:
		vel.x = direction * vel.max_speed


func _process_telegraph(entity_id: int, ai: Dictionary, enemy: Dictionary, delta: float) -> void:
	if not enemy:
		ai.state = "attack"
		return

	enemy.is_telegraphing = true
	enemy.telegraph_timer += delta

	if enemy.telegraph_timer >= enemy.telegraph_time:
		enemy.is_telegraphing = false
		enemy.telegraph_timer = 0
		ai.state = "attack"
		enemy_attack_started.emit(entity_id)


func _process_attack(entity_id: int, ai: Dictionary, enemy: Dictionary, _delta: float) -> void:
	# Attack is handled by combat system via weapon component
	# Just set state back to chase after attack
	ai.attack_cooldown = 1.0  # Time between attacks
	ai.state = "chase"

	if enemy:
		enemy.is_telegraphing = false
		enemy.telegraph_timer = 0


func _can_detect_player(ai: Dictionary, pos: Dictionary, player_pos: Dictionary) -> bool:
	if not player_pos:
		return false

	var distance = Vector2(player_pos.x - pos.x, player_pos.y - pos.y).length()
	return distance <= ai.detection_range


## Set patrol points for an enemy
func set_patrol_points(entity_id: int, points: Array) -> void:
	var ai = get_component(entity_id, "ai")
	if ai:
		ai.patrol_points = points
		ai.patrol_index = 0
		ai.state = "patrol"
