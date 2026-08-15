class_name MomentumSystem
extends ECSSystem
## Momentum is composure, carried by every combatant.
##
## Blocking spends it, parries and landed attacks build it, and idle time decays
## it. Spending it down to zero leaves the entity Broken: staggered, unable to
## act, and open to a Deathblow until it recovers. Filling the bar banks a Charge
## and drops back to `bank_floor` rather than to zero, so the player's best play
## never leaves them defenceless.


signal momentum_changed(entity_id: int, current: float, max_val: float)
signal charge_banked(entity_id: int, charges: int)
signal charge_spent(entity_id: int, charges: int)
signal entity_broken(entity_id: int)
signal entity_recovered(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["momentum"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var momentum = get_component(entity_id, "momentum")
		if momentum.broken:
			_process_broken(entity_id, momentum, delta)
			continue
		_process_decay(entity_id, momentum, delta)


func _process_decay(entity_id: int, momentum: Dictionary, delta: float) -> void:
	# Decay timer counts down
	if momentum.decay_timer > 0:
		momentum.decay_timer -= delta
		return

	# Apply decay. Idle decay never Breaks anything — only spending does — and
	# enemies run with decay_rate 0 so waiting them out is not a strategy.
	if momentum.current > 0.0 and momentum.decay_rate > 0.0:
		momentum.current = maxf(0.0, momentum.current - momentum.decay_rate * delta)
		momentum_changed.emit(entity_id, momentum.current, momentum.max)


## A Broken entity cannot act: inputs are dropped, the attack window is shut, and
## AI/boss state is pinned to stagger for as long as the opening lasts.
func _process_broken(entity_id: int, momentum: Dictionary, delta: float) -> void:
	_suppress(entity_id, momentum)
	momentum.broken_timer -= delta
	if momentum.broken_timer <= 0.0:
		recover(entity_id)


func _suppress(entity_id: int, momentum: Dictionary) -> void:
	var input = get_component(entity_id, "input_state")
	if input:
		input.move_direction = 0.0
		input.jump_pressed = false
		input.jump_just_pressed = false
		input.attack_light = false
		input.attack_heavy = false
		input.dodge_pressed = false
		input.dash_pressed = false
		input.parry_pressed = false
		input.parry_held = false
		input.echo_pressed = false

	var parry = get_component(entity_id, "parry")
	if parry:
		parry.is_parrying = false
		parry.is_blocking = false

	var weapon = get_component(entity_id, "weapon")
	if weapon:
		weapon.is_attacking = false
		weapon.hitbox_active = false

	var velocity = get_component(entity_id, "velocity")
	if velocity:
		velocity.x = 0.0

	var ai = get_component(entity_id, "ai")
	if ai:
		ai.state = "stagger"
		ai.stagger_timer = maxf(ai.stagger_timer, momentum.broken_timer)

	var boss = get_component(entity_id, "boss")
	if boss:
		boss.staggered = true
		boss.stagger_timer = maxf(boss.stagger_timer, momentum.broken_timer)


## Build momentum. Filling the bar banks a Charge and drops back to bank_floor.
func add_momentum(entity_id: int, amount: float) -> void:
	var momentum = get_component(entity_id, "momentum")
	if not momentum or momentum.broken:
		return

	var previous: float = momentum.current
	momentum.current = minf(momentum.current + amount, momentum.max)
	momentum.decay_timer = momentum.decay_delay

	# Banking is the act of FILLING the bar, so a bar already sitting at max —
	# an enemy's, which spawns full — does not mint Charges out of nothing.
	var banked: bool = momentum.current >= momentum.max and previous < momentum.max
	if banked:
		_bank_charge(entity_id, momentum)
	if banked or momentum.current != previous:
		momentum_changed.emit(entity_id, momentum.current, momentum.max)


## Spend momentum — a blocked hit paid for by the blocker, or an attacker's
## composure torn off by a parry. Reaching zero Breaks the entity. Returns the
## amount actually taken off the bar, which may be less than asked for.
func spend_momentum(entity_id: int, amount: float) -> float:
	var momentum = get_component(entity_id, "momentum")
	if not momentum or momentum.broken:
		return 0.0

	var spent: float = minf(momentum.current, maxf(0.0, amount))
	momentum.current -= spent
	momentum.decay_timer = momentum.decay_delay
	momentum_changed.emit(entity_id, momentum.current, momentum.max)

	if momentum.current <= 0.0:
		_break(entity_id, momentum)

	return spent


## True while the entity is Broken and open to a Deathblow.
func is_broken(entity_id: int) -> bool:
	var momentum = get_component(entity_id, "momentum")
	return momentum != null and momentum.broken


## Spend one banked Charge. False when the pool is empty — an empty pool is the
## only thing that can refuse an ability that costs a Charge.
func spend_charge(entity_id: int) -> bool:
	var momentum = get_component(entity_id, "momentum")
	if not momentum or momentum.charges <= 0:
		return false

	momentum.charges -= 1
	charge_spent.emit(entity_id, momentum.charges)
	return true


## End a Broken state and restore the bar to bank_floor. Called on its own when
## the opening times out, and by a Deathblow that leaves the target alive so the
## same Break cannot be cashed in twice.
func recover(entity_id: int) -> void:
	var momentum = get_component(entity_id, "momentum")
	if not momentum:
		return

	momentum.broken = false
	momentum.broken_timer = 0.0
	momentum.current = momentum.bank_floor
	momentum.decay_timer = momentum.decay_delay

	entity_recovered.emit(entity_id)
	momentum_changed.emit(entity_id, momentum.current, momentum.max)


## Get current momentum percentage (0-1)
func get_momentum_percent(entity_id: int) -> float:
	var momentum = get_component(entity_id, "momentum")
	if not momentum:
		return 0.0
	return momentum.current / momentum.max


func _bank_charge(entity_id: int, momentum: Dictionary) -> void:
	momentum.charges = mini(momentum.charges + 1, momentum.charges_max)
	momentum.current = momentum.bank_floor
	charge_banked.emit(entity_id, momentum.charges)


func _break(entity_id: int, momentum: Dictionary) -> void:
	momentum.current = 0.0
	momentum.broken = true
	momentum.broken_timer = momentum.broken_duration
	entity_broken.emit(entity_id)
