extends GutTest
## Block now has the cost it never had: it spends Momentum as well as chipping
## health, and blocking with nothing left to spend leaves the blocker Broken.

const Combat = preload("res://scripts/ecs/systems/combat_system.gd")
var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _arena(block_start_momentum: float) -> Array:
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var momentum := MomentumSystem.new(); ecs.register_system(momentum)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	var a = ecs.create_entity()
	ecs.add_component(a, "position", Components.position(20, 0))
	ecs.add_component(a, "velocity", Components.velocity())
	var w = Components.weapon(20, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"
	ecs.add_component(a, "weapon", w)
	var en = Components.enemy("ronin_drone"); en.facing = -1
	ecs.add_component(a, "enemy", en)
	ecs.add_component(a, "tag_enemy", Components.tag_enemy())

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	var pm = Components.momentum(); pm.current = block_start_momentum
	ecs.add_component(p, "momentum", pm)
	var pr = Components.parry(); pr.is_blocking = true
	ecs.add_component(p, "parry", pr)
	ecs.add_component(p, "tag_player", Components.tag_player())

	return [ecs, combat, momentum, p]


func test_block_damage_is_chipped():
	assert_eq(Combat.block_damage(20, 0.3), 6)
	assert_eq(Combat.block_damage(1, 0.3), 1, "minimum 1")


func test_blocking_target_takes_reduced_damage_no_death():
	var arena = _arena(100.0)
	var ecs = arena[0]; var combat = arena[1]; var p = arena[3]
	watch_signals(combat)

	combat.process(0.016)

	assert_eq(ecs.get_component(p, "health").current, 94, "blocked 20-dmg hit chips for 6")
	assert_signal_emitted(combat, "blocked")


func test_blocking_spends_momentum_in_proportion_to_the_blow():
	var arena = _arena(100.0)
	var ecs = arena[0]; var combat = arena[1]; var p = arena[3]

	combat.process(0.016)

	var m = ecs.get_component(p, "momentum")
	# block_cost_mult defaults to 1.0, so a 20-damage blow costs 20 Momentum.
	assert_almost_eq(m.current, 80.0, 0.001, "the blow lands on composure, not only health")


func test_blocking_with_nothing_left_to_spend_breaks_the_blocker():
	var arena = _arena(8.0)
	var ecs = arena[0]; var combat = arena[1]; var momentum = arena[2]; var p = arena[3]
	watch_signals(momentum)

	combat.process(0.016)

	var m = ecs.get_component(p, "momentum")
	assert_almost_eq(m.current, 0.0, 0.001, "the bar is emptied")
	assert_true(m.broken, "blocking with nothing left to spend Breaks you")
	assert_signal_emitted_with_parameters(momentum, "entity_broken", [p])


func test_block_costs_nothing_when_the_attack_is_unblockable():
	var arena = _arena(100.0)
	var ecs = arena[0]; var combat = arena[1]
	for attacker_id in ecs.get_entities_with("tag_enemy"):
		ecs.get_component(attacker_id, "weapon").unblockable = true

	combat.process(0.016)

	var players = ecs.get_entities_with("tag_player")
	var m = ecs.get_component(players[0], "momentum")
	assert_almost_eq(m.current, 100.0, 0.001, "a perilous attack goes past the block entirely")
	assert_lt(ecs.get_component(players[0], "health").current, 100, "and lands on health")
