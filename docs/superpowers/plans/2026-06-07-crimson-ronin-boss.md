# Wolf-Zero — Crimson Ronin Boss — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** A real boss that proves the parry conceit: the **Crimson Ronin** — a telegraphed-attack duel where the player reads tells, **parries to stagger** him, and punishes the opening. Two phases (faster + new patterns under 50% HP), a boss health bar, and boss death → VICTORY.

**Architecture:** A new `boss` component + `BossSystem` (its own state machine: intro → idle → telegraph → attack → recover, plus a `stagger` opening driven by the player's parry). The boss uses the existing combat hitbox model (opens a weapon hitbox on the attack window) so the player's parry/block/dodge all work against it. The parry branch in `CombatSystem` is extended to stagger a `boss` (not just `ai`). The boss is a scaled, red-tinted FreeKnight ("Crimson Ronin"), spawned as the level's final arena (replacing the placeholder elite). A boss HP bar is added to the HUD. **No new art** — scale + red tint is the boss look (a bespoke boss sprite is a future art item).

**Tech Stack:** Godot 4.6, GDScript, GUT. Binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH; every command self-terminates — `--quit-after` for game runs; never background; never leave processes). Tests `... -gtest=res://test/<f>.gd`; suite `-gconfig=res://.gutconfig.json`. `--import` once for new classes.

**Branch:** `feat/audio` (rolling; HEAD ~`9f1b74e`). Aligns with [[wolf-zero-vision]] (parry-centric).

**Reuses:** combat hitbox model (`weapon.is_attacking/hitbox_active/attack_type`); the parry branch in `CombatSystem._apply_damage` (sets `atk_ai.state="stagger"` — we extend it for `boss`); `_spawn_enemy`/archetypes; `LevelOne.arenas()` (last arena currently `elite_oni`); the dying-state death flow; `GameState.win_run()`.

---

## Task 1: `boss` component + BossSystem + parry-staggers-boss

**Files:** `scripts/ecs/components.gd`, `scripts/ecs/systems/boss_system.gd` (create), `scripts/ecs/systems/combat_system.gd`; Test `test/unit/test_boss_system.gd`.

- [ ] **Step 1: `boss()` factory** in `components.gd`:
```gdscript
## Boss controller state.
static func boss(boss_name: String = "Crimson Ronin") -> Dictionary:
	return {
		"name": boss_name,
		"phase": 1,
		"state": "intro",          # intro, idle, telegraph, attack, recover, stagger
		"state_timer": 1.2,
		"pattern": "",
		"staggered": false,
		"stagger_timer": 0.0,
		"facing": -1,
		"detection_range": 900.0,
	}
```

- [ ] **Step 2: Extend the parry branch in `combat_system.gd`.** In `_apply_damage`'s parry branch, where it does `var atk_ai = get_component(attacker_id, "ai"); if atk_ai: atk_ai.state = "stagger" ...`, ALSO add:
```gdscript
		var atk_boss = get_component(attacker_id, "boss")
		if atk_boss:
			atk_boss.staggered = true
			atk_boss.stagger_timer = 1.4
```

- [ ] **Step 3: Failing test** `test/unit/test_boss_system.gd`:
```gdscript
extends GutTest
const Boss = preload("res://scripts/ecs/systems/boss_system.gd")

func test_phase_two_under_half_hp():
	assert_eq(Boss.phase_for_hp(300, 300), 1)
	assert_eq(Boss.phase_for_hp(151, 300), 1)
	assert_eq(Boss.phase_for_hp(150, 300), 2)
	assert_eq(Boss.phase_for_hp(1, 300), 2)

func test_pattern_pool_grows_in_phase_two():
	assert_eq(Boss.patterns_for_phase(1), ["slash"])
	var p2 = Boss.patterns_for_phase(2)
	assert_true(p2.has("slash") and p2.has("lunge") and p2.size() >= 2, "phase 2 adds patterns")

func test_pattern_spec_has_timings():
	var s = Boss.pattern_spec("slash")
	assert_true(s.has("telegraph") and s.has("active") and s.has("recover") and s.has("damage"))
```
Run RED.

