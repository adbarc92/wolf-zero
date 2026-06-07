# Wolf-Zero Vertical Slice — P1: Two-Way Combat Core — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the P0 sandbox into a real two-way fight: a Ronin Drone that has gravity, its own sprite, telegraphs, and actually damages the player; weighty hits (hitstop/shake already exist — add knockback); player death → respawn; and a win state when the drone dies.

**Architecture:** Build on the P0 ECS. Enemies become full physics bodies (gravity). Combat hit-resolution moves to run *after* the flag-setters (AI opens enemy hitboxes, Echo sets its own) by reordering CombatSystem after EchoSystem — the minimal correct fix for what exists; the full CombatInput/HitboxResolution split is deferred to P2 when ParrySystem also writes flags. AnimationSystem gains per-entity sprite sets so the enemy stops borrowing the player's frames.

**Tech Stack:** Godot 4.6, GDScript, GUT. Run Godot via `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH). Tests: `& "C:\Godot\Godot_v4.6.1-stable_win64.exe" --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/<f>.gd` (note `res://`); full suite `-gconfig=res://.gutconfig.json`. New `class_name` globals require `... --headless --import` once before tests compile.

**Spec:** `docs/superpowers/specs/2026-06-04-vertical-slice-design.md` (phase **P1** in §10; gaps G1, F2; §9.4 facing/stagger).

**Branch:** `feat/vertical-slice` (continues from P0; HEAD ~`2385bb9`).

---

## Key facts about the current code (verified)

- `CombatSystem` (`scripts/ecs/systems/combat_system.gd`): `_process_attack_inputs` starts attacks only for entities with `input_state`; `_process_hitboxes` iterates every entity with `weapon.hitbox_active`, computes `facing = attacker_input.facing if attacker_input else 1` (so input-less enemies default to facing **right**), picks targets by tag (`is_player → tag_enemy` else `tag_player`), and `_apply_damage` already calls `VFXManager.hit_effect(...)` (hitstop+shake+sparks) and emits `entity_damaged`/`entity_died`. main.gd connects to those CombatSystem signals.
- `AISystem` (`scripts/ecs/systems/ai_system.gd`): states idle/patrol/chase/telegraph/attack. `_process_attack` only sets `attack_cooldown` and returns to chase — it never opens a hitbox. Enemy has `enemy` component (`telegraph_time`, `is_telegraphing`, `has_armor`, `armor_hits`) and `ai` component, but **no `platformer` and no `input_state`**.
- `MovementSystem` applies gravity only `if platformer`; enemies have none → they don't fall.
- `AnimationSystem` (`scripts/ecs/systems/animation_system.gd`): uses a single `player_frames` for every entity; creates an `"Anim"` AnimatedSprite2D child.
- `VFXManager` (autoload): `hit_effect(pos, damage, is_critical)`, `hitstop`, `screen_shake`, sparks all working.
- `HealthSystem`: handles invincibility decay + `heal`/`is_alive`; death is decided in CombatSystem (`entity_died`).
- `main.gd`: `_spawn_player` (CharacterBody2D, grants dash), `_spawn_enemy` (CharacterBody2D + placeholder red Sprite2D + `sprite` component), `_create_test_platforms` (floor at y=600), `_on_entity_died` (player branch only prints; enemy branch awards XP and frees node), `_build_player_frames`.

---

## File structure (P1)

| File | Responsibility | Action |
|------|----------------|--------|
| `scripts/ecs/systems/movement_system.gd` | gravity for any physics body | Modify (Task 1) |
| `scripts/main/main.gd` | enemy gets platformer; per-set frames; reorder Combat; respawn; win | Modify (Tasks 1,2,3,6,7,8) |
| `scripts/ecs/systems/animation_system.gd` | per-entity sprite set | Modify (Task 2) |
| `scripts/ecs/components.gd` | `sprite.frame_set`; enemy `facing` + `attack_windup` fields | Modify (Tasks 2,4,5) |
| `scripts/ecs/systems/combat_system.gd` | facing from velocity; knockback on hit | Modify (Tasks 4,6) |
| `scripts/ecs/systems/ai_system.gd` | open enemy hitbox window on attack | Modify (Task 5) |
| `scripts/ui/win_label.gd` | simple victory banner | Create (Task 8) |
| `test/unit/test_enemy_gravity.gd` … | tests | Create per task |

