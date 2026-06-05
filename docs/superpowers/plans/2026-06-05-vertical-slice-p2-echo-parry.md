# Wolf-Zero Vertical Slice — P2: Echo Utility + Parry + Stagger — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make the two signature defensive/offensive systems real: the Holographic Echo becomes **visible** and fights **enemies** (not the player) and draws their aggro; and **Parry** lets the player negate an incoming attack, reflect damage, and **stagger** the attacker.

**Architecture:** Build on P0/P1. The Echo gets a render node + correct combat team + facing + aggro. A new `ParrySystem` manages a short parry window (runs after Input, before Combat); the actual negate/reflect/stagger happens inside `CombatSystem._apply_damage` when the target is parrying (Combat already runs late, after all hitbox flags are set — so no separate resolution pass is needed yet; the formal CombatInput/HitboxResolution split is deferred to P3 when ProjectileSystem adds a second resolver). Enemies gain a `stagger` AI state.

**Tech Stack:** Godot 4.6, GDScript, GUT. Godot binary: `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH). Tests: `... --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/<path>.gd` (note `res://`); suite `-gconfig=res://.gutconfig.json`. New `class_name` → run `... --headless --import` once before tests compile.

**Spec:** `docs/superpowers/specs/2026-06-04-vertical-slice-design.md` (phase **P2**; G5 echo; G4 parry/stagger; §9.4 stagger).

**Branch:** `feat/vertical-slice` (continues from P1; HEAD ~`50fb957`).

---

## Verified current state

- `CombatSystem._process_hitboxes` (combat_system.gd:136): `is_player = has_component(attacker, "tag_player")`; `target_tag = "tag_enemy" if is_player else "tag_player"`. The echo carries `tag_echo` (not `tag_player`) → `is_player=false` → **echo attacks the player**. Facing comes from `resolve_facing(input_state, velocity, enemy)`; the echo has none of those except velocity.
- `CombatSystem._apply_damage` (combat_system.gd:193): applies damage + knockback + VFX, emits `entity_damaged`/`entity_died`, clears `weapon.hitbox_active`. No parry handling.
- `EchoSystem._spawn_echo` (echo_system.gd:104): creates the echo via `ecs.create_entity()` — **nodeless**, so AnimationSystem (needs a Node2D) never renders it and `_process_playback`'s `get_node()` sync is a no-op. The echo is **invisible**. Playback sets `vel` from the recorded frame and `sprite.modulate` to translucent cyan.
- `AISystem` (ai_system.gd): states idle/patrol/chase/telegraph/attack/(now from P1) attack opens a hitbox. `_process_patrol` already retargets to a `tag_echo` entity within range; chase does not. No `stagger` state.
- Components (`components.gd`): `input_state` has `dash_pressed` (P0); `ai()` has no `stagger_timer`; no `parry()` factory. `enemy()` has `facing` (P1).
- Input map (`project.godot`): move/jump/crouch/attack_light/attack_heavy/dodge/dash/echo_activate/pause. No `parry`.

---

## File structure (P2)

| File | Responsibility | Tasks |
|------|----------------|-------|
| `scripts/ecs/systems/combat_system.gd` | echo team; parry negate/reflect/stagger | T1, T4 |
| `scripts/ecs/systems/echo_system.gd` | echo gets a node; facing nudge | T1 |
| `scripts/ecs/systems/ai_system.gd` | echo aggro in chase; stagger state | T2, T4 |
| `scripts/ecs/components.gd` | `parry()`; `ai.stagger_timer`; `input_state.parry_pressed` | T3, T4 |
| `scripts/ecs/systems/parry_system.gd` | parry window manager | T3 (create) |
| `project.godot` | `parry` input action | T3 |
| `scripts/ecs/systems/input_system.gd` | read `parry` action | T3 |
| `scripts/main/main.gd` | register ParrySystem; player parry component; connect parried | T5 |

---

## Task 1: Echo fights enemies, is visible, and faces correctly

**Why:** G5 — the echo attacks the player (wrong team), has no visual, and defaults facing right.

**Files:** Modify `scripts/ecs/systems/combat_system.gd`, `scripts/ecs/systems/echo_system.gd`; Test `test/integration/test_echo_combat.gd`.

