extends Control
## HUD - Heads Up Display
##
## Displays health, momentum, echo cooldown, and combo counter.
## Subscribes to GameEvents for updates.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var health_bar: ColorRect = %HealthBar
@onready var health_bar_damage: ColorRect = %HealthBarDamage
@onready var health_label: Label = %HealthLabel

@onready var momentum_bar: ColorRect = %MomentumBar

@onready var echo_cooldown: ColorRect = %EchoCooldown
@onready var echo_icon: Label = %EchoIcon

@onready var combo_counter: Label = %ComboCounter
@onready var damage_numbers: Node2D = %DamageNumbers

# =============================================================================
# STATE
# =============================================================================

var _health_bar_width: float = 250.0
var _momentum_bar_width: float = 400.0
var _echo_bar_height: float = 35.0

var _current_health: int = 100
var _max_health: int = 100
var _target_health_width: float = 250.0

var _current_momentum: float = 0.0
var _max_momentum: float = 100.0

var _echo_cooldown_remaining: float = 0.0
var _echo_cooldown_total: float = 8.0
var _echo_ready: bool = false

var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_display_duration: float = 2.0

# Damage bar lerp
var _damage_bar_target: float = 250.0
var _damage_bar_speed: float = 100.0

# Colors
const COLOR_HEALTH = Color(0.0, 0.9, 0.8, 1.0)
const COLOR_HEALTH_LOW = Color(1.0, 0.3, 0.2, 1.0)
const COLOR_MOMENTUM_BASE = Color(1.0, 0.4, 0.8, 1.0)
const COLOR_MOMENTUM_ECHO = Color(0.0, 0.8, 1.0, 1.0)
const COLOR_MOMENTUM_DAMAGE = Color(1.0, 0.6, 0.2, 1.0)
const COLOR_MOMENTUM_ULTIMATE = Color(1.0, 0.9, 0.3, 1.0)
const COLOR_ECHO_READY = Color(0.0, 1.0, 1.0, 1.0)
const COLOR_ECHO_COOLDOWN = Color(0.3, 0.3, 0.4, 1.0)


func _ready() -> void:
	_connect_signals()
	_initialize_bars()

	# Hide combo counter initially
	combo_counter.visible = false


func _process(delta: float) -> void:
	_update_damage_bar(delta)
	_update_combo_timer(delta)
	_update_echo_cooldown_display()


func _connect_signals() -> void:
	GameEvents.ui_update_health.connect(_on_health_updated)
	GameEvents.ui_update_momentum.connect(_on_momentum_updated)
	GameEvents.ui_update_echo_cooldown.connect(_on_echo_cooldown_updated)
	GameEvents.ui_show_damage_number.connect(_on_show_damage_number)

	GameEvents.momentum_threshold_echo_reached.connect(_on_echo_threshold_reached)
	GameEvents.momentum_threshold_damage_reached.connect(_on_damage_threshold_reached)
	GameEvents.momentum_threshold_ultimate_reached.connect(_on_ultimate_threshold_reached)
	GameEvents.momentum_threshold_lost.connect(_on_threshold_lost)

	GameEvents.echo_activated.connect(_on_echo_activated)
	GameEvents.echo_ready.connect(_on_echo_ready)
	GameEvents.echo_not_ready.connect(_on_echo_not_ready)

	# Connect to combat system for combos
	if ECS:
		var combat_system: CombatSystem = ECS.get_system(CombatSystem)
		if combat_system:
			combat_system.combo_increased.connect(_on_combo_increased)


func _initialize_bars() -> void:
	# Set initial sizes
	health_bar.size.x = _health_bar_width
	health_bar_damage.size.x = _health_bar_width

	# Momentum starts empty (from center)
	momentum_bar.size.x = 0
	momentum_bar.position.x = _momentum_bar_width / 2

	# Echo cooldown
	echo_cooldown.size.y = _echo_bar_height


# =============================================================================
# HEALTH
# =============================================================================

func _on_health_updated(current: int, max_hp: int) -> void:
	_current_health = current
	_max_health = max_hp

	var percent = float(current) / float(max_hp)
	_target_health_width = _health_bar_width * percent

	# Immediately update health bar
	health_bar.size.x = _target_health_width

	# Damage bar will lerp down
	_damage_bar_target = _target_health_width

	# Update label
	health_label.text = "%d / %d" % [current, max_hp]

	# Change color when low
	if percent <= 0.25:
		health_bar.color = COLOR_HEALTH_LOW
		_pulse_health_bar()
	else:
		health_bar.color = COLOR_HEALTH


func _update_damage_bar(delta: float) -> void:
	if health_bar_damage.size.x > _damage_bar_target:
		health_bar_damage.size.x = move_toward(
			health_bar_damage.size.x,
			_damage_bar_target,
			_damage_bar_speed * delta
		)