---

## Task 1: Enemies have gravity (fall and land on the floor)

**Why:** F2 — enemies have no `platformer`, so MovementSystem applies no gravity and they float. Give the enemy a `platformer` so it falls onto the floor like the player.

**Files:** Modify `scripts/main/main.gd`; Test `test/unit/test_enemy_gravity.gd`.

- [ ] **Step 1: Write the failing test** `test/unit/test_enemy_gravity.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_gravity_applies_to_entity_with_platformer():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var move := MovementSystem.new()
	move.ecs = ecs

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(0, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "collision", Components.collision())  # on_ground defaults false
	ecs.add_component(e, "platformer", Components.platformer())

	move.process(1.0 / 60.0)

	var vel = ecs.get_component(e, "velocity")
	assert_gt(vel.y, 0.0, "an airborne entity with a platformer accrues downward velocity")
```

- [ ] **Step 2: Run it — expect PASS already** (MovementSystem already applies gravity when `platformer` exists). This test documents the contract; if it fails, stop and report.

Run: `& "C:\Godot\Godot_v4.6.1-stable_win64.exe" --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_enemy_gravity.gd`

- [ ] **Step 3: Give the enemy a `platformer` component in `main.gd._spawn_enemy`**

In `_spawn_enemy`, after the `velocity`/`collision` components are added and before the `ai` component, add:

```gdscript
	ECS.add_component(entity_id, "platformer", Components.platformer())
```

- [ ] **Step 4: Verify the enemy lands in a running game**

Run headless for ~3s and confirm no errors, enemy spawns:
`& "C:\Godot\Godot_v4.6.1-stable_win64.exe" --headless --path . --quit-after 180`
(Visual confirmation that it rests on the floor comes in the Task 9 screenshot.)

- [ ] **Step 5: Commit**

```bash
git add scripts/main/main.gd test/unit/test_enemy_gravity.gd test/unit/test_enemy_gravity.gd.uid
git commit -m "fix: enemies have gravity (add platformer component)"
```

---

## Task 2: Per-entity sprite sets (enemy stops borrowing player frames)

**Why:** AnimationSystem uses `player_frames` for every entity, so the enemy renders as the player knight (and still has a red placeholder Sprite2D under it). Give entities a `sprite.frame_set` key and let AnimationSystem pick from a dict of SpriteFrames; build an enemy set (FreeKnight Colour2) and remove the enemy placeholder Sprite2D.

**Files:** Modify `scripts/ecs/components.gd`, `scripts/ecs/systems/animation_system.gd`, `scripts/main/main.gd`; Test `test/unit/test_frame_set.gd`.

- [ ] **Step 1: Add `frame_set` to the sprite component** in `components.gd` `sprite()`:

```gdscript
		"modulate": Color.WHITE,
		"frame_set": "player",
		"z_index": 0,
```

- [ ] **Step 2: Write the failing test** `test/unit/test_frame_set.gd`

```gdscript
extends GutTest

const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_frames_for_known_set():
	var anim = Anim.new()
	var pf := SpriteFrames.new()
	var ef := SpriteFrames.new()
	anim.frame_sets = {"player": pf, "enemy": ef}
	assert_eq(anim.frames_for("player"), pf)
	assert_eq(anim.frames_for("enemy"), ef)

func test_frames_for_unknown_falls_back_to_player():
	var anim = Anim.new()
	var pf := SpriteFrames.new()
	anim.frame_sets = {"player": pf}
	assert_eq(anim.frames_for("nope"), pf, "unknown set falls back to player")
```

