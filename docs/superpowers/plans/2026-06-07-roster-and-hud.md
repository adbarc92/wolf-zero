# Wolf-Zero — Enemy Roster Completion + HUD Lives — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Autonomous content: finish the documented 5-enemy roster — **Shinobi Ghost** (cloak + blink/flank) and **Tech-Priest** (keep-distance support that heals nearby enemies) — add them to the level, and surface **lives** on the HUD (+ hide the HUD outside PLAYING).

**Architecture:** Both new enemies are AISystem **behaviors** keyed on a new `enemy.behavior` field ("melee" default / "shinobi" / "support"); `_process_chase` branches by behavior, with pure static helpers for the math (TDD-able). Archetypes (`main.archetype`) set the behavior + stats; `_spawn_enemy` applies it. They're added to existing arenas in `LevelOne`. HUD lives + visibility are driven by `GameState` (lives + `state_changed`).

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH; commands self-terminate — `--quit-after`; never background; never leave processes). Tests `... -gtest=res://test/<f>.gd`; suite `-gconfig=res://.gutconfig.json`. `--import` once for new members.

**Branch:** `feat/content` (off `main`). Serves the documented roster (FR-ENM-004 Shinobi, FR-ENM-005 Tech-Priest) and [[wolf-zero-vision]].

**Current AISystem:** states idle/patrol/chase/telegraph/attack/stagger; `_process_chase` handles echo-aggro, target validity, range→telegraph, else move toward target; `_process_attack` opens a melee hitbox or fires a projectile if `enemy.is_ranged`. `enemy` component: type, telegraph_time(0.8), telegraph_timer, is_telegraphing, has_armor, armor_hits, facing, is_ranged. `main.archetype(kind)` → stats incl. damage/speed/detection/attack_range/tint/is_ranged. `_spawn_enemy` applies archetype. `LevelOne.arenas()` has 3 arenas (drones; ashigaru+drone; crimson_ronin boss).

---

## Task 1: HUD lives + hide HUD outside PLAYING

**Files:** `scripts/ui/hud.gd`, `scripts/main/main.gd` (or wherever HUD lives are sourced). Test optional (pure formatting helper).

