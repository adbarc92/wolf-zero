# Wolf-Zero Vertical Slice — P4: Handcrafted Level + Checkpoints + Polish — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Turn the test sandbox into a real, beatable level: a linear Neo Edo run (traversal → Arena 1 → traversal → Arena 2 → Elite) with parallax atmosphere, a camera bounded to the level, checkpoint-based respawn that **restores the current arena's enemies**, a clear **win** at the end, and a tuning pass — completing the vertical slice.

**Architecture:** Build on P0–P3. The level is **code-defined data** (`LevelOne`): platform/wall rects, the player spawn, ordered **arenas** (an x-trigger range + an enemy roster + a checkpoint), and a goal x. `main.gd` builds the geometry, wires a `ParallaxBackground`, bounds the `Camera2D`, and runs a small **level flow** in `_process`: when the player crosses an arena's trigger x, spawn that arena's enemies and set the checkpoint; on death, respawn at the last checkpoint and re-spawn that arena's roster; when the player passes the goal x (after the last arena is cleared), show **VICTORY**. Trigger/checkpoint selection are pure static helpers (TDD); geometry/parallax/camera are scene wiring (smoke + screenshot). No hand-painted TileMap — code geometry + parallax art (a tileset-painting pass is deferred to the editor).

**Tech Stack:** Godot 4.6, GDScript, GUT. Godot binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH). Tests: `... -gtest=res://test/<path>.gd`; suite `-gconfig=res://.gutconfig.json`. New `class_name` → `--import` once.

**Spec:** `docs/superpowers/specs/2026-06-04-vertical-slice-design.md` (phase **P4**; level §2.3 Neon Yoshiwara; G7 checkpoint/respawn). Salvaged art: `assets/MoonlitGraveyard/Background_0.png`/`Background_1.png`, `assets/Sidescroller Shooter - Central City/.../Background/*`.

**Branch:** `feat/vertical-slice` (continues from P3 + polish; HEAD ~`4608d16`).

---

## Verified current state

- `main.gd`: `_spawn_test_scene()` spawns the player at `Vector2(200,400)` (`_player_spawn`) + a 3-enemy roster + `_create_test_platforms()` (floor at y=600 + a few platforms + the wall via `_add_platform(pos, size)`). `_on_entity_died` respawns the player (fixed spawn) and shows VICTORY when `tag_enemy` count hits 0 (`_is_victory`, `_show_victory`, `WinLabel`). `_process` sets `camera.position = player_pos` each frame. `archetype(kind)` table exists. `_respawn_player_state(health, pos, spawn)` static helper exists. `GameState` has `current_checkpoint` (bare int).
- Camera2D (`scenes/main/main.tscn`) has `position_smoothing_enabled = true`; main._process overrides `camera.position` directly each frame (fights smoothing — reconcile here).
- Enemies are spawned by `_spawn_enemy(position, enemy_type)` (archetype-driven, P3).

---

## File structure (P4)

| File | Responsibility | Tasks |
|------|----------------|-------|
| `scripts/levels/level_one.gd` | static level data (geometry, spawn, arenas, goal) + pure flow helpers | T1, T3 (create) |
| `scripts/main/main.gd` | build geometry, parallax, camera limits, level flow, checkpoint respawn, win | T1–T5 |
| tests | pure helpers | T1, T3, T4 |

---

## Task 1: LevelOne data + geometry builder + camera limits

**Why:** Replace the ad-hoc test scene with a real, longer linear level and bound the camera to it.

**Files:** Create `scripts/levels/level_one.gd`; Modify `scripts/main/main.gd`; Test `test/unit/test_level_one.gd`.

