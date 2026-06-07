class_name ScreenManager
extends CanvasLayer

var _label: Label

## Pure: overlay text for a given state (empty = hidden, e.g. during PLAYING).
static func screen_text(state: int, _lives: int) -> String:
	match state:
		GameState.State.MENU:
			return "WOLF ZERO\n\nNeo Edo\n\n[Enter] Begin"
		GameState.State.PAUSED:
			return "PAUSED\n\n[Esc] Resume    [R] Restart"
		GameState.State.VICTORY:
			return "VICTORY\n\n[R] Play Again"
		GameState.State.GAME_OVER:
			return "DEFEAT\n\n[R] Retry"
		_:
			return ""

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 48)
	_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	add_child(_label)
	GameState.state_changed.connect(_on_state_changed)
	_refresh(GameState.current_state)

func _on_state_changed(new_state: int, _old: int) -> void:
	_refresh(new_state)

func _refresh(state: int) -> void:
	var t := screen_text(state, GameState.lives)
	_label.text = t
	_label.visible = t != ""