- [ ] **Step 1: Write the failing test** `test/integration/test_echo_combat.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_echo_damages_enemy_not_player():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	# Player at x=0
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "input_state", Components.input_state())
	ecs.add_component(p, "tag_player", Components.tag_player())

	# Enemy at x=40
	var en = ecs.create_entity()
	ecs.add_component(en, "position", Components.position(40, 0))
	ecs.add_component(en, "velocity", Components.velocity())
	ecs.add_component(en, "collision", Components.collision(32, 64))
	ecs.add_component(en, "health", Components.health(50))
	ecs.add_component(en, "tag_enemy", Components.tag_enemy())

	# Echo at x=20, mid-attack, facing right (velocity > 0)
	var echo = ecs.create_entity()
	ecs.add_component(echo, "position", Components.position(20, 0))
	var v = Components.velocity(); v.x = 50.0
	ecs.add_component(echo, "velocity", v)
	ecs.add_component(echo, "tag_echo", Components.tag_echo())
	var w = Components.weapon(15, 0.25); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "light"
	ecs.add_component(echo, "weapon", w)

	var enemy_hp = ecs.get_component(en, "health").current
	var player_hp = ecs.get_component(p, "health").current
	combat.process(0.016)

	assert_lt(ecs.get_component(en, "health").current, enemy_hp, "echo damages the enemy")
	assert_eq(ecs.get_component(p, "health").current, player_hp, "echo does NOT damage the player")
```

- [ ] **Step 2: Run it — expect FAIL** (echo currently hits the player, not the enemy).

- [ ] **Step 3: Treat the echo as player-team in `_process_hitboxes`**

In `combat_system.gd._process_hitboxes`, replace:

```gdscript
		var is_player = has_component(attacker_id, "tag_player")

		# Check against potential targets
		var target_tag = "tag_enemy" if is_player else "tag_player"
```
with:
```gdscript
		var is_player_team = has_component(attacker_id, "tag_player") or has_component(attacker_id, "tag_echo")

		# Check against potential targets
		var target_tag = "tag_enemy" if is_player_team else "tag_player"
```

- [ ] **Step 4: Run the test — expect PASS.**

- [ ] **Step 5: Make the echo visible + facing-correct in `echo_system.gd`**

In `_spawn_echo`, create the echo WITH a node so AnimationSystem renders it. Replace `var echo_id = ecs.create_entity()` with:

```gdscript
	# Create a render node so AnimationSystem draws the echo (translucent cyan).
	var echo_node := Node2D.new()
	echo_node.name = "Echo"
	echo_node.position = Vector2(pos.x, pos.y)
	var container = ecs.get_entity_node(owner_id)
	if container and container.get_parent():
		container.get_parent().add_child(echo_node)
	var echo_id = ecs.create_entity_with_node(echo_node)
```

The echo already gets a `sprite` component (frame_set defaults to "player"); playback sets `sprite.modulate` to translucent cyan, which AnimationSystem applies. In `_process_playback`, after `vel.x = frame.velocity.x`, nudge the velocity sign so `resolve_facing` reflects the recorded facing even when the recorded velocity is ~0:

```gdscript
			vel.x = frame.velocity.x
			vel.y = frame.velocity.y
			if abs(vel.x) < 1.0:
				vel.x = float(frame.facing) * 50.0  # facing hint for combat (echo doesn't move via velocity)
```

- [ ] **Step 6: Run full suite (all pass) + 3s headless run (no errors).**

- [ ] **Step 7: Commit**

```bash
git add scripts/ecs/systems/combat_system.gd scripts/ecs/systems/echo_system.gd test/integration/test_echo_combat.gd test/integration/test_echo_combat.gd.uid
git commit -m "feat: echo fights enemies, renders, and faces correctly"
```

---

## Task 2: Echo draws enemy aggro while chasing

**Why:** G5 — the echo is a decoy; enemies should switch to a nearby echo even mid-chase.

**Files:** Modify `scripts/ecs/systems/ai_system.gd`; Test `test/integration/test_echo_aggro.gd`.

- [ ] **Step 1: Write the failing test** `test/integration/test_echo_aggro.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_chasing_enemy_retargets_to_nearby_echo():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var ai := AISystem.new(); ecs.register_system(ai)

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(500, 0))
	ecs.add_component(p, "tag_player", Components.tag_player())

	var en = ecs.create_entity()
	ecs.add_component(en, "position", Components.position(0, 0))
	ecs.add_component(en, "velocity", Components.velocity())
	var ai_c = Components.ai("chase"); ai_c.state = "chase"; ai_c.target_entity = p
	ecs.add_component(en, "ai", ai_c)
	ecs.add_component(en, "tag_enemy", Components.tag_enemy())

	# Echo right next to the enemy (within detection range), much closer than the player
	var echo = ecs.create_entity()
	ecs.add_component(echo, "position", Components.position(50, 0))
	ecs.add_component(echo, "tag_echo", Components.tag_echo())

	ai.process(0.016)

	assert_eq(ecs.get_component(en, "ai").target_entity, echo,
		"a chasing enemy retargets to a much closer echo")
```