func _pulse_health_bar() -> void:
	var tween = create_tween()
	tween.tween_property(health_bar, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(health_bar, "modulate", Color.WHITE, 0.1)


# =============================================================================
# MOMENTUM
# =============================================================================

func _on_momentum_updated(current: float, max_val: float) -> void:
	_current_momentum = current
	_max_momentum = max_val

	var percent = current / max_val
	var bar_width = _momentum_bar_width * percent

	# Bar expands from center
	momentum_bar.size.x = bar_width
	momentum_bar.position.x = (_momentum_bar_width - bar_width) / 2

	# Update color based on thresholds
	_update_momentum_color(percent)


func _update_momentum_color(percent: float) -> void:
	if percent >= 1.0:
		momentum_bar.color = COLOR_MOMENTUM_ULTIMATE
	elif percent >= 0.5:
		momentum_bar.color = COLOR_MOMENTUM_DAMAGE
	elif percent >= 0.25:
		momentum_bar.color = COLOR_MOMENTUM_ECHO
	else:
		momentum_bar.color = COLOR_MOMENTUM_BASE


func _on_echo_threshold_reached() -> void:
	_flash_momentum_bar(COLOR_MOMENTUM_ECHO)


func _on_damage_threshold_reached() -> void:
	_flash_momentum_bar(COLOR_MOMENTUM_DAMAGE)


func _on_ultimate_threshold_reached() -> void:
	_flash_momentum_bar(COLOR_MOMENTUM_ULTIMATE)
	_show_ultimate_ready()


func _on_threshold_lost(_threshold_name: String) -> void:
	# Could add visual feedback for losing threshold
	pass


func _flash_momentum_bar(color: Color) -> void:
	var tween = create_tween()
	tween.tween_property(momentum_bar, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tween.tween_property(momentum_bar, "modulate", Color.WHITE, 0.2)


func _show_ultimate_ready() -> void:
	# Could show "ULTIMATE READY" text
	pass


# =============================================================================
# ECHO COOLDOWN
# =============================================================================

func _on_echo_cooldown_updated(remaining: float, total: float) -> void:
	_echo_cooldown_remaining = remaining
	_echo_cooldown_total = total
	_echo_ready = remaining <= 0


func _update_echo_cooldown_display() -> void:
	if _echo_cooldown_total <= 0:
		return

	if _echo_ready:
		echo_cooldown.size.y = _echo_bar_height
		echo_cooldown.offset_top = -_echo_bar_height
		echo_cooldown.color = COLOR_ECHO_READY
		echo_icon.modulate = COLOR_ECHO_READY
	else:
		var percent = 1.0 - (_echo_cooldown_remaining / _echo_cooldown_total)
		var fill_height = _echo_bar_height * percent
		echo_cooldown.size.y = fill_height
		echo_cooldown.offset_top = -fill_height
		echo_cooldown.color = COLOR_ECHO_COOLDOWN
		echo_icon.modulate = COLOR_ECHO_COOLDOWN


func _on_echo_activated() -> void:
	# Flash the echo icon
	var tween = create_tween()
	tween.tween_property(echo_icon, "modulate", Color.WHITE, 0.05)
	tween.tween_property(echo_icon, "modulate", COLOR_ECHO_COOLDOWN, 0.1)

	_echo_ready = false


func _on_echo_ready() -> void:
	_echo_ready = true
	# Pulse effect
	var tween = create_tween()
	tween.tween_property(echo_icon, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(echo_icon, "scale", Vector2(1.0, 1.0), 0.1)


func _on_echo_not_ready() -> void:
	_echo_ready = false


# =============================================================================
# COMBO COUNTER
# =============================================================================

func _on_combo_increased(entity_id: int, combo_count: int) -> void:
	# Only show for player
	if entity_id != GameState.player_entity_id:
		return

	_combo_count = combo_count
	_combo_timer = _combo_display_duration

	combo_counter.visible = true
	combo_counter.text = "%d HIT" % combo_count if combo_count > 1 else ""

	# Scale pop effect
	var tween = create_tween()
	combo_counter.scale = Vector2(1.5, 1.5)
	tween.tween_property(combo_counter, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

	# Color intensity based on combo
	var intensity = min(1.0 + combo_count * 0.1, 2.0)
	combo_counter.modulate = Color(intensity, intensity, intensity)


func _update_combo_timer(delta: float) -> void:
	if _combo_timer > 0:
		_combo_timer -= delta

		# Fade out near end
		if _combo_timer < 0.5:
			combo_counter.modulate.a = _combo_timer / 0.5

		if _combo_timer <= 0:
			combo_counter.visible = false
			_combo_count = 0


# =============================================================================
# DAMAGE NUMBERS
# =============================================================================

func _on_show_damage_number(world_position: Vector2, damage: int, is_critical: bool) -> void:
	var label = Label.new()
	label.text = str(damage)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Style
	label.add_theme_font_size_override("font_size", 20 if not is_critical else 28)
	label.add_theme_color_override("font_color", Color.WHITE if not is_critical else Color.YELLOW)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	damage_numbers.add_child(label)

	# Convert world position to screen position
	var camera = get_viewport().get_camera_2d()
	if camera:
		var screen_pos = world_position - camera.position + get_viewport_rect().size / 2
		label.position = screen_pos + Vector2(randf_range(-20, 20), -30)
	else:
		label.position = world_position

	# Animate
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