- [ ] **Step 4: Implement `scripts/ecs/systems/boss_system.gd`:**
```gdscript
class_name BossSystem
extends ECSSystem
## Drives entities with a `boss` component: a telegraph->attack->recover loop with
## two phases and a parry-driven stagger opening. Uses the combat weapon hitbox.

signal boss_phase_changed(entity_id: int, phase: int)


func _get_required_components() -> Array[String]:
	return ["boss", "position"]


static func phase_for_hp(current: int, max_hp: int) -> int:
	return 2 if float(current) <= float(max_hp) * 0.5 else 1

static func patterns_for_phase(phase: int) -> Array:
	if phase >= 2:
		return ["slash", "lunge", "combo"]
	return ["slash"]

static func pattern_spec(name: String) -> Dictionary:
	match name:
		"lunge":
			return {"telegraph": 0.6, "active": 0.3, "recover": 0.8, "damage": 26, "lunge": true}
		"combo":
			return {"telegraph": 0.55, "active": 0.5, "recover": 0.6, "damage": 18, "lunge": false}
		_:  # slash
			return {"telegraph": 0.75, "active": 0.2, "recover": 0.85, "damage": 22, "lunge": false}

# A tiny deterministic-ish picker (no Math.random in this env): rotate by an int.
static func pick_pattern(phase: int, tick: int) -> String:
	var pool := patterns_for_phase(phase)
	return pool[tick % pool.size()]


var _tick := 0

func process(delta: float) -> void:
	var players := ecs.get_entities_with("tag_player")
	var player_id: int = players[0] if players.size() > 0 else -1
	var ppos = ecs.get_component(player_id, "position") if player_id >= 0 else null

	for entity_id in get_entities():
		var boss = get_component(entity_id, "boss")
		var pos = get_component(entity_id, "position")
		var health = get_component(entity_id, "health")
		var weapon = get_component(entity_id, "weapon")
		var vel = get_component(entity_id, "velocity")

		# Phase
		if health:
			var ph := phase_for_hp(health.current, health.max)
			if ph != boss.phase:
				boss.phase = ph
				boss_phase_changed.emit(entity_id, ph)

		# Face the player
		if ppos:
			boss.facing = -1 if ppos.x < pos.x else 1

		# Stagger opening (set by the parry branch in CombatSystem)
		if boss.staggered:
			if weapon: weapon.hitbox_active = false
			if vel: vel.x = 0.0
			boss.stagger_timer -= delta
			if boss.stagger_timer <= 0.0:
				boss.staggered = false
				boss.state = "idle"
				boss.state_timer = 0.4
			continue

		boss.state_timer -= delta

		match boss.state:
			"intro", "idle", "recover":
				if weapon: weapon.hitbox_active = false
				if vel: vel.x = 0.0
				if boss.state_timer <= 0.0:
					_tick += 1
					boss.pattern = pick_pattern(boss.phase, _tick)
					boss.state = "telegraph"
					boss.state_timer = pattern_spec(boss.pattern).telegraph
			"telegraph":
				# windup (animation/feedback could read boss.state); approach a bit
				if vel and ppos:
					vel.x = boss.facing * 60.0
				if boss.state_timer <= 0.0:
					var spec := pattern_spec(boss.pattern)
					boss.state = "attack"
					boss.state_timer = spec.active
					if weapon:
						weapon.damage = int(spec.damage)
						weapon.is_attacking = true
						weapon.hitbox_active = true
						weapon.attack_type = "enemy"
					if spec.get("lunge", false) and vel:
						vel.x = boss.facing * 520.0
			"attack":
				if boss.state_timer <= 0.0:
					if weapon:
						weapon.is_attacking = false
						weapon.hitbox_active = false
					boss.state = "recover"
					boss.state_timer = pattern_spec(boss.pattern).recover
```
Run GREEN (`--import`). **Commit:** `feat: boss component + BossSystem (phases, patterns, parry-stagger)`.

(Note: the boss attacker facing is read by `CombatSystem.resolve_facing` via its `enemy` component OR velocity. Give the boss an `enemy` component too in Task 2 so `resolve_facing` uses `enemy.facing`; BossSystem keeps `enemy.facing` in sync — OR rely on velocity. In Task 2, set `enemy.facing` from `boss.facing` each frame, or add boss to resolve_facing. Simplest: Task 2 gives the boss an `enemy` component and BossSystem also writes `enemy.facing = boss.facing`.)

---

## Task 2: Spawn the Crimson Ronin + integrate as the final boss + death→victory

**Files:** `scripts/main/main.gd`, `scripts/levels/level_one.gd`; Test `test/unit/test_boss_spawn.gd`.

