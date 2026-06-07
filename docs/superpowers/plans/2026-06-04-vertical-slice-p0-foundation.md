# Wolf-Zero Vertical Slice — P0: Physics & Render Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the player a real, animated, physics-driven character that runs, jumps, and dashes on a tilemap floor at 60 FPS, with the momentum HUD updating from combat and pause that actually freezes the game — the foundation every later phase builds on.

**Architecture:** The existing hybrid ECS stays. We make the **ECS the single source of truth for movement**: `MovementSystem` computes velocity only, and a new **`PhysicsSyncSystem`** (running right after it, inside the ECS `_physics_process` loop) owns `move_and_slide()` and reads collision flags back into components — one deterministic order, eliminating the stale-frame bug from attaching a per-node controller. A new **`AnimationSystem`** becomes the renderer, owning each entity's `AnimatedSprite2D` and driving it from the `sprite` component.

**Tech Stack:** Godot 4.6 (GL Compatibility / Mobile renderer), GDScript, GUT (Godot Unit Test) for tests. Salvaged FreeKnight sprite sheets under `assets/FreeKnight_v1/`.

**Spec:** `docs/superpowers/specs/2026-06-04-vertical-slice-design.md` (this is phase **P0** of §10).

**Branch:** `feat/vertical-slice`.

---

## Conventions for this plan

- The Godot binary is invoked as `godot` below. If it isn't on PATH, substitute the full path (e.g. `& "C:\Program Files\Godot\Godot_v4.6.exe"`). All commands run from the repo root `wolf-zero/`.
- "Run the scene" = `godot --path . ` (opens the project main scene `scenes/main/main.tscn`).
- GUT tests live under `test/unit/` and run headless via the GUT CLI (Task 1 wires this up).
- Component data are plain `Dictionary` objects returned by `Components.*` factories (see `scripts/ecs/components.gd`). Systems extend `ECSSystem` (`scripts/ecs/ecs_system.gd`): override `_get_required_components()` and `process(delta)`; helpers `get_entities()`, `get_component(id, type)`, `has_component(id, type)`, `get_node(id)` are available.
- ECS API (`scripts/ecs/ecs.gd`): `create_entity_with_node(node)`, `add_component(id, type, data)`, `get_component(id, type)`, `get_entity_node(id)`, `get_entities_with(type)`, `get_entities_with_all([types])`, `register_system(system)`.

---

## File structure (P0)

| File | Responsibility | Action |
|------|----------------|--------|
| `addons/gut/…` | Test framework | Install |
| `.gutconfig.json` | GUT CLI config | Create |
| `test/unit/test_momentum_routing.gd` | Momentum-from-combat test | Create |
| `test/unit/test_movement_velocity.gd` | Dodge/dash-as-velocity test | Create |
| `test/unit/test_animation_state.gd` | Animation-name derivation test | Create |
| `test/integration/test_physics_sync.gd` | move_and_slide read-back test | Create |
| `scripts/ecs/systems/physics_sync_system.gd` | Owns move_and_slide + collision read-back | Create |
| `scripts/ecs/systems/animation_system.gd` | Renderer: owns AnimatedSprite2D from `sprite` | Create |
| `scripts/render/sprite_frames_builder.gd` | Build SpriteFrames from FreeKnight strips | Create |
| `scripts/ecs/systems/movement_system.gd` | Velocity-only; dodge/dash set velocity; dash trigger | Modify |
| `scripts/ecs/systems/combat_system.gd` | Route momentum through MomentumSystem | Modify |
| `scripts/ecs/components.gd` | Add `dash_pressed` to `input_state` | Modify |
| `scripts/ecs/ecs.gd` | `PROCESS_MODE_PAUSABLE` so pause works | Modify |
| `scripts/main/main.gd` | Register new systems; stop creating Sprite2D; pause handler; grant dash; tilemap floor | Modify |
| `project.godot` | Add `dash` input action | Modify |
| `scripts/entities/player_controller.gd` | Now unused (PhysicsSync replaces it) | Delete |

---

## Task 1: Install and wire up the GUT test framework

**Files:**
- Create: `addons/gut/` (downloaded), `.gutconfig.json`, `test/unit/test_sanity.gd`
- Modify: `project.godot` (enable plugin)

- [ ] **Step 1: Install GUT**

GUT 9.x supports Godot 4. Install via the Godot Asset Library in-editor (Project → AssetLib → search "Gut" → Download → install the `addons/gut` folder), OR clone it:

