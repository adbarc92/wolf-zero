# Wolf-Zero Vertical Slice — P3: Roster + Traversal — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Broaden the fight and the movement: a ranged **Cyber-Ashigaru** firing projectiles (parryable), an armored **Oni Mech** + an **Elite** variant, and **wall-slide / wall-jump** traversal — so the full melee+traversal+Echo+parry kit is exercised against a real roster.

**Architecture:** Build on P0–P2. A new `ProjectileSystem` owns projectile entities (kinematic, like the echo — exempt from PhysicsSync). Ranged enemies fire projectiles from `AISystem._process_attack`. Enemy **archetypes** parameterize `_spawn_enemy`. Wall mechanics extend `MovementSystem` (wall-slide cap + wall-climb) and rely on the existing `JumpSystem` wall-jump (now fed by PhysicsSync's `on_wall`). The CombatInput/HitboxResolution split is **not** needed (projectiles resolve their own collisions; melee/echo already resolve correctly via ordering) — deferred indefinitely unless a future system requires it.

**Tech Stack:** Godot 4.6, GDScript, GUT. Godot binary `C:\Godot\Godot_v4.6.1-stable_win64.exe` (NOT on PATH). Tests: `... -gtest=res://test/<path>.gd`; suite `-gconfig=res://.gutconfig.json`. New `class_name` → `--import` once before tests compile.

**Spec:** `docs/superpowers/specs/2026-06-04-vertical-slice-design.md` (phase **P3**; enemies §7; G6 projectiles; wall-run §3.3).

**Branch:** `feat/vertical-slice` (continues from P2; HEAD ~`7277d62`).

---

## Verified current state

- `MovementSystem` (movement_system.gd): gravity in `_apply_gravity`; `_update_platformer_timers` decrements `wall_run_timer` while `on_wall && !on_ground` but **nothing uses it** (no wall-slide/climb). PhysicsSync now sets `collision.on_wall`/`wall_direction`, so `JumpSystem._try_jump`'s wall-jump branch is live — but the test scene has **no walls**.
- `AISystem._process_attack` (P1/P2): opens a melee hitbox + faces target. No ranged path. `enemy` component has no `is_ranged`. `ai` has `stagger` state (P2).
- `_spawn_enemy(position, enemy_type)` (main.gd:189): hardcodes health 50, weapon (10, 0.5), `platformer`, `ai("patrol")`, frame_set "enemy". Only `ronin_drone` is ever spawned.
- `CombatSystem.apply_damage_to(target_id, damage, source_id=-1)` exists (emits `entity_damaged`/`entity_died`, respects invincibility). `parry` component has `is_parrying`.
- Projectiles: no component/system. `tag_projectile` factory exists (`Components.tag_projectile`). Physics layers declared but unused (combat is distance-based).
- Echo precedent: kinematic entity with a Node2D, exempt from PhysicsSync (it's not a CharacterBody2D), position set directly.

---

## File structure (P3)

| File | Responsibility | Tasks |
|------|----------------|-------|
| `scripts/ecs/components.gd` | `projectile()`; `enemy.is_ranged` | T1, T2 |
| `scripts/ecs/systems/projectile_system.gd` | move/lifetime/hit/parry-reflect | T2 (create) |
| `scripts/ecs/systems/ai_system.gd` | ranged enemies fire projectiles | T3 |
| `scripts/ecs/systems/movement_system.gd` | wall-slide + wall-climb | T4 |
| `scripts/main/main.gd` | archetypes; roster spawn; test wall; register systems | T5 |
| tests | per task | all |

---

## Task 1: Projectile component + the `is_ranged` enemy flag

**Files:** Modify `scripts/ecs/components.gd`. (No test — these are data factories exercised by later tasks.)

- [ ] **Step 1: Add a `projectile()` factory** (place near `weapon()`):
```gdscript
## Projectile (kinematic, travels in a direction until it hits or expires)
static func projectile(damage: int = 8, speed: float = 600.0, team: String = "enemy") -> Dictionary:
	return {
		"damage": damage,
		"speed": speed,
		"direction": 1,        # -1 left, 1 right
		"team": team,          # "enemy" projectiles hit players; "player" hit enemies
		"lifetime": 3.0,
		"elapsed": 0.0,
		"radius": 16.0,        # hit radius
	}
```

- [ ] **Step 2: Add `is_ranged` to the `enemy()` factory**:
```gdscript
		"facing": 1,
		"is_ranged": false,
```
(Insert `is_ranged` after `facing`.)

- [ ] **Step 3: Parse check** — `--headless --check-only --script scripts/ecs/components.gd` (or run the full suite; it must still pass: 18 scripts / 28 tests).

- [ ] **Step 4: Commit**
```bash
git add scripts/ecs/components.gd
git commit -m "feat: projectile component factory and enemy is_ranged flag"
```

---

## Task 2: ProjectileSystem (travel, lifetime, hit, parry-reflect)

**Why:** G6 — ranged attacks need a real projectile entity with its own movement and collision (distance-based, consistent with the rest of combat). Parrying reflects the projectile.

**Files:** Create `scripts/ecs/systems/projectile_system.gd`; Test `test/integration/test_projectile.gd`.

- [ ] **Step 1: Write the failing test** `test/integration/test_projectile.gd`
```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func _player(ecs, x):
	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(x, 0))
	ecs.add_component(p, "health", Components.health(100))
	ecs.add_component(p, "tag_player", Components.tag_player())
	return p

func _projectile(ecs, x, dir, team):
	var pr = ecs.create_entity()
	ecs.add_component(pr, "position", Components.position(x, 0))
	var data = Components.projectile(8, 600.0, team); data.direction = dir
	ecs.add_component(pr, "projectile", data)
	ecs.add_component(pr, "tag_projectile", Components.tag_projectile())
	return pr

func test_enemy_projectile_travels_and_damages_player():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)

	var p = _player(ecs, 50)
	var pr = _projectile(ecs, 0, 1, "enemy")   # moving right toward player at x=50
	var hp = ecs.get_component(p, "health").current

	# Advance until it reaches the player (600 px/s; ~0.1s)
	for i in range(10):
		proj.process(1.0 / 60.0)

	assert_lt(ecs.get_component(p, "health").current, hp, "enemy projectile damages the player")
	assert_false(ecs.entity_exists(pr), "projectile is consumed on hit")

func test_parry_reflects_projectile_to_player_team():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)

	var p = _player(ecs, 20)
	var parry = Components.parry(); parry.is_parrying = true
	ecs.add_component(p, "parry", parry)
	var pr = _projectile(ecs, 0, 1, "enemy")

	for i in range(6):
		proj.process(1.0 / 60.0)

	# On a parried hit the projectile survives, flips to player team, reverses
	assert_true(ecs.entity_exists(pr), "parried projectile is not consumed")
	assert_eq(ecs.get_component(pr, "projectile").team, "player", "reflected to player team")
	assert_eq(ecs.get_component(pr, "projectile").direction, -1, "reversed direction")
	assert_eq(ecs.get_component(p, "health").current, 100, "parry negates projectile damage")

func test_projectile_expires_after_lifetime():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var combat := CombatSystem.new(); ecs.register_system(combat)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)
	var pr = _projectile(ecs, 0, 1, "enemy")
	ecs.get_component(pr, "projectile").lifetime = 0.05
	proj.process(0.1)
	assert_false(ecs.entity_exists(pr), "projectile expires after its lifetime")
```

- [ ] **Step 2: Run — expect FAIL** (`ProjectileSystem` missing).

- [ ] **Step 3: Create `scripts/ecs/systems/projectile_system.gd`**
```gdscript
class_name ProjectileSystem
extends ECSSystem
## Moves projectile entities, expires them, and resolves hits against the
## opposite team (distance-based). A parrying target reflects the projectile.

signal projectile_hit(projectile_id: int, target_id: int)
signal projectile_reflected(projectile_id: int)


func _get_required_components() -> Array[String]:
	return ["projectile", "position"]


func process(delta: float) -> void:
	# Iterate a copy of ids since we may destroy during iteration.
	var ids: Array = get_entities().duplicate()
	for pid in ids:
		if not ecs.entity_exists(pid):
			continue
		var proj = get_component(pid, "projectile")
		var pos = get_component(pid, "position")

		# Travel
		pos.x += float(proj.direction) * proj.speed * delta
		_sync_node(pid, pos)

		# Lifetime
		proj.elapsed += delta
		if proj.elapsed >= proj.lifetime:
			_destroy(pid)
			continue

		# Collision vs opposite team
		var target_tag := "tag_player" if proj.team == "enemy" else "tag_enemy"
		for tid in ecs.get_entities_with(target_tag):
			var tpos = ecs.get_component(tid, "position")
			if tpos == null:
				continue
			if abs(tpos.x - pos.x) > proj.radius or abs(tpos.y - pos.y) > 48.0:
				continue
			# Parry reflection
			var tparry = ecs.get_component(tid, "parry")
			if tparry and tparry.is_parrying:
				tparry.is_parrying = false
				proj.team = "player" if proj.team == "enemy" else "enemy"
				proj.direction = -proj.direction
				proj.elapsed = 0.0
				projectile_reflected.emit(pid)
				break
			# Damage
			var combat = ecs.get_system(CombatSystem)
			if combat:
				combat.apply_damage_to(tid, proj.damage, pid)
			projectile_hit.emit(pid, tid)
			_destroy(pid)
			break


## Spawn a projectile entity travelling from `from` toward `dir` for `team`.
func spawn(from: Vector2, dir: int, team: String, damage: int = 8) -> int:
	var node := Node2D.new()
	node.name = "Projectile"
	node.position = from
	if _container():
		_container().add_child(node)
		var rect := ColorRect.new()
		rect.size = Vector2(16, 6)
		rect.position = Vector2(-8, -3)
		rect.color = Color(1.0, 0.4, 0.1) if team == "enemy" else Color(0.0, 0.9, 1.0)
		node.add_child(rect)
	var pid = ecs.create_entity_with_node(node)
	ecs.add_component(pid, "position", Components.position(from.x, from.y))
	var data = Components.projectile(damage, 600.0, team)
	data.direction = dir
	ecs.add_component(pid, "projectile", data)
	ecs.add_component(pid, "tag_projectile", Components.tag_projectile())
	return pid


func _container() -> Node:
	# Spawn into the same parent the entities live under, if any.
	var any_node = null
	var players := ecs.get_entities_with("tag_player")
	if players.size() > 0:
		any_node = ecs.get_entity_node(players[0])
	if any_node and any_node.get_parent():
		return any_node.get_parent()
	return null


func _sync_node(pid: int, pos: Dictionary) -> void:
	var node = get_node(pid)
	if node and node is Node2D:
		node.position = Vector2(pos.x, pos.y)


func _destroy(pid: int) -> void:
	var node = get_node(pid)
	if node:
		node.queue_free()
	ecs.destroy_entity(pid)
```

- [ ] **Step 4: Run the test — expect PASS** (all 3). Then full suite — all pass.

- [ ] **Step 5: Commit**
```bash
git add scripts/ecs/systems/projectile_system.gd scripts/ecs/systems/projectile_system.gd.uid test/integration/test_projectile.gd test/integration/test_projectile.gd.uid
git commit -m "feat: ProjectileSystem with travel, lifetime, hit, and parry-reflect"
```

---

## Task 3: Ranged enemies fire projectiles

**Why:** The Cyber-Ashigaru pressures the player from range, forcing gap-closing or Echo use.

**Files:** Modify `scripts/ecs/systems/ai_system.gd`; Test `test/integration/test_ranged_enemy.gd`.

- [ ] **Step 1: Write the failing test** `test/integration/test_ranged_enemy.gd`
```gdscript
extends GutTest

var ECSScript = preload("res://scripts/ecs/ecs.gd")

func test_ranged_enemy_in_attack_state_spawns_a_projectile():
	var ecs = ECSScript.new(); add_child_autofree(ecs)
	var ai := AISystem.new(); ecs.register_system(ai)
	var proj := ProjectileSystem.new(); ecs.register_system(proj)

	var p = ecs.create_entity()
	ecs.add_component(p, "position", Components.position(0, 0))
	ecs.add_component(p, "tag_player", Components.tag_player())

	var e = ecs.create_entity()
	ecs.add_component(e, "position", Components.position(200, 0))
	ecs.add_component(e, "velocity", Components.velocity())
	ecs.add_component(e, "weapon", Components.weapon(8, 0.5))
	var enemy = Components.enemy("cyber_ashigaru"); enemy.is_ranged = true
	ecs.add_component(e, "enemy", enemy)
	var ai_c = Components.ai("chase"); ai_c.state = "attack"; ai_c.target_entity = p
	ecs.add_component(e, "ai", ai_c)
	ecs.add_component(e, "tag_enemy", Components.tag_enemy())

	assert_eq(ecs.get_entities_with("tag_projectile").size(), 0, "no projectiles before")
	ai.process(0.016)
	assert_eq(ecs.get_entities_with("tag_projectile").size(), 1, "ranged enemy fired one projectile")
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Branch on `is_ranged` in `AISystem._process_attack`**

In `ai_system.gd._process_attack`, after computing `enemy.facing` toward the target and BEFORE opening the melee hitbox, add a ranged branch that fires a projectile instead:
```gdscript
		if enemy and enemy.get("is_ranged", false):
			var proj_sys = ecs.get_system(ProjectileSystem)
			if proj_sys:
				var dir = enemy.facing
				var from = Vector2(pos.x + dir * 30.0, pos.y)
				var dmg = weapon.damage if weapon else 8
				proj_sys.spawn(from, dir, "enemy", dmg)
			ai.attack_cooldown = 1.2
			ai.state = "chase"
			if enemy:
				enemy.is_telegraphing = false
				enemy.telegraph_timer = 0.0
			return
```
(Place this right after the block that sets `enemy.facing`, so the facing is correct; keep the existing melee logic below it for non-ranged enemies.)

- [ ] **Step 4: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 5: Commit**
```bash
git add scripts/ecs/systems/ai_system.gd test/integration/test_ranged_enemy.gd test/integration/test_ranged_enemy.gd.uid
git commit -m "feat: ranged enemies fire projectiles on attack"
```

---

## Task 4: Wall-slide + wall-climb

**Why:** Traversal flavor. Wall-jump is already live (JumpSystem + PhysicsSync `on_wall`); add wall-slide (capped fall while pressed against a wall) and a brief wall-climb (hold jump while the wall-run timer lasts).

**Files:** Modify `scripts/ecs/systems/movement_system.gd`; Test `test/unit/test_wall_slide.gd`.

- [ ] **Step 1: Write the failing test** `test/unit/test_wall_slide.gd`
```gdscript
extends GutTest

const Move = preload("res://scripts/ecs/systems/movement_system.gd")

func test_wall_slide_caps_fall_speed():
	# Falling fast while on a wall → capped to the slide speed.
	assert_almost_eq(Move.wall_adjust_velocity_y(900.0, true, false, 120.0), 120.0, 0.01,
		"fast fall on a wall is capped to slide speed")

func test_no_wall_no_change():
	assert_almost_eq(Move.wall_adjust_velocity_y(900.0, false, false, 120.0), 900.0, 0.01,
		"off a wall, vertical velocity is unchanged")

func test_wall_climb_overrides_with_upward_velocity():
	# Holding jump with climb available → upward velocity.
	assert_lt(Move.wall_adjust_velocity_y(50.0, true, true, 120.0), 0.0,
		"climbing produces upward (negative) velocity")
```

- [ ] **Step 2: Run — expect FAIL** (`wall_adjust_velocity_y` missing).

- [ ] **Step 3: Add the pure helper + apply it in `process()`**

Add the static helper to `movement_system.gd`:
```gdscript
## Adjust vertical velocity for wall interactions.
## on_wall: touching a wall and airborne. climbing: holding the climb input with time left.
static func wall_adjust_velocity_y(vy: float, on_wall: bool, climbing: bool, slide_speed: float) -> float:
	if not on_wall:
		return vy
	if climbing:
		return -slide_speed * 1.5   # climb upward
	return min(vy, slide_speed)     # cap downward slide
```
In `process()`, after the gravity block (`if platformer: _apply_gravity(...)`), apply the wall adjustment for entities on a wall:
```gdscript
		# Wall slide / climb
		if platformer and collision and collision.on_wall and not collision.on_ground:
			var climbing := input != null and input.jump_pressed and platformer.wall_run_timer > 0.0
			vel.y = wall_adjust_velocity_y(vel.y, true, climbing, 120.0)
```

- [ ] **Step 4: Run the test — expect PASS.** Full suite — all pass.

- [ ] **Step 5: Commit**
```bash
git add scripts/ecs/systems/movement_system.gd test/unit/test_wall_slide.gd test/unit/test_wall_slide.gd.uid
git commit -m "feat: wall-slide and wall-climb"
```

---

## Task 5: Enemy archetypes, roster spawn, test wall, register systems

**Why:** Spawn the actual roster (Ronin Drone, Cyber-Ashigaru, Oni Mech, Elite) with distinct stats; register the new systems; add a wall so traversal is exercisable.

**Files:** Modify `scripts/main/main.gd`; Test `test/unit/test_archetypes.gd`.

- [ ] **Step 1: Write the failing test** `test/unit/test_archetypes.gd`
```gdscript
extends GutTest

const Main = preload("res://scripts/main/main.gd")

func test_archetype_table_has_the_roster():
	var a = Main.archetype("oni_mech")
	assert_true(a.has("health") and a.has("armor_hits"), "oni_mech has health + armor")
	assert_gt(a.armor_hits, 0, "oni is armored")
	assert_true(Main.archetype("cyber_ashigaru").is_ranged, "ashigaru is ranged")
	assert_gt(Main.archetype("elite_oni").health, Main.archetype("oni_mech").health,
		"elite is tougher than a normal oni")
```

- [ ] **Step 2: Run — expect FAIL** (`archetype` missing).

- [ ] **Step 3: Add an archetype table + apply it in `_spawn_enemy`**

Add a static archetype table to `main.gd`:
```gdscript
static func archetype(kind: String) -> Dictionary:
	match kind:
		"cyber_ashigaru":
			return {"health": 30, "damage": 8, "speed": 260.0, "armor_hits": 0,
				"is_ranged": true, "detection": 420.0, "attack_range": 320.0, "tint": Color(0.7, 1.0, 0.8)}
		"oni_mech":
			return {"health": 120, "damage": 20, "speed": 140.0, "armor_hits": 3,
				"is_ranged": false, "detection": 300.0, "attack_range": 60.0, "tint": Color(1.0, 0.6, 0.5)}
		"elite_oni":
			return {"health": 200, "damage": 26, "speed": 170.0, "armor_hits": 4,
				"is_ranged": false, "detection": 380.0, "attack_range": 64.0, "tint": Color(1.0, 0.3, 0.3)}
		_:  # ronin_drone
			return {"health": 50, "damage": 10, "speed": 200.0, "armor_hits": 0,
				"is_ranged": false, "detection": 300.0, "attack_range": 50.0, "tint": Color.WHITE}
```
In `_spawn_enemy`, after the existing component adds, apply the archetype. Replace the hardcoded health/weapon/enemy setup with archetype-driven values (read the current code and adapt; key changes):
```gdscript
	var arch := archetype(enemy_type)
	var base_health = int(arch.health)
	if GameState.is_solo:
		base_health = int(base_health * 0.85)
	ECS.add_component(entity_id, "health", Components.health(base_health))
	ECS.add_component(entity_id, "weapon", Components.weapon(int(arch.damage), 0.5))
	ECS.add_component(entity_id, "platformer", Components.platformer())
	ECS.add_component(entity_id, "ai", Components.ai("patrol"))
	ECS.add_component(entity_id, "enemy", Components.enemy(enemy_type))
	# Apply archetype
	var vel = ECS.get_component(entity_id, "velocity"); vel.max_speed = arch.speed
	var enemy = ECS.get_component(entity_id, "enemy")
	enemy.is_ranged = arch.is_ranged
	enemy.has_armor = arch.armor_hits > 0
	enemy.armor_hits = arch.armor_hits
	var ai = ECS.get_component(entity_id, "ai")
	ai.detection_range = arch.detection
	ai.attack_range = arch.attack_range
	ECS.get_component(entity_id, "sprite").modulate = arch.tint
```
(Keep the existing patrol-points setup that follows.)

- [ ] **Step 4: Register the new systems** in `_initialize_ecs`. Add `ProjectileSystem` after `CombatSystem`:
```gdscript
	ECS.register_system(CombatSystem.new())
	ECS.register_system(ProjectileSystem.new())
	ECS.register_system(MomentumSystem.new())
```
(WallSystem isn't separate — wall logic lives in MovementSystem, already registered.)

- [ ] **Step 5: Spawn a small roster + a test wall** in `_spawn_test_scene` / `_create_test_platforms`. Replace the single enemy spawn with a few:
```gdscript
	_spawn_enemy(Vector2(600, 400), "ronin_drone")
	_spawn_enemy(Vector2(1000, 400), "cyber_ashigaru")
	_spawn_enemy(Vector2(1400, 400), "oni_mech")
```
And add a vertical wall in `_create_test_platforms` (a tall StaticBody2D) so wall-slide/jump are usable:
```gdscript
	_add_platform(Vector2(1700, 450), Vector2(40, 300))  # tall wall
```
(Confirm `_add_platform(position, size)` exists with that signature; if it differs, adapt.)

- [ ] **Step 6: Verify** — `--import`, full suite green, 3s headless run clean (`ECS initialized with 13 systems`, player + 3 enemies spawn, no SCRIPT ERROR).

- [ ] **Step 7: Commit**
```bash
git add scripts/main/main.gd test/unit/test_archetypes.gd test/unit/test_archetypes.gd.uid
git commit -m "feat: enemy archetypes, roster spawn, test wall, register ProjectileSystem"
```

---

## Task 6: Final P3 review + smoke test

- [ ] **Step 1: Full suite green.**
- [ ] **Step 2: Clean 3s headless run** (13 systems, player + 3 enemies, no SCRIPT ERROR).
- [ ] **Step 3: Screenshot** — confirm the roster renders (player + three tinted enemy knights on the floor, a wall on the right).
- [ ] **Step 4: Interactive playtest checklist (user):** the Ashigaru fires orange projectiles (parry with **L** to reflect them back); the Oni Mech shrugs off light hits (use heavy **K** to break armor); wall-slide down the right wall and wall-jump off it.

---

## P3 Definition of Done

- [ ] **Cyber-Ashigaru** fires parryable projectiles (`ProjectileSystem`).
- [ ] **Oni Mech** (armored) + **Elite** archetypes exist and spawn; armor resists light attacks.
- [ ] **Wall-slide** + **wall-jump** work against a wall.
- [ ] A roster of distinct enemies spawns and fights.
- [ ] All tests pass; clean boot; ~60 FPS.

When signed off, proceed to the **P4 plan** (handcrafted Neo Edo level: tilemap, parallax, camera limits, checkpoints + the full-arena enemy-restore respawn; pacing/tuning pass) — the last phase of the slice.