- [ ] **Step 1: Create `scripts/levels/level_one.gd`** with the level data + a couple pure helpers:
```gdscript
class_name LevelOne
extends RefCounted
## Static data + pure flow helpers for the vertical-slice level.

const SPAWN := Vector2(200, 540)
const GOAL_X := 3950.0
const FLOOR_Y := 600.0
const EXTENT_X := 4200.0

## Solid geometry as rects [Vector2 center, Vector2 size].
static func platforms() -> Array:
	return [
		[Vector2(2100, FLOOR_Y + 16), Vector2(EXTENT_X, 32)],  # long floor
		[Vector2(700, 470), Vector2(180, 20)],                 # opening hop
		[Vector2(1050, 400), Vector2(160, 20)],
		[Vector2(1700, 430), Vector2(40, 320)],                # wall (wall-jump)
		[Vector2(2750, 470), Vector2(200, 20)],                # arena-2 ledge (ashigaru)
	]

## Ordered arenas: trigger_x (player past this activates), checkpoint Vector2,
## and the enemy roster [ [type, Vector2], ... ].
static func arenas() -> Array:
	return [
		{"trigger_x": 1300.0, "checkpoint": Vector2(1250, 540), "enemies": [
			["ronin_drone", Vector2(1600, 540)], ["ronin_drone", Vector2(1850, 540)]]},
		{"trigger_x": 2500.0, "checkpoint": Vector2(2450, 540), "enemies": [
			["cyber_ashigaru", Vector2(2750, 430)], ["ronin_drone", Vector2(2950, 540)]]},
		{"trigger_x": 3300.0, "checkpoint": Vector2(3250, 540), "enemies": [
			["elite_oni", Vector2(3650, 540)]]},
	]


## Index of the first not-yet-activated arena the player has reached, else -1.
static func arena_to_activate(player_x: float, activated: Array) -> int:
	var defs := arenas()
	for i in range(defs.size()):
		if not activated.has(i) and player_x >= defs[i].trigger_x:
			return i
	return -1
```

- [ ] **Step 2: Write the failing test** `test/unit/test_level_one.gd`:
```gdscript
extends GutTest

func test_arena_activates_when_player_passes_trigger():
	# Player before any trigger → none.
	assert_eq(LevelOne.arena_to_activate(100.0, []), -1)
	# Past arena 0's trigger (1300) → 0.
	assert_eq(LevelOne.arena_to_activate(1350.0, []), 0)
	# Arena 0 already activated, past arena 1 (2500) → 1.
	assert_eq(LevelOne.arena_to_activate(2600.0, [0]), 1)
	# All activated → -1.
	assert_eq(LevelOne.arena_to_activate(9999.0, [0, 1, 2]), -1)
```
Run it — expect FAIL (`--import` first for the new class).

- [ ] **Step 3: Build the level geometry + camera limits in `main.gd`**

Replace `_create_test_platforms()`'s body to build from `LevelOne.platforms()` (keep `_add_platform(pos, size)`), and update `_spawn_test_scene` to use the level spawn and NOT spawn the old roster (arenas spawn enemies now, Task 3):
```gdscript
func _spawn_test_scene() -> void:
	_player_spawn = LevelOne.SPAWN
	_player_entity_id = _spawn_player(_player_spawn)
	GameState.player_entity_id = _player_entity_id
	_build_level()

func _build_level() -> void:
	for p in LevelOne.platforms():
		_add_platform(p[0], p[1])
	# Camera bounds
	camera.limit_left = 0
	camera.limit_right = int(LevelOne.EXTENT_X)
	camera.limit_top = -400
	camera.limit_bottom = int(LevelOne.FLOOR_Y) + 120
```
Remove the old `_create_test_platforms` floor/platform hardcode (or have `_build_level` replace it). Keep `_add_platform`.

- [ ] **Step 4: Reconcile camera follow** — in `_process`, keep following the player horizontally but let Godot clamp to limits. Replace the direct `camera.position = Vector2(player_pos.x, player_pos.y)` with following only x and a fixed y, so the bounded camera reads naturally:
```gdscript
	camera.position = Vector2(player_pos.x, LevelOne.FLOOR_Y - 120)
```
(Camera limits clamp the edges; `position_smoothing` eases it.)

- [ ] **Step 5: Run the test — expect PASS.** Full suite green. 3s headless run: clean, player spawns at level start, no SCRIPT ERROR.