```bash
git clone --depth 1 --branch v9.3.0 https://github.com/bitwes/Gut.git /tmp/gut
mkdir -p addons
cp -r /tmp/gut/addons/gut addons/gut
```

- [ ] **Step 2: Enable the plugin and create GUT config**

Enable in editor (Project → Project Settings → Plugins → GUT → Enable), or add to `project.godot` under `[editor_plugins]`:

```
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

Create `.gutconfig.json`:

```json
{
  "dirs": ["res://test/unit", "res://test/integration"],
  "include_subdirs": true,
  "log_level": 1,
  "should_exit": true
}
```

- [ ] **Step 3: Write a sanity test**

Create `test/unit/test_sanity.gd`:

```gdscript
extends GutTest

func test_gut_runs():
	assert_eq(2 + 2, 4, "GUT is wired up")
```

- [ ] **Step 4: Run the GUT CLI and verify it passes**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```
Expected: output shows `1 passing` (or similar), exit code 0.

- [ ] **Step 5: Commit**

```bash
git add addons/gut .gutconfig.json test/unit/test_sanity.gd project.godot
git commit -m "test: install and configure GUT"
```

---

## Task 2: Route combat momentum through MomentumSystem (fixes HUD desync)

**Why:** `CombatSystem._add_momentum` (combat_system.gd:209) mutates the component directly and never emits `momentum_changed`, so the HUD (which listens on that signal, main.gd:319) never updates from attacks. `MomentumSystem.add_momentum` (momentum_system.gd:64) does emit it. Route through it, matching how `DodgeSystem` already does (dodge_system.gd:39-43).

**Files:**
- Test: `test/unit/test_momentum_routing.gd`
- Modify: `scripts/ecs/systems/combat_system.gd`

- [ ] **Step 1: Write the failing test**

Create `test/unit/test_momentum_routing.gd`. This builds a tiny ECS with the momentum + combat systems, fires a light attack, and asserts the `momentum_changed` signal fired (proof it went through MomentumSystem).

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_ecs() -> Node:
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	return ecs

func test_light_attack_emits_momentum_changed():
	var ecs = _make_ecs()
	var momentum_sys = MomentumSystem.new()
	var combat_sys = CombatSystem.new()
	ecs.register_system(momentum_sys)
	ecs.register_system(combat_sys)

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "weapon", Components.weapon(15, 0.25))
	ecs.add_component(e, "health", Components.health(100))
	ecs.add_component(e, "momentum", Components.momentum())
	ecs.add_component(e, "input_state", Components.input_state())
	ecs.add_component(e, "tag_player", Components.tag_player())

	watch_signals(momentum_sys)
	var input = ecs.get_component(e, "input_state")
	input.attack_light = true

	combat_sys.process(0.016)

	assert_signal_emitted(momentum_sys, "momentum_changed",
		"combat momentum must go through MomentumSystem so the HUD updates")
	var momentum = ecs.get_component(e, "momentum")
	assert_eq(momentum.current, 5.0, "gain_attack (5.0) applied once")
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_momentum_routing.gd
```
Expected: FAIL — `momentum_changed` not emitted (CombatSystem mutates the dict directly).

- [ ] **Step 3: Replace the local momentum mutation with a MomentumSystem call**

In `scripts/ecs/systems/combat_system.gd`, delete the entire `_add_momentum` function (lines ~205-224) and replace its two call sites. Both `_start_light_attack` and `_start_heavy_attack` contain the line `_add_momentum(entity_id, "attack")`. Replace each with:

```gdscript
	# Add momentum (routed through MomentumSystem so HUD/threshold signals fire)
	var momentum_system = ecs.get_system(MomentumSystem)
	if momentum_system:
		var momentum = get_component(entity_id, "momentum")
		if momentum:
			momentum_system.add_momentum(entity_id, momentum.gain_attack)
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_momentum_routing.gd
```
Expected: PASS (both assertions).

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/combat_system.gd test/unit/test_momentum_routing.gd
git commit -m "fix: route combat momentum through MomentumSystem so HUD updates"
```

---

## Task 3: Convert dodge and dash to velocity-only (no direct position writes)

**Why:** `_apply_dodge_movement` (movement_system.gd:90) and `_apply_dash_movement` (line 100) do `pos.x += …` and write `node.position` directly. Under the incoming `PhysicsSyncSystem` (Task 5) those writes fight `move_and_slide`. Make them set `vel` only; PhysicsSync integrates.

**Files:**
- Test: `test/unit/test_movement_velocity.gd`
- Modify: `scripts/ecs/systems/movement_system.gd`

- [ ] **Step 1: Write the failing test**