- [ ] **Step 3: Run it — expect FAIL** (`frame_sets`/`frames_for` don't exist).

- [ ] **Step 4: Update AnimationSystem to use per-entity frame sets**

In `animation_system.gd`: replace `var player_frames: SpriteFrames = null` with a dict and add `frames_for`, and make `_ensure_anim_node` take the entity's set:

```gdscript
## Named SpriteFrames sets, injected by main.gd (e.g. {"player":..., "enemy":...}).
var frame_sets: Dictionary = {}


## Resolve a frame-set name to a SpriteFrames, falling back to "player".
func frames_for(set_name: String) -> SpriteFrames:
	if frame_sets.has(set_name):
		return frame_sets[set_name]
	return frame_sets.get("player", null)
```

Change the `process()` loop so the sprite-node creation uses the entity's `frame_set`:

```gdscript
		var sprite_comp = get_component(entity_id, "sprite")
		var anim_node := _ensure_anim_node(node, sprite_comp.get("frame_set", "player"))
```

And update `_ensure_anim_node`:

```gdscript
func _ensure_anim_node(node: Node, set_name: String) -> AnimatedSprite2D:
	var existing := node.get_node_or_null("Anim")
	if existing is AnimatedSprite2D:
		return existing
	var frames := frames_for(set_name)
	if frames == null:
		return null
	var anim := AnimatedSprite2D.new()
	anim.name = "Anim"
	anim.sprite_frames = frames
	anim.play("idle")
	node.add_child(anim)
	return anim
```

- [ ] **Step 5: Run the test — expect PASS.** (Run `--import` first if a class change requires it.)

- [ ] **Step 6: Wire frame sets + enemy sprite in main.gd**

In `_initialize_ecs`, replace `anim.player_frames = _build_player_frames()` with:

```gdscript
	anim.frame_sets = {
		"player": _build_player_frames(),
		"enemy": _build_enemy_frames(),
	}
```

Add `_build_enemy_frames()` (FreeKnight Colour2 = a visually distinct recolor; same strip layout):

```gdscript
const FK2 := "res://assets/FreeKnight_v1/Colour2/NoOutline/120x80_PNGSheets/"

func _build_enemy_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	SpriteFramesBuilder.add_strip(sf, "idle", load(FK2 + "_Idle.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "run", load(FK2 + "_Run.png"), 120, 80, 12.0)
	SpriteFramesBuilder.add_strip(sf, "light_1", load(FK2 + "_Attack.png"), 120, 80, 14.0, false)
	SpriteFramesBuilder.add_strip(sf, "hit", load(FK2 + "_Hit.png"), 120, 80, 12.0, false)
	return sf
```

In `_spawn_enemy`: delete the placeholder `Sprite2D` block (the red Image/ImageTexture/Sprite2D child), and set the enemy's frame set after adding the `sprite` component:

```gdscript
	ECS.add_component(entity_id, "sprite", Components.sprite())
	ECS.get_component(entity_id, "sprite").frame_set = "enemy"
```

> Confirm `assets/FreeKnight_v1/Colour2/NoOutline/120x80_PNGSheets/_Idle.png` exists; if Colour2 paths differ, use Colour1 with a red `modulate` instead and report.

- [ ] **Step 7: Run full suite (all pass) + a 3s headless run (no errors).**

- [ ] **Step 8: Commit**

```bash
git add scripts/ecs/components.gd scripts/ecs/systems/animation_system.gd scripts/main/main.gd test/unit/test_frame_set.gd test/unit/test_frame_set.gd.uid
git commit -m "feat: per-entity sprite sets; enemy uses its own frames"
```

---

## Task 3: Reorder CombatSystem after EchoSystem (correct hit-resolution timing)

**Why:** Spec round-3 F1 — every system that sets `hitbox_active` (AI for enemies, Echo for the echo) must run before hit resolution. AI runs early; Echo runs late. Moving CombatSystem to run *after* Echo makes both flag-sets resolve same-frame. (Full CombatInput/HitboxResolution split deferred to P2 with ParrySystem.)

**Files:** Modify `scripts/main/main.gd`.

- [ ] **Step 1: Reorder registration** in `_initialize_ecs` so Echo precedes Combat:

```gdscript
	ECS.register_system(InputSystem.new())
	ECS.register_system(AISystem.new())
	ECS.register_system(JumpSystem.new())
	ECS.register_system(DodgeSystem.new())
	ECS.register_system(MovementSystem.new())
	ECS.register_system(PhysicsSyncSystem.new())
	ECS.register_system(EchoSystem.new())
	ECS.register_system(CombatSystem.new())
	ECS.register_system(MomentumSystem.new())
	ECS.register_system(HealthSystem.new())
```
(Animation registration stays last, unchanged.)

- [ ] **Step 2: Verify suite + 3s run still clean.**

- [ ] **Step 3: Commit**

```bash
git add scripts/main/main.gd
git commit -m "refactor: run CombatSystem after EchoSystem so all hitbox flags resolve same-frame"
```

---

## Task 4: Hit resolution derives facing for input-less attackers

**Why:** G1 — `_process_hitboxes` defaults facing to `1` (right) when there's no `input_state`, so an enemy (or echo) to the player's left never connects. Derive facing from velocity sign, with a stored fallback so a stationary attacker keeps its last facing.

**Files:** Modify `scripts/ecs/systems/combat_system.gd`, `scripts/ecs/components.gd`; Test `test/unit/test_attacker_facing.gd`.

- [ ] **Step 1: Add a `facing` field to the `enemy` component** in `components.gd` `enemy()`:

```gdscript
		"armor_hits": 0,
		"facing": 1,
```

- [ ] **Step 2: Write the failing test** `test/unit/test_attacker_facing.gd`

```gdscript
extends GutTest

const Combat = preload("res://scripts/ecs/systems/combat_system.gd")

func test_facing_from_input_state_when_present():
	assert_eq(Combat.resolve_facing({"facing": -1}, {"x": 0.0}, {"facing": 1}), -1,
		"input_state.facing wins when present")

func test_facing_from_velocity_when_no_input():
	assert_eq(Combat.resolve_facing(null, {"x": -50.0}, {"facing": 1}), -1,
		"derive from velocity sign")

func test_facing_falls_back_to_enemy_facing_when_still():
	assert_eq(Combat.resolve_facing(null, {"x": 0.0}, {"facing": -1}), -1,
		"stationary input-less attacker keeps stored facing")
```

- [ ] **Step 3: Run — expect FAIL** (`resolve_facing` missing).

- [ ] **Step 4: Add `resolve_facing` and use it in `_process_hitboxes`**

Add the static helper to `combat_system.gd`:

```gdscript
## Decide an attacker's facing: input_state.facing → velocity sign → stored enemy.facing.
static func resolve_facing(input_state, velocity, enemy) -> int:
	if input_state != null:
		return input_state.facing
	if velocity != null and abs(velocity.x) > 1.0:
		return -1 if velocity.x < 0.0 else 1
	if enemy != null:
		return enemy.get("facing", 1)
	return 1
```

In `_process_hitboxes`, replace the facing line:

```gdscript
		var attacker_input = get_component(attacker_id, "input_state")
		var attacker_vel = get_component(attacker_id, "velocity")
		var attacker_enemy = get_component(attacker_id, "enemy")
		var facing = resolve_facing(attacker_input, attacker_vel, attacker_enemy)
```

- [ ] **Step 5: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/ecs/systems/combat_system.gd scripts/ecs/components.gd test/unit/test_attacker_facing.gd test/unit/test_attacker_facing.gd.uid
git commit -m "feat: derive attacker facing from velocity for input-less entities"
```

---

## Task 5: Enemies actually attack (open a hitbox window on telegraph→attack)

**Why:** G1 core — AISystem never opens a hitbox, so the enemy can't damage the player. On entering `attack`, open the enemy's weapon hitbox for a short window and set the enemy's facing toward the player; CombatSystem (now after AI, Task 3) resolves the hit.

**Files:** Modify `scripts/ecs/systems/ai_system.gd`; Test `test/integration/test_enemy_attacks_player.gd`.

- [ ] **Step 1: Write the failing integration test** `test/integration/test_enemy_attacks_player.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_enemy_in_attack_state_damages_nearby_player():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var ai := AISystem.new(); ecs.register_system(ai)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	# Player at x=0
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "input_state", Components.input_state())
	ecs.add_component(p, "tag_player", Components.tag_player())

	# Enemy at x=20 (within the 60px attack range), already in attack state
	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(20, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "weapon", Components.weapon(10, 0.4))
	ecs.add_component(e, "health", Components.health(50))
	var enemy = Components.enemy("ronin_drone")
	ecs.add_component(e, "enemy", enemy)
	var ai_c = Components.ai("chase"); ai_c.state = "attack"; ai_c.attack_cooldown = 0.0
	ai_c.target_entity = p  # chase normally sets this; required for _process_attack to fire
	ecs.add_component(e, "ai", ai_c)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())

	var hp_before = ecs.get_component(p, "health").current
	ai.process(0.016)      # opens the enemy hitbox window + sets facing toward player
	combat.process(0.016)  # resolves hitboxes

	assert_lt(ecs.get_component(p, "health").current, hp_before,
		"an attacking enemy in range damages the player")
