extends Control
## HUD - Heads Up Display
##
## Displays health, momentum, banked Charges, and combo counter.
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

# Lives label (built in code, near the health bar)
var _lives_label: Label

# Charge pool readout (built in code, under the lives label)
var _charges_label: Label

# Boss bar (built in code, top-center, hidden unless a boss is active)
var _boss_container: Control
var _boss_bar: ColorRect
var _boss_label: Label
var _boss_bar_width: float = 600.0
var _boss_max_hp: int = 1

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
var _broken: bool = false

var _charges: int = 0
var _max_charges: int = 3
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
## Near the top of the bar: a Charge is about to bank.
const COLOR_MOMENTUM_FULL = Color(1.0, 0.9, 0.3, 1.0)
## Broken: spent to zero, staggered and open.
const COLOR_MOMENTUM_BROKEN = Color(1.0, 0.2, 0.15, 1.0)
const COLOR_ECHO_READY = Color(0.0, 1.0, 1.0, 1.0)
const COLOR_ECHO_EMPTY = Color(0.3, 0.3, 0.4, 1.0)


const COLOR_BOSS_BG = Color(0.12, 0.04, 0.06, 0.85)
const COLOR_BOSS_FILL = Color(1.0, 0.2, 0.25, 1.0)


func _ready() -> void:
	_build_boss_bar()
	_build_lives_label()
	_build_charges_label()
	_connect_signals()
	# Deferred so bar sizes are applied after the initial layout pass
	# (avoids "anchors will override size after _ready" warnings).
	_initialize_bars.call_deferred()

	# Hide combo counter initially
	combo_counter.visible = false

	# Initialize lives display and HUD visibility from current state
	set_lives(GameState.lives)
	_apply_visibility(GameState.current_state)


func _process(delta: float) -> void:
	_update_damage_bar(delta)
	_update_combo_timer(delta)


func _connect_signals() -> void:
	GameEvents.ui_update_health.connect(_on_health_updated)
	GameEvents.ui_update_momentum.connect(_on_momentum_updated)
	GameEvents.ui_show_damage_number.connect(_on_show_damage_number)

	GameEvents.charges_changed.connect(_on_charges_changed)
	GameEvents.momentum_broken.connect(_on_momentum_broken)
	GameEvents.momentum_recovered.connect(_on_momentum_recovered)

	GameEvents.echo_activated.connect(_on_echo_activated)
	GameEvents.echo_ready.connect(_on_echo_ready)
	GameEvents.echo_not_ready.connect(_on_echo_not_ready)

	GameEvents.boss_spawned.connect(_on_boss_spawned)
	GameEvents.boss_health.connect(_on_boss_health)
	GameEvents.boss_defeated.connect(_on_boss_defeated)

	GameEvents.lives_changed.connect(set_lives)
	GameState.state_changed.connect(_on_state_changed)

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

	_update_momentum_color(percent)


func _update_momentum_color(percent: float) -> void:
	if _broken:
		momentum_bar.color = COLOR_MOMENTUM_BROKEN
	elif percent >= 0.8:
		momentum_bar.color = COLOR_MOMENTUM_FULL
	else:
		momentum_bar.color = COLOR_MOMENTUM_BASE


func _on_momentum_broken() -> void:
	_broken = true
	_update_momentum_color(0.0)
	_flash_momentum_bar()


func _on_momentum_recovered() -> void:
	_broken = false