Create `test/unit/test_movement_velocity.gd`:

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _entity_with_dodge(ecs):
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "collision", Components.collision())
	ecs.add_component(e, "platformer", Components.platformer())
	ecs.add_component(e, "dodge", Components.dodge())
	ecs.add_component(e, "input_state", Components.input_state())
	return e

func test_dodge_sets_velocity_not_position():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var move_sys = MovementSystem.new()
	move_sys.ecs = ecs

	var e = _entity_with_dodge(ecs)
	var dodge = ecs.get_component(e, "dodge")
	var input = ecs.get_component(e, "input_state")
	dodge.is_dodging = true
	input.facing = 1
	var pos = ecs.get_component(e, "position")
	var start_x = pos.x

	move_sys.process(0.016)

	var vel = ecs.get_component(e, "velocity")
	assert_almost_eq(vel.x, dodge.dodge_speed, 0.01,
		"dodge sets horizontal velocity to dodge_speed")
	assert_eq(pos.x, start_x,
		"dodge must NOT integrate position directly (PhysicsSync owns that)")
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_movement_velocity.gd
```
Expected: FAIL — `pos.x` changed (dodge integrates position today).

- [ ] **Step 3: Rewrite dodge/dash to set velocity only**

In `scripts/ecs/systems/movement_system.gd`, replace `_apply_dodge_movement` and `_apply_dash_movement` with velocity-only versions (remove the `pos.x +=`, `vel.y = 0` stays, remove the `_sync_node_position` call):

```gdscript
func _apply_dodge_movement(entity_id: int, _pos: Dictionary, vel: Dictionary, dodge: Dictionary, _delta: float) -> void:
	var input = get_component(entity_id, "input_state")
	var direction = input.facing if input else 1
	vel.x = direction * dodge.dodge_speed
	vel.y = 0  # No vertical movement during dodge


func _apply_dash_movement(entity_id: int, _pos: Dictionary, vel: Dictionary, platformer: Dictionary, _input: Dictionary, _delta: float) -> void:
	var input = get_component(entity_id, "input_state")
	var direction = input.facing if input else 1
	vel.x = direction * platformer.dash_speed
	vel.y = 0  # No vertical movement during dash
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_movement_velocity.gd
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/movement_system.gd test/unit/test_movement_velocity.gd
git commit -m "refactor: dodge/dash set velocity, not position"
```

---

## Task 4: Make MovementSystem velocity-only for physics bodies (stop integrating/syncing position)

**Why:** MovementSystem currently does `pos.x += vel.x * delta` and `_sync_node_position(...)` (movement_system.gd:47-51). Once `PhysicsSyncSystem` (Task 5) owns `move_and_slide` + position read-back, MovementSystem must NOT also move the node, or they double-apply. MovementSystem keeps computing velocity (input accel, gravity, friction) and updating `previous_x/y`.

**Files:**
- Modify: `scripts/ecs/systems/movement_system.gd`

- [ ] **Step 1: Remove direct position integration and node sync from the main loop**

In `process()`, delete these two lines near the end of the per-entity loop (movement_system.gd:46-51):

```gdscript
		# Update position
		pos.x += vel.x * delta
		pos.y += vel.y * delta

		# Sync with Godot node if present
		_sync_node_position(entity_id, pos)
