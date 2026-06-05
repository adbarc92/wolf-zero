class_name DebugOverlay
extends CanvasLayer
## Dev-only input-action guide. Lists each game action and its current binding
## (read live from InputMap, so it never drifts from project.godot), plus an FPS
## readout. Toggle with F1. Only shown in debug builds (see main.gd wiring).

const ACTIONS: Array[String] = [
	"move_left", "move_right", "jump", "crouch",
	"attack_light", "attack_heavy", "dodge", "dash",
	"echo_activate", "pause",
]

var _fps_label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep visible/updating while paused
	_build_ui()
	visible = OS.is_debug_build()


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 70)
	panel.modulate = Color(1, 1, 1, 0.9)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "CONTROLS  (F1 to toggle)"
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(title)

	for action in ACTIONS:
		var row := Label.new()
		row.text = "%s    %s" % [_pretty(action), describe_binding(action)]
		vbox.add_child(row)

	_fps_label = Label.new()
	_fps_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	vbox.add_child(_fps_label)

	add_child(panel)


func _process(_delta: float) -> void:
	if _fps_label:
		_fps_label.text = "FPS    %d" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		visible = not visible


## Human-readable action label, e.g. "attack_light" -> "Attack Light".
static func _pretty(action: String) -> String:
	return action.capitalize()


## Describe an action's bindings (keyboard key names + gamepad buttons/axes),
## read from the live InputMap. Returns "-" for unknown actions.
static func describe_binding(action: String) -> String:
	if not InputMap.has_action(action):
		return "-"
	var parts: Array[String] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var kc: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			parts.append(OS.get_keycode_string(kc))
		elif ev is InputEventJoypadButton:
			parts.append("Pad%d" % ev.button_index)
		elif ev is InputEventJoypadMotion:
			parts.append("Axis%d" % ev.axis)
	return ", ".join(parts)
