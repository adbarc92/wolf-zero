extends GutTest
var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _arena():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var a = ecs.create_entity()
	ecs.add_component(a, "position", Components.position(20, 0))
	ecs.add_component(a, "velocity", Components.velocity())
	var w = Components.weapon(20, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"; w.unblockable = true
	ecs.add_component(a, "weapon", w)
	var en = Components.enemy("oni_warlord"); en.facing = -1
	ecs.add_component(a, "enemy", en)
	ecs.add_component(a, "tag_enemy", Components.tag_enemy())
	return [ecs, combat]

func _add_target(ecs, defended: String):
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	var pr = Components.parry()
	if defended == "parry": pr.is_parrying = true
	if defended == "block": pr.is_blocking = true
	ecs.add_component(p, "parry", pr)
	ecs.add_component(p, "tag_player", Components.tag_player())
	return p

func test_perilous_bypasses_parry_and_block():
	for d in ["parry", "block"]:
		var arena = _arena(); var ecs = arena[0]; var combat = arena[1]
		var p = _add_target(ecs, d)
		combat.process(0.016)
		assert_lt(ecs.get_component(p, "health").current, 100, "perilous lands through %s" % d)

func test_dodge_iframes_still_avoid_perilous():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]
	var p = _add_target(ecs, "none")
	ecs.get_component(p, "health").invincible = true
	combat.process(0.016)
	assert_eq(ecs.get_component(p, "health").current, 100, "i-frames avoid perilous")