```

Leave the `pos.previous_x/y` assignment at the top of the loop intact (PhysicsSync writes the new `pos` from the node).

- [ ] **Step 2: Delete the now-unused `_sync_node_position` helper**

Remove the `_sync_node_position` function (movement_system.gd:130-133). (Tasks 3 and 4 removed all its callers.)

- [ ] **Step 3: Verify the project still parses**

Run:
```bash
godot --headless --check-only --path .
```
Expected: no parse errors. (Behavior is exercised in Task 5's integration test.)

- [ ] **Step 4: Commit**

```bash
git add scripts/ecs/systems/movement_system.gd
git commit -m "refactor: MovementSystem computes velocity only; PhysicsSync owns position"
```

---

## Task 5: Create PhysicsSyncSystem (single physics authority)

**Why (spec §9.1, G0/F1):** physics must run inside the ECS loop in a deterministic order, not in a separate per-node `_physics_process`. PhysicsSync iterates entities whose node is a `CharacterBody2D` and which are **not** `tag_echo`, pushes the `velocity` component onto the node, calls `move_and_slide()`, then reads `node.position` + `is_on_floor/wall/ceiling` back into `position`/`collision`.

**Files:**
- Create: `scripts/ecs/systems/physics_sync_system.gd`
- Test: `test/integration/test_physics_sync.gd`

- [ ] **Step 1: Write the failing integration test**

Create `test/integration/test_physics_sync.gd`. It drops a `CharacterBody2D` above a `StaticBody2D` floor, runs PhysicsSync over a few physics frames with downward velocity, and asserts the entity lands (`collision.on_ground == true`) and `position` is synced from the node.

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _make_floor(parent: Node) -> void:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 200)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1000, 40)
	cs.shape = shape
	floor_body.add_child(cs)
	parent.add_child(floor_body)

func _make_body(parent: Node) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	body.position = Vector2(0, 0)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body

func test_body_falls_and_lands_with_collision_readback():
	var root := Node2D.new()
	add_child_autofree(root)
	_make_floor(root)
	var body := _make_body(root)

	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var phys := PhysicsSyncSystem.new()
	phys.ecs = ecs

	var e = ecs.create_entity_with_node(body)
	ecs.add_component(e, "position", Components.position(0, 0))
	var vel = Components.velocity()
	vel.y = 400.0  # falling
	ecs.add_component(e, "velocity", vel)
	ecs.add_component(e, "collision", Components.collision(32, 64))

	# Simulate several physics frames
	for i in range(30):
		var v = ecs.get_component(e, "velocity")
		v.y += 1800.0 * (1.0 / 60.0)  # gravity, mimicking MovementSystem
		phys.process(1.0 / 60.0)
		await get_tree().physics_frame

	var collision = ecs.get_component(e, "collision")
	var pos = ecs.get_component(e, "position")
	assert_true(collision.on_ground, "body should land on the floor")
	assert_almost_eq(pos.y, body.position.y, 0.01, "position component synced from node")
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_physics_sync.gd
```
Expected: FAIL — `PhysicsSyncSystem` does not exist (parse/class error).

- [ ] **Step 3: Implement PhysicsSyncSystem**

Create `scripts/ecs/systems/physics_sync_system.gd`:

```gdscript
class_name PhysicsSyncSystem
extends ECSSystem
## Single physics authority. For each entity whose node is a CharacterBody2D
## (and is NOT a kinematic echo), pushes the velocity component onto the node,
## runs move_and_slide(), then reads position + collision flags back into ECS.


func _get_required_components() -> Array[String]:
	return ["velocity", "position", "collision"]


func process(_delta: float) -> void:
	for entity_id in get_entities():
		# Echoes are kinematic replays — they set position directly, skip physics.
		if has_component(entity_id, "tag_echo"):
			continue

		var node = get_node(entity_id)
		if not (node is CharacterBody2D):
			continue

		var vel = get_component(entity_id, "velocity")
		var pos = get_component(entity_id, "position")
		var collision = get_component(entity_id, "collision")

		# Push ECS velocity onto the body and integrate via Godot physics.
		node.velocity = Vector2(vel.x, vel.y)
		node.move_and_slide()

		# Read results back into ECS components.
		pos.x = node.position.x
		pos.y = node.position.y
		vel.x = node.velocity.x
		vel.y = node.velocity.y

		collision.on_ground = node.is_on_floor()
		collision.on_wall = node.is_on_wall()
		collision.on_ceiling = node.is_on_ceiling()
		if collision.on_wall:
			collision.wall_direction = -int(sign(node.get_wall_normal().x))
		else:
			collision.wall_direction = 0
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_physics_sync.gd
```
Expected: PASS — body lands, `on_ground` true, position synced.

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/physics_sync_system.gd test/integration/test_physics_sync.gd
git commit -m "feat: PhysicsSyncSystem owns move_and_slide and collision read-back"
```

---

## Task 6: Add the `dash` input action and dash trigger

**Why:** there is no `dash` input action (project.godot only has move/jump/crouch/attack_light/attack_heavy/dodge/echo_activate/pause), no `dash_pressed` input field, and nothing ever sets `platformer.is_dashing = true`.

**Files:**
- Modify: `project.godot`, `scripts/ecs/components.gd`, `scripts/ecs/systems/input_system.gd`, `scripts/ecs/systems/movement_system.gd`

- [ ] **Step 1: Add the `dash` input action (keyboard + gamepad)**

In `project.godot`, under `[input]`, add (keyboard Shift = physical_keycode 4194325; gamepad button 10 = right shoulder / R1 area — adjust later in tuning):

```
dash={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194325,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"button_index":10,"pressure":0.0,"pressed":true,"script":null)
]
}
```

- [ ] **Step 2: Add `dash_pressed` to the input_state component**

In `scripts/ecs/components.gd`, in `input_state()`, add the field after `dodge_pressed`:

```gdscript
		"dodge_pressed": false,
		"dash_pressed": false,
		"echo_pressed": false,
