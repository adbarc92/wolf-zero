extends GutTest
## CombatSystem normal-damage path: combo damage bonus, and armor handling
## (heavy attacks break armor; light attacks are reduced against it).
## Parry/block/perilous resolution is covered by test_parry_resolution/test_block/test_perilous.

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _make_attacker(ecs) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "weapon", Components.weapon(10, 0.3))
	ecs.add_component(e, "health", Components.health(100))
	var input = Components.input_state(); input.facing = 1
	ecs.add_component(e, "input_state", input)
	ecs.add_component(e, "tag_player", Components.tag_player())
	return e

func _make_target(ecs, armored: bool) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(40, 0))  # in front, within attack range
	ecs.add_component(e, "collision", Components.collision())
	ecs.add_component(e, "health", Components.health(100))
	var enemy = Components.enemy("oni_mech")
	enemy.has_armor = armored
	enemy.armor_hits = 2 if armored else 0
	ecs.add_component(e, "enemy", enemy)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())
	return e


func test_light_attack_includes_combo_damage_bonus():
	var ecs = _make_ecs()
	var sys = CombatSystem.new(); ecs.register_system(sys)
	var attacker = _make_attacker(ecs)
	var target = _make_target(ecs, false)
	ecs.get_component(attacker, "input_state").attack_light = true

	sys.process(0.016)

	# damage = weapon.damage(10) + combo_current(1) * 2 = 12
	assert_eq(ecs.get_component(target, "health").current, 88, "light hit applies base + combo bonus")


func test_light_attack_is_halved_against_armor_and_leaves_armor_intact():
	var ecs = _make_ecs()
	var sys = CombatSystem.new(); ecs.register_system(sys)
	var attacker = _make_attacker(ecs)
	var target = _make_target(ecs, true)
	ecs.get_component(attacker, "input_state").attack_light = true

	sys.process(0.016)

	# (10 + 1*2) halved -> int(12 * 0.5) = 6
	assert_eq(ecs.get_component(target, "health").current, 94, "light damage is halved against armor")
	assert_eq(ecs.get_component(target, "enemy").armor_hits, 2, "light attacks do not break armor")


func test_heavy_attack_breaks_armor_and_deals_full_damage():
	var ecs = _make_ecs()
	var sys = CombatSystem.new(); ecs.register_system(sys)
	var attacker = _make_attacker(ecs)
	var target = _make_target(ecs, true)
	var input = ecs.get_component(attacker, "input_state")
	input.attack_heavy = true
	input.attack_direction = Vector2(1, 0)  # heavy_forward

	sys.process(0.016)

	# heavy resets combo to 0 -> damage = 10; not halved; armor_hits decremented
	assert_eq(ecs.get_component(target, "enemy").armor_hits, 1, "heavy attack strips one armor hit")
	assert_eq(ecs.get_component(target, "health").current, 90, "heavy deals full damage through armor")
