class_name ProjectileSystem
extends ECSSystem
## Moves projectile entities, expires them, and resolves hits against the
## opposite team (distance-based). A parrying target reflects the projectile.

signal projectile_hit(projectile_id: int, target_id: int)
signal projectile_reflected(projectile_id: int)


func _get_required_components() -> Array[String]:
	return ["projectile", "position"]


func process(delta: float) -> void:
	var ids: Array = get_entities().duplicate()
	for pid in ids:
		if not ecs.entity_exists(pid):
			continue
		var proj = get_component(pid, "projectile")
		var pos = get_component(pid, "position")

		pos.x += float(proj.direction) * proj.speed * delta
		_sync_node(pid, pos)

		proj.elapsed += delta
		if proj.elapsed >= proj.lifetime:
			_destroy(pid)
			continue

		var target_tag := "tag_player" if proj.team == "enemy" else "tag_enemy"
		for tid in ecs.get_entities_with(target_tag):
			var tpos = ecs.get_component(tid, "position")
			if tpos == null:
				continue
			if abs(tpos.x - pos.x) > proj.radius or abs(tpos.y - pos.y) > 48.0:
				continue
			var tparry = ecs.get_component(tid, "parry")
			if tparry and tparry.is_parrying:
				tparry.is_parrying = false
				proj.team = "player" if proj.team == "enemy" else "enemy"
				proj.direction = -proj.direction
				proj.elapsed = 0.0
				projectile_reflected.emit(pid)
				break
			var combat = ecs.get_system(CombatSystem)
			if combat:
				combat.apply_damage_to(tid, proj.damage, pid)
			projectile_hit.emit(pid, tid)
			_destroy(pid)
			break


## Spawn a projectile entity travelling from `from` toward `dir` for `team`.
func spawn(from: Vector2, dir: int, team: String, damage: int = 8) -> int:
	var node := Node2D.new()
	node.name = "Projectile"
	node.position = from
	var container = _container()
	if container:
		container.add_child(node)
		var rect := ColorRect.new()
		rect.size = Vector2(16, 6)
		rect.position = Vector2(-8, -3)
		rect.color = Color(1.0, 0.4, 0.1) if team == "enemy" else Color(0.0, 0.9, 1.0)
		node.add_child(rect)
	var pid = ecs.create_entity_with_node(node)
	ecs.add_component(pid, "position", Components.position(from.x, from.y))
	var data = Components.projectile(damage, 600.0, team)
	data.direction = dir
	ecs.add_component(pid, "projectile", data)
	ecs.add_component(pid, "tag_projectile", Components.tag_projectile())
	return pid


func _container() -> Node:
	var any_node = null
	var players = ecs.get_entities_with("tag_player")
	if players.size() > 0:
		any_node = ecs.get_entity_node(players[0])
	if any_node and any_node.get_parent():
		return any_node.get_parent()
	return null


func _sync_node(pid: int, pos: Dictionary) -> void:
	var node = get_node(pid)
	if node and node is Node2D:
		node.position = Vector2(pos.x, pos.y)


func _destroy(pid: int) -> void:
	var node = get_node(pid)
	if node:
		node.queue_free()
	ecs.destroy_entity(pid)
