# Wolf-Zero — Defense (Parry + Block) & Lethality — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make defense the heart of combat (the game's conceit). Unify **parry + block** on the one defense button — tap = perfect parry (already built: negate+reflect+stagger), **hold = block** (chip damage, committal, no reflect) — and retune enemies to be **deliberate and dangerous** so reading/defending matters (MMX × Katana-Zero feel; player stays health-pool).

**Architecture:** Extend the existing `parry` component + `ParrySystem` with a `is_blocking` state driven by *holding* the defense action (`parry_held`); the active parry window still fires on the initial *press*. `CombatSystem._apply_damage` gains a block branch (chip multiplier, no knockback/stagger) ordered after the parry branch. Blocking is committal (slowed movement) and shows a guard tint (no dedicated FreeKnight block clip exists — tint is the placeholder cue). A new `blocked` signal drives a block SFX. Lethality is a tuning pass on `main.archetype()` damage + enemy `telegraph_time` + AI `attack_cooldown`.

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH; every command self-terminates — `--quit-after` for game runs; never background; never leave processes). Tests `... -gtest=res://test/<f>.gd`; suite `-gconfig=res://.gutconfig.json`. `--import` once for new members.

**Branch:** `feat/audio` (rolling; HEAD ~`950c5fa`).

**Current defense code:** `parry` component = `{is_parrying, parry_timer, parry_window:0.2, cooldown, cooldown_duration:0.5}`. `input_state.parry_pressed` (just_pressed). `ParrySystem.process`: ticks cooldown; if `is_parrying` ticks the window; elif `parry_pressed && cooldown<=0` opens the window. `CombatSystem._apply_damage`: first branch handles `target_parry.is_parrying` (negate+reflect+stagger+`parried` signal). `SfxGenerator.make(name)` + `AudioManager` build/play SFX; `main._connect_signals` wires combat signals to audio. `main.archetype(kind)` holds enemy stats; `AISystem._process_attack` sets `ai.attack_cooldown` (melee 1.0, ranged 1.2) and enemies have `enemy.telegraph_time` (0.5).

---

## Task 1: Block (hold defense → chip-damage guard)

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/input_system.gd`, `scripts/ecs/systems/parry_system.gd`, `scripts/ecs/systems/combat_system.gd`, `scripts/ecs/systems/movement_system.gd`, `scripts/ecs/systems/animation_system.gd`, `scripts/audio/sfx_generator.gd`, `scripts/audio/audio_manager.gd`, `scripts/main/main.gd`; Tests `test/unit/test_block.gd`.

- [ ] **Step 1: Component fields.** In `components.gd`: add `"parry_held": false,` to `input_state()` (next to `parry_pressed`); add to `parry()`: `"is_blocking": false,` and `"block_damage_mult": 0.3,`.

- [ ] **Step 2: Read the held input.** In `input_system.gd._process_ability_input`, after the parry read: `input.parry_held = Input.is_action_pressed("parry")`.

- [ ] **Step 3: ParrySystem block state.** At the end of the per-entity loop in `process()`, set:
```gdscript
		# Holding the defense button (outside the active parry window) = block.
		parry.is_blocking = input.parry_held and not parry.is_parrying
```
(Block is allowed even during parry cooldown — only a *fresh* parry needs cooldown.)

- [ ] **Step 4: Combat block branch + signal.** In `combat_system.gd`: add `signal blocked(defender_id: int, attacker_id: int)` near the others. In `_apply_damage`, AFTER the parry branch and BEFORE the normal damage math, add:
```gdscript
	var target_block = get_component(target_id, "parry")
	if target_block and target_block.is_blocking:
		var dmg_blocked: int = max(1, int(weapon.damage * target_block.block_damage_mult))
		var th = get_component(target_id, "health")
		if th and not th.invincible:
			th.current -= dmg_blocked
			th.hurt_timer = 0.12
			th.invincible = true
			th.invincibility_timer = th.invincibility_duration
			entity_damaged.emit(target_id, dmg_blocked, th.current)
			if th.current <= 0:
				entity_died.emit(target_id)
		blocked.emit(target_id, attacker_id)
		weapon.hitbox_active = false   # consume the hit; no knockback/stagger
		return
```
(Static helper for testability: add `static func block_damage(raw: int, mult: float) -> int: return max(1, int(raw * mult))` and use it.)

- [ ] **Step 5: Committal movement while blocking.** In `movement_system.gd`, where the crouch move-scale is computed, also slow when blocking:
```gdscript
		if input:
			var move_scale := 1.0
			if input.crouch_pressed and collision and collision.on_ground:
				move_scale = 0.4
			var pc = get_component(entity_id, "parry")
			if pc and pc.get("is_blocking", false) and collision and collision.on_ground:
				move_scale = 0.15
			_apply_input_movement(vel, input, delta, move_scale)
```

- [ ] **Step 6: Guard tint (placeholder visual).** In `animation_system.gd.process`, after computing modulate, if the entity is blocking, override the tint:
```gdscript
		var pc = get_component(entity_id, "parry")
		if pc and pc.get("is_blocking", false):
			anim_node.modulate = Color(0.6, 0.8, 1.0)   # steel-blue guard cue (no block clip in the set)
