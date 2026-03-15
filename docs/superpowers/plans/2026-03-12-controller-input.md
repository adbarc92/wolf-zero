# Controller Input Support Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add gamepad/controller bindings to all input actions and wire a new crouch input through the ECS, so the game is playable with a controller.

**Architecture:** All input methods (keyboard, touch, controller) converge at Godot's Input action system. We add joypad events to `project.godot`, add `crouch_pressed` to the `input_state` component, and update the InputSystem to read crouch and use it for downward attack direction.

**Tech Stack:** Godot 4.6, GDScript, custom ECS

**Spec:** `docs/superpowers/specs/2026-03-12-controller-input-design.md`

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `project.godot` | Modify (lines 45-86) | Add gamepad bindings to all input actions, add `crouch` action |
| `scripts/ecs/components.gd` | Modify (line 145-156) | Add `crouch_pressed` to `input_state` component |
| `scripts/ecs/systems/input_system.gd` | Modify (lines 20-27, 47-64) | Read crouch input, wire into attack direction |

---

## Chunk 1: Controller Input

### Task 1: Add gamepad bindings to project.godot

**Files:**
- Modify: `project.godot:45-86`

- [ ] **Step 1: Add controller bindings to all existing input actions and create the crouch action**

Replace the entire `[input]` section in `project.godot` with the following. Each action keeps its existing keyboard binding and adds gamepad button/axis events:

```ini
[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"axis":0,"axis_value":-1.0,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":13,"pressure":0.0,"pressed":true,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"axis":0,"axis_value":1.0,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":14,"pressure":0.0,"pressed":true,"script":null)
]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":0,"pressure":0.0,"pressed":true,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"axis":1,"axis_value":-1.0,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":11,"pressure":0.0,"pressed":true,"script":null)
]
}
crouch={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"axis":1,"axis_value":1.0,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":12,"pressure":0.0,"pressed":true,"script":null)
]
}
attack_light={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":74,"key_label":0,"unicode":106,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":2,"pressure":0.0,"pressed":true,"script":null)
]
}
attack_heavy={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":75,"key_label":0,"unicode":107,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":3,"pressure":0.0,"pressed":true,"script":null)
]
}
dodge={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194325,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":1,"pressure":0.0,"pressed":true,"script":null)
]
}
echo_activate={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":113,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":5,"pressure":0.0,"pressed":true,"script":null)
]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":6,"pressure":0.0,"pressed":true,"script":null)
]
}
```

**Godot joypad button reference:**
- 0 = A/Cross (South), 1 = B/Circle (East), 2 = X/Square (West), 3 = Y/Triangle (North)
- 5 = RB/R1, 6 = Start
- 11 = D-pad Up, 12 = D-pad Down, 13 = D-pad Left, 14 = D-pad Right

**Godot joypad axis reference:**
- Axis 0 = Left stick X (-1.0 = left, 1.0 = right)
- Axis 1 = Left stick Y (-1.0 = up, 1.0 = down)

- [ ] **Step 2: Commit**

```bash
git add project.godot
git commit -m "feat: add gamepad bindings to all input actions and add crouch action"
```

---

### Task 2: Add crouch_pressed to input_state component

**Files:**
- Modify: `scripts/ecs/components.gd:145-156`

- [ ] **Step 1: Add crouch_pressed field to input_state**

In `scripts/ecs/components.gd`, add `"crouch_pressed": false,` to the `input_state()` function's return dictionary, after the `"jump_just_pressed"` line:

```gdscript
static func input_state() -> Dictionary:
	return {
		"move_direction": 0.0,  # -1 to 1
		"jump_pressed": false,
		"jump_just_pressed": false,
		"crouch_pressed": false,
		"attack_light": false,
		"attack_heavy": false,
		"attack_direction": Vector2.ZERO,
		"dodge_pressed": false,
		"echo_pressed": false,
		"facing": 1,  # 1 right, -1 left
	}
```

- [ ] **Step 2: Commit**

```bash
git add scripts/ecs/components.gd
git commit -m "feat: add crouch_pressed to input_state component"
```

---

### Task 3: Update InputSystem to read crouch and wire into attack direction

**Files:**
- Modify: `scripts/ecs/systems/input_system.gd:20-27` (movement input)
- Modify: `scripts/ecs/systems/input_system.gd:47-64` (attack direction)

- [ ] **Step 1: Add crouch reading to _process_movement_input**

In `scripts/ecs/systems/input_system.gd`, add crouch reading at the end of `_process_movement_input()`:

```gdscript
func _process_movement_input(input: Dictionary) -> void:
	# Horizontal movement
	input.move_direction = Input.get_axis("move_left", "move_right")

	# Jump
	input.jump_just_pressed = Input.is_action_just_pressed("jump")
	input.jump_pressed = Input.is_action_pressed("jump")

	# Crouch
	input.crouch_pressed = Input.is_action_pressed("crouch")
```

- [ ] **Step 2: Wire crouch into _get_attack_direction for down attacks**

In `scripts/ecs/systems/input_system.gd`, replace the TODO comment in `_get_attack_direction()` with the crouch check:

```gdscript
func _get_attack_direction(input: Dictionary) -> Vector2:
	var direction = Vector2.ZERO

	# Check for directional input
	if Input.is_action_pressed("move_left"):
		direction.x = -1
	elif Input.is_action_pressed("move_right"):
		direction.x = 1

	if Input.is_action_pressed("jump"):  # Up
		direction.y = -1
	elif input.crouch_pressed:  # Down
		direction.y = 1

	# Default to forward if no direction
	if direction == Vector2.ZERO:
		direction.x = input.facing

	return direction.normalized()
```

- [ ] **Step 3: Commit**

```bash
git add scripts/ecs/systems/input_system.gd
git commit -m "feat: read crouch input and wire into directional attacks"
```

---

### Task 4: Manual verification

- [ ] **Step 1: Launch the game in Godot editor**

Open the project in Godot 4.6 and run the main scene (F5). Verify:
1. Keyboard controls still work (A/D move, Space jump, J/K attack, Shift dodge, Q echo)
2. S key triggers crouch input (no visible behavior yet, but no errors)

- [ ] **Step 2: Test with a connected controller**

With a gamepad connected:
1. Left stick left/right and D-pad left/right move the player
2. Left stick up, D-pad up, and A button (South) trigger jump
3. Left stick down and D-pad down trigger crouch (no visible behavior yet)
4. X button (West) triggers light attack
5. Y button (North) triggers heavy attack
6. B button (East) triggers dodge
7. RB/R1 triggers echo activate
8. Start button triggers pause

- [ ] **Step 3: Final commit if any fixes needed**