```

- [ ] **Step 3: Read the dash action in InputSystem**

In `scripts/ecs/systems/input_system.gd`, in `_process_ability_input`, add:

```gdscript
func _process_ability_input(input: Dictionary) -> void:
	# Echo activation
	input.echo_pressed = Input.is_action_just_pressed("echo_activate")
	# Dash
	input.dash_pressed = Input.is_action_just_pressed("dash")
```

- [ ] **Step 4: Add a dash trigger in MovementSystem**

In `scripts/ecs/systems/movement_system.gd` `process()`, immediately before the `if platformer and platformer.is_dashing:` check, add a trigger that starts a dash when the input fires, dash is unlocked, and it's off cooldown:

```gdscript
		# Dash trigger
		if platformer and input and input.dash_pressed and platformer.has_dash \
				and not platformer.is_dashing and platformer.dash_cooldown <= 0:
			platformer.is_dashing = true
			platformer.dash_duration = 0.2
			platformer.dash_cooldown = 0.6
```

- [ ] **Step 5: Verify it parses and existing tests still pass**

Run:
```bash
godot --headless --check-only --path .
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```
Expected: no parse errors; all prior tests pass.

- [ ] **Step 6: Commit**

```bash
git add project.godot scripts/ecs/components.gd scripts/ecs/systems/input_system.gd scripts/ecs/systems/movement_system.gd
git commit -m "feat: add dash input action and dash trigger"
```

---

## Task 7: Build SpriteFrames from FreeKnight strips

**Why:** the FreeKnight art is horizontal sprite-strips (each PNG is N frames of 120×80 laid left-to-right). We need a helper that slices a strip into an `AtlasTexture` per frame and assembles a Godot `SpriteFrames` resource the AnimationSystem can play.

**Files:**
- Create: `scripts/render/sprite_frames_builder.gd`
- Test: `test/unit/test_sprite_frames_builder.gd`

- [ ] **Step 1: Write the failing test**

Create `test/unit/test_sprite_frames_builder.gd`. It builds frames from a real FreeKnight idle strip and asserts the clip exists with the expected frame count (`texture.width / 120`).

```gdscript
extends GutTest

const Builder = preload("res://scripts/render/sprite_frames_builder.gd")

func test_builds_clip_from_strip():
	var tex_path = "res://assets/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png"
	var tex: Texture2D = load(tex_path)
	assert_not_null(tex, "FreeKnight idle strip loads")

	var sf := SpriteFrames.new()
	Builder.add_strip(sf, "idle", tex, 120, 80, 10.0)

	assert_true(sf.has_animation("idle"), "clip 'idle' added")
	var expected_frames = int(tex.get_width() / 120)
	assert_eq(sf.get_frame_count("idle"), expected_frames,
		"frame count = strip width / frame width")
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_sprite_frames_builder.gd
```
Expected: FAIL — builder script does not exist.

- [ ] **Step 3: Implement the builder**

Create `scripts/render/sprite_frames_builder.gd`:

```gdscript
class_name SpriteFramesBuilder
extends RefCounted
## Builds Godot SpriteFrames from horizontal sprite-strip PNGs
## (each frame is frame_w x frame_h, laid left-to-right).


## Add one animation clip to `sf` by slicing `texture` into AtlasTextures.
static func add_strip(sf: SpriteFrames, clip: String, texture: Texture2D,
		frame_w: int, frame_h: int, fps: float, loop: bool = true) -> void:
	if texture == null:
		return
	var count := int(texture.get_width() / frame_w)
	if not sf.has_animation(clip):
		sf.add_animation(clip)
	sf.set_animation_speed(clip, fps)
	sf.set_animation_loop(clip, loop)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sf.add_frame(clip, atlas)
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_sprite_frames_builder.gd
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/render/sprite_frames_builder.gd test/unit/test_sprite_frames_builder.gd
git commit -m "feat: SpriteFramesBuilder slices FreeKnight strips into clips"
```

---

## Task 8: Create AnimationSystem (the renderer) + animation-state derivation

**Why (spec §9.1/§9.4):** nothing reads the `sprite` component today. AnimationSystem owns each entity's `AnimatedSprite2D` (creates it on first sight), derives the clip name from component state each frame, and applies `flip_h`/`modulate`. The derivation is a pure function we TDD; node creation/playback is integration-verified in Task 10.

**Files:**
- Create: `scripts/ecs/systems/animation_system.gd`
- Test: `test/unit/test_animation_state.gd`

- [ ] **Step 1: Write the failing test for the derivation function**

Create `test/unit/test_animation_state.gd`:

```gdscript
extends GutTest