```

- [ ] **Step 2: Run it — expect FAIL** (enemy never opens a hitbox).

- [ ] **Step 3: Open the hitbox + set facing in `AISystem._process_attack`**

Replace `_process_attack` in `ai_system.gd`:

```gdscript
func _process_attack(entity_id: int, ai: Dictionary, enemy: Dictionary, _delta: float) -> void:
	# Face the target and open the weapon hitbox for this attack.
	var weapon = get_component(entity_id, "weapon")
	var pos = get_component(entity_id, "position")
	if weapon and pos and ai.target_entity >= 0 and ecs.entity_exists(ai.target_entity):
		var target_pos = ecs.get_component(ai.target_entity, "position")
		if target_pos and enemy:
			enemy.facing = -1 if target_pos.x < pos.x else 1
		weapon.is_attacking = true
		weapon.hitbox_active = true
		weapon.attack_type = "enemy"
		weapon.attack_timer = weapon.attack_speed  # CombatSystem timers will close it

	ai.attack_cooldown = 1.0  # time between attacks
	ai.state = "chase"

	if enemy:
		enemy.is_telegraphing = false
		enemy.telegraph_timer = 0
```

(Note: `CombatSystem._process_attack_timers` decrements `attack_timer` and clears `is_attacking`/`hitbox_active` when it expires, so the window self-closes. `_apply_damage` already disables `hitbox_active` after a successful hit to prevent multi-hit.)

- [ ] **Step 4: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/ai_system.gd test/integration/test_enemy_attacks_player.gd test/integration/test_enemy_attacks_player.gd.uid
git commit -m "feat: enemies open a hitbox window on attack and damage the player"
```

