extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _player(ecs, x):
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(x, 0))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "tag_player", Components.tag_player())
	return p

func _projectile(ecs, x, dir, team):
	var pr = ecs.create_entity()
	ecs.add_component(pr, "position", Components.position(x, 0))
	var data = Components.projectile(8, 600.0, team); data.direction = dir
	ecs.add_component(pr, "projectile", data)
	ecs.add_component(pr, "tag_projectile", Components.tag_projectile())
	return pr

func test_enemy_projectile_travels_and_damages_player():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)
	var p = _player(ecs, 50)
	var pr = _projectile(ecs, 0, 1, "enemy")
	var hp = ecs.get_component(p, "health").current
	for i in range(10):
		proj.process(1.0 / 60.0)
	assert_lt(ecs.get_component(p, "health").current, hp, "enemy projectile damages the player")
	assert_false(ecs.entity_exists(pr), "projectile is consumed on hit")

func test_parry_reflects_projectile_to_player_team():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)
	var p = _player(ecs, 20)
	var parry = Components.parry(); parry.is_parrying = true
	ecs.add_component(p, "parry", parry)
	var pr = _projectile(ecs, 0, 1, "enemy")
	for i in range(6):
		proj.process(1.0 / 60.0)
	assert_true(ecs.entity_exists(pr), "parried projectile is not consumed")
	assert_eq(ecs.get_component(pr, "projectile").team, "player", "reflected to player team")
	assert_eq(ecs.get_component(pr, "projectile").direction, -1, "reversed direction")
	assert_eq(ecs.get_component(p, "health").current, 100, "parry negates projectile damage")

func test_projectile_expires_after_lifetime():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)
	var pr = _projectile(ecs, 0, 1, "enemy")
	ecs.get_component(pr, "projectile").lifetime = 0.05
	proj.process(0.1)
	assert_false(ecs.entity_exists(pr), "projectile expires after its lifetime")