const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_idle_when_still_on_ground():
	var anim = Anim.derive_clip(
		{"x": 0.0, "y": 0.0},                       # velocity
		{"on_ground": true},                         # collision
		{"is_attacking": false, "attack_type": "none", "combo_current": 0}, # weapon
		{"is_dodging": false},                       # dodge
		{"is_dashing": false})                       # platformer
	assert_eq(anim, "idle")

func test_run_when_moving_on_ground():
	var anim = Anim.derive_clip(
		{"x": 120.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(anim, "run")

func test_fall_when_airborne_descending():
	var anim = Anim.derive_clip(
		{"x": 0.0, "y": 200.0}, {"on_ground": false},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(anim, "fall")

func test_dash_overrides_run():
	var anim = Anim.derive_clip(
		{"x": 800.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": false, "attack_type": "none", "combo_current": 0},
		{"is_dodging": false}, {"is_dashing": true})
	assert_eq(anim, "dash")

func test_attack_clip_uses_combo_index():
	var anim = Anim.derive_clip(
		{"x": 0.0, "y": 0.0}, {"on_ground": true},
		{"is_attacking": true, "attack_type": "light", "combo_current": 3},
		{"is_dodging": false}, {"is_dashing": false})
	assert_eq(anim, "light_3")
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_animation_state.gd
```
Expected: FAIL — `animation_system.gd` / `derive_clip` does not exist.

- [ ] **Step 3: Implement AnimationSystem with `derive_clip` and node rendering**

Create `scripts/ecs/systems/animation_system.gd`:

```gdscript
class_name AnimationSystem
extends ECSSystem
## Renderer: owns each entity's AnimatedSprite2D and drives it from the
## `sprite` component. Derives the clip name from gameplay state each frame.

## Shared SpriteFrames for the player (built once, injected by main.gd).
var player_frames: SpriteFrames = null


func _get_required_components() -> Array[String]:
	return ["sprite", "position"]


## Pure derivation: highest-priority state wins.
## Order: dodge → dash → attack → airborne → run → idle.
static func derive_clip(vel: Dictionary, collision: Dictionary, weapon: Dictionary,
		dodge: Dictionary, platformer: Dictionary) -> String:
	if dodge and dodge.get("is_dodging", false):
		return "roll"
	if platformer and platformer.get("is_dashing", false):
		return "dash"
	if weapon and weapon.get("is_attacking", false):
		var atype: String = weapon.get("attack_type", "none")
		if atype == "light":
			return "light_%d" % max(1, weapon.get("combo_current", 1))
		if atype.begins_with("heavy"):
			return atype
	if collision and not collision.get("on_ground", true):
		return "fall" if vel.get("y", 0.0) > 0.0 else "jump"
	if abs(vel.get("x", 0.0)) > 1.0:
		return "run"
	return "idle"


func process(_delta: float) -> void:
	for entity_id in get_entities():
		var node = get_node(entity_id)
		if not (node is Node2D):
			continue
		var sprite_comp = get_component(entity_id, "sprite")

		var anim_node := _ensure_anim_node(node)
		if anim_node == null:
			continue

		var vel = get_component(entity_id, "velocity")
		var collision = get_component(entity_id, "collision")
		var weapon = get_component(entity_id, "weapon")
		var dodge = get_component(entity_id, "dodge")
		var platformer = get_component(entity_id, "platformer")
		var input = get_component(entity_id, "input_state")

		var clip := derive_clip(
			vel if vel else {}, collision if collision else {},
			weapon if weapon else {}, dodge if dodge else {},
			platformer if platformer else {})
		sprite_comp.animation = clip

		if anim_node.sprite_frames and anim_node.sprite_frames.has_animation(clip):
			if anim_node.animation != clip:
				anim_node.play(clip)
		# Facing
		if input:
			anim_node.flip_h = input.facing < 0
		anim_node.modulate = sprite_comp.modulate


## Create (once) the AnimatedSprite2D child for an entity node.
func _ensure_anim_node(node: Node) -> AnimatedSprite2D:
	var existing := node.get_node_or_null("Anim")
	if existing is AnimatedSprite2D:
		return existing
	if player_frames == null:
		return null
	var anim := AnimatedSprite2D.new()
	anim.name = "Anim"
	anim.sprite_frames = player_frames
	anim.play("idle")
	node.add_child(anim)
	return anim
```

- [ ] **Step 4: Run the test to verify it passes**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_animation_state.gd
```
Expected: PASS (all five cases).

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/animation_system.gd test/unit/test_animation_state.gd
git commit -m "feat: AnimationSystem renders entities and derives clips from state"
```

---

## Task 9: Make pause actually pause

**Why:** `ECS` autoload is `PROCESS_MODE_ALWAYS` (ecs.gd:32), so `get_tree().paused = true` (GameState.pause_game, game_state.gd:265) does not stop the system loop. Set ECS to pausable, and wire the `pause` input action to GameState.

**Files:**
- Modify: `scripts/ecs/ecs.gd`, `scripts/main/main.gd`

- [ ] **Step 1: Make ECS pausable**

In `scripts/ecs/ecs.gd` `_ready()`, change:

```gdscript
	process_mode = Node.PROCESS_MODE_ALWAYS
```
to:
```gdscript
	process_mode = Node.PROCESS_MODE_PAUSABLE
```

- [ ] **Step 2: Add a pause handler in main.gd**

In `scripts/main/main.gd`, add an `_unhandled_input` handler that toggles pause on the `pause` action:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.current_state == GameState.State.PLAYING:
			GameState.pause_game()
		elif GameState.current_state == GameState.State.PAUSED:
			GameState.resume_game()
```

- [ ] **Step 3: Manual verification (smoke test)**

Run the project:
```bash
godot --path .
```
Press the pause key (Escape). Expected: the player and any motion freeze (ECS no longer processes while paused). Press again: resumes. (No automated test — pause is a tree-level integration.)

- [ ] **Step 4: Commit**

```bash
git add scripts/ecs/ecs.gd scripts/main/main.gd
git commit -m "fix: pause freezes the ECS loop and is toggled by the pause action"
```

---

## Task 10: Wire it together in main.gd — register systems, real sprite, dash granted, tilemap floor

**Why:** `main.gd` must register the new systems in the correct order, build the player's SpriteFrames and inject them into AnimationSystem, stop creating the placeholder `Sprite2D`, grant dash for the slice, and give the player a real floor to stand on. This is the integration that makes P0 visible.

**Files:**
- Modify: `scripts/main/main.gd`

- [ ] **Step 1: Register the new systems in the target order**

In `_initialize_ecs()` (main.gd:23), replace the registration block so order is:
Input → AI → CombatInput(existing CombatSystem for now) → Jump → Dodge → Movement → **PhysicsSync** → Momentum → Echo → Health → **Animation**. (Parry/Wall/Projectile arrive in later phases; CombatSystem stays single for P0.)

```gdscript
func _initialize_ecs() -> void:
	ECS.register_system(InputSystem.new())
	ECS.register_system(AISystem.new())
	ECS.register_system(JumpSystem.new())
	ECS.register_system(DodgeSystem.new())
	ECS.register_system(MovementSystem.new())
	ECS.register_system(PhysicsSyncSystem.new())
	ECS.register_system(CombatSystem.new())
	ECS.register_system(MomentumSystem.new())
	ECS.register_system(EchoSystem.new())
	ECS.register_system(HealthSystem.new())

	var anim := AnimationSystem.new()
	anim.player_frames = _build_player_frames()
	ECS.register_system(anim)

	print("ECS initialized with %d systems" % ECS.get_debug_info().system_count)
```

- [ ] **Step 2: Build the player's SpriteFrames from FreeKnight**

Add to `main.gd` a helper that assembles the player clips with `SpriteFramesBuilder`. (Uses the Colour1/NoOutline 120×80 strips; missing clips like `parry` fall back later.)

```gdscript
const FK := "res://assets/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/"

func _build_player_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	# Remove the auto-created "default" clip to keep things clean.
	if sf.has_animation("default"):
		sf.remove_animation("default")
	SpriteFramesBuilder.add_strip(sf, "idle", load(FK + "_Idle.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "run", load(FK + "_Run.png"), 120, 80, 14.0)
	SpriteFramesBuilder.add_strip(sf, "jump", load(FK + "_Jump.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "fall", load(FK + "_Fall.png"), 120, 80, 10.0, false)
	SpriteFramesBuilder.add_strip(sf, "dash", load(FK + "_Dash.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "roll", load(FK + "_Roll.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_1", load(FK + "_Attack.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_2", load(FK + "_Attack2.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_3", load(FK + "_AttackCombo.png"), 120, 80, 16.0, false)
	# light_4/5 reuse combo art until dedicated frames exist
	SpriteFramesBuilder.add_strip(sf, "light_4", load(FK + "_AttackCombo.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "light_5", load(FK + "_AttackCombo.png"), 120, 80, 16.0, false)
	SpriteFramesBuilder.add_strip(sf, "hit", load(FK + "_Hit.png"), 120, 80, 12.0, false)
	return sf
```

> Note: confirm these exact filenames exist (the import commit listed `_Attack.png`, `_Attack2.png`, `_AttackCombo.png`, `_Idle.png`, `_Run.png`, `_Jump.png`, `_Fall.png`, `_Dash.png`, `_Roll.png`, `_Hit.png`). If `_AttackCombo.png` is absent in Colour1, use `_Attack2.png` for light_3-5.

- [ ] **Step 3: Stop creating the placeholder Sprite2D; scale the body to the art**

In `_spawn_player` (main.gd:78), delete the Sprite2D placeholder block (main.gd:93-101). AnimationSystem now creates the visual `Anim` child. Keep the `CharacterBody2D` + `CollisionShape2D` (32×64). The FreeKnight frame is 120×80; the `AnimatedSprite2D` will render larger than the 32×64 hurtbox — that's intentional (collision box = gameplay hurtbox of record, spec §9.5). Add `player_node.add_to_group("player")` for convenience.

- [ ] **Step 4: Grant dash for the slice**

In `_spawn_player`, after applying unlocked abilities (main.gd:121-124), force dash on for the slice:

```gdscript
	platformer.has_dash = true  # Slice grants dash (spec §10 P0)
```

- [ ] **Step 5: Replace the placeholder test scene with a real tilemap floor**

For P0, a single wide floor is enough to validate movement (the full handcrafted level is P4). Keep `_create_test_platforms()` for now but widen the floor so the player can run/dash. No code change required if the existing floor (1920×32 at y=600) suffices; confirm the player spawns above it (`Vector2(200, 400)`).

- [ ] **Step 6: Run the full test suite**

Run:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```
Expected: all unit + integration tests pass.

- [ ] **Step 7: Smoke-test the running game (P0 acceptance)**

Run:
```bash
godot --path .
```
Verify by hand (spec §9.5 / §10 P0 DoD):
- Player is an **animated FreeKnight sprite** (idle), standing on the floor (not falling through, not floating).
- **Left/right** runs (run animation, correct facing/flip).
- **Jump** (Space) leaves the ground and lands.
- **Dash** (Shift) bursts horizontally with the dash animation.
- **Dodge** rolls with i-frames.
- Attacking (J) shows a light attack clip and the **momentum bar in the HUD rises**.
- **Pause** (Esc) freezes everything; unpause resumes.
- The FPS overlay (enable via `Engine.get_frames_per_second()` debug or the editor monitor) reads ~60.

- [ ] **Step 8: Commit**

```bash
git add scripts/main/main.gd
git commit -m "feat: wire P0 foundation — systems, animated player, dash, pause"
```

---

## Task 11: Delete the now-dead player_controller.gd

**Why:** `PhysicsSyncSystem` replaces the per-node controller approach; `player_controller.gd` was never attached and is now superseded.

**Files:**
- Delete: `scripts/entities/player_controller.gd` (+ `.uid`)

- [ ] **Step 1: Confirm nothing references it**

Run:
```bash
grep -rn "player_controller" scripts scenes
```
Expected: no references (other than the file itself).

- [ ] **Step 2: Delete the file**

```bash
git rm scripts/entities/player_controller.gd scripts/entities/player_controller.gd.uid
```

- [ ] **Step 3: Verify the project parses and tests pass**

Run:
```bash
godot --headless --check-only --path .
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```
Expected: clean parse, all tests pass.

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove dead player_controller.gd (replaced by PhysicsSyncSystem)"
```

---

## P0 Definition of Done (acceptance)

All of the following hold:
- [ ] GUT runs headless; all unit + integration tests pass.
- [ ] Player is an animated FreeKnight sprite that stands on a tilemap floor.
- [ ] Run, jump, dash, dodge all work and read clearly via animation.
- [ ] Attacking raises the momentum bar in the HUD (signal path fixed).
- [ ] Pause (Esc) genuinely freezes gameplay; unpause resumes.
- [ ] ~60 FPS in normal play.
- [ ] No `player_controller.gd`; `MovementSystem` no longer writes node positions; `PhysicsSyncSystem` is the sole physics authority.

When this is signed off by a quick playtest, proceed to the **P1 plan** (two-way combat core): a separate `docs/superpowers/plans/2026-06-04-vertical-slice-p1-combat.md`, written with the same TDD structure, building on these foundations.
```