- [ ] **Step 1: `_spawn_boss(position)` in `main.gd`** (scaled, red, high HP, boss + enemy + weapon + tags; node scaled 1.8x):
```gdscript
func _spawn_boss(position: Vector2) -> int:
	var node = CharacterBody2D.new()
	node.name = "CrimsonRonin"
	node.position = position
	node.scale = Vector2(1.8, 1.8)
	entities_node.add_child(node)
	var cs = CollisionShape2D.new()
	var shape = RectangleShape2D.new(); shape.size = Vector2(32, 64)
	cs.shape = shape; node.add_child(cs)
	var id = ECS.create_entity_with_node(node)
	ECS.add_component(id, "position", Components.position(position.x, position.y))
	ECS.add_component(id, "velocity", Components.velocity())
	ECS.add_component(id, "collision", Components.collision(32, 64))
	var spr = Components.sprite(); spr.frame_set = "enemy"; spr.modulate = Color(1.0, 0.25, 0.25)
	ECS.add_component(id, "sprite", spr)
	ECS.add_component(id, "health", Components.health(320))
	ECS.add_component(id, "weapon", Components.weapon(22, 0.5))
	ECS.add_component(id, "platformer", Components.platformer())
	var en = Components.enemy("crimson_ronin"); en.facing = -1
	ECS.add_component(id, "enemy", en)
	ECS.add_component(id, "boss", Components.boss("Crimson Ronin"))
	ECS.add_component(id, "tag_enemy", Components.tag_enemy())
	GameEvents.ui_show_message.emit("Crimson Ronin", 2.5)
	return id
```
Also: in `BossSystem.process`, after setting `boss.facing`, sync the enemy facing so `resolve_facing` aims the hitbox: `var en = get_component(entity_id, "enemy"); if en: en.facing = boss.facing`.

- [ ] **Step 2: Make the final arena spawn the boss.** In `level_one.gd.arenas()`, change the last arena's enemies to `[["crimson_ronin", Vector2(3650, 540)]]`. In `main._activate_arena` AND `_restore_arena`, when iterating `arena.enemies`, branch: `if spec[0] == "crimson_ronin": ids.append(_spawn_boss(spec[1])) else: ids.append(_spawn_enemy(spec[1], spec[0]))`.

- [ ] **Step 3: Register BossSystem** in `_initialize_ecs` (after `AISystem`): `ECS.register_system(BossSystem.new())`.

- [ ] **Step 4: Boss death → victory.** In `main._on_entity_died` (or the dying-finish for enemies), detect a boss: if `ECS.has_component(entity_id, "boss")` → trigger the win: `_won = true; GameState.win_run(); get_tree().paused = true`. (Do this when the boss actually dies/finishes dying — put it in `_finish_enemy_death` guarded by the boss component, BEFORE destroying the entity; or in `_on_entity_died` set a flag the finish reads. Keep XP award.)

- [ ] **Step 5: Failing test** `test/unit/test_boss_spawn.gd`:
```gdscript
extends GutTest

func test_final_arena_is_the_boss():
	var arenas = LevelOne.arenas()
	var last = arenas[arenas.size() - 1]
	assert_eq(last.enemies[0][0], "crimson_ronin", "final arena spawns the boss")
```
RED → implement → GREEN.

- [ ] **Step 6:** `--import`; full suite green; boot check clean (still MENU on launch — boss only spawns when the player reaches the final arena). **Commit:** `feat: spawn Crimson Ronin as the final boss; boss death wins`.

---

## Task 3: Boss HP bar + review

**Files:** `scripts/ui/hud.gd` (+ maybe `scenes/ui/hud.tscn`), `scripts/main/main.gd`; Test optional.

- [ ] **Step 1: Boss bar.** Add a top-center boss health bar to the HUD that is hidden unless a boss is active. Simplest, code-only: in `hud.gd`, create a `ProgressBar` (or a styled ColorRect pair) named "BossBar" + a name Label, hidden by default; add methods `show_boss(name)`, `update_boss(current, max)`, `hide_boss()`. Drive it from `main`: when `_spawn_boss` runs, call the HUD to show it; in `main._process` (PLAYING), if a boss entity exists, update its bar from the boss's `health`; on boss death, hide it. Wire via direct reference (`@onready var hud` or find it) or via `GameEvents` (add `boss_spawned(name)`, `boss_health(cur,max)`, `boss_defeated`). Keep it simple and guarded.
- [ ] **Step 2:** Full suite green; boot clean.
- [ ] **Step 3: Review montage** (temp `tools/`, deleted after): start level → teleport the player to the final arena trigger (x≈3350) so the boss spawns → screenshot the boss (big red samurai) + boss bar → force a parry (set the boss to `attack` + player `is_parrying`, run combat) and assert `boss.staggered` becomes true → drop boss HP below 50% and confirm `phase==2` → set boss HP to 0 and confirm VICTORY. Confirm no SCRIPT ERROR. Delete `tools/`.
- [ ] **Commit:** `feat: boss health bar + boss-fight review`.

---

## Definition of Done
- [ ] Reaching the final arena spawns the **Crimson Ronin** (big, red), with a boss HP bar.
- [ ] He cycles telegraphed attacks; **parrying staggers him** into a punish window; under 50% HP he enters **phase 2** (faster + lunge/combo).
- [ ] Defeating him → **VICTORY**.
- [ ] All tests pass; clean boot; ~60 FPS.
- [ ] (Boss art is a scaled/tinted FreeKnight placeholder — a bespoke Crimson Ronin sprite is a future art item.)
