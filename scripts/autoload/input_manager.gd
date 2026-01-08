extends Node
## Input Manager - Handles touch/gesture input for mobile and maps to game actions
##
## Supports both gesture-based controls and virtual button controls.

# =============================================================================
# SIGNALS
# =============================================================================

signal gesture_tap(position: Vector2)
signal gesture_swipe(direction: Vector2, speed: float)
signal gesture_two_finger_tap()
signal virtual_joystick_changed(direction: Vector2)

# =============================================================================
# CONFIGURATION
# =============================================================================

## Minimum distance for a swipe to register
var swipe_threshold: float = 50.0

## Maximum time for a tap (longer = hold)
var tap_max_duration: float = 0.2

## Sensitivity multiplier for gestures
var gesture_sensitivity: float = 1.0

## Current control scheme: "gesture" or "buttons"
var control_scheme: String = "gesture"

# =============================================================================
# STATE
# =============================================================================

var _touch_start_position: Vector2 = Vector2.ZERO
var _touch_start_time: float = 0.0
var _is_touching: bool = false
var _touch_index: int = -1

var _second_touch_position: Vector2 = Vector2.ZERO
var _second_touch_active: bool = false

# Virtual joystick state
var _joystick_active: bool = false
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_direction: Vector2 = Vector2.ZERO
var _joystick_radius: float = 100.0

# Screen zones (for gesture controls)
var _screen_size: Vector2 = Vector2.ZERO
var _left_zone_width: float = 0.4  # Left 40% for movement
var _right_zone_width: float = 0.6  # Right 60% for actions


func _ready() -> void:
	_screen_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Load settings
	gesture_sensitivity = GameState.settings.gesture_sensitivity
	control_scheme = GameState.settings.control_scheme


func _on_viewport_size_changed() -> void:
	_screen_size = get_viewport().get_visible_rect().size


func _input(event: InputEvent) -> void:
	if control_scheme == "gesture":
		_handle_gesture_input(event)
	else:
		_handle_button_input(event)


# =============================================================================
# GESTURE INPUT
# =============================================================================

func _handle_gesture_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Check for second finger (two-finger tap for Echo)
		if _is_touching and not _second_touch_active:
			_second_touch_active = true
			_second_touch_position = event.position

			# Two finger tap detected
			gesture_two_finger_tap.emit()
			_simulate_action("echo_activate")
			return

		# First touch
		_is_touching = true
		_touch_index = event.index
		_touch_start_position = event.position
		_touch_start_time = Time.get_ticks_msec() / 1000.0

		# Check if in left zone (joystick area)
		if event.position.x < _screen_size.x * _left_zone_width:
			_joystick_active = true
			_joystick_center = event.position
	else:
		# Touch released
		if event.index == _touch_index:
			var touch_duration = Time.get_ticks_msec() / 1000.0 - _touch_start_time
			var touch_distance = event.position.distance_to(_touch_start_position)

			# Determine gesture type
			if touch_distance < swipe_threshold * gesture_sensitivity:
				# Tap
				if touch_duration < tap_max_duration:
					_handle_tap(event.position)
			else:
				# Swipe
				var direction = (event.position - _touch_start_position).normalized()
				var speed = touch_distance / touch_duration
				_handle_swipe(direction, speed)

			_is_touching = false
			_touch_index = -1
			_joystick_active = false
			_joystick_direction = Vector2.ZERO
			virtual_joystick_changed.emit(Vector2.ZERO)

		# Second finger released
		if _second_touch_active and event.index != _touch_index:
			_second_touch_active = false


func _handle_drag(event: InputEventScreenDrag) -> void:
	if _joystick_active and event.index == _touch_index:
		# Update joystick direction
		var offset = event.position - _joystick_center
		if offset.length() > _joystick_radius:
			offset = offset.normalized() * _joystick_radius

		_joystick_direction = offset / _joystick_radius
		virtual_joystick_changed.emit(_joystick_direction)

		# Emit movement input
		if abs(_joystick_direction.x) > 0.2:
			if _joystick_direction.x > 0:
				_simulate_action("move_right", true)
				_simulate_action("move_left", false)
			else:
				_simulate_action("move_left", true)
				_simulate_action("move_right", false)
		else:
			_simulate_action("move_left", false)
			_simulate_action("move_right", false)


func _handle_tap(position: Vector2) -> void:
	gesture_tap.emit(position)

	# Right side tap = light attack
	if position.x > _screen_size.x * _left_zone_width:
		_simulate_action("attack_light")


func _handle_swipe(direction: Vector2, speed: float) -> void:
	gesture_swipe.emit(direction, speed)

	# Only process swipes on right side of screen
	if _touch_start_position.x < _screen_size.x * _left_zone_width:
		return

	# Determine swipe action
	if abs(direction.y) > abs(direction.x):
		# Vertical swipe
		if direction.y < -0.5:
			# Swipe up = jump
			_simulate_action("jump")
		elif direction.y > 0.5:
			# Swipe down = could be crouch or down attack
			pass
	else:
		# Horizontal swipe
		if abs(direction.x) > 0.5:
			# Horizontal swipe in combat = heavy attack or dodge
			if speed > 500:
				_simulate_action("dodge")
			else:
				_simulate_action("attack_heavy")


# =============================================================================
# BUTTON INPUT (Alternative scheme)
# =============================================================================

func _handle_button_input(_event: InputEvent) -> void:
	# Virtual buttons are handled by UI nodes that emit input actions
	# This is just a placeholder for any additional processing
	pass


# =============================================================================
# UTILITY
# =============================================================================

func _simulate_action(action: String, pressed: bool = true) -> void:
	if pressed:
		Input.action_press(action)
		# Auto-release after short delay for "just_pressed" actions
		get_tree().create_timer(0.05).timeout.connect(
			func(): Input.action_release(action)
		)
	else:
		Input.action_release(action)


## Get current joystick direction (for UI display)
func get_joystick_direction() -> Vector2:
	return _joystick_direction


## Check if joystick is active
func is_joystick_active() -> bool:
	return _joystick_active


## Update settings
func update_sensitivity(value: float) -> void:
	gesture_sensitivity = value
	GameState.settings.gesture_sensitivity = value


func set_control_scheme(scheme: String) -> void:
	control_scheme = scheme
	GameState.settings.control_scheme = scheme
