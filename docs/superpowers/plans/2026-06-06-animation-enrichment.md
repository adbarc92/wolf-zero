# Wolf-Zero — Animation Enrichment — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Leverage the unused FreeKnight clips: animate gameplay we already have (wall-slide/climb, hurt, death), add a **slide** evade, and wire polish transitions + attack variety — for both player (Colour1) and enemies (Colour2).

**Architecture:** `AnimationSystem.derive_clip` stays the single source of clip selection; extend it with **trailing optional params** (backward-compatible — existing 5/6-arg callers and their tests keep working). New supporting state: a `health.hurt_timer` (set on real damage), a `dying` component (defers despawn so a death anim can play), and a `platformer.is_sliding` flag (a new slide move). `main.gd` adds the new clips to `_build_player_frames`/`_build_enemy_frames`. Slide reuses inputs (dash while holding crouch). Stateful transitions (turn-around, crouch-transition) are tracked per-entity inside AnimationSystem.

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH). Tests: `... -gtest=res://test/<path>.gd`; suite `-gconfig=res://.gutconfig.json`. New `class_name` members → `--import` once.

**Branch:** `feat/vertical-slice` (HEAD ~`253f545`; 46 tests passing).

**Clip inventory (FreeKnight, both colours):** wired = idle, run, jump, fall, dash, roll, light_1–5, hit*, crouch, crouch_walk. Unused = WallSlide, WallClimb, WallClimbNoMovement, WallHang, Death, DeathNoMovement, JumpFallInbetween, TurnAround, Slide(+transitions), CrouchAttack, CrouchTransition, CrouchFull, Attack*NoMovement. (*hit is loaded but never played.)

**derive_clip priority (final):** dead → hurt → roll(dodge) → dash → slide → attack(crouch_attack / light_n) → wall(climb/slide) → airborne(jump / jump_fall_inbetween / fall) → crouch(crouch/crouch_walk) → run → idle.

---

## Task 1: Wall-slide / wall-climb + hurt animations (Group A, part 1)

**Files:** `scripts/ecs/systems/animation_system.gd`, `scripts/ecs/components.gd`, `scripts/ecs/systems/combat_system.gd`, `scripts/ecs/systems/health_system.gd`, `scripts/main/main.gd`; Test `test/unit/test_anim_wall_hurt.gd`.

- [ ] **Step 1: Add `hurt_timer` to `health()`** in `components.gd`:
```gdscript
		"invincibility_duration": 0.5,
		"hurt_timer": 0.0,
```

- [ ] **Step 2: Set `hurt_timer` on real damage.** In `combat_system.gd._apply_damage`, where actual damage is applied to `target_health.current` (the non-parry path), add `target_health.hurt_timer = 0.25`. In `apply_damage_to` (projectile/external path) do the same after applying damage.

- [ ] **Step 3: Decrement it in `health_system.gd`.** In `_process_invincibility` (or the per-entity loop), add: `if health.hurt_timer > 0.0: health.hurt_timer = max(0.0, health.hurt_timer - delta)`.

- [ ] **Step 4: Extend `derive_clip` (trailing optional params) + write the failing test.** New signature:
```gdscript
static func derive_clip(vel: Dictionary, collision: Dictionary, weapon: Dictionary,
		dodge: Dictionary, platformer: Dictionary, crouching: bool = false,
		hurt: bool = false, on_wall: bool = false, climbing: bool = false) -> String:
```
Insert near the top (after dodge/dash, before attack — but hurt should beat most): order becomes
`if hurt: return "hit"` (right after the dodge/dash checks), then attack, then
`if on_wall and not grounded: return "wall_climb" if climbing else "wall_slide"` (before the airborne fall/jump), then existing crouch/run/idle. Use `collision.get("on_ground", true)` for grounded.
Test `test/unit/test_anim_wall_hurt.gd`:
```gdscript
extends GutTest
const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_hurt_overrides_movement():
	assert_eq(Anim.derive_clip({"x":100.0,"y":0.0},{"on_ground":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, true), "hit")

func test_wall_slide_when_on_wall_airborne():
	assert_eq(Anim.derive_clip({"x":0.0,"y":50.0},{"on_ground":false,"on_wall":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, false, true, false), "wall_slide")

func test_wall_climb_when_climbing():
	assert_eq(Anim.derive_clip({"x":0.0,"y":-50.0},{"on_ground":false,"on_wall":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}, false, false, true, true), "wall_climb")

func test_existing_callers_unaffected():
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},{"is_attacking":false},
		{"is_dodging":false},{"is_dashing":false}), "idle")
```
Run RED → implement → GREEN.

