# Wolf-Zero — Perilous Attacks + Oni Warlord (second boss) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Deepen the defensive conceit with **perilous (unblockable) attacks** — "red" strikes that can't be parried or blocked, only **dodged** (i-frames) — and add a **second boss, the Oni Warlord**, built around them, making a two-boss finale (Crimson Ronin → Oni Warlord) that teaches the parry-vs-dodge read (Sekiro / Katana-Zero).

**Architecture:** A `weapon.unblockable` flag; `CombatSystem._apply_damage` skips the parry + block branches when it's set, so the hit lands unless the target has i-frames (dodge already sets `health.invincible`). `BossSystem` gains a `perilous` pattern (sets `weapon.unblockable` during its active window) with a bright telegraph cue; Crimson Ronin uses it in phase 2. `_spawn_boss` is generalized per boss `kind`; `boss.is_final` gates the victory (Crimson Ronin becomes a mid-boss, Oni Warlord the finale). `LevelOne` is extended with a 4th arena for the Warlord.

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH; commands self-terminate — `--quit-after`; never background; never leave processes). Tests `... -gtest=res://test/<f>.gd`; suite `-gconfig=res://.gutconfig.json`. `--import` once for new members.

**Branch:** `feat/perilous` (off fresh `main`, which has touch + roster). Serves [[wolf-zero-vision]] (parry-centric, deliberate combat).

**Key current code:**
- `CombatSystem._apply_damage` (combat_system.gd:199): parry branch at ~202 (`target_parry.is_parrying`), block branch at ~231 (`target_block.is_blocking`). Normal damage path respects `target_health.invincible` (dodge i-frames). `weapon` carries `damage`, `is_attacking`, `hitbox_active`, `attack_type`.
- `DodgeSystem` sets `health.invincible = true` during i-frames.
- `BossSystem` (boss_system.gd): `pattern_spec(name)`, `patterns_for_phase(phase)`, `pick_pattern(phase, tick)`; `process()` runs telegraph→attack→recover and opens `weapon` on the attack window; `boss` component = `{name, phase, state, state_timer, pattern, staggered, stagger_timer, facing, detection_range}`.
- `main._spawn_boss(position)` (main.gd:396) hardcodes Crimson Ronin (hp 320, red, scale 1.8). `_activate_arena`/`_restore_arena` (424/438) branch `if spec[0] == "crimson_ronin": _spawn_boss(spec[1])`. `_finish_enemy_death` (684): at ~693 `if ECS.has_component(eid,"boss") and not _won: boss_defeated + win_run`.
- `LevelOne`: SPAWN(200,540), GOAL_X 3950, FLOOR_Y 600, EXTENT_X 4200; floor platform `[Vector2(2100, FLOOR_Y+16), Vector2(EXTENT_X, 32)]` (center ≈ EXTENT_X/2); arenas()[2] is the crimson_ronin boss arena.

---