```
(Apply after the existing `anim_node.modulate = sprite_comp.modulate` line.)

- [ ] **Step 7: Block SFX.** In `sfx_generator.gd.make`, add a case `"block": return from_samples(_noise_burst(0.08, 0.5))` blended with a low tone — e.g. `return from_samples(_mix(_noise_burst(0.08,0.4), _blip(0.10, 180.0, 120.0, 0.4)))`; add a tiny `_mix(a, b)` helper that sums two equal-length-ish arrays (pad to max len). In `audio_manager.gd._ready`, add `"block"` to the built names list. In `main._connect_signals`, connect `combat_system.blocked` → a handler `_on_sfx_blocked(_d,_a)` that `_audio.play("block")`.

- [ ] **Step 8: Failing tests** `test/unit/test_block.gd`:
```gdscript
extends GutTest
const Combat = preload("res://scripts/ecs/systems/combat_system.gd")
var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_block_damage_is_chipped():
	assert_eq(Combat.block_damage(20, 0.3), 6)
	assert_eq(Combat.block_damage(1, 0.3), 1, "minimum 1")

func test_blocking_target_takes_reduced_damage_no_death():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	# attacker (enemy) with an open hitbox
	var a = ecs.create_entity()
	ecs.add_component(a, "position", Components.position(20, 0))
	ecs.add_component(a, "velocity", Components.velocity())
	var w = Components.weapon(20, 0.4); w.is_attacking = true; w.hitbox_active = true; w.attack_type = "enemy"
	ecs.add_component(a, "weapon", w)
	var en = Components.enemy("ronin_drone"); en.facing = -1
	ecs.add_component(a, "enemy", en)
	ecs.add_component(a, "tag_enemy", Components.tag_enemy())
	# blocking player
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "velocity", Components.velocity())
	ecs.add_component(p, "collision", Components.collision(32, 64))
	ecs.add_component(p, "health", Components.health(100))
	var pr = Components.parry(); pr.is_blocking = true
	ecs.add_component(p, "parry", pr)
	ecs.add_component(p, "tag_player", Components.tag_player())
	watch_signals(combat)
	combat.process(0.016)
	var hp = ecs.get_component(p, "health").current
	assert_eq(hp, 100 - 6, "blocked 20-dmg hit chips for 6")
	assert_signal_emitted(combat, "blocked")
```
- [ ] **Step 9:** `--import`, tests PASS, full suite green, boot check clean. **Commit:** `feat: hold-to-block (chip damage) unified with parry on the defense button`.

---

## Task 2: Lethality pass — deliberate, dangerous enemies

**Files:** `scripts/main/main.gd` (`archetype`), `scripts/ecs/components.gd` (`enemy()` telegraph default), `scripts/ecs/systems/ai_system.gd` (attack cadence); Test `test/unit/test_lethality.gd`.

- [ ] **Step 1: Failing test** `test/unit/test_lethality.gd`:
```gdscript
extends GutTest
const Main = preload("res://scripts/main/main.gd")

func test_enemies_hit_harder():
	assert_gte(Main.archetype("ronin_drone").damage, 16, "drones hit hard enough that defense matters")
	assert_gte(Main.archetype("oni_mech").damage, 26)
	assert_gte(Main.archetype("elite_oni").damage, 34)
```
RED.

- [ ] **Step 2: Raise archetype damage** in `main.archetype()`: ronin_drone `damage: 18`, cyber_ashigaru `damage: 14`, oni_mech `damage: 30`, elite_oni `damage: 38`. (Player HP stays 100 → a ronin hit is ~18%, an oni ~30%: every hit matters, blocking/parrying becomes essential.)

- [ ] **Step 3: Clearer, slower telegraphs.** In `components.gd.enemy()`, raise `"telegraph_time"` from 0.5 to **0.8** (more readable windup → parry/block is reactable). In `ai_system.gd._process_attack`, raise the post-attack `ai.attack_cooldown` from `1.0` to **1.5** (melee) and the ranged branch from `1.2` to **1.7** (fewer, weightier attacks).

- [ ] **Step 4:** GREEN; full suite; boot check clean (3 enemies still spawn, no errors). **Commit:** `tune: more deliberate, dangerous enemies (lethality pass)`.

---

## Task 3: Review

- [ ] Full suite green; boot to title clean.
- [ ] Montage (temp `tools/`, deleted after): start level, force the player to block (`Input.action_press("parry")` held ~0.3s) and screenshot the guard tint; have an enemy attack a blocking player and confirm via logs that damage is chipped (read player HP before/after). Confirm no SCRIPT ERROR. Delete `tools/`.
- [ ] **Human step:** play — hold L to block (steel-blue tint, you take chip), tap L at the strike for a perfect parry (negate+reflect+stagger). Enemies now hit hard with clear windups; defense is the core. Tune `block_damage_mult`, `telegraph_time`, and damage to taste.

## Definition of Done
- [ ] Hold defense = block (chip ~30%, committal, no reflect, guard tint + block SFX); tap = perfect parry (unchanged).
- [ ] Enemies hit harder with clearer, slower telegraphs and fewer attacks — defense is essential.
- [ ] All tests pass; clean boot; ~60 FPS.
- [ ] (No dedicated block animation in the FreeKnight set — tint is the placeholder; a real block pose is a future art item.)