---

## Task 6: Knockback on hit

**Why:** Hits should shove the victim. hitstop+shake already fire in `_apply_damage`; add a horizontal velocity impulse away from the attacker.

**Files:** Modify `scripts/ecs/systems/combat_system.gd`; Test `test/unit/test_knockback.gd`.

- [ ] **Step 1: Write the failing test** `test/unit/test_knockback.gd`

```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_hit_applies_knockback_away_from_attacker():
	var ecs = ECSScript.new()
	add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)

	# Attacker (player) at x=0 facing right; target (enemy) at x=40
	var a = ecs.create_entity()
	ecs.add_component(a, "position", Components.position(0, 0))
	ecs.add_component(a, "weapon", Components.weapon(15, 0.25))
	ecs.add_component(a, "health", Components.health(100))
	ecs.add_component(a, "input_state", Components.input_state())
	ecs.add_component(a, "tag_player", Components.tag_player())
	var ai = ecs.get_component(a, "input_state"); ai.facing = 1
	var w = ecs.get_component(a, "weapon"); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "light"

	var t = ecs.create_entity()
	ecs.add_component(t, "position", Components.position(40, 0))
	ecs.add_component(t, "velocity", Components.velocity())
	ecs.add_component(t, "collision", Components.collision(32, 64))
	ecs.add_component(t, "health", Components.health(50))
	ecs.add_component(t, "tag_enemy", Components.tag_enemy())

	combat.process(0.016)

	assert_gt(ecs.get_component(t, "velocity").x, 0.0,
		"target is knocked to the right (away from a right-facing attacker)")
```