## Task 1: Perilous (unblockable) attack mechanic

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/combat_system.gd`; Test `test/unit/test_perilous.gd`.

- [ ] **Step 1:** In `components.gd.weapon(...)`, add `"unblockable": false,` to the returned dict.
- [ ] **Step 2:** In `combat_system.gd._apply_damage`, gate BOTH defensive branches on not-unblockable:
  - Parry branch: change `if target_parry and target_parry.is_parrying:` → `if target_parry and target_parry.is_parrying and not weapon.get("unblockable", false):`
  - Block branch: change `if target_block and target_block.is_blocking:` → `if target_block and target_block.is_blocking and not weapon.get("unblockable", false):`
  (Leave everything else; the normal damage path already respects `target_health.invincible`, so a dodging target still avoids perilous hits.)
- [ ] **Step 3: Failing test** `test/unit/test_perilous.gd`:
```gdscript
extends GutTest
var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _arena():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	# attacker with an open UNBLOCKABLE hitbox
	var a = ecs.create_entity()
	ecs.add_component(a, "position", Components.position(20, 0))
	ecs.add_component(a, "velocity", Components.velocity())
	var w = Components.weapon(20, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"; w.unblockable = true
	ecs.add_component(a, "weapon", w)
	var en = Components.enemy("oni_warlord"); en.facing = -1
	ecs.add_component(a, "enemy", en)
	ecs.add_component(a, "tag_enemy", Components.tag_enemy())
	return [ecs, combat]

func _add_target(ecs, defended: String):
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	var pr = Components.parry()
	if defended == "parry": pr.is_parrying = true
	if defended == "block": pr.is_blocking = true
	ecs.add_component(p, "parry", pr)
	ecs.add_component(p, "tag_player", Components.tag_player())
	return p

func test_perilous_bypasses_parry_and_block():
	for d in ["parry", "block"]:
		var arena = _arena(); var ecs = arena[0]; var combat = arena[1]
		var p = _add_target(ecs, d)
		combat.process(0.016)
		assert_lt(ecs.get_component(p, "health").current, 100, "perilous lands through %s" % d)

func test_dodge_iframes_still_avoid_perilous():
	var arena = _arena(); var ecs = arena[0]; var combat = arena[1]
	var p = _add_target(ecs, "none")
	ecs.get_component(p, "health").invincible = true   # as during a dodge
	combat.process(0.016)
	assert_eq(ecs.get_component(p, "health").current, 100, "i-frames avoid perilous")
```
RED → implement → GREEN.
- [ ] **Step 4:** `--import`; suite green (baseline 76; +2). **Commit:** `feat: perilous (unblockable) attacks — bypass parry/block, dodge still avoids`.

---

## Task 2: BossSystem perilous pattern + Crimson Ronin phase-2 + telegraph cue

**Files:** `scripts/ecs/systems/boss_system.gd`; Test `test/unit/test_boss_perilous.gd`.

- [ ] **Step 1:** In `boss_system.gd.pattern_spec(name)`, add:
```gdscript
		"perilous":
			return {"telegraph": 0.7, "active": 0.3, "recover": 0.9, "damage": 30, "lunge": true, "unblockable": true}
```
- [ ] **Step 2:** In `patterns_for_phase(phase)`, add `"perilous"` to the phase-2 pool: `return ["slash", "lunge", "combo", "perilous"]`.
- [ ] **Step 3:** In `process()`, where the attack window opens the weapon (sets `weapon.is_attacking/hitbox_active/damage`), ALSO set `weapon.unblockable = spec.get("unblockable", false)`. Where the attack window CLOSES (recover) and in the idle/recover/stagger resets that set `weapon.hitbox_active = false`, ALSO set `weapon.unblockable = false` (so it never lingers).
- [ ] **Step 4: Telegraph cue.** During `telegraph` state, if `boss.pattern == "perilous"`, flash the sprite to a bright warning tint so the player reads "dodge, don't parry": set `var spr = get_component(entity_id, "sprite"); if spr: spr.modulate = Color(1.6, 1.4, 0.4)` while telegraphing a perilous move; otherwise restore the boss's base tint. (Use the boss's stored base color — for simplicity, in the non-perilous telegraph/idle set `spr.modulate` back to the entity's intended tint. If tracking the base tint is awkward, set perilous-telegraph → bright cue, and on entering `attack`/`recover` reset to `Color(1,1,1,1)*` the original; simplest: store the base modulate once in the boss dict as `boss["base_tint"]` when first seen, and restore it.)
- [ ] **Step 5: Failing test** `test/unit/test_boss_perilous.gd`:
```gdscript
extends GutTest
const Boss = preload("res://scripts/ecs/systems/boss_system.gd")

func test_perilous_spec_is_unblockable():
	assert_true(Boss.pattern_spec("perilous").get("unblockable", false))

func test_phase_two_pool_includes_perilous():
	assert_true(Boss.patterns_for_phase(2).has("perilous"))
	assert_false(Boss.patterns_for_phase(1).has("perilous"), "phase 1 has no perilous")
```
RED → implement → GREEN.
- [ ] **Step 6:** `--import`; suite green; boot clean. **Commit:** `feat: boss perilous pattern + telegraph cue (Crimson Ronin phase 2)`.

---

## Task 3: Oni Warlord — second boss, is_final victory, level extension

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/boss_system.gd`, `scripts/main/main.gd`, `scripts/levels/level_one.gd`; Tests `test/unit/test_oni_warlord.gd` (+ update `test_boss_spawn.gd` and any boss-win test).

- [ ] **Step 1: boss component** — in `components.gd.boss(...)` add `"is_final": true,` and `"kind": "crimson_ronin",`.
- [ ] **Step 2: Warlord pattern pool** — in `boss_system.gd`, add a kind-aware pool:
```gdscript
static func patterns_for(kind: String, phase: int) -> Array:
	if kind == "oni_warlord":
		return ["perilous", "combo", "lunge", "slash"] if phase >= 2 else ["slash", "perilous", "lunge"]
	return patterns_for_phase(phase)
```
In `process()`, replace the `pick_pattern(boss.phase, _tick)` call with one that uses the boss kind:
```gdscript
	var pool := patterns_for(boss.get("kind", "crimson_ronin"), boss.phase)
	boss.pattern = pool[_tick % pool.size()]
```
(Keep `pick_pattern` for back-compat/tests, or update its callers — ensure the existing `test_boss_system.gd` still passes; if it tests `pick_pattern`, leave that function intact.)
- [ ] **Step 3: Generalize `_spawn_boss`** in `main.gd` to `func _spawn_boss(position: Vector2, kind: String = "crimson_ronin") -> int:` with a per-kind config:
```gdscript
	var cfg := {
		"crimson_ronin": {"name": "Crimson Ronin", "hp": 320, "tint": Color(1.0, 0.25, 0.25), "scale": 1.8, "dmg": 22, "final": false},
		"oni_warlord":   {"name": "Oni Warlord",   "hp": 480, "tint": Color(0.55, 0.4, 0.7), "scale": 2.3, "dmg": 28, "final": true},
	}.get(kind, {})
```
Use `cfg` for the node name (sanitized), `node.scale`, `spr.modulate = cfg.tint`, `Components.health(cfg.hp)`, `Components.weapon(cfg.dmg, 0.5)`, `Components.enemy(kind)`, `Components.boss(cfg.name)`; then set the boss component's `kind = kind` and `is_final = cfg.final`. Emit `GameEvents.ui_show_message`/`boss_spawned`/`boss_health` with `cfg.name`/`cfg.hp`. (Crimson Ronin keeps hp 320 but is now NOT final.)
- [ ] **Step 4: Generalize the arena boss branch** in BOTH `_activate_arena` and `_restore_arena`:
```gdscript
		if spec[0] == "crimson_ronin" or spec[0] == "oni_warlord":
			ids.append(_spawn_boss(spec[1], spec[0]))
		else:
			ids.append(_spawn_enemy(spec[1], spec[0]))
```
- [ ] **Step 5: Victory only on the final boss** — in `_finish_enemy_death`, change the boss-win guard to require `is_final`:
```gdscript
	var b = ECS.get_component(eid, "boss")
	if b and b.get("is_final", true) and not _won:
		_won = true
		GameEvents.boss_defeated.emit()
		GameState.win_run()
		get_tree().paused = true
```
(So killing the Crimson Ronin clears its arena but does NOT win; the player proceeds to the Oni Warlord.)
- [ ] **Step 6: Extend the level** in `level_one.gd`:
  - `const EXTENT_X := 5200.0`, `const GOAL_X := 4950.0`.
  - Update the floor platform to span the new width centered correctly: `[Vector2(EXTENT_X / 2.0, FLOOR_Y + 16), Vector2(EXTENT_X, 32)]`.
  - Append a 4th arena (Oni Warlord) to `arenas()`:
```gdscript
			{"trigger_x": 4050.0, "checkpoint": Vector2(4000, 540), "enemies": [
				["oni_warlord", Vector2(4450, 540)]]},
```
- [ ] **Step 7: Update affected tests.**
  - `test/unit/test_boss_spawn.gd` asserts the final arena is `crimson_ronin` → change to `oni_warlord`.
  - If any test (e.g. a win-condition test) asserts Crimson Ronin's death wins, update it to reflect that only the final boss (Oni Warlord) wins. Run the full suite and fix any roster/size/index assertions that the 4th arena changes (legitimate updates).
- [ ] **Step 8: Failing test** `test/unit/test_oni_warlord.gd`:
```gdscript
extends GutTest
const Boss = preload("res://scripts/ecs/systems/boss_system.gd")

func test_final_arena_is_oni_warlord():
	var arenas = LevelOne.arenas()
	assert_eq(arenas[arenas.size() - 1].enemies[0][0], "oni_warlord")

func test_warlord_uses_perilous_from_phase_one():
	assert_true(Boss.patterns_for("oni_warlord", 1).has("perilous"))
```
RED → implement → GREEN.
- [ ] **Step 9:** `--import`; full suite green; boot check (`15`? systems unchanged at 14; MENU; no SCRIPT ERROR). **Commit:** `feat: Oni Warlord second boss (perilous-heavy) + is_final two-boss finale + extended level`.

---

## Task 4: Review

- [ ] Full suite green; boot clean.
- [ ] Montage (temp `tools/`, deleted after):
  - Spawn a boss doing a perilous attack vs a **blocking** player → confirm via logs the player still takes damage (perilous bypasses block); repeat with the player **invincible** (dodge) → no damage.
  - Teleport the player to the final arena (x≈4060) → confirm an `oni_warlord` boss spawns (bigger, purple) and its `boss.is_final == true`; screenshot it (`tools/warlord.png`).
  - Confirm killing the Crimson Ronin does NOT set VICTORY, but killing the Oni Warlord (set its health 0 + finish) DOES (`GameState.current_state == VICTORY`).
  - No SCRIPT ERROR. Delete `tools/`.
- [ ] **Commit** any fixes.

## Definition of Done
- [ ] Perilous attacks bypass parry/block but are avoided by dodging (i-frames); they have a bright telegraph cue.
- [ ] Crimson Ronin throws perilous attacks in phase 2 (mid-boss now); the **Oni Warlord** is the perilous-heavy final boss.
- [ ] Two-boss finale: Crimson Ronin → Oni Warlord; only the Warlord's death wins.
- [ ] Level extended so both fit before the goal.
- [ ] All tests pass; clean boot; ~60 FPS.
- [ ] (Bosses reuse tinted/scaled FreeKnight frames — bespoke art is a future item; perilous cue is a tint flash, not bespoke VFX.)