- [ ] **Step 6: Commit**
```bash
git add scripts/levels/level_one.gd scripts/main/main.gd test/unit/test_level_one.gd test/unit/test_level_one.gd.uid
git commit -m "feat: LevelOne data + geometry builder + camera limits"
```

---

## Task 2: Parallax background (Neo Edo atmosphere)

**Why:** Depth + mood. Use salvaged background layers behind the gameplay.

**Files:** Modify `scripts/main/main.gd`. (No unit test — visual; smoke + screenshot.)

- [ ] **Step 1: Add a parallax background** built in code in `_ready` (after `_setup_vfx_manager`). Confirm the texture paths exist first (list `assets/MoonlitGraveyard/`); use the two MoonlitGraveyard background layers (atmospheric, fits neon-night Neo Edo):
```gdscript
func _setup_parallax() -> void:
	var pbg := ParallaxBackground.new()
	pbg.name = "Parallax"
	_add_layer(pbg, "res://assets/MoonlitGraveyard/Background_0.png", 0.2, Vector2(0.5, 0.5))
	_add_layer(pbg, "res://assets/MoonlitGraveyard/Background_1.png", 0.5, Vector2(1.0, 1.0))
	add_child(pbg)

func _add_layer(pbg: ParallaxBackground, path: String, scroll_scale: float, scale_v: Vector2) -> void:
	var tex = load(path)
	if tex == null:
		return
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(scroll_scale, scroll_scale)
	layer.motion_mirroring = Vector2(tex.get_width() * scale_v.x * 4, 0)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = scale_v
	spr.position = Vector2(0, 0)
	layer.add_child(spr)
	pbg.add_child(layer)
```
Call `_setup_parallax()` in `_ready`. (Adjust scales/positions in the tuning pass, Task 6. If MoonlitGraveyard paths differ, use `Sidescroller Shooter - Central City/.../Background/Base Color.png` and report.)

- [ ] **Step 2: Verify** — 3s headless run clean; a screenshot (controller will take one) shows a background behind the gameplay.

- [ ] **Step 3: Commit**
```bash
git add scripts/main/main.gd
git commit -m "feat: parallax background for Neo Edo atmosphere"
```

---

## Task 3: Arena activation + enemy spawning

**Why:** Enemies should appear as the player advances into each arena (not all at once at level load).

**Files:** Modify `scripts/main/main.gd`; Test `test/integration/test_arena_flow.gd`.

- [ ] **Step 1: Track arena state + poll in `_process`.** Add fields:
```gdscript
var _arenas_activated: Array = []
var _arena_enemies: Dictionary = {}  # arena_index -> Array[entity_id]
var _current_arena: int = -1
```
In `_process` (after the camera update, guarded by `_player_entity_id >= 0`):
```gdscript
	var px = ECS.get_component(_player_entity_id, "position").x
	var idx = LevelOne.arena_to_activate(px, _arenas_activated)
	if idx >= 0:
		_activate_arena(idx)
```
Add:
```gdscript
func _activate_arena(index: int) -> void:
	_arenas_activated.append(index)
	_current_arena = index
	var arena = LevelOne.arenas()[index]
	_player_spawn = arena.checkpoint            # checkpoint = this arena's start
	var ids: Array = []
	for spec in arena.enemies:
		ids.append(_spawn_enemy(spec[1], spec[0]))
	_arena_enemies[index] = ids
```

- [ ] **Step 2: Write the failing integration test** `test/integration/test_arena_flow.gd`
```gdscript
extends GutTest

# Verifies arena_to_activate gates correctly as the player advances. (Spawning is
# exercised in-engine; this guards the gating logic that drives it.)
func test_arena_gating_sequence():
	var activated := []
	var i0 = LevelOne.arena_to_activate(1350.0, activated)
	assert_eq(i0, 0, "enter arena 0")
	activated.append(i0)
	assert_eq(LevelOne.arena_to_activate(1400.0, activated), -1, "no re-activation while inside arena 0")
	assert_eq(LevelOne.arena_to_activate(2600.0, activated), 1, "advance to arena 1")
```
Run — expect PASS already (logic from Task 1); if it fails, stop and report. (This documents the flow contract before wiring spawning.)

