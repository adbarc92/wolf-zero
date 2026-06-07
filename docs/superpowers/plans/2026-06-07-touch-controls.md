# Wolf-Zero — Touch Controls (mobile input layer) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** An on-screen touch control scheme for the mobile target (commuter audience). A left D-pad + right action buttons (MMX-style) that **synthesize the existing input actions**, so the ECS `InputSystem` needs zero changes and the defense button's tap-vs-hold (parry/block) works automatically. Testable on desktop via mouse→touch emulation.

**Architecture:** A `TouchControls` `CanvasLayer` builds `TouchScreenButton`s from a layout table; each button's `.action` is one of our InputMap actions (move_left/move_right/crouch/jump/attack_light/parry/dash/echo_activate) — `TouchScreenButton` synthesizes that action on touch, so `InputSystem` (which reads `Input.is_action_pressed/just_pressed`) drives gameplay unchanged. Enable `emulate_touch_from_mouse` so the buttons work with a mouse on desktop (dev/testing) and on touchscreens natively. Controls auto-show when a touchscreen is present, with a dev force-toggle (F2). Button textures are generated in code (translucent squares + glyph labels — placeholder art).

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH; commands self-terminate — `--quit-after`; never background; never leave processes). Tests `... -gtest=res://test/<f>.gd`; suite `-gconfig=res://.gutconfig.json`. `--import` once for new classes.