- [ ] **Step 2: Run — expect FAIL** (chase never checks for echoes).

- [ ] **Step 3: Add echo retargeting at the top of `_process_chase`**

In `ai_system.gd._process_chase`, immediately after the function's first line, add a check that switches the target to a closer in-range echo:

```gdscript
	# Aggro: a nearby echo decoy steals the enemy's attention.
	if ai.can_be_distracted:
		var echoes := ecs.get_entities_with("tag_echo")
		for echo_id in echoes:
			var echo_pos = ecs.get_component(echo_id, "position")
			if echo_pos == null:
				continue
			var d_echo = Vector2(echo_pos.x - pos.x, echo_pos.y - pos.y).length()
			if d_echo <= ai.detection_range and ai.target_entity != echo_id:
				ai.target_entity = echo_id
				break
```

(`pos` is the enemy position already passed into `_process_chase`; confirm the parameter name and reuse it.)

- [ ] **Step 4: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/ai_system.gd test/integration/test_echo_aggro.gd test/integration/test_echo_aggro.gd.uid
git commit -m "feat: echo draws enemy aggro while chasing"
```

---

## Task 3: Parry window (input + component + ParrySystem)

**Why:** G4 — parry needs an input action, a window-state component, and a system that opens the window on press (off cooldown).

**Files:** Modify `project.godot`, `scripts/ecs/components.gd`, `scripts/ecs/systems/input_system.gd`; Create `scripts/ecs/systems/parry_system.gd`; Test `test/unit/test_parry_window.gd`.

- [ ] **Step 1: Add the `parry` input action to `project.godot`** under `[input]` (keyboard L = physical_keycode 76; gamepad button 4 = LB/L1). Mirror the exact formatting of an existing action (e.g. `dash`), changing only the events:

```
parry={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":76,"key_label":0,"unicode":108,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":4,"pressure":0.0,"pressed":true,"script":null)
]
}
```

- [ ] **Step 2: Add `parry_pressed` to `input_state()` and a `parry()` factory** in `components.gd`.

In `input_state()`, after `dash_pressed`:
```gdscript
		"dash_pressed": false,
		"parry_pressed": false,
		"echo_pressed": false,
```
Add a new factory (near `dodge()`):
```gdscript
## Parry window state
static func parry() -> Dictionary:
	return {
		"is_parrying": false,
		"parry_timer": 0.0,
		"parry_window": 0.2,    # seconds the parry is active after pressing
		"cooldown": 0.0,
		"cooldown_duration": 0.5,
	}
```

- [ ] **Step 3: Read the `parry` action in `input_system.gd`** `_process_ability_input`:
```gdscript
	# Dash
	input.dash_pressed = Input.is_action_just_pressed("dash")
	# Parry
	input.parry_pressed = Input.is_action_just_pressed("parry")
```

- [ ] **Step 4: Write the failing test** `test/unit/test_parry_window.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _entity(ecs):
	var e = ecs.create_entity()
	ecs.add_component(e, "parry", Components.parry())
	ecs.add_component(e, "input_state", Components.input_state())
	return e

func test_press_opens_window_then_closes():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var sys := ParrySystem.new(); sys.ecs = ecs
	var e = _entity(ecs)
	ecs.get_component(e, "input_state").parry_pressed = true

	sys.process(0.01)
	assert_true(ecs.get_component(e, "parry").is_parrying, "window opens on press")

	# Let the window elapse
	ecs.get_component(e, "input_state").parry_pressed = false
	sys.process(0.5)
	assert_false(ecs.get_component(e, "parry").is_parrying, "window closes after parry_window")

func test_cannot_reparry_during_cooldown():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var sys := ParrySystem.new(); sys.ecs = ecs
	var e = _entity(ecs)
	var input = ecs.get_component(e, "input_state")

	input.parry_pressed = true
	sys.process(0.01)            # opens the window (cooldown now 0.5)
	input.parry_pressed = false
	sys.process(0.3)             # window (0.2s) elapses; cooldown still ~0.19s
	assert_false(ecs.get_component(e, "parry").is_parrying, "window closed")
	input.parry_pressed = true
	sys.process(0.01)            # press again, but still on cooldown
	assert_false(ecs.get_component(e, "parry").is_parrying, "blocked by cooldown")
```

- [ ] **Step 5: Run — expect FAIL** (`ParrySystem` missing).

- [ ] **Step 6: Create `scripts/ecs/systems/parry_system.gd`**

```gdscript
class_name ParrySystem
extends ECSSystem
## Manages the parry window: opens it on press (off cooldown), counts it down.
## The actual negate/reflect/stagger happens in CombatSystem when a parrying
## target is hit.

