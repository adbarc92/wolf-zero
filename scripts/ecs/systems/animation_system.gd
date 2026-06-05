class_name AnimationSystem
extends ECSSystem
## Renderer: owns each entity's AnimatedSprite2D and drives it from the
## `sprite` component. Derives the clip name from gameplay state each frame.

## Named SpriteFrames sets, injected by main.gd (e.g. {"player":..., "enemy":...}).
var frame_sets: Dictionary = {}


## Resolve a frame-set name to a SpriteFrames, falling back to "player".
func frames_for(set_name: String) -> SpriteFrames:
	if frame_sets.has(set_name):
		return frame_sets[set_name]
	return frame_sets.get("player", null)


func _get_required_components() -> Array[String]:
	return ["sprite", "position"]


## Pure derivation: highest-priority state wins.
## Order: dodge -> dash -> attack -> airborne -> run -> idle.
static func derive_clip(vel: Dictionary, collision: Dictionary, weapon: Dictionary,
		dodge: Dictionary, platformer: Dictionary) -> String:
	if dodge and dodge.get("is_dodging", false):
		return "roll"
	if platformer and platformer.get("is_dashing", false):
		return "dash"
	if weapon and weapon.get("is_attacking", false):
		var atype: String = weapon.get("attack_type", "none")
		if atype == "light":
			return "light_%d" % max(1, weapon.get("combo_current", 1))
		if atype.begins_with("heavy"):
			return atype
	if collision and not collision.get("on_ground", true):
		return "fall" if vel.get("y", 0.0) > 0.0 else "jump"
	if abs(vel.get("x", 0.0)) > 1.0:
		return "run"
	return "idle"


func process(_delta: float) -> void:
	for entity_id in get_entities():
		var node = get_node(entity_id)
		if not (node is Node2D):
			continue
		var sprite_comp = get_component(entity_id, "sprite")
		var anim_node := _ensure_anim_node(node, sprite_comp.get("frame_set", "player"))
		if anim_node == null:
			continue

		var vel = get_component(entity_id, "velocity")
		var collision = get_component(entity_id, "collision")
		var weapon = get_component(entity_id, "weapon")
		var dodge = get_component(entity_id, "dodge")
		var platformer = get_component(entity_id, "platformer")
		var input = get_component(entity_id, "input_state")

		var clip := derive_clip(
			vel if vel else {}, collision if collision else {},
			weapon if weapon else {}, dodge if dodge else {},
			platformer if platformer else {})
		sprite_comp.animation = clip

		if anim_node.sprite_frames and anim_node.sprite_frames.has_animation(clip):
			if anim_node.animation != clip:
				anim_node.play(clip)
		if input:
			anim_node.flip_h = input.facing < 0
		anim_node.modulate = sprite_comp.modulate


func _ensure_anim_node(node: Node, set_name: String) -> AnimatedSprite2D:
	var existing := node.get_node_or_null("Anim")
	if existing is AnimatedSprite2D:
		return existing
	var frames := frames_for(set_name)
	if frames == null:
		return null
	var anim := AnimatedSprite2D.new()
	anim.name = "Anim"
	anim.sprite_frames = frames
	anim.play("idle")
	node.add_child(anim)
	return anim
