extends GutTest
const Combat = preload("res://scripts/ecs/systems/combat_system.gd")
var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_block_damage_is_chipped():
	assert_eq(Combat.block_damage(20, 0.3), 6)
	assert_eq(Combat.block_damage(1, 0.3), 1, "minimum 1")

func test_blocking_target_takes_reduced_damage_no_death():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
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
	var pr = Components.parry(); pr.is_blocking = true
	ecs.add_component(p, "parry", pr)
	ecs.add_component(p, "tag_player", Components.tag_player())
	watch_signals(combat)
	combat.process(0.016)
	assert_eq(ecs.get_component(p, "health").current, 94, "blocked 20-dmg hit chips for 6")
	assert_signal_emitted(combat, "blocked")