signal parry_opened(entity_id: int)


func _get_required_components() -> Array[String]:
	return ["parry", "input_state"]


func process(delta: float) -> void:
	for entity_id in get_entities():
		var parry = get_component(entity_id, "parry")
		var input = get_component(entity_id, "input_state")

		if parry.cooldown > 0.0:
			parry.cooldown = max(0.0, parry.cooldown - delta)

		if parry.is_parrying:
			parry.parry_timer -= delta
			if parry.parry_timer <= 0.0:
				parry.is_parrying = false
		elif input.parry_pressed and parry.cooldown <= 0.0:
			parry.is_parrying = true
			parry.parry_timer = parry.parry_window
			parry.cooldown = parry.cooldown_duration
			parry_opened.emit(entity_id)
```

- [ ] **Step 7: Run the test — expect PASS** (run `--import` first for the new class). Full suite — all pass.

- [ ] **Step 8: Commit**

```bash
git add project.godot scripts/ecs/components.gd scripts/ecs/systems/input_system.gd scripts/ecs/systems/parry_system.gd scripts/ecs/systems/parry_system.gd.uid test/unit/test_parry_window.gd test/unit/test_parry_window.gd.uid
git commit -m "feat: parry input, component, and ParrySystem window manager"
```

---

## Task 4: Parry resolution (negate + reflect + stagger)

**Why:** G4 — when a parrying player is hit, negate the damage, reflect it to the attacker, and put the attacker into a `stagger` state.

**Files:** Modify `scripts/ecs/systems/combat_system.gd`, `scripts/ecs/systems/ai_system.gd`, `scripts/ecs/components.gd`; Test `test/integration/test_parry_resolution.gd`.

- [ ] **Step 1: Add `stagger_timer` to the `ai()` component** in `components.gd`:
```gdscript
		"attack_cooldown": 0.0,
		"stagger_timer": 0.0,
		"can_be_distracted": true,  # By Echo
```

- [ ] **Step 2: Add a `parried` signal to CombatSystem** (near the other signals at the top of `combat_system.gd`):
```gdscript
signal parried(defender_id: int, attacker_id: int)
```

- [ ] **Step 3: Write the failing integration test** `test/integration/test_parry_resolution.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_parry_negates_damage_reflects_and_staggers():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	# Player (parrying) at x=0
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "momentum", Components.momentum())
	ecs.add_component(p, "input_state", Components.input_state())
	var parry = Components.parry(); parry.is_parrying = true
	ecs.add_component(p, "parry", parry)
	ecs.add_component(p, "tag_player", Components.tag_player())

	# Enemy attacking the player from x=20
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(20, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "health", Components.health(50))
	var enemy = Components.enemy("ronin_drone"); enemy.facing = -1
	ecs.add_component(e, "enemy", enemy)
	var ai_c = Components.ai("chase"); ai_c.state = "attack"
	ecs.add_component(e, "ai", ai_c)
	var w = Components.weapon(12, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"
	ecs.add_component(e, "weapon", w)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())

	var player_hp = ecs.get_component(p, "health").current
	var enemy_hp = ecs.get_component(e, "health").current
	combat.process(0.016)

	assert_eq(ecs.get_component(p, "health").current, player_hp, "parry negates player damage")
	assert_lt(ecs.get_component(e, "health").current, enemy_hp, "parry reflects damage to attacker")
	assert_eq(ecs.get_component(e, "ai").state, "stagger", "attacker is staggered")
```

- [ ] **Step 4: Run — expect FAIL.**

- [ ] **Step 5: Add the parry branch at the TOP of `_apply_damage`** (before the damage math), in `combat_system.gd`:

```gdscript
func _apply_damage(attacker_id: int, target_id: int, weapon: Dictionary) -> void:
	# Parry: a parrying target negates the hit, reflects damage, and staggers the attacker.
	var target_parry = get_component(target_id, "parry")
	if target_parry and target_parry.is_parrying:
		target_parry.is_parrying = false
		var atk_health = get_component(attacker_id, "health")
		if atk_health:
			var reflect: int = max(weapon.damage, 10)
			atk_health.current -= reflect
			entity_damaged.emit(attacker_id, reflect, atk_health.current)
			if atk_health.current <= 0:
				entity_died.emit(attacker_id)
		var atk_ai = get_component(attacker_id, "ai")
		if atk_ai:
			atk_ai.state = "stagger"
			atk_ai.stagger_timer = 1.0
		var mom = get_component(target_id, "momentum")
		var mom_sys = ecs.get_system(MomentumSystem)
		if mom and mom_sys:
			mom_sys.add_momentum(target_id, mom.gain_parry)
		parried.emit(target_id, attacker_id)
		if VFXManager:
			VFXManager.screen_shake(0.5, 0.15)
		weapon.hitbox_active = false  # consume the attack
		return

	var target_health = get_component(target_id, "health")
	# ... existing damage logic continues unchanged ...
