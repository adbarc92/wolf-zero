extends Node
## VFX Manager - Handles visual effects like hitstop, screen shake, and effect spawning
##
## Autoload that manages game-wide visual effects for combat feedback.

# =============================================================================
# SIGNALS
# =============================================================================

signal hitstop_started()
signal hitstop_ended()
signal screen_shake_started()

# =============================================================================
# CONFIGURATION
# =============================================================================

## Default hitstop duration in seconds
var default_hitstop_duration: float = 0.05

## Screen shake settings
var shake_decay: float = 5.0
var shake_max_offset: Vector2 = Vector2(10, 10)

# =============================================================================
# STATE
# =============================================================================

var _hitstop_timer: float = 0.0
var _is_hitstop_active: bool = false
var _pre_hitstop_timescale: float = 1.0
var _hitstop_start_time: int = 0  # For real-time tracking

var _shake_amount: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _camera: Camera2D = null

# Effect container node (set by main scene)
var _effect_container: Node2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_process_hitstop(delta)
	_process_screen_shake(delta)


# =============================================================================
# HITSTOP
# =============================================================================

## Trigger a hitstop (brief freeze) for impact feel
func hitstop(duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_hitstop_duration

	if _is_hitstop_active:
		# Extend existing hitstop - update timer if new duration is longer
		var elapsed_ms = Time.get_ticks_msec() - _hitstop_start_time
		var remaining = _hitstop_timer - (elapsed_ms / 1000.0)
		if duration > remaining:
			_hitstop_timer = duration
			_hitstop_start_time = Time.get_ticks_msec()
		return

	_is_hitstop_active = true
	_hitstop_timer = duration
	_hitstop_start_time = Time.get_ticks_msec()
	_pre_hitstop_timescale = Engine.time_scale
	Engine.time_scale = 0.0
	hitstop_started.emit()


func _process_hitstop(_delta: float) -> void:
	if not _is_hitstop_active:
		return

	# Use real time since Engine.time_scale is 0 (delta would be 0)
	var elapsed_ms = Time.get_ticks_msec() - _hitstop_start_time
	var elapsed_sec = elapsed_ms / 1000.0

	if elapsed_sec >= _hitstop_timer:
		_is_hitstop_active = false
		Engine.time_scale = _pre_hitstop_timescale
		hitstop_ended.emit()


## Check if hitstop is currently active
func is_hitstop_active() -> bool:
	return _is_hitstop_active


# =============================================================================
# SCREEN SHAKE
# =============================================================================

## Set the camera reference for screen shake
func set_camera(camera: Camera2D) -> void:
	_camera = camera


## Trigger screen shake
func screen_shake(amount: float, duration: float = 0.2) -> void:
	_shake_amount = amount
	screen_shake_started.emit()

	# Create a tween to decay the shake
	var tween = create_tween()
	tween.tween_property(self, "_shake_amount", 0.0, duration).set_ease(Tween.EASE_OUT)


func _process_screen_shake(_delta: float) -> void:
	if not _camera or _shake_amount <= 0:
		if _camera:
			_camera.offset = Vector2.ZERO
		return

	# Random offset based on shake amount
	_shake_offset = Vector2(
		randf_range(-1, 1) * _shake_amount * shake_max_offset.x,
		randf_range(-1, 1) * _shake_amount * shake_max_offset.y
	)
	_camera.offset = _shake_offset


# =============================================================================
# EFFECT SPAWNING
# =============================================================================

## Set the container node for spawning effects
func set_effect_container(container: Node2D) -> void:
	_effect_container = container


## Spawn a slash effect at position
func spawn_slash(position: Vector2, direction: int, attack_type: String = "light") -> void:
	if not _effect_container:
		return

	var slash = SlashEffect.new()
	slash.position = position
	slash.direction = direction
	slash.attack_type = attack_type
	_effect_container.add_child(slash)


## Spawn hit sparks at position
func spawn_hit_sparks(position: Vector2, count: int = 5, color: Color = Color.WHITE) -> void:
	if not _effect_container:
		return

	var sparks = HitSparks.new()
	sparks.position = position
	sparks.spark_count = count
	sparks.spark_color = color
	_effect_container.add_child(sparks)


## Spawn a generic effect at position
func spawn_effect(effect: Node2D, position: Vector2) -> void:
	if not _effect_container:
		return

	effect.position = position
	_effect_container.add_child(effect)


# =============================================================================
# COMBAT VFX HELPERS
# =============================================================================

## Full hit effect: hitstop + shake + sparks
func hit_effect(position: Vector2, damage: int, is_critical: bool = false) -> void:
	# Hitstop scales with damage
	var stop_duration = default_hitstop_duration
	if is_critical:
		stop_duration *= 2.0
	elif damage > 20:
		stop_duration *= 1.5

	hitstop(stop_duration)

	# Screen shake scales with damage
	var shake_intensity = 0.3 + (damage / 100.0) * 0.5
	if is_critical:
		shake_intensity *= 1.5
	screen_shake(shake_intensity, 0.15)

	# Spawn sparks
	var spark_count = 3 + int(damage / 10)
	var spark_color = Color.YELLOW if is_critical else Color.WHITE
	spawn_hit_sparks(position, spark_count, spark_color)


## Attack swing effect
func attack_effect(position: Vector2, direction: int, attack_type: String) -> void:
	spawn_slash(position, direction, attack_type)


# =============================================================================
# SLASH EFFECT CLASS
# =============================================================================

class SlashEffect extends Node2D:
	var direction: int = 1
	var attack_type: String = "light"
	var lifetime: float = 0.15
	var elapsed: float = 0.0

	# Visual properties
	var arc_length: float = 80.0
	var arc_width: float = 40.0
	var arc_angle: float = 0.0  # Starting angle


	func _ready() -> void:
		# Set rotation based on attack type
		match attack_type:
			"light", "light_1", "light_2", "light_3", "light_4", "light_5":
				arc_angle = randf_range(-30, 30)
			"heavy_up":
				arc_angle = -90
			"heavy_down":
				arc_angle = 90
			"heavy_forward":
				arc_angle = 0

		# Flip if facing left
		if direction < 0:
			scale.x = -1


	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= lifetime:
			queue_free()
			return

		queue_redraw()


	func _draw() -> void:
		var progress = elapsed / lifetime
		var alpha = 1.0 - progress

		# Draw arc slash
		var color = Color(0.0, 0.9, 1.0, alpha)  # Cyan
		var points: PackedVector2Array = []
		var colors: PackedColorArray = []

		var segments = 8
		var start_angle = deg_to_rad(arc_angle - 45)
		var end_angle = deg_to_rad(arc_angle + 45)

		# Inner arc
		for i in range(segments + 1):
			var t = float(i) / segments
			var angle = lerp(start_angle, end_angle, t)
			var inner_radius = arc_length * 0.3 * (1.0 - progress * 0.5)
			points.append(Vector2(cos(angle), sin(angle)) * inner_radius)
			colors.append(Color(color.r, color.g, color.b, alpha * 0.3))

		# Outer arc (reverse order to form polygon)
		for i in range(segments, -1, -1):
			var t = float(i) / segments
			var angle = lerp(start_angle, end_angle, t)
			var outer_radius = arc_length * (1.0 + progress * 0.3)
			points.append(Vector2(cos(angle), sin(angle)) * outer_radius)
			colors.append(Color(color.r, color.g, color.b, alpha))

		if points.size() >= 3:
			draw_polygon(points, colors)

		# Draw bright edge
		var edge_points: PackedVector2Array = []
		for i in range(segments + 1):
			var t = float(i) / segments
			var angle = lerp(start_angle, end_angle, t)
			var radius = arc_length * (1.0 + progress * 0.3)
			edge_points.append(Vector2(cos(angle), sin(angle)) * radius)

		if edge_points.size() >= 2:
			draw_polyline(edge_points, Color(1.0, 1.0, 1.0, alpha * 0.8), 2.0)


# =============================================================================
# HIT SPARKS CLASS
# =============================================================================

class HitSparks extends Node2D:
	var spark_count: int = 5
	var spark_color: Color = Color.WHITE
	var lifetime: float = 0.3
	var elapsed: float = 0.0

	var sparks: Array = []


	func _ready() -> void:
		# Generate random spark directions and speeds
		for i in range(spark_count):
			var spark = {
				"angle": randf() * TAU,
				"speed": randf_range(100, 300),
				"size": randf_range(2, 6),
				"offset": Vector2.ZERO,
			}
			sparks.append(spark)


	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= lifetime:
			queue_free()
			return

		# Update spark positions
		for spark in sparks:
			var velocity = Vector2(cos(spark.angle), sin(spark.angle)) * spark.speed
			spark.offset += velocity * delta
			spark.speed *= 0.9  # Slow down

		queue_redraw()


	func _draw() -> void:
		var progress = elapsed / lifetime
		var alpha = 1.0 - progress

		for spark in sparks:
			var size = spark.size * (1.0 - progress * 0.5)
			var color = Color(spark_color.r, spark_color.g, spark_color.b, alpha)

			# Draw spark as small circle with trail
			draw_circle(spark.offset, size, color)

			# Draw small trail
			var trail_end = spark.offset - Vector2(cos(spark.angle), sin(spark.angle)) * size * 3
			draw_line(spark.offset, trail_end, Color(color.r, color.g, color.b, alpha * 0.5), size * 0.5)
