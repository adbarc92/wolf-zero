extends GutTest
## Deathblow: the finish available against a Broken enemy. It kills a regular
## enemy outright whatever health remains, and ends exactly one boss phase.
##
## There is no separate Deathblow input — landing an attack on something that is
## already open IS the finish.

var ECSScript = preload("res://scripts/ecs/ecs.gd")


func _arena() -> Array:
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var momentum := MomentumSystem.new(); ecs.register_system(momentum)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	return [ecs, combat, momentum]


func _add_player(ecs) -> int:
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "momentum", Components.momentum())
	ecs.add_component(p, "input_state", Components.input_state())
	var w = Components.weapon(15, 0.25); w.hitbox_active = true
	ecs.add_component(p, "weapon", w)
	ecs.add_component(p, "tag_player", Components.tag_player())
	return p


func _add_enemy(ecs, max_hp: int) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(20, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "collision", Components.collision(32, 64))
	ecs.add_component(e, "health", Components.health(max_hp))
	ecs.add_component(e, "momentum", Components.enemy_momentum())
	var en = Components.enemy("oni_mech"); en.facing = -1
	ecs.add_component(e, "enemy", en)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())
	return e


# =============================================================================
# BREAKING
# =============================================================================

func test_parries_drain_enemy_momentum_and_three_of_them_break_it():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]
	var p = _add_player(ecs)
	var e = _add_enemy(ecs, 400)
	# The player parries; the enemy is the one swinging.
	ecs.get_component(p, "weapon").hitbox_active = false
	var pr = Components.parry(); pr.is_parrying = true
	ecs.add_component(p, "parry", pr)
	var w = Components.weapon(12, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"
	ecs.add_component(e, "weapon", w)

	var em = ecs.get_component(e, "momentum")
	var pm = ecs.get_component(p, "momentum")
	var start: float = em.current

	combat.process(0.016)

	assert_almost_eq(em.current, start - pm.parry_drain, 0.001, "a parry tears composure off the attacker")

	# Two more parries take it to zero: 3 * 34 >= 100.
	for _i in range(2):
		ecs.get_component(p, "parry").is_parrying = true
		ecs.get_component(e, "weapon").hitbox_active = true
		combat.process(0.016)

	assert_true(em.broken, "three parries Break any enemy")


# =============================================================================
# THE FINISH
# =============================================================================

func test_deathblow_kills_a_broken_regular_enemy_outright():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]
	_add_player(ecs)
	var e = _add_enemy(ecs, 400)
	momentum.spend_momentum(e, 999.0)
	watch_signals(combat)

	combat.process(0.016)

	assert_eq(ecs.get_component(e, "health").current, 0,
		"a Deathblow ignores the 385 health a 15-damage swing would have left")
	assert_signal_emitted(combat, "deathblow")
	assert_signal_emitted(combat, "entity_died")


func test_an_unbroken_enemy_just_takes_normal_damage():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]
	_add_player(ecs)
	var e = _add_enemy(ecs, 400)
	watch_signals(combat)

	combat.process(0.016)

	assert_eq(ecs.get_component(e, "health").current, 385, "15 damage off 400")
	assert_signal_not_emitted(combat, "deathblow")


func test_a_broken_player_is_open_but_not_instantly_finished():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]
	var p = _add_player(ecs)
	ecs.get_component(p, "weapon").hitbox_active = false
	var e = _add_enemy(ecs, 400)
	var w = Components.weapon(20, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"
	ecs.add_component(e, "weapon", w)
	momentum.spend_momentum(p, 999.0)
	watch_signals(combat)

	combat.process(0.016)

	assert_eq(ecs.get_component(p, "health").current, 80, "Broken means open, not executed")
	assert_signal_not_emitted(combat, "deathblow", "Deathblow is the player's verb")


# =============================================================================
# BOSSES
# =============================================================================

func _add_boss(ecs, max_hp: int, phase: int) -> int:
	var b = _add_enemy(ecs, max_hp)
	var boss = Components.boss("Crimson Ronin")
	boss.phase = phase
	ecs.add_component(b, "boss", boss)
	if phase >= 2:
		ecs.get_component(b, "health").current = int(max_hp * 0.5)
	return b


func test_deathblow_on_a_boss_ends_exactly_one_phase():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]
	_add_player(ecs)
	var b = _add_boss(ecs, 320, 1)
	momentum.spend_momentum(b, 999.0)
	watch_signals(combat)

	combat.process(0.016)

	var health = ecs.get_component(b, "health")
	assert_eq(health.current, 160, "the boss drops to the top of the next phase band")
	assert_eq(BossSystem.phase_for_hp(health.current, health.max), 2, "which is phase 2")
	assert_signal_emitted(combat, "deathblow")
	assert_signal_not_emitted(combat, "entity_died", "a phase ended, not the fight")


func test_a_boss_that_survives_a_deathblow_recovers_its_composure():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]
	_add_player(ecs)
	var b = _add_boss(ecs, 320, 1)
	momentum.spend_momentum(b, 999.0)

	combat.process(0.016)

	var m = ecs.get_component(b, "momentum")
	assert_false(m.broken, "the opening is spent with the phase")
	assert_almost_eq(m.current, m.max, 0.001, "one Break buys one phase, not two")


func test_deathblow_in_the_final_phase_kills():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]
	_add_player(ecs)
	var b = _add_boss(ecs, 320, 2)
	momentum.spend_momentum(b, 999.0)
	watch_signals(combat)

	combat.process(0.016)

	assert_eq(ecs.get_component(b, "health").current, 0, "the last phase has nowhere to fall to")
	assert_signal_emitted(combat, "entity_died")


func test_boss_system_reads_the_new_phase_off_health():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]
	_add_player(ecs)
	var b = _add_boss(ecs, 320, 1)
	var boss_system := BossSystem.new(); ecs.register_system(boss_system)
	momentum.spend_momentum(b, 999.0)
	watch_signals(boss_system)

	combat.process(0.016)
	boss_system.process(0.016)

	assert_eq(ecs.get_component(b, "boss").phase, 2, "phase stays a pure function of health")
	assert_signal_emitted_with_parameters(boss_system, "boss_phase_changed", [b, 2])


func test_deathblow_health_bands():
	assert_eq(BossSystem.deathblow_health(1, 320), 160, "phase 1 ends at the halfway band")
	assert_eq(BossSystem.deathblow_health(BossSystem.PHASE_MAX, 320), 0, "the final phase ends in death")
