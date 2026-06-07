class_name CombatSystem
extends ECSSystem
## Handles combat actions: attacks, combos, damage application


signal attack_started(entity_id: int, attack_type: String)
signal attack_hit(attacker_id: int, target_id: int, damage: int)
signal combo_increased(entity_id: int, combo_count: int)
signal entity_damaged(entity_id: int, damage: int, current_hp: int)
signal entity_died(entity_id: int)
signal parried(defender_id: int, attacker_id: int)
signal blocked(defender_id: int, attacker_id: int)


static func block_damage(raw: int, mult: float) -> int:
	return max(1, int(raw * mult))


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
	var input_entities: Array[String] = ["weapon", "input_state"]
	for entity_id in ecs.get_entities_with_all(input_entities):
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

	# Add momentum (routed through MomentumSystem so HUD/threshold signals fire)
	var momentum_system = ecs.get_system(MomentumSystem)
	if momentum_system:
		var momentum = get_component(entity_id, "momentum")
		if momentum:
			momentum_system.add_momentum(entity_id, momentum.gain_attack)

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

	# Add momentum (routed through MomentumSystem so HUD/threshold signals fire)
	var momentum_system = ecs.get_system(MomentumSystem)
	if momentum_system:
		var momentum = get_component(entity_id, "momentum")
		if momentum:
			momentum_system.add_momentum(entity_id, momentum.gain_attack)

	# Spawn attack VFX
	var pos = get_component(entity_id, "position")
	if pos and VFXManager:
		var facing = input.facing if input else 1
		var attack_pos = Vector2(pos.x + facing * 40, pos.y)
		VFXManager.attack_effect(attack_pos, facing, weapon.attack_type)


## Decide an attacker's facing: input_state.facing -> velocity sign -> stored enemy.facing.
static func resolve_facing(input_state, velocity, enemy) -> int:
	if input_state != null:
		return input_state.facing
	if velocity != null and abs(velocity.x) > 1.0:
		return -1 if velocity.x < 0.0 else 1
	if enemy != null:
		return enemy.get("facing", 1)
	return 1


func _process_hitboxes() -> void:
	# Get all entities with active hitboxes
	for attacker_id in ecs.get_entities_with("weapon"):
		var weapon = get_component(attacker_id, "weapon")
		if not weapon.hitbox_active:
			continue

		var attacker_pos = get_component(attacker_id, "position")
		if not attacker_pos:
			continue

		var attacker_input = get_component(attacker_id, "input_state")
		var attacker_vel = get_component(attacker_id, "velocity")
		var attacker_enemy = get_component(attacker_id, "enemy")
		var facing = resolve_facing(attacker_input, attacker_vel, attacker_enemy)
		var is_player_team = has_component(attacker_id, "tag_player") or has_component(attacker_id, "tag_echo")

		# Check against potential targets
		var target_tag = "tag_enemy" if is_player_team else "tag_player"
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
	# Parry: a parrying target negates the hit, reflects damage, and staggers the attacker.
	var target_parry = get_component(target_id, "parry")
	if target_parry and target_parry.is_parrying:
		target_parry.is_parrying = false
		var atk_health = get_component(attacker_id, "health")
		if atk_health:
			var reflect: int = max(weapon.damage, 10)
			atk_health.current -= reflect
			entity_damaged.emit(attacker_id, reflect, atk_health.current)
			if atk_health.current <= 0:
				entity_died.emit(attacker_id)
		var atk_ai = get_component(attacker_id, "ai")
		if atk_ai:
			atk_ai.state = "stagger"
			atk_ai.stagger_timer = 1.0
		var mom = get_component(target_id, "momentum")
		var mom_sys = ecs.get_system(MomentumSystem)
		if mom and mom_sys:
			mom_sys.add_momentum(target_id, mom.gain_parry)
		parried.emit(target_id, attacker_id)
		if VFXManager:
			VFXManager.screen_shake(0.5, 0.15)
		weapon.hitbox_active = false  # consume the attack
		return

	# Block: a blocking target takes chip damage, no knockback/stagger, no reflect.
	var target_block = get_component(target_id, "parry")
	if target_block and target_block.is_blocking:
		var th = get_component(target_id, "health")
		if th and not th.invincible:
			var dmg_blocked := block_damage(weapon.damage, target_block.block_damage_mult)
			th.current -= dmg_blocked
			th.hurt_timer = 0.12
			th.invincible = true
			th.invincibility_timer = th.invincibility_duration
			entity_damaged.emit(target_id, dmg_blocked, th.current)
			if th.current <= 0:
				entity_died.emit(target_id)
		blocked.emit(target_id, attacker_id)
		weapon.hitbox_active = false
		return

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
	target_health.hurt_timer = 0.25

	# Knockback away from the attacker
	var target_vel = get_component(target_id, "velocity")
	var attacker_pos_k = get_component(attacker_id, "position")
	var target_pos_k = get_component(target_id, "position")
	if target_vel and attacker_pos_k and target_pos_k:
		var dir := 1.0 if target_pos_k.x >= attacker_pos_k.x else -1.0
		var knock := 250.0
		if weapon.attack_type.begins_with("heavy"):
			knock = 450.0
		target_vel.x = dir * knock
		target_vel.y = -120.0  # small pop

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


## Apply damage to an entity from external source
func apply_damage_to(target_id: int, damage: int, _source_id: int = -1) -> void:
	var health = get_component(target_id, "health")
	if not health or health.invincible:
		return

	health.current -= damage
	health.invincible = true
	health.invincibility_timer = health.invincibility_duration
	health.hurt_timer = 0.25

	entity_damaged.emit(target_id, damage, health.current)

	if health.current <= 0:
		entity_died.emit(target_id)