- [ ] **Step 1:** In `hud.gd`, add a small **lives** display (top-left near the health bar) — e.g. a Label showing `"♥ x{n}"` (or `"LIVES n"`). Add `set_lives(n)`. Drive it: connect to `GameState.state_changed` and/or a new `GameEvents.lives_changed(n)` signal — simplest: in `main`, emit lives on `begin_run`/`lose_life`. Add `GameEvents.lives_changed(lives: int)`; emit it from `main` right after `GameState.begin_run()` (full) and in the death flow after `GameState.lose_life()`. HUD listens → `set_lives`.
- [ ] **Step 2: Hide the HUD outside PLAYING.** The HUD root (CanvasLayer) should be hidden in MENU/VICTORY/GAME_OVER and shown in PLAYING/PAUSED. Connect the HUD to `GameState.state_changed` → set the HUD root `visible = (state in [PLAYING, PAUSED])`. (Pick the HUD's top node; guard nulls.)
- [ ] **Step 3:** Pure helper + test (`test/unit/test_hud_lives.gd`): a static `HUD.lives_text(n) -> String` returning e.g. `"LIVES  %d" % n`; assert `lives_text(3) == "LIVES  3"`. RED→GREEN.
- [ ] **Step 4:** suite green; boot clean. **Commit:** `feat: HUD lives display + hide HUD outside PLAYING`.

---

## Task 2: Shinobi Ghost (cloak + blink/flank)

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/ai_system.gd`, `scripts/main/main.gd` (archetype + spawn behavior), `scripts/levels/level_one.gd`; Test `test/unit/test_shinobi.gd`.

- [ ] **Step 1: enemy fields** in `components.gd.enemy()`: add `"behavior": "melee",`, `"blink_timer": 2.5,`, `"cloak_timer": 0.0,`.
- [ ] **Step 2: pure helper + behavior in `ai_system.gd`.** Add:
```gdscript
## The x just past the player, on the side opposite the shinobi (to flank/teleport behind).
static func blink_target_x(player_x: float, self_x: float, offset: float = 160.0) -> float:
	# blink to the far side of the player
	return player_x + (offset if self_x < player_x else -offset)
```
In `_process_chase`, near the top (after target validity), branch for shinobi:
```gdscript
	if enemy and enemy.get("behavior", "melee") == "shinobi":
		enemy.blink_timer -= _delta
		var spr = get_component(entity_id, "sprite")
		# decay cloak
		if enemy.cloak_timer > 0.0:
			enemy.cloak_timer -= _delta
			if spr: spr.modulate.a = 0.35
		elif spr:
			spr.modulate.a = 1.0
		if enemy.blink_timer <= 0.0 and target_pos:
			pos.x = blink_target_x(target_pos.x, pos.x)
			_sync_node_x(entity_id, pos)   # if a node-sync helper exists; else set node.position via ecs.get_entity_node
			enemy.blink_timer = 2.5
			enemy.cloak_timer = 0.5
			if spr: spr.modulate.a = 0.35
```
(`enemy`, `pos`, `target_pos`, `_delta` are available in `_process_chase` — confirm the param name for delta is `_delta`; if so rename to `delta` and use it. For node sync, after editing `pos.x`, also set the entity node's `position.x` so the blink is visible — `var n = ecs.get_entity_node(entity_id); if n: n.position.x = pos.x`. PhysicsSync will reconcile next frame.) After the shinobi block, fall through to normal chase (range→telegraph→attack melee).
- [ ] **Step 3: archetype + spawn.** In `main.archetype()` add:
```gdscript
		"shinobi_ghost":
			return {"health": 40, "damage": 16, "speed": 300.0, "armor_hits": 0,
				"is_ranged": false, "behavior": "shinobi", "detection": 500.0, "attack_range": 60.0, "tint": Color(0.5, 0.5, 0.7)}
```
In `_spawn_enemy`, after applying other archetype fields: `ECS.get_component(entity_id, "enemy").behavior = arch.get("behavior", "melee")`.
- [ ] **Step 4: add to a level arena.** In `level_one.gd.arenas()`, add a Shinobi to arena 0 (or 1): e.g. arena 0 enemies append `["shinobi_ghost", Vector2(1750, 540)]`.
- [ ] **Step 5: failing test** `test/unit/test_shinobi.gd`:
```gdscript
extends GutTest
const AI = preload("res://scripts/ecs/systems/ai_system.gd")

func test_blink_goes_to_far_side_of_player():
	# shinobi left of player -> blink to player's right (+offset)
	assert_almost_eq(AI.blink_target_x(500.0, 300.0, 160.0), 660.0, 0.01)
	# shinobi right of player -> blink to player's left (-offset)
	assert_almost_eq(AI.blink_target_x(500.0, 900.0, 160.0), 340.0, 0.01)
```
RED→GREEN.
- [ ] **Step 6:** `--import`; suite green; boot clean. **Commit:** `feat: Shinobi Ghost enemy (cloak + blink/flank)`.

---

## Task 3: Tech-Priest (keep-distance support that heals allies)

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/ai_system.gd`, `scripts/main/main.gd`, `scripts/levels/level_one.gd`; Test `test/unit/test_tech_priest.gd`.

- [ ] **Step 1: enemy field** in `enemy()`: add `"support_timer": 3.0,`.
- [ ] **Step 2: pure helper + behavior in `ai_system.gd`.** Add:
```gdscript
## Heal amount clamped so it never exceeds max.
static func support_heal(current: int, max_hp: int, amount: int) -> int:
	return min(max_hp, current + amount)
```
In `_process_chase`, branch for support (before normal approach):
```gdscript
	if enemy and enemy.get("behavior", "melee") == "support":
		# Keep distance from the player.
		if vel and target_pos:
			var to_player = target_pos.x - pos.x
			if abs(to_player) < 260.0:
				vel.x = -sign(to_player) * vel.max_speed   # flee
			else:
				vel.x = 0.0
		# Periodic heal pulse to nearby wounded allies.
		enemy.support_timer -= _delta
		if enemy.support_timer <= 0.0:
			enemy.support_timer = 3.0
			for ally in ecs.get_entities_with("tag_enemy"):
				if ally == entity_id:
					continue
				var apos = ecs.get_component(ally, "position")
				var ah = ecs.get_component(ally, "health")
				if apos and ah and Vector2(apos.x - pos.x, apos.y - pos.y).length() <= 400.0:
					ah.current = support_heal(ah.current, ah.max, 12)
		return  # support doesn't melee-approach
```
(Confirm delta param name; ensure `vel`/`target_pos` are in scope in `_process_chase`.)
- [ ] **Step 3: archetype + spawn.** Add to `archetype()`:
```gdscript
		"tech_priest":
			return {"health": 35, "damage": 6, "speed": 230.0, "armor_hits": 0,
				"is_ranged": false, "behavior": "support", "detection": 520.0, "attack_range": 40.0, "tint": Color(0.7, 0.9, 0.5)}
```
(`_spawn_enemy` already applies `behavior` from Task 2.)
- [ ] **Step 4: add to arena.** In `level_one.gd`, add `["tech_priest", Vector2(2600, 540)]` to arena 1 (the mid arena) so it heals the ashigaru/drone — a real "kill the priest first" fight.
- [ ] **Step 5: failing test** `test/unit/test_tech_priest.gd`:
```gdscript
extends GutTest
const AI = preload("res://scripts/ecs/systems/ai_system.gd")

func test_support_heal_clamps_to_max():
	assert_eq(AI.support_heal(20, 50, 12), 32)
	assert_eq(AI.support_heal(45, 50, 12), 50, "never exceeds max")
```
RED→GREEN.
- [ ] **Step 6:** `--import`; suite green; boot clean. **Commit:** `feat: Tech-Priest enemy (keep-distance support healer)`.

---

## Task 4: Review

- [ ] Full suite green; boot clean (`14 systems`, MENU).
- [ ] Montage (temp `tools/`, deleted after): start level; teleport the player through arena 0 (screenshot the **Shinobi** — bluish, blinks/low-alpha) and arena 1 (screenshot the **Tech-Priest** — greenish, keeps distance; confirm via logs it heals a wounded ally: pre-damage an ally, run frames, read its HP up). Confirm no SCRIPT ERROR. Delete `tools/`.
- [ ] **Commit** any fixes.

## Definition of Done
- [ ] Shinobi Ghost cloaks (low alpha) and blinks to flank the player, then strikes.
- [ ] Tech-Priest keeps its distance and periodically heals nearby enemies (kill-the-priest dynamic).
- [ ] Both spawn in the level; HUD shows **lives** and hides outside PLAYING.
- [ ] All tests pass; clean boot; ~60 FPS.
- [ ] (Both reuse the FreeKnight enemy frames with distinct tints — bespoke art is a future item.)