- [ ] **Step 5: Pass the new flags from `AnimationSystem.process`.** Compute and pass:
```gdscript
		var health = get_component(entity_id, "health")
		var hurt: bool = health != null and health.get("hurt_timer", 0.0) > 0.0
		var on_wall: bool = collision != null and collision.get("on_wall", false) and not collision.get("on_ground", true)
		var climbing: bool = on_wall and input != null and input.get("jump_pressed", false) \
			and platformer != null and platformer.get("wall_run_timer", 0.0) > 0.0
		var clip := derive_clip(..., crouching, hurt, on_wall, climbing)
```

- [ ] **Step 6: Add the clips to both frame builders in `main.gd`:**
```gdscript
	SpriteFramesBuilder.add_strip(sf, "wall_slide", load(FK + "_WallSlide.png"), 120, 80, 10.0)
	SpriteFramesBuilder.add_strip(sf, "wall_climb", load(FK + "_WallClimb.png"), 120, 80, 12.0)
```
(and the FK2 equivalents in `_build_enemy_frames`).

- [ ] **Step 7:** `--import`, run test (PASS), full suite green, 3s run clean. **Commit:** `feat: animate wall-slide/climb and hurt reactions`.

---

## Task 2: Death animation (dying state defers despawn)

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/animation_system.gd`, `scripts/main/main.gd`; Test `test/unit/test_dying.gd`.

- [ ] **Step 1: Add a `dying()` component** in `components.gd`:
```gdscript
static func dying() -> Dictionary:
	return {"timer": 0.6}
```

- [ ] **Step 2: derive_clip — dead beats everything.** Add a `dead: bool = false` trailing param; at the very top of `derive_clip`: `if dead: return "death"`. In `process`, `var dead := has_component(entity_id, "dying")` and pass it.

- [ ] **Step 3: Defer despawn in `main.gd._on_entity_died`.** Instead of immediately destroying the enemy / respawning the player:
  - **Enemy:** add a `dying` component, zero its velocity, and stop its AI (set `ai.state = "dead"` if present, or just rely on dying). In `_process`, tick `dying.timer` for all entities with `dying`; when ≤ 0, do the existing despawn (queue_free + destroy_entity, award XP). Keep the arena/win bookkeeping.
  - **Player:** add `dying`; while dying, suppress input/respawn; when the timer expires, run the existing respawn + arena restore.
  (Implement a small `_process_dying(delta)` helper called from `_process`.)

- [ ] **Step 4: Failing test** `test/unit/test_dying.gd`:
```gdscript
extends GutTest
const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_dead_clip_wins():
	# dead flag (last param) overrides everything, even attacking
	assert_eq(Anim.derive_clip({"x":0.0,"y":0.0},{"on_ground":true},
		{"is_attacking":true,"attack_type":"light","combo_current":2},
		{"is_dodging":false},{"is_dashing":false}, false, true, false, false, true), "death")
```
(`dead` is the final trailing param.) RED → implement → GREEN.

- [ ] **Step 5: Add death clips to both builders:** `add_strip(sf, "death", load(FK + "_Death.png"), 120, 80, 10.0, false)` (+ FK2). `--import`, full suite, 3s run clean. **Commit:** `feat: death animation via a dying state that defers despawn`.

---

## Task 3: Slide mechanic (new evade)

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/movement_system.gd`, `scripts/ecs/systems/animation_system.gd`, `scripts/main/main.gd`; Test `test/unit/test_slide.gd`.

- [ ] **Step 1: Add slide fields to `platformer()`:**
```gdscript
		"is_sliding": false,
		"slide_timer": 0.0,
		"slide_duration": 0.35,
		"slide_speed": 700.0,
```

