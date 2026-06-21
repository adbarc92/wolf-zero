class_name AnimationSystem
extends ECSSystem
## Renderer: owns each entity's AnimatedSprite2D and drives it from the
## `sprite` component. Derives the clip name from gameplay state each frame.

## Named SpriteFrames sets, injected by main.gd (e.g. {"player":..., "enemy":...}).
var frame_sets: Dictionary = {}

var _transient: Dictionary = {}     # entity_id -> {clip, time_left}
var _last_facing: Dictionary = {}   # entity_id -> int
var _last_crouch: Dictionary = {}   # entity_id -> bool


## Resolve a frame-set name to a SpriteFrames, falling back to "player".
func frames_for(set_name: String) -> SpriteFrames:
	if frame_sets.has(set_name):
		return frame_sets[set_name]
	return frame_sets.get("player", null)


func _get_required_components() -> Array[String]:
	return ["sprite", "position"]


## Pure derivation: highest-priority state wins.
## Order: dodge -> dash -> attack -> airborne -> crouch -> run -> idle.
static func derive_clip(vel: Dictionary, collision: Dictionary, weapon: Dictionary,
		dodge: Dictionary, platformer: Dictionary, crouching: bool = false,
		hurt: bool = false, on_wall: bool = false, climbing: bool = false,
		dead: bool = false, sliding: bool = false) -> String:
	if dead:
		return "death"
	if dodge and dodge.get("is_dodging", false):
		return "roll"
	if platformer and platformer.get("is_dashing", false):
		return "dash"
	if sliding:
		return "slide"
	if hurt:
		return "hit"
	if weapon and weapon.get("is_attacking", false):
		var atype: String = weapon.get("attack_type", "none")
		if atype == "light":
			if crouching:
				return "crouch_attack"
			if abs(vel.get("x", 0.0)) < 1.0:
				return "light_%d_nomove" % max(1, weapon.get("combo_current", 1))
			return "light_%d" % max(1, weapon.get("combo_current", 1))
		if atype.begins_with("heavy"):
			return atype
	if on_wall:
		return "wall_climb" if climbing else "wall_slide"
	if collision and not collision.get("on_ground", true):
		if abs(vel.get("y", 0.0)) < 80.0:
			return "jump_fall_inbetween"
		return "fall" if vel.get("y", 0.0) > 0.0 else "jump"
	if crouching:
		return "crouch_walk" if abs(vel.get("x", 0.0)) > 1.0 else "crouch"
	if abs(vel.get("x", 0.0)) > 1.0:
		return "run"
	return "idle"


func process(delta: float) -> void:
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

		var crouching: bool = input != null and input.get("crouch_pressed", false) \
			and collision != null and collision.get("on_ground", false)
		var health = get_component(entity_id, "health")
		var hurt: bool = health != null and health.get("hurt_timer", 0.0) > 0.0
		var on_wall: bool = collision != null and collision.get("on_wall", false) and not collision.get("on_ground", true)
		var climbing: bool = on_wall and input != null and input.get("jump_pressed", false) \
			and platformer != null and platformer.get("wall_run_timer", 0.0) > 0.0
		var dead: bool = has_component(entity_id, "dying")
		var sliding: bool = platformer != null and platformer.get("is_sliding", false)
		var clip := derive_clip(
			vel if vel else {}, collision if collision else {},
			weapon if weapon else {}, dodge if dodge else {},
			platformer if platformer else {}, crouching, hurt, on_wall, climbing, dead, sliding)

		# Turn-around transient (grounded facing flip)
		if input and collision and collision.get("on_ground", false):
			var lf = _last_facing.get(entity_id, input.facing)
			if lf != input.facing:
				_transient[entity_id] = {"clip": "turn_around", "time_left": 0.15}
			_last_facing[entity_id] = input.facing
		# Crouch-transition transient (crouch just pressed)
		var was_crouch = _last_crouch.get(entity_id, false)
		if crouching and not was_crouch:
			_transient[entity_id] = {"clip": "crouch_transition", "time_left": 0.12}
		_last_crouch[entity_id] = crouching
		# Apply transient only over low-priority derived clips
		if _transient.has(entity_id):
			var t = _transient[entity_id]
			t.time_left -= delta
			if t.time_left <= 0.0:
				_transient.erase(entity_id)
			elif clip in ["idle", "run", "crouch", "crouch_walk"] \
					and anim_node.sprite_frames and anim_node.sprite_frames.has_animation(t.clip):
				clip = t.clip

		sprite_comp.animation = clip

		if anim_node.sprite_frames and anim_node.sprite_frames.has_animation(clip):
			if anim_node.animation != clip:
				anim_node.play(clip)
		if input:
			anim_node.flip_h = input.facing < 0
		anim_node.modulate = sprite_comp.modulate
		var pc = get_component(entity_id, "parry")
		if pc and pc.get("is_blocking", false):
			anim_node.modulate = Color(0.6, 0.8, 1.0)


## Half-height of the 32x64 collision box, in local node units. The node origin
## is the body centre, so floor contact is +FLOOR_ANCHOR below it.
const FLOOR_ANCHOR := 32.0


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
	# Pixel-art: nearest-neighbour so the samurai sheets stay crisp when scaled
	# (the project default is Linear, which would soften them).
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Anchor the frame bottom (≈ the character's feet) to the collision-box floor,
	# regardless of the per-character frame height (player 96, enemy 64, boss 108).
	# AnimatedSprite2D is centred, so the frame bottom sits at offset.y + frame_h/2;
	# solving for it landing on +FLOOR_ANCHOR gives offset.y = FLOOR_ANCHOR - h/2.
	var fh := _frame_height(frames)
	if fh > 0:
		anim.offset = Vector2(0, FLOOR_ANCHOR - fh / 2.0)
	anim.play("idle")
	node.add_child(anim)
	return anim


## Height of a single frame, read from the idle clip's first frame (0 if absent).
func _frame_height(frames: SpriteFrames) -> int:
	if frames == null or not frames.has_animation("idle") or frames.get_frame_count("idle") == 0:
		return 0
	var tex := frames.get_frame_texture("idle", 0)
	return tex.get_height() if tex else 0