**Branch:** `feat/touch-controls` (off `feat/post-slice`; PR #5 pending). Serves [[wolf-zero-vision]] (mobile is core).

**Honest limit:** headless has no real touch device; we verify (a) the pure layout table, (b) that `TouchControls` instantiates + builds the buttons, (c) a **mouse-emulated press** drives the action, and (d) a screenshot of the on-screen controls. True multi-touch feel needs an on-device / mobile-export test.

**InputSystem actions (confirmed):** move_left, move_right, jump, crouch, attack_light, attack_heavy, dodge, dash, parry, echo_activate.

---

## Task 1: TouchControls overlay (buttons synthesize input actions)

**Files:** Create `scripts/ui/touch_controls.gd`; Modify `project.godot` (emulate_touch_from_mouse); Test `test/unit/test_touch_controls.gd`.

- [ ] **Step 1: Enable mouse→touch emulation** in `project.godot` under `[input_devices]`:
```
[input_devices]

pointing/emulate_touch_from_mouse=true
```
(If an `[input_devices]` section exists, merge; otherwise add it.)

- [ ] **Step 2: Create `scripts/ui/touch_controls.gd`:**
```gdscript
class_name TouchControls
extends CanvasLayer
## On-screen touch controls. Each button is a TouchScreenButton whose `action`
## synthesizes one of the game's input actions, so InputSystem is unchanged.
## Mouse drives them on desktop via emulate_touch_from_mouse.

var force_visible := false

## Button layout for a 1920x1080 reference: {action, glyph, pos, color}.
static func layout() -> Array:
	return [
		{"action": "move_left",     "glyph": "◀",   "pos": Vector2(150, 920),  "color": Color(1,1,1,0.25)},
		{"action": "move_right",    "glyph": "▶",   "pos": Vector2(310, 920),  "color": Color(1,1,1,0.25)},
		{"action": "crouch",        "glyph": "▼",   "pos": Vector2(230, 1010), "color": Color(1,1,1,0.2)},
		{"action": "jump",          "glyph": "JMP", "pos": Vector2(1790, 940), "color": Color(0.4,0.9,1,0.3)},
		{"action": "attack_light",  "glyph": "ATK", "pos": Vector2(1650, 980), "color": Color(1,0.5,0.4,0.3)},
		{"action": "parry",         "glyph": "DEF", "pos": Vector2(1700, 840), "color": Color(0.6,0.8,1,0.35)},
		{"action": "dash",          "glyph": "DSH", "pos": Vector2(1540, 940), "color": Color(0.8,1,0.6,0.3)},
		{"action": "echo_activate", "glyph": "ECHO","pos": Vector2(1850, 820), "color": Color(0.9,0.6,1,0.3)},
	]

static func should_show() -> bool:
	return DisplayServer.is_touchscreen_available()

const BTN := 120

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	for spec in layout():
		_make_button(spec)
	_apply_visibility()

func _make_button(spec: Dictionary) -> void:
	var b := TouchScreenButton.new()
	b.action = spec.action
	b.position = spec.pos
	b.texture_normal = _btn_texture(spec.color)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BTN, BTN)
	b.shape = shape
	# center the shape on the texture
	var lbl := Label.new()
	lbl.text = spec.glyph
	lbl.size = Vector2(BTN, BTN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1,1,1,0.9))
	b.add_child(lbl)
	add_child(b)

func _btn_texture(c: Color) -> ImageTexture:
	var img := Image.create(BTN, BTN, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		force_visible = not force_visible
		_apply_visibility()

func _apply_visibility() -> void:
	visible = force_visible or should_show()
```
(Note: `TouchScreenButton.shape` anchors at the node origin; the texture also draws from the origin, so they align. Fine for placeholders.)

- [ ] **Step 3: Failing test** `test/unit/test_touch_controls.gd`:
```gdscript
extends GutTest
const TC = preload("res://scripts/ui/touch_controls.gd")

func test_layout_covers_core_actions():
	var actions := []
	for spec in TC.layout():
		actions.append(spec.action)
	for a in ["move_left", "move_right", "jump", "attack_light", "parry", "dash", "echo_activate"]:
		assert_true(actions.has(a), "touch layout includes %s" % a)

func test_every_button_has_glyph_and_pos():
	for spec in TC.layout():
		assert_true(spec.has("action") and spec.has("glyph") and spec.has("pos"))
		assert_true(spec.pos is Vector2)
```
RED (`--import`) → implement → GREEN.

- [ ] **Step 4:** `--import`; full suite green (baseline 73; +2). Parse check clean. **Commit:** `feat: TouchControls overlay (TouchScreenButtons synthesizing input actions)`.

---

## Task 2: Wire into main + verify render & mouse-press

**Files:** `scripts/main/main.gd`.

- [ ] **Step 1:** In `main._ready()`, add the overlay (force-visible in debug so it's testable on desktop):
```gdscript
	var touch := TouchControls.new()
	if OS.is_debug_build():
		touch.force_visible = true
	add_child(touch)
```
(Place after the other overlays/ScreenManager.)

- [ ] **Step 2: Verify**
  - `--import`; full suite green; boot check (`--headless --path . --quit-after 150`): no SCRIPT ERROR; MENU.
  - **Render + press montage** (temp `tools/`, delete after): instance main, `_start_level()`, screenshot `res://tools/touch.png` (controls visible since debug). Then simulate a tap on the JUMP button to confirm the action fires: parse the JUMP button's screen position from `TouchControls.layout()` (the jump pos + half BTN), then feed an `InputEventScreenTouch` (pressed=true at that position) via `Input.parse_input_event(...)` OR warp the mouse there and send `InputEventMouseButton` (emulate_touch_from_mouse converts it). Wait a frame and PRINT `Input.is_action_pressed("jump")` (expect true). Release. Also confirm the player's vertical velocity goes negative (jumped) as a stronger check if feasible. Print results; confirm no SCRIPT ERROR; confirm `touch.png` exists. Delete `tools/`.
  (If simulating the press proves flaky headlessly, at minimum confirm the controls render in `touch.png` and that `TouchControls` built 8 buttons — and report that on-device press testing remains.)

- [ ] **Step 3: Commit:** `feat: show touch controls in-game (debug-forced for desktop testing)`.

---

## Definition of Done
- [ ] An on-screen control scheme renders (left D-pad + right action buttons incl. a DEF parry/block button).
- [ ] Buttons synthesize the real input actions (verified by a mouse/touch-emulated press driving `jump`); InputSystem unchanged.
- [ ] Auto-shows on touchscreens; F2 force-toggles on desktop; mouse→touch emulation enabled.
- [ ] All tests pass; clean boot.
- [ ] (Button art is placeholder; layout/sizes need on-device tuning. Analog stick + gesture combat are future refinements.)
