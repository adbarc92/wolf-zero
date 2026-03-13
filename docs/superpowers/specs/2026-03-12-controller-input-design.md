# Controller Input Support

## Goal

Add gamepad/controller support so the game is playable with a controller, mapping to the existing platformer movement and combat systems. Also add a `crouch` input action wired through the ECS for future use.

## Context

The game uses an ECS architecture where all input methods (keyboard, touch) converge at Godot's Input action system. The InputSystem ECS system reads these actions each physics frame and writes to `input_state` components. Touch input is handled by the InputManager autoload, which simulates Input actions via `_simulate_action()`. This means adding controller support only requires adding gamepad bindings to project.godot — no new input processing code is needed for existing actions.

## Controller Mappings

| Action | Keyboard | Controller |
|--------|----------|------------|
| `move_left` | A | Left stick left / D-pad left |
| `move_right` | D | Left stick right / D-pad right |
| `jump` | Space | Left stick up / D-pad up / A button (South) |
| `crouch` (new) | S | Left stick down / D-pad down |
| `attack_light` | J | X button (West) |
| `attack_heavy` | K | Y button (North) |
| `dodge` | Shift | B button (East) |
| `echo_activate` | Q | RB / R1 |
| `pause` | Esc | Start |

Stick axes use a deadzone of 0.5. Jump is mapped to stick-up for accessibility on mobile controllers where button count may be limited — this means vertical stick is overloaded (up=jump, down=crouch), which is a deliberate trade-off for this mobile-first game.

Godot axis reference: `JOY_AXIS_LEFT_X` (axis 0, negative=left, positive=right), `JOY_AXIS_LEFT_Y` (axis 1, negative=up, positive=down).

## Changes Required

### 1. project.godot — Add gamepad bindings to all input actions

Add joypad button and axis events alongside existing keyboard events for every action. Add a new `crouch` action with keyboard (S) and gamepad (left stick down, D-pad down) bindings.

### 2. components.gd — Add crouch to input_state

Add `crouch_pressed: false` to the `input_state` component dictionary.

### 3. input_system.gd — Read crouch action and wire into attack direction

In `_process_movement_input()`, read `Input.is_action_pressed("crouch")` and set `input.crouch_pressed`.

In `_get_attack_direction()`, use `crouch_pressed` to set `direction.y = 1` for down-direction attacks. The existing codebase already defines `"heavy_down"` attack types and has a TODO comment for this.

## Out of Scope

- Crouch movement behavior (reduced speed, shorter hitbox, animations)
- Touch crouch trigger — the existing gesture system has no swipe-down mapping for crouch yet. Mobile-only players cannot crouch until a touch gesture is assigned in a future update.
- Right stick aiming
- Controller vibration/haptics
- Controller connect/disconnect notifications or UI prompt switching
- Deadzone tuning — using 0.5 consistently with existing mappings; can be adjusted during playtesting

## Design Principle

All three input methods (touch, keyboard, controller) converge at Godot's Input action system. The ECS InputSystem reads from this unified layer, so no input-method-specific logic is needed in game systems. This keeps the architecture clean for a mobile-first game that also supports controllers.