- [ ] **Step 2: Run it — expect FAIL** (no knockback).

- [ ] **Step 3: Apply knockback in `_apply_damage`**

In `combat_system.gd._apply_damage`, after `target_health.current -= damage` and before/after the VFX call, add (the attacker facing is already computed in `_process_hitboxes`; pass it in). Update the `_apply_damage` signature call to include facing, OR recompute direction from positions inside `_apply_damage`. Simpler — recompute from positions:

```gdscript
	# Knockback away from the attacker
	var target_vel = get_component(target_id, "velocity")
	var attacker_pos = get_component(attacker_id, "position")
	var target_pos2 = get_component(target_id, "position")
	if target_vel and attacker_pos and target_pos2:
		var dir := 1.0 if target_pos2.x >= attacker_pos.x else -1.0
		var knock := 250.0
		if weapon.attack_type.begins_with("heavy"):
			knock = 450.0
		target_vel.x = dir * knock
		target_vel.y = -120.0  # small pop
```

- [ ] **Step 4: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/ecs/systems/combat_system.gd test/unit/test_knockback.gd test/unit/test_knockback.gd.uid
git commit -m "feat: knockback impulse on hit"
```

---

## Task 7: Player death → respawn at a fixed spawn point

**Why:** G7 (P1 minimal) — currently the player death branch only prints. Respawn the player: reset HP to max and teleport its node back to the spawn position. (Full checkpoints + per-arena enemy restore are P4.)

**Files:** Modify `scripts/main/main.gd`; Test `test/integration/test_player_respawn.gd`.

- [ ] **Step 1: Store the spawn position** — in `main.gd`, add a field `var _player_spawn: Vector2` and set it in `_spawn_test_scene` where the player is spawned:

```gdscript
	_player_spawn = Vector2(200, 400)
	_player_entity_id = _spawn_player(_player_spawn)
```

- [ ] **Step 2: Write the failing integration test** `test/integration/test_player_respawn.gd`

```gdscript
extends GutTest

# Verifies the respawn helper resets health and position. We test the pure helper
# Main._respawn_player_state(health, pos_component, spawn) to avoid scene wiring.
const Main = preload("res://scripts/main/main.gd")

func test_respawn_resets_health_and_position():
	var health = Components.health(100)
	health.current = 0
	var pos = Components.position(999, 999)
	Main._respawn_player_state(health, pos, Vector2(200, 400))
	assert_eq(health.current, health.max, "health restored to full")
	assert_eq(pos.x, 200.0)
	assert_eq(pos.y, 400.0)
```

- [ ] **Step 3: Run — expect FAIL** (`_respawn_player_state` missing).

- [ ] **Step 4: Implement the helper + wire death**

Add the pure static helper to `main.gd`:

```gdscript
static func _respawn_player_state(health: Dictionary, pos: Dictionary, spawn: Vector2) -> void:
	health.current = health.max
	health.invincible = false
	health.invincibility_timer = 0.0
	pos.x = spawn.x
	pos.y = spawn.y
```

In `_on_entity_died`, replace the player branch body with a respawn:

```gdscript
	if entity_id == _player_entity_id:
		GameEvents.player_died.emit()
		var health = ECS.get_component(_player_entity_id, "health")
		var pos = ECS.get_component(_player_entity_id, "position")
		_respawn_player_state(health, pos, _player_spawn)
		var node = ECS.get_entity_node(_player_entity_id)
		if node:
			node.position = _player_spawn
			if node is CharacterBody2D:
				node.velocity = Vector2.ZERO
		GameEvents.ui_update_health.emit(health.current, health.max)
		print("Player respawned")