- [ ] **Step 2: Slide trigger + movement in `movement_system.gd`.** A slide is a dash performed while holding crouch on the ground: in the dash-trigger area, if `input.dash_pressed and input.crouch_pressed and collision.on_ground and not is_sliding and dash_cooldown<=0` → start slide (`is_sliding=true`, `slide_timer=slide_duration`, `dash_cooldown=0.6`) **instead of** dash. Add a slide branch (like dash) before/after the dash branch: while `is_sliding`, set `vel.x = facing * slide_speed`, `vel.y` keeps gravity, and grant i-frames (`health.invincible = true` during the slide) so it ducks projectiles/attacks; `continue`. Tick `slide_timer` in `_update_platformer_timers` (which now runs every frame — P4 dash fix) and clear `is_sliding` + clear the slide-granted invincibility when it expires. Be careful not to fight dodge's invincibility handling.

- [ ] **Step 3: derive_clip slide.** Add `sliding: bool = false` trailing param; place `if sliding: return "slide"` after dash, before attack. Pass `platformer.is_sliding` from `process`.

- [ ] **Step 4: Failing test** `test/unit/test_slide.gd`: assert `derive_clip(..., sliding=true)` returns `"slide"`, and a movement test that with crouch+dash held on the ground the entity enters `is_sliding` and `vel.x` reaches ~`slide_speed`. RED → implement → GREEN.

- [ ] **Step 5: Add slide clips:** `add_strip(sf, "slide", load(FK + "_Slide.png"), 120, 80, 14.0, false)` (+ FK2). `--import`, suite, 3s run. **Commit:** `feat: slide evade (dash+crouch) with i-frames + animation`.

---

## Task 4: Polish transitions + attack variety

**Files:** `scripts/ecs/systems/animation_system.gd`, `scripts/main/main.gd`; Test `test/unit/test_anim_polish.gd`.

- [ ] **Step 1: derive_clip additions:**
  - **jump_fall_inbetween:** in the airborne branch, if `abs(vel.y) < 80.0` return `"jump_fall_inbetween"` (apex), else fall/jump as now.
  - **crouch_attack:** in the attack branch, if `crouching` return `"crouch_attack"`.
  - **no-movement attacks:** if attacking, not crouching, and `abs(vel.x) < 1.0`, map light attacks to the NoMovement variants — return `"light_%d_nomove" % combo` (define those clips), else the lunging `light_%d`.
- [ ] **Step 2: Stateful transitions in `AnimationSystem`** (per-entity, tracked in a Dictionary keyed by entity id):
  - **turn_around:** when `input.facing` flips while grounded and not busy, play `"turn_around"` for ~0.15s (override run/idle).
  - **crouch_transition:** when crouch is newly pressed, play `"crouch_transition"` briefly before settling to `"crouch"`.
  (Keep this simple: a small `_transient: Dictionary` of `{entity_id: {clip, time_left}}`; if a transient is active and its clip exists, it wins over the derived run/idle/crouch.)
- [ ] **Step 3: Failing test** `test/unit/test_anim_polish.gd`: cover jump_fall_inbetween (airborne, small vy), crouch_attack (crouching + attacking), and no-movement light attack (attacking, vx≈0). RED → implement → GREEN. (Turn-around/crouch-transition are stateful — verify via the smoke screenshot, not a unit test.)
- [ ] **Step 4: Add clips to both builders:** `jump_fall_inbetween`, `turn_around`, `crouch_transition`, `crouch_attack`, and `light_1_nomove`..`light_5_nomove` (from `_AttackNoMovement.png` / `_Attack2NoMovement.png` / `_AttackComboNoMovement.png` — reuse the combo-nomove sheet for 3–5 as we did for the lunging combo). `--import`, suite, 3s run. **Commit:** `feat: jump/turn/crouch transitions + crouch-attack + no-movement attack variants`.

---

## Task 5: Final review + animation montage

- [ ] Full suite green; 3s headless run clean (no SCRIPT ERROR).
- [ ] Montage capture: force the player through states (idle, run, jump-apex, wall-slide on the wall, slide via crouch+dash, hurt via a hit, death) and screenshot a few to confirm the new clips render (and that missing-clip fallbacks don't crash).
- [ ] **Commit** any tuning.

## Definition of Done
- [ ] Wall-slide/climb, hurt, and death animations play for player + enemies.
- [ ] Slide evade works (i-frames) with its animation.
- [ ] Jump-apex, turn-around, crouch transitions, crouch-attack, and no-movement attack variants play.
- [ ] All tests pass; clean boot; ~60 FPS.