- [ ] **Step 3: Verify** — full suite green; 3s headless run clean (no enemies spawn at x=200 start since the player hasn't reached a trigger; logs show no errors).

- [ ] **Step 4: Commit**
```bash
git add scripts/main/main.gd test/integration/test_arena_flow.gd test/integration/test_arena_flow.gd.uid
git commit -m "feat: arenas activate and spawn enemies as the player advances"
```

---

## Task 4: Checkpoint respawn that restores the current arena

**Why:** G7 (full) — dying mid-arena should return the player to that arena's checkpoint with the arena's enemies restored (not an empty/unwinnable arena).

**Files:** Modify `scripts/main/main.gd`; Test `test/integration/test_checkpoint_restore.gd`.

- [ ] **Step 1: On player death, respawn + restore the current arena.** In `_on_entity_died`'s player branch (currently respawns at `_player_spawn`), after the existing respawn, restore the current arena's enemies:
```gdscript
		# Restore the current arena (clear survivors, re-spawn its roster)
		if _current_arena >= 0:
			_restore_arena(_current_arena)
```
Add:
```gdscript
func _restore_arena(index: int) -> void:
	# Despawn any survivors from this arena.
	for eid in _arena_enemies.get(index, []):
		if ECS.entity_exists(eid):
			var n = ECS.get_entity_node(eid)
			if n: n.queue_free()
			ECS.destroy_entity(eid)
	# Re-spawn the roster.
	var arena = LevelOne.arenas()[index]
	var ids: Array = []
	for spec in arena.enemies:
		ids.append(_spawn_enemy(spec[1], spec[0]))
	_arena_enemies[index] = ids
```
And make the death branch respawn at the arena checkpoint (`_player_spawn` is set to the arena checkpoint in `_activate_arena`, so the existing `_respawn_player_state(health, pos, _player_spawn)` already returns the player to the checkpoint).

- [ ] **Step 2: Write the failing integration test** `test/integration/test_checkpoint_restore.gd`

This tests the pure restore decision: a helper `LevelOne.roster_for(index)` returns the arena's enemy count so we can assert restoration count without scene wiring. Add to `level_one.gd`:
```gdscript
static func roster_for(index: int) -> Array:
	var defs := arenas()
	if index < 0 or index >= defs.size():
		return []
	return defs[index].enemies
```
Test:
```gdscript
extends GutTest

func test_arena_roster_sizes():
	assert_eq(LevelOne.roster_for(0).size(), 2, "arena 0 has two drones")
	assert_eq(LevelOne.roster_for(2).size(), 1, "elite arena has one enemy")
	assert_eq(LevelOne.roster_for(-1).size(), 0, "no arena -> empty roster")

func test_checkpoint_is_arena_start():
	assert_eq(LevelOne.arenas()[0].checkpoint, Vector2(1250, 540))
```
Run — expect FAIL (`roster_for` missing), then add it, then PASS.

- [ ] **Step 3: Verify** — full suite green; 3s run clean.

- [ ] **Step 4: Commit**
```bash
git add scripts/main/main.gd scripts/levels/level_one.gd test/integration/test_checkpoint_restore.gd test/integration/test_checkpoint_restore.gd.uid
git commit -m "feat: checkpoint respawn restores the current arena's enemies"
```

---

## Task 5: Win at the level goal

**Why:** A clear end. Reaching the goal x after clearing the last arena = victory. (Replaces the "all enemies dead" win, which no longer fits a level where enemies spawn progressively.)

**Files:** Modify `scripts/main/main.gd`; Test `test/unit/test_level_win.gd`.

- [ ] **Step 1: Add a pure win check to `level_one.gd`:**
```gdscript
## Win when the player passes the goal AND the final arena has been cleared.
static func is_level_won(player_x: float, final_arena_cleared: bool) -> bool:
	return final_arena_cleared and player_x >= GOAL_X
```

- [ ] **Step 2: Write the failing test** `test/unit/test_level_win.gd`
```gdscript
extends GutTest

func test_win_requires_goal_and_final_arena_cleared():
	assert_false(LevelOne.is_level_won(4000.0, false), "not won until final arena cleared")
	assert_false(LevelOne.is_level_won(1000.0, true), "not won before the goal")
	assert_true(LevelOne.is_level_won(4000.0, true), "won past goal with final arena cleared")
```
Run — expect FAIL, add helper, PASS.

- [ ] **Step 3: Wire it in `_process`.** After the arena-activation poll, check the win:
```gdscript
	var final_idx = LevelOne.arenas().size() - 1
	var final_cleared = _arena_enemies.has(final_idx) \
		and _living_count(_arena_enemies[final_idx]) == 0 \
		and _arenas_activated.has(final_idx)
	if not _won and LevelOne.is_level_won(px, final_cleared):
		_won = true
		_show_victory()
```
Add a `var _won := false` field and a helper:
```gdscript
func _living_count(ids: Array) -> int:
	var n := 0
	for eid in ids:
		if ECS.entity_exists(eid):
			n += 1
	return n
```
Remove the old per-kill `_is_victory`/`_show_victory` call in `_on_entity_died` (or leave `_is_victory` unused). The goal can sit just past the elite arena; place a visual goal marker (a tall cyan ColorRect at `GOAL_X`) in `_build_level`.

- [ ] **Step 4: Verify** — full suite green; 3s run clean.

- [ ] **Step 5: Commit**
```bash
git add scripts/main/main.gd scripts/levels/level_one.gd test/unit/test_level_win.gd test/unit/test_level_win.gd.uid
git commit -m "feat: win at the level goal after clearing the final arena"
```

---

## Task 6: Tuning pass + final review + smoke test

**Why:** Make the whole run feel good and confirm it plays start-to-finish.

**Files:** Modify tunable constants (`components.gd` defaults, `archetype` values, VFX) as needed; no new systems.

- [ ] **Step 1: Playtest-tune (record numbers in the commit).** With the controller capturing screenshots at several player x positions (start, arena 1, arena 2, elite, goal), sanity-check pacing. Adjust as needed and note each change:
  - player `max_speed`/`jump_force`/`gravity` for responsive feel,
  - enemy `detection`/`attack_range`/`speed` so arenas aren't trivial or unfair,
  - hitstop/knockback magnitudes,
  - parallax layer scales/offsets so the background frames the level.
- [ ] **Step 2: Full suite green.**
- [ ] **Step 3: Clean run** — `--headless --path . --quit-after 300`, no SCRIPT ERROR; arenas activate as the player advances (drive the player via a capture script that presses move_right, or reposition the player in stages) — confirm no errors when each arena spawns and on a simulated death/respawn.
- [ ] **Step 4: Screenshot montage** — capture the player at level start (with parallax), inside Arena 1, and at the elite/goal, to confirm geometry, parallax, camera bounds, and enemy spawns render.
- [ ] **Step 5: Commit** the tuning changes:
```bash
git add -A
git commit -m "tune: P4 pacing pass (movement, enemy ranges, parallax framing)"
```

---

## P4 Definition of Done

- [ ] A linear level builds from `LevelOne` data with camera bounded to its extents.
- [ ] **Parallax** background renders for atmosphere.
- [ ] **Arenas** activate and spawn their rosters as the player advances.
- [ ] Dying respawns at the arena **checkpoint** with that arena's enemies **restored**.
- [ ] Reaching the **goal** after clearing the final arena shows **VICTORY**.
- [ ] All tests pass; clean boot; ~60 FPS.

This completes the vertical slice (P0–P4). After sign-off, the natural follow-ups (not part of the slice) are: a hand-painted TileMap art pass in the editor (or PixelLab-generated tiles), audio, and the full DoD playtest from the spec (§11).