```

- [ ] **Step 5: Run the test — expect PASS.** Full suite — all pass. 3s run — clean.

- [ ] **Step 6: Commit**

```bash
git add scripts/main/main.gd test/integration/test_player_respawn.gd test/integration/test_player_respawn.gd.uid
git commit -m "feat: player death respawns at fixed spawn point"
```

---

## Task 8: Win state when the enemy is defeated

**Why:** P1 DoD needs a clear win. With one Ronin Drone, killing it = victory. Show a centered "VICTORY" banner.

**Files:** Create `scripts/ui/win_label.gd`; Modify `scripts/main/main.gd`; Test `test/unit/test_win_condition.gd`.

- [ ] **Step 1: Write the failing test** `test/unit/test_win_condition.gd`

```gdscript
extends GutTest

const Main = preload("res://scripts/main/main.gd")

func test_win_when_no_enemies_remain():
	assert_true(Main._is_victory(0), "zero living enemies = victory")
	assert_false(Main._is_victory(1), "enemies remaining = not yet")
```

- [ ] **Step 2: Run — expect FAIL** (`_is_victory` missing).

- [ ] **Step 3: Add `_is_victory` + a win banner**

Add to `main.gd`:

```gdscript
static func _is_victory(living_enemy_count: int) -> bool:
	return living_enemy_count <= 0
```

In `_on_entity_died`, in the enemy branch (after `ECS.destroy_entity(entity_id)`), check remaining enemies and show the banner:

```gdscript
		var remaining := ECS.get_entities_with("tag_enemy").size()
		if _is_victory(remaining):
			_show_victory()
```

Add `_show_victory()` which adds a `WinLabel`:

```gdscript
func _show_victory() -> void:
	if has_node("WinLayer"):
		return
	var layer := CanvasLayer.new()
	layer.name = "WinLayer"
	layer.layer = 50
	layer.add_child(preload("res://scripts/ui/win_label.gd").new())
	add_child(layer)
```

Create `scripts/ui/win_label.gd`:

```gdscript
class_name WinLabel
extends Label

func _ready() -> void:
	text = "VICTORY"
	add_theme_font_size_override("font_size", 96)
	add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	set_anchors_preset(Control.PRESET_CENTER)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
```

- [ ] **Step 4: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/win_label.gd scripts/ui/win_label.gd.uid scripts/main/main.gd test/unit/test_win_condition.gd test/unit/test_win_condition.gd.uid
git commit -m "feat: victory banner when all enemies are defeated"
```

---

## Task 9: Final P1 review + smoke test

- [ ] **Step 1: Full suite green** — `& "C:\Godot\Godot_v4.6.1-stable_win64.exe" --headless -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`. All pass.
- [ ] **Step 2: Clean 3s headless run** — no SCRIPT ERROR, player + enemy spawn.
- [ ] **Step 3: Screenshot** — (controller will instance the scene, render ~2s, capture) to confirm: player knight and a visually distinct enemy knight both standing on the floor (enemy no longer floating, no longer the player's frames, no red box).
- [ ] **Step 4: Interactive playtest checklist (user):** enemy approaches, telegraphs, and damages the player (health bar drops); player light/heavy combos kill the enemy with hitstop+shake+knockback; dying respawns at spawn; killing the enemy shows VICTORY; ~60 FPS.

---

## P1 Definition of Done

- [ ] Enemy has gravity, its own sprite, telegraphs, and **damages the player**.
- [ ] Hits feel weighty: hitstop + screen shake (existing) + **knockback** (new).
- [ ] Player death **respawns** at the spawn point.
- [ ] Defeating the enemy shows a **VICTORY** state.
- [ ] All tests pass; clean boot; ~60 FPS.

When signed off, proceed to the **P2 plan** (Echo combat utility + Parry + enemy stagger), where the CombatInput/HitboxResolution split is introduced.
