class_name BossSystem
extends ECSSystem
## Drives entities with a `boss` component: telegraph->attack->recover with two
## phases and a parry-driven stagger opening. Uses the combat weapon hitbox.

signal boss_phase_changed(entity_id: int, phase: int)


func _get_required_components() -> Array[String]:
	return ["boss", "position"]


static func phase_for_hp(current: int, max_hp: int) -> int:
	return 2 if float(current) <= float(max_hp) * 0.5 else 1

static func patterns_for_phase(phase: int) -> Array:
	if phase >= 2:
		return ["slash", "lunge", "combo"]
	return ["slash"]

static func pattern_spec(name: String) -> Dictionary:
	match name:
		"lunge":
			return {"telegraph": 0.6, "active": 0.3, "recover": 0.8, "damage": 26, "lunge": true}
		"combo":
			return {"telegraph": 0.55, "active": 0.5, "recover": 0.6, "damage": 18, "lunge": false}
		_:
			return {"telegraph": 0.75, "active": 0.2, "recover": 0.85, "damage": 22, "lunge": false}

static func pick_pattern(phase: int, tick: int) -> String:
	var pool := patterns_for_phase(phase)
	return pool[tick % pool.size()]


var _tick := 0

func process(delta: float) -> void:
	var players = ecs.get_entities_with("tag_player")
	var player_id: int = players[0] if players.size() > 0 else -1
	var ppos = ecs.get_component(player_id, "position") if player_id >= 0 else null

	for entity_id in get_entities():
		var boss = get_component(entity_id, "boss")
		var pos = get_component(entity_id, "position")
		var health = get_component(entity_id, "health")
		var weapon = get_component(entity_id, "weapon")
		var vel = get_component(entity_id, "velocity")

		if health:
			var ph := phase_for_hp(health.current, health.max)
			if ph != boss.phase:
				boss.phase = ph
				boss_phase_changed.emit(entity_id, ph)

		if ppos:
			boss.facing = -1 if ppos.x < pos.x else 1
		var en = get_component(entity_id, "enemy")
		if en:
			en.facing = boss.facing

		if boss.staggered:
			if weapon: weapon.hitbox_active = false
			if vel: vel.x = 0.0
			boss.stagger_timer -= delta
			if boss.stagger_timer <= 0.0:
				boss.staggered = false
				boss.state = "idle"
				boss.state_timer = 0.4
			continue

		boss.state_timer -= delta
		match boss.state:
			"intro", "idle", "recover":
				if weapon: weapon.hitbox_active = false
				if vel: vel.x = 0.0
				if boss.state_timer <= 0.0:
					_tick += 1
					boss.pattern = pick_pattern(boss.phase, _tick)
					boss.state = "telegraph"
					boss.state_timer = pattern_spec(boss.pattern).telegraph
			"telegraph":
				if vel:
					vel.x = boss.facing * 60.0
				if boss.state_timer <= 0.0:
					var spec := pattern_spec(boss.pattern)
					boss.state = "attack"
					boss.state_timer = spec.active
					if weapon:
						weapon.damage = int(spec.damage)
						weapon.is_attacking = true
						weapon.hitbox_active = true
						weapon.attack_type = "enemy"
					if spec.get("lunge", false) and vel:
						vel.x = boss.facing * 520.0
			"attack":
				if boss.state_timer <= 0.0:
					if weapon:
						weapon.is_attacking = false
						weapon.hitbox_active = false
					boss.state = "recover"
					boss.state_timer = pattern_spec(boss.pattern).recover