func _flash_momentum_bar() -> void:
	var tween = create_tween()
	tween.tween_property(momentum_bar, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tween.tween_property(momentum_bar, "modulate", Color.WHITE, 0.2)


# =============================================================================
# CHARGES
# =============================================================================

static func charges_text(charges: int, max_charges: int) -> String:
	return "CHARGE  %d / %d" % [charges, max_charges]


func _build_charges_label() -> void:
	var label := Label.new()
	label.name = "ChargesLabel"
	# Directly under the lives label, in the same top-left cluster.
	label.position = Vector2(24.0, 86.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", COLOR_ECHO_READY)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 16)
	label.text = charges_text(0, _max_charges)
	add_child(label)
	_charges_label = label


func _on_charges_changed(charges: int, max_charges: int) -> void:
	_charges = charges
	_max_charges = max_charges
	_echo_ready = charges > 0

	if _charges_label:
		_charges_label.text = charges_text(charges, max_charges)
		_charges_label.modulate = COLOR_ECHO_READY if _echo_ready else COLOR_ECHO_EMPTY

	_update_echo_display()


## The Charge pool is Echo's only gate, so the indicator is simply lit or dark —
## there is no cooldown left to fill up.
func _update_echo_display() -> void:
	echo_cooldown.size.y = _echo_bar_height
	echo_cooldown.offset_top = -_echo_bar_height
	var tint: Color = COLOR_ECHO_READY if _echo_ready else COLOR_ECHO_EMPTY
	echo_cooldown.color = tint
	echo_icon.modulate = tint


func _on_echo_activated() -> void:
	# Flash the echo icon
	var tween = create_tween()
	tween.tween_property(echo_icon, "modulate", Color.WHITE, 0.05)
	tween.tween_property(echo_icon, "modulate", COLOR_ECHO_EMPTY, 0.1)


func _on_echo_ready() -> void:
	_echo_ready = true
	_update_echo_display()
	# Pulse effect
	var tween = create_tween()
	tween.tween_property(echo_icon, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(echo_icon, "scale", Vector2(1.0, 1.0), 0.1)


func _on_echo_not_ready() -> void:
	_echo_ready = false
	_update_echo_display()


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
# BOSS BAR
# =============================================================================

func _build_boss_bar() -> void:
	_boss_container = Control.new()
	_boss_container.name = "BossContainer"
	# Top-center anchor
	_boss_container.anchor_left = 0.5
	_boss_container.anchor_right = 0.5
	_boss_container.offset_left = -_boss_bar_width / 2.0
	_boss_container.offset_right = _boss_bar_width / 2.0
	_boss_container.offset_top = 24.0
	_boss_container.offset_bottom = 76.0
	_boss_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_container.visible = false
	add_child(_boss_container)

	var label := Label.new()
	label.name = "BossLabel"
	label.anchor_right = 1.0
	label.offset_bottom = 22.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 18)
	label.text = "Boss"
	_boss_container.add_child(label)
	_boss_label = label

	var bg := ColorRect.new()
	bg.name = "BossBarBG"
	bg.anchor_right = 1.0
	bg.offset_top = 24.0
	bg.offset_bottom = 48.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = COLOR_BOSS_BG
	_boss_container.add_child(bg)

	var fill := ColorRect.new()
	fill.name = "BossBar"
	fill.offset_top = 24.0
	fill.offset_bottom = 48.0
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.color = COLOR_BOSS_FILL
	fill.size.x = _boss_bar_width
	_boss_container.add_child(fill)
	_boss_bar = fill


func _on_boss_spawned(boss_name: String) -> void:
	if not _boss_container:
		return
	if _boss_label:
		_boss_label.text = boss_name
	_boss_max_hp = 1
	if _boss_bar:
		_boss_bar.size.x = _boss_bar_width
	_boss_container.visible = true


func _on_boss_health(current: int, max_hp: int) -> void:
	if not _boss_bar:
		return
	_boss_max_hp = max(max_hp, 1)
	var percent: float = clampf(float(current) / float(_boss_max_hp), 0.0, 1.0)
	_boss_bar.size.x = _boss_bar_width * percent


func _on_boss_defeated() -> void:
	if _boss_container:
		_boss_container.visible = false


# =============================================================================
# LIVES
# =============================================================================

static func lives_text(n: int) -> String:
	return "LIVES  %d" % n


func _build_lives_label() -> void:
	var label := Label.new()
	label.name = "LivesLabel"
	# Position near the health bar (top-left area, just below it)
	label.position = Vector2(24.0, 64.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	_lives_label = label


func set_lives(n: int) -> void:
	if _lives_label:
		_lives_label.text = lives_text(n)


# =============================================================================
# HUD VISIBILITY
# =============================================================================

func _on_state_changed(new_state: GameState.State, _old_state: GameState.State) -> void:
	_apply_visibility(new_state)


func _apply_visibility(state: GameState.State) -> void:
	visible = (state == GameState.State.PLAYING or state == GameState.State.PAUSED)


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