```

(Keep the rest of `_apply_damage` exactly as-is after this inserted block.)

- [ ] **Step 6: Add the `stagger` state to AISystem.** In `ai_system.gd` `process()`'s `match ai.state` block, add a case:
```gdscript
			"stagger":
				_process_stagger(entity_id, ai, delta)
```
And add the handler:
```gdscript
func _process_stagger(entity_id: int, ai: Dictionary, delta: float) -> void:
	var vel = get_component(entity_id, "velocity")
	if vel:
		vel.x = 0.0
	# Cancel any in-progress telegraph/attack.
	var enemy = get_component(entity_id, "enemy")
	if enemy:
		enemy.is_telegraphing = false
		enemy.telegraph_timer = 0.0
	var weapon = get_component(entity_id, "weapon")
	if weapon:
		weapon.hitbox_active = false
	ai.stagger_timer -= delta
	if ai.stagger_timer <= 0.0:
		ai.state = "chase"
```

- [ ] **Step 7: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 8: Commit**

```bash
git add scripts/ecs/systems/combat_system.gd scripts/ecs/systems/ai_system.gd scripts/ecs/components.gd test/integration/test_parry_resolution.gd test/integration/test_parry_resolution.gd.uid
git commit -m "feat: parry negates damage, reflects, and staggers the attacker"
```

---

## Task 5: Wire ParrySystem + give the player a parry component

**Why:** Register ParrySystem (after Input, before Combat) and add a `parry` component to the player so the system processes it.

**Files:** Modify `scripts/main/main.gd`.

- [ ] **Step 1: Register ParrySystem** in `_initialize_ecs`, immediately after `AISystem`:
```gdscript
	ECS.register_system(InputSystem.new())
	ECS.register_system(AISystem.new())
	ECS.register_system(ParrySystem.new())
	ECS.register_system(JumpSystem.new())
	...
```
(ParrySystem runs before MovementSystem/Combat, so the window is set before Combat resolves.)

- [ ] **Step 2: Add the parry component to the player** in `_spawn_player`, alongside the other components:
```gdscript
	ECS.add_component(entity_id, "dodge", Components.dodge())
	ECS.add_component(entity_id, "parry", Components.parry())
```

- [ ] **Step 3: (Optional feedback) connect `parried`** in `_connect_signals`, after the combat connections:
```gdscript
		combat_system.parried.connect(_on_parried)
```
And add:
```gdscript
func _on_parried(_defender_id: int, _attacker_id: int) -> void:
	print("Parry!")
```

- [ ] **Step 4: Verify** — `--import`, full suite green, 3s headless run clean (`ECS initialized with 12 systems` now, player + enemy spawn, no SCRIPT ERROR).

- [ ] **Step 5: Commit**

```bash
git add scripts/main/main.gd
git commit -m "feat: register ParrySystem and give the player a parry component"
```

---

## Task 6: Final P2 review + smoke test

- [ ] **Step 1: Full suite green.**
- [ ] **Step 2: Clean 3s headless run** (12 systems, no SCRIPT ERROR).
- [ ] **Step 3: Screenshot** — confirm the scene still renders; (the echo is only visible after activation, which needs input, so the static screenshot mainly confirms no regressions).
- [ ] **Step 4: Interactive playtest checklist (user):** press **Q** to deploy an Echo near the enemy — it appears translucent-cyan, the enemy turns to attack it, and the echo's replayed attacks hurt the enemy. Press **L** just as the enemy strikes — the hit is negated, the enemy takes reflected damage and freezes (stagger), and momentum jumps.

---

## P2 Definition of Done

- [ ] The Echo is **visible** (translucent cyan), damages **enemies** (not the player), faces correctly, and **draws enemy aggro**.
- [ ] **Parry** negates an incoming attack, **reflects** damage, and **staggers** the attacker; it has a window + cooldown and grants momentum.
- [ ] Enemies have a working **stagger** state.
- [ ] All tests pass; clean boot; ~60 FPS.

When signed off, proceed to the **P3 plan** (Cyber-Ashigaru + ProjectileSystem, Oni Mech + elite, wall-jump/wall-run) — where the CombatInput/HitboxResolution split is introduced for the projectile resolver.
