extends GutTest
## BossSystem runtime state machine: phase change, telegraph->attack->recover,
## the parry-driven stagger opening, and perilous (unblockable) attacks.
## (Static pattern/phase helpers are covered by test_boss_system.gd.)

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func _make_boss(ecs, max_hp: int = 300) -> int:
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "health", Components.health(max_hp))
	ecs.add_component(e, "weapon", Components.weapon())
	ecs.add_component(e, "boss", Components.boss("Test Boss"))
	return e


func test_phase_changes_to_two_under_half_hp():
	var ecs = _make_ecs()
	var sys = BossSystem.new(); ecs.register_system(sys)
	var e = _make_boss(ecs, 300)
	ecs.get_component(e, "health").current = 100  # under 50%
	watch_signals(sys)

	sys.process(0.0)

	assert_eq(ecs.get_component(e, "boss").phase, 2, "drops to phase 2 below half HP")
	assert_signal_emitted_with_parameters(sys, "boss_phase_changed", [e, 2])


func test_idle_telegraph_attack_recover_cycle():
	var ecs = _make_ecs()
	var sys = BossSystem.new(); ecs.register_system(sys)
	var e = _make_boss(ecs, 300)  # full HP -> stays phase 1
	var boss = ecs.get_component(e, "boss")
	var weapon = ecs.get_component(e, "weapon")
	boss.state = "idle"
	boss.state_timer = 0.1

	sys.process(0.2)  # idle timer expires -> pick pattern, telegraph
	assert_eq(boss.state, "telegraph", "idle -> telegraph when the state timer expires")
	assert_eq(boss.pattern, "slash", "phase 1 crimson_ronin telegraphs slash")
	assert_false(weapon.hitbox_active, "hitbox stays off during telegraph wind-up")

	sys.process(0.8)  # telegraph -> attack
	assert_eq(boss.state, "attack", "telegraph -> attack")
	assert_true(weapon.hitbox_active, "hitbox is live during the attack window")

	sys.process(0.3)  # attack -> recover
	assert_eq(boss.state, "recover", "attack -> recover")
	assert_false(weapon.hitbox_active, "hitbox closes after the attack")


func test_stagger_disables_weapon_then_recovers_to_idle():
	var ecs = _make_ecs()
	var sys = BossSystem.new(); ecs.register_system(sys)
	var e = _make_boss(ecs, 300)
	var boss = ecs.get_component(e, "boss")
	var weapon = ecs.get_component(e, "weapon")
	boss.staggered = true
	boss.stagger_timer = 1.0
	weapon.hitbox_active = true
	weapon.unblockable = true

	sys.process(0.5)
	assert_false(weapon.hitbox_active, "stagger immediately drops the boss's hitbox")
	assert_true(boss.staggered, "still staggered while the timer runs")

	sys.process(0.6)  # stagger_timer now <= 0
	assert_false(boss.staggered, "stagger ends when its timer elapses")
	assert_eq(boss.state, "idle", "boss returns to idle after the stagger opening")


func test_perilous_attack_is_unblockable():
	var ecs = _make_ecs()
	var sys = BossSystem.new(); ecs.register_system(sys)
	var e = _make_boss(ecs, 300)
	var boss = ecs.get_component(e, "boss")
	var weapon = ecs.get_component(e, "weapon")
	boss.state = "telegraph"
	boss.pattern = "perilous"
	boss.state_timer = 0.1

	sys.process(0.2)  # telegraph -> attack with the perilous spec

	assert_eq(boss.state, "attack")
	assert_true(weapon.unblockable, "perilous attacks set the weapon unblockable (parry/block bypass)")
