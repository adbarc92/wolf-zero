class_name CombatSystem
extends ECSSystem
## Handles combat actions: attacks, combos, damage application


signal attack_started(entity_id: int, attack_type: String)
signal attack_hit(attacker_id: int, target_id: int, damage: int)
signal combo_increased(entity_id: int, combo_count: int)
signal entity_damaged(entity_id: int, damage: int, current_hp: int)
signal entity_died(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["weapon", "health"]


func process(delta: float) -> void:
	_process_attack_timers(delta)
	_process_attack_inputs()
	_process_hitboxes()


func _process_attack_timers(delta: float) -> void:
	for entity_id in ecs.get_entities_with("weapon"):
		var weapon = get_component(entity_id, "weapon")

		# Update attack timer
		if weapon.attack_timer > 0:
			weapon.attack_timer -= delta
			if weapon.attack_timer <= 0:
				weapon.is_attacking = false
				weapon.hitbox_active = false
				weapon.attack_type = "none"

		# Update combo timer
		if weapon.combo_timer > 0:
			weapon.combo_timer -= delta
			if weapon.combo_timer <= 0:
				weapon.combo_current = 0


func _process_attack_inputs() -> void:
	for entity_id in ecs.get_entities_with_all(["weapon", "input_state"]):
		var weapon = get_component(entity_id, "weapon")
		var input = get_component(entity_id, "input_state")

		# Can't attack while already attacking
		if weapon.is_attacking:
			continue

		# Light attack
		if input.attack_light:
			_start_light_attack(entity_id, weapon)
		# Heavy attack
		elif input.attack_heavy:
			_start_heavy_attack(entity_id, weapon, input)


func _start_light_attack(entity_id: int, weapon: Dictionary) -> void:
	weapon.is_attacking = true
	weapon.attack_timer = weapon.attack_speed
	weapon.hitbox_active = true
	weapon.attack_type = "light"

	# Combo handling
	if weapon.combo_current < weapon.combo_max:
		weapon.combo_current += 1
		combo_increased.emit(entity_id, weapon.combo_current)
	weapon.combo_timer = weapon.combo_window

	attack_started.emit(entity_id, "light_%d" % weapon.combo_current)

	# Add momentum
	_add_momentum(entity_id, "attack")

	# Spawn attack VFX
	var pos = get_component(entity_id, "position")
	var input = get_component(entity_id, "input_state")
	if pos and VFXManager:
		var facing = input.facing if input else 1
		var attack_pos = Vector2(pos.x + facing * 40, pos.y)
		VFXManager.attack_effect(attack_pos, facing, "light_%d" % weapon.combo_current)


func _start_heavy_attack(entity_id: int, weapon: Dictionary, input: Dictionary) -> void:
	weapon.is_attacking = true
	weapon.attack_timer = weapon.attack_speed * 1.5  # Heavy is slower
	weapon.hitbox_active = true

	# Determine heavy attack type based on direction
	var dir = input.attack_direction
	if dir.y < -0.5:
		weapon.attack_type = "heavy_up"
	elif dir.y > 0.5:
		weapon.attack_type = "heavy_down"
	else:
		weapon.attack_type = "heavy_forward"

	# Reset combo on heavy attack
	weapon.combo_current = 0
	weapon.combo_timer = 0

	attack_started.emit(entity_id, weapon.attack_type)

	# Add momentum
	_add_momentum(entity_id, "attack")

	# Spawn attack VFX
	var pos = get_component(entity_id, "position")
	if pos and VFXManager:
		var facing = input.facing if input else 1
		var attack_pos = Vector2(pos.x + facing * 40, pos.y)
		VFXManager.attack_effect(attack_pos, facing, weapon.attack_type)


func _process_hitboxes() -> void:
	# Get all entities with active hitboxes
	for attacker_id in ecs.get_entities_with("weapon"):
		var weapon = get_component(attacker_id, "weapon")
		if not weapon.hitbox_active:
			continue

		var attacker_pos = get_component(attacker_id, "position")
		var attacker_input = get_component(attacker_id, "input_state")
		if not attacker_pos:
			continue

		var facing = attacker_input.facing if attacker_input else 1
		var is_player = has_component(attacker_id, "tag_player")

		# Check against potential targets
		var target_tag = "tag_enemy" if is_player else "tag_player"
		for target_id in ecs.get_entities_with(target_tag):
			if _check_hit(attacker_id, target_id, facing):
				_apply_damage(attacker_id, target_id, weapon)


func _check_hit(attacker_id: int, target_id: int, facing: int) -> bool:
	var attacker_pos = get_component(attacker_id, "position")
	var target_pos = get_component(target_id, "position")
	var target_collision = get_component(target_id, "collision")
	var target_health = get_component(target_id, "health")

	if not attacker_pos or not target_pos or not target_collision or not target_health:
		return false

	# Check invincibility
	if target_health.invincible:
		return false

	# Simple hitbox check (could be more sophisticated)
	var attack_range = 60.0  # Base attack range
	var attack_width = 40.0

	var dx = target_pos.x - attacker_pos.x
	var dy = target_pos.y - attacker_pos.y

	# Check if target is in front of attacker
	if facing > 0 and dx < 0:
		return false
	if facing < 0 and dx > 0:
		return false

	# Check distance
	if abs(dx) > attack_range or abs(dy) > attack_width:
		return false

	return true


func _apply_damage(attacker_id: int, target_id: int, weapon: Dictionary) -> void:
	var target_health = get_component(target_id, "health")
	var target_enemy = get_component(target_id, "enemy")

	var damage = weapon.damage

	# Bonus damage from combo
	damage += weapon.combo_current * 2

	# Check armor
	if target_enemy and target_enemy.has_armor and target_enemy.armor_hits > 0:
		if weapon.attack_type.begins_with("heavy"):
			target_enemy.armor_hits -= 1
		else:
			damage = int(damage * 0.5)  # Reduced damage against armor

	# Apply damage
	target_health.current -= damage
	target_health.invincible = true
	target_health.invincibility_timer = target_health.invincibility_duration

	attack_hit.emit(attacker_id, target_id, damage)
	entity_damaged.emit(target_id, damage, target_health.current)

	# Hit VFX (hitstop, shake, sparks)
	var target_pos = get_component(target_id, "position")
	if target_pos and VFXManager:
		var is_critical = weapon.combo_current >= 4  # Critical on high combo
		VFXManager.hit_effect(Vector2(target_pos.x, target_pos.y), damage, is_critical)

	# Check death
	if target_health.current <= 0:
		entity_died.emit(target_id)

	# Disable hitbox after hit to prevent multi-hit
	weapon.hitbox_active = false


func _add_momentum(entity_id: int, action_type: String) -> void:
	var momentum = get_component(entity_id, "momentum")
	if not momentum:
		return

	var gain = 0.0
	match action_type:
		"attack":
			gain = momentum.gain_attack
		"dodge":
			gain = momentum.gain_dodge
		"parry":
			gain = momentum.gain_parry

	momentum.current = min(momentum.current + gain, momentum.max)
	momentum.decay_timer = momentum.decay_delay


## Apply damage to an entity from external source
func apply_damage_to(target_id: int, damage: int, _source_id: int = -1) -> void:
	var health = get_component(target_id, "health")
	if not health or health.invincible:
		return

	health.current -= damage
	health.invincible = true
	health.invincibility_timer = health.invincibility_duration

	entity_damaged.emit(target_id, damage, health.current)

	if health.current <= 0:
		entity_died.emit(target_id)
