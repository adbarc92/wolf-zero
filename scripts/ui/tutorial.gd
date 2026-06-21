extends CanvasLayer
class_name Tutorial
## First-run onboarding prompts for the three unlearnable mechanics:
## momentum, Echo, and parry.
##
## Each prompt is triggered by a real GameEvents signal, shown once, and then
## never again for the rest of the run. The trigger/show-once decision is kept
## as PURE state logic (see TriggerState below) so it can be unit-tested without
## a running scene. The CanvasLayer half only renders the chosen prompt.
##
## Lane Z owns the wiring: main.gd should `add_child(Tutorial.new())` in _ready,
## gated on a first-run flag. Persistence (suppressing prompts on later runs) is
## also Lane Z's call via a GameState flag.

# =============================================================================
# TRIGGER STATE (pure, testable — no scene, no nodes)
# =============================================================================

## Identifiers for each teachable mechanic. Kept as plain String keys so the
## state machine has zero scene dependencies.
const PROMPT_MOMENTUM := "momentum"
const PROMPT_ECHO := "echo"
const PROMPT_PARRY := "parry"

## SHORT copy — commute / one-handed audience. One line each.
const COPY := {
	PROMPT_MOMENTUM: "Momentum building — keep attacking to charge up.",
	PROMPT_ECHO: "Echo ready! Send a decoy to bait enemies.",
	PROMPT_PARRY: "Tap parry just before a hit to deflect it.",
}

## Pure show-once trigger state machine.
##
## Drives entirely off method calls — the Tutorial node feeds it GameEvents,
## but tests can feed it directly. A prompt fires at most once per instance;
## once shown it is "spent" and will never fire again.
class TriggerState:
	## prompt_id -> has it already been shown this run
	var _shown: Dictionary = {}

	## Returns the prompt_id to display for this trigger, or "" if nothing
	## should be shown (unknown id, or already shown once). Marks it shown.
	func request(prompt_id: String) -> String:
		if not COPY.has(prompt_id):
			return ""
		if _shown.get(prompt_id, false):
			return ""
		_shown[prompt_id] = true
		return prompt_id

	## True once this prompt has fired (and been spent).
	func was_shown(prompt_id: String) -> bool:
		return _shown.get(prompt_id, false)

	## True once every known prompt has been shown — Lane Z can use this to
	## flip a persistent "tutorial complete" flag if it wants to.
	func all_shown() -> bool:
		for id in COPY.keys():
			if not _shown.get(id, false):
				return false
		return true

# --- Trigger map (signal -> prompt) ----------------------------------------
# Resolved as pure functions so the test can assert the mapping without a node.
# Each maps a real, on-bus GameEvents signal to the mechanic it teaches.

## First momentum gain (current rises above 0) teaches what momentum is.
static func prompt_for_momentum_changed(current: float) -> String:
	return PROMPT_MOMENTUM if current > 0.0 else ""

## Crossing the echo momentum threshold teaches Echo (the signal only fires
## at the threshold, so it always maps).
static func prompt_for_echo_threshold() -> String:
	return PROMPT_ECHO

## Taking the first hit teaches parry (you got hit — next time, deflect it).
static func prompt_for_player_damaged() -> String:
	return PROMPT_PARRY

# =============================================================================
# PRESENTATION (scene side — anchoring follows hud.gd conventions)
# =============================================================================

## How long a prompt stays on screen before auto-dismissing.
const SHOW_DURATION := 4.0

const COLOR_PANEL := Color(0.04, 0.05, 0.08, 0.85)
const COLOR_TEXT := Color(0.85, 0.95, 1.0, 1.0)

var _state := TriggerState.new()
var _panel: PanelContainer
var _label: Label
var _dismiss_timer: float = 0.0


func _ready() -> void:
	layer = 60  # above HUD, below the win overlay (main.gd WinLayer is 50... 60 sits above HUD)
	process_mode = Node.PROCESS_MODE_ALWAYS  # readable while paused
	_build_prompt()
	_connect_signals()


func _build_prompt() -> void:
	var panel := PanelContainer.new()
	panel.name = "TutorialPrompt"
	# Bottom-center, above the on-screen controls.
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = -150.0
	panel.offset_bottom = -100.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.name = "TutorialLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 18)
	panel.add_child(label)

	panel.visible = false
	add_child(panel)
	_panel = panel
	_label = label


func _connect_signals() -> void:
	GameEvents.momentum_changed.connect(_on_momentum_changed)
	GameEvents.momentum_threshold_echo_reached.connect(_on_echo_threshold_reached)
	GameEvents.player_damaged.connect(_on_player_damaged)


func _process(delta: float) -> void:
	if _dismiss_timer <= 0.0:
		return
	_dismiss_timer -= delta
	if _dismiss_timer <= 0.0:
		_dismiss()


# --- Signal handlers: map event -> prompt, then show-once via TriggerState ---

func _on_momentum_changed(current: float, _max_value: float, _percent: float) -> void:
	_try_show(prompt_for_momentum_changed(current))


func _on_echo_threshold_reached() -> void:
	_try_show(prompt_for_echo_threshold())


func _on_player_damaged(_damage: int, _current_health: int) -> void:
	_try_show(prompt_for_player_damaged())


func _try_show(prompt_id: String) -> void:
	if prompt_id == "":
		return
	var resolved := _state.request(prompt_id)
	if resolved == "":
		return
	_show(resolved)


func _show(prompt_id: String) -> void:
	if not _label:
		return
	_label.text = COPY.get(prompt_id, "")
	_panel.visible = true
	_dismiss_timer = SHOW_DURATION


func _dismiss() -> void:
	_dismiss_timer = 0.0
	if _panel:
		_panel.visible = false
