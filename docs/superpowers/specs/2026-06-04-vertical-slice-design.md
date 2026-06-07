# Wolf-Zero Vertical Slice — Design Spec

| Field | Value |
|-------|-------|
| Date | 2026-06-04 |
| Status | Approved (pending written review) |
| Supersedes scope of | CoreDesign.md / Requirements.md for *this build effort only* |
| Branch | `feat/vertical-slice` (based on `feat/import-art-assets`) |

## 1. Purpose

Produce **one polished, playable vertical slice** of Wolf-Zero that proves the core loop is fun
*before* committing to the documented 281-task commercial game. The slice exercises all three
design pillars — fluid melee combat, the Holographic Echo, and Neo Edo atmosphere — in a single
hand-built level. Everything else in the design docs is deferred, not deleted.

This spec is the source of truth for the slice. Where it conflicts with `CoreDesign.md` or
`Requirements.md`, this spec wins for the duration of this effort.

## 2. Decisions (resolved during grilling, 2026-06-04)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Effort scope | Vertical slice of the core loop (documented Phase 1 MVP) |
| 2 | Platform/input | Desktop now (keyboard + gamepad); mobile/touch deferred; input stays abstracted |
| 3 | Co-op | Solo-only; ECS kept multi-entity-friendly for a future 2nd player |
| 4 | Combat identity | Health-pool hack-and-slash (HP bars, combos, momentum) — NOT one-hit-lethal |
| 5 | Mechanic set | Core melee **+ traversal** (wall-jump/wall-run/dash included) |
| 6 | Art | Real animated sprites + a new AnimationSystem, using salvaged FreeKnight pack |
| 7 | Level | One handcrafted ~3–5 min linear Neo Edo level (TileMap + parallax) |
| 8 | Enemies | Three Phase-1 types + a level-ending elite |

## 3. Identity

A 2D side-scrolling hack-and-slash with platforming, set in Neo Edo (cyberpunk feudal Japan).
The player is **Kira**. Health-pool combat with weighty hits; the signature Holographic Echo
deploys a translucent replay of the player's last few seconds of actions for combat and traversal.

## 4. In / Out of scope

**IN:** one handcrafted level · move/jump/wall-jump/wall-run/dash · dodge · light combo · heavy
directional · parry · Holographic Echo · momentum gauge · 3 enemy types + elite · real animated
sprites + AnimationSystem · projectiles (for ranged enemy) · death→checkpoint respawn ·
game-feel polish (hitstop, knockback, screen shake) · pause/restart · 60 FPS.

**OUT (deferred):** co-op & networking · mobile/touch/gesture · weapon roster & switching ·
skill trees · XP/currency economy depth · missions 2–12 · real multi-phase bosses · full menu
suite (title/loadout/armory/mission-select) · audio production · accessibility suite ·
monetization · save system beyond in-level checkpoints.

## 5. The core loop

Traverse (wall-jump / dash) → enter combat arena → read enemy telegraphs → combo / dodge /
parry / deploy Echo to win the exchange → build Momentum → advance → elite encounter →
level-complete win state.

## 6. Mechanics — target behavior and current state

The repo contains a hybrid ECS (entities = int IDs, components = dictionaries, ordered systems
run in `_physics_process`). Build on it; do not rewrite.

> **Reality caveat (round-1 critique).** Many systems exist as *files* but are **non-functional in
> the assembled scene** because the physics bridge is not wired (see Gap G0) and several triggers
> and input actions don't exist (Gap G3). The "State" column below reflects *assembled-scene*
> behavior, not "is there a .gd file". Re-audit every label against an actual play test before the
> plan estimates off it.

| Verb | Target behavior | State (assembled scene) | Work |
|------|-----------------|--------------------------|------|
| Move / horizontal | Accel/friction | logic present but bypasses Godot physics (G0) | fix bridge, tune |
| Jump / gravity / coyote | Variable height, jump-buffer | **non-functional** — `on_ground` never set, so gravity never resets & jump never fires (G0) | fix bridge, then tune |
| Wall-jump | Kick off wall | **non-functional** — `on_wall` never set (G0) | fix bridge, then build/tune |
| Wall-run | Hold + climb wall | **build from scratch** — only an unread countdown timer exists; nothing suppresses gravity or climbs | build `WallSystem`, feed `on_wall` |
| Dash | Burst, cooldown | **build trigger** — dash *movement* coded but `is_dashing` is never set; no `dash` input action | add input + trigger, tune |
| Dodge (roll) | i-frames mid-roll | coded (DodgeSystem); unverified in play | wire input dependable, tune |
| Light combo (5) | Chain + combo bonus | coded (CombatSystem) | tune feel |
| Heavy directional | up/fwd/down, armor-break | coded | tune feel |
| **Parry** | Tap at impact → negate + reflect + stagger | ❌ missing entirely | **build** (see Gap G4 — multi-part) |
| **Holographic Echo** | Record N s; deploy translucent replay that damages enemies + draws aggro | recording/playback work; **combat targeting is broken** (G5) | fix team/targeting/aggro, polish |
| Momentum gauge | Build on hit/dodge/parry; thresholds | coded (MomentumSystem); reachability unverified (G5) | verify it can actually reach 25% in play |

### Known gaps to fix (part of "proper implementation")

- **G0 — CRITICAL: no working physics authority, and the obvious fix is also wrong.**
  `main.gd._spawn_player` (main.gd:78) creates a bare `CharacterBody2D` and never attaches
  `player_controller.gd`, so `move_and_slide()` never runs and `collision.on_ground/on_wall` are
  never written → gravity never resets, jump/wall-jump/wall-run cannot fire. **But simply
  attaching the controller is ALSO wrong (round-2 F1):** `ECS` is an autoload whose
  `_physics_process` (ecs.gd:35) runs *before* any entity node's `_physics_process`, so every
  system would read `on_ground/on_wall` one physics frame stale (jump fires a frame late, wall
  flags always lag). **Resolution:** do NOT split authority across two `_physics_process`
  callbacks. Introduce a single **`PhysicsSyncSystem`** inside the ECS loop, run immediately after
  `MovementSystem`: for each entity with a `CharacterBody2D` node, set `node.velocity` from the
  `velocity` component, call `node.move_and_slide()`, then read `node.position` and
  `is_on_floor/wall/ceiling` back into the `position`/`collision` components — one deterministic
  order, one authority. `MovementSystem` computes velocity ONLY and must stop writing
  `node.position` (remove all four writes at movement_system.gd:51/90/94/100/104).
- **G0b — Dodge & dash integrate position directly, not velocity.** `_apply_dodge_movement`
  (movement_system.gd:90) and `_apply_dash_movement` (line 100) do `pos.x += …` and write
  `node.position`, bypassing velocity. Under `PhysicsSyncSystem` they will double-apply or be
  overwritten. **Resolution:** rewrite both to set `vel.x/vel.y` only; let `PhysicsSyncSystem`
  integrate. Explicit sub-task, separate from G0.
- **G1 — Enemy attacks are unbuilt, not just "unwired".** `AISystem._process_attack` never
  activates a hitbox; and `CombatSystem` only starts attacks from `input_state`, which enemies
  lack. Worse, `_process_hitboxes` derives `facing` from `input_state` and **defaults to 1
  (right)** for input-less entities, so enemy hits and Echo hits resolve as if always facing
  right. **Resolution:** add an enemy-attack path (open/close a hitbox window on
  telegraph→attack) and a facing source for input-less entities (derive from velocity sign or
  target direction).
- **G2 — No render path for the `sprite` component.** Nodes carry a hardcoded `Sprite2D` named
  "Sprite"; nothing reads the `sprite` component's `animation/flip_h/modulate` (EchoSystem and
  the damage-flash *write* them, but no system applies them). **Resolution:** the new
  AnimationSystem must *be* the renderer (own sprite-node creation, map `animation`→SpriteFrames),
  and reconcile the hardcoded `node.get_node("Sprite")` lookups in `main.gd`.
- **G3 — Missing input actions.** `project.godot` defines only move/jump/crouch/attack_light/
  attack_heavy/dodge/echo_activate/pause. **No `dash`, `parry`, or `restart`; `pause` has no
  handler.** **Resolution:** enumerate and add every new action (keyboard + gamepad) plus the
  `input_state` fields and `InputSystem` reads.
- **G4 — Parry is multiple interlocking builds.** Needs: a timing window vs the enemy
  telegraph→attack transition; reflect-vs-melee *and* reflect-vs-projectile; an **enemy stagger
  state/field that does not exist today**; and there is **no parry/block animation in the
  FreeKnight set** (placeholder gap). **Resolution:** break parry into sub-tasks and accept the
  anim gap explicitly.
- **G5 — Echo combat contract is broken AND the echo's physics model is undefined.** The spawned
  echo has neither `tag_player` nor `tag_enemy`, so `_process_hitboxes` treats its targets as
  `tag_player` → the **echo attacks the player**, and its facing defaults right (G1). Aggro draw
  only reads `tag_echo` in the AI `patrol` state, not `chase`. Also two spawn paths disagree:
  `EchoSystem._spawn_echo` (echo_system.gd:102) makes a **nodeless** entity while
  `EntityFactory.create_echo` makes a CharacterBody2D — and playback writes `pos`/`node.position`
  directly (echo_system.gd:159+), which is the opposite of G0's node-as-physics model.
  **Resolution:** declare the echo a **kinematic, non-physics replay entity** — exempt from
  `PhysicsSyncSystem`, sets position directly (it's a replay, shouldn't collide with terrain),
  uses an **`Area2D`** child (created by AnimationSystem) for hitbox/aggro overlap, carries an
  explicit non-player/non-enemy team tag whose hits resolve against `tag_enemy`. Reconcile the two
  spawn paths into one. (The 25% reachability worry is misplaced — see G9 below.)
- **G9 — Momentum desyncs the HUD, not "is it reachable".** 25% ÷ `gain_attack`(5) = 5 hits, hit
  in one combo — easily reachable. The real bug: `CombatSystem._add_momentum` (combat_system.gd:209)
  mutates the component directly and **never emits `momentum_changed`/threshold signals**, while
  `DodgeSystem` routes through `MomentumSystem.add_momentum` which does. So attack-gained momentum
  never updates the HUD (main.gd:319 listens on `momentum_changed`) or fires the echo-ready event.
  **Resolution:** delete CombatSystem's local `_add_momentum`; route all gains through
  `MomentumSystem.add_momentum`.
- **G6 — No projectile subsystem.** Required for the ranged Ashigaru. No projectile movement/
  lifetime/collision exists; physics layers are defined but unused (all combat is distance-based).
  **Resolution:** build `ProjectileSystem` (spawn/travel/lifetime/hit + parry-reflect hook) and a
  ranged AI state, scoped as their own items.
- **G7 — Death/respawn, pause, restart, win-state are unimplemented.** `_on_entity_died` only
  prints for the player; `GameState.current_checkpoint` is a bare int with no position/state; no
  pause handler, no `restart`, no win node. All are load-bearing for the Definition of Done.
  **Resolution:** add checkpoint data (position + arenas cleared), respawn flow, pause, restart,
  and a level-complete trigger as explicit plan items.

## 7. Enemies

| Enemy | Role / teaches | State | Work |
|-------|----------------|-------|------|
| Ronin Drone | Basic telegraphed melee | ✅ AI state machine exists | wire real damage, sprite |
| Cyber-Ashigaru | Ranged pressure → close gap / use Echo | ❌ needs projectile | build ranged AI + ProjectileSystem |
| Oni Mech | Armored/heavy → forces heavy attacks & parry | ✅ armor logic in CombatSystem | wire damage, telegraphs, sprite |
| Elite Oni Mech | Level-ending mini-boss-lite | — | tuned variant (more HP, extra pattern) |

All enemies must have **readable telegraphs** (animation + brief windup) and clear attack audio
cue placeholders. Solo-mode 15% HP reduction already applied in `main.gd`.

## 8. Level

One handcrafted linear level, ~3–5 minutes:
- Godot **TileMap** built from the salvaged **"Sidescroller Shooter – Central City"** tileset, with
  parallax background layers (Central City / MoonlitGraveyard art).
- Layout: opening **traversal stretch** (wall-jump + dash gaps) → **Arena 1** (2–3 Ronin Drones) →
  short traversal → **Arena 2** (Ashigaru on ledges + Drones, forces Echo/gap-closing) →
  **Elite encounter** (Elite Oni Mech) → **level-complete trigger**.
- **Checkpoints** before Arena 1, Arena 2, and the Elite. Camera limits bound to level extents.
- Built as its own scene loaded by `main.gd` instead of the current `_spawn_test_scene` hardcode.

## 9. Technical approach

Build on the existing ECS. **Task zero is a working, playtested physics foundation (G0/G0b)** —
until bodies run real Godot physics under one deterministic authority, nothing else works.

### 9.1 Pinned cross-cutting decisions (resolving round-2 ambiguities)

- **Physics authority = a single in-ECS `PhysicsSyncSystem`** (G0/G0b). Not per-node
  `_physics_process`. Runs right after `MovementSystem`; it owns `move_and_slide` and the
  read-back. `MovementSystem` computes velocity only.
- **Combat collision model = distance/AABB checks in ECS for the *entire* slice** — melee,
  projectiles, parry-window detection, **and the Echo's hitbox** all use component-space overlap
  math (extending the existing `_check_hit` distance model), **not** Area2D/physics-layer overlap.
  Rationale: consistent, cheap, already partly built. Physics layers 7/8 stay unused. **The slice
  introduces zero hitbox/hurtbox Area2D nodes — including the Echo** (this overrides the earlier
  round-2 "echo uses an Area2D" idea; the echo resolves through the same distance pass).
- **Single hitbox-resolution pass (round-3 F1).** Any system that sets `hitbox_active` — player
  attacks, the **enemy-attack window**, and **Echo playback** — must run *before* the one pass
  that resolves hits, or it reads stale flags (the exact bug G0 fixed for physics). Therefore
  split `CombatSystem` into: **CombatInput** (start player attacks, open/refresh windows; runs
  early) and **HitboxResolution** (the single `_process_hitboxes` pass; runs late, after AI,
  Echo, and Projectile have set their flags this frame). See §9.3 for placement.
- **PhysicsSync predicate.** `PhysicsSyncSystem` processes entities whose node is a
  `CharacterBody2D` **and** that do **not** carry `tag_echo`. The Echo is exempt (it's a kinematic
  replay): it sets `position` directly and is rendered by a plain `AnimatedSprite2D` (no
  `CharacterBody2D`, no `velocity` integration — drop the unused `velocity` from the echo or leave
  it inert and documented).
- **Gravity/physics apply to ALL physics bodies, not just the player (round-3 F2).** Enemies
  currently have no `platformer`/`input_state`, so MovementSystem applies them neither gravity nor
  friction and they'd float. Fix: give enemies a minimal gravity-bearing component (add
  `platformer`, or have MovementSystem apply gravity to any entity with `collision`+`velocity`).
  This is a P1 contract item.
- **Node ownership contract (G2/F4):** the **spawn factory** creates *only* the physics node
  (`CharacterBody2D` + `CollisionShape2D`). **`AnimationSystem`** creates and owns the visual
  child (`AnimatedSprite2D`) on first sight of a `sprite` component, applies
  `animation`/`flip_h`/`modulate`, and **owns the damage-flash** (move it out of `main.gd`).
  Delete the placeholder `Sprite2D` creation from `main.gd`/`entity_factory.gd` and re-point the
  `get_node("Sprite")` callers.
- **Pause actually pauses:** `ECS` autoload is `PROCESS_MODE_ALWAYS` (ecs.gd:32), so
  `get_tree().paused` won't freeze systems. Either set it PAUSABLE or gate the system loop on
  `GameState.current_state`. Required for the pause DoD item.
- **Momentum single path (G9):** all gains route through `MomentumSystem.add_momentum` so HUD +
  threshold events fire from combat too.

### 9.2 New / changed pieces

- **`PhysicsSyncSystem`** (new) + **dodge/dash → velocity** rewrite (G0/G0b).
- **`AnimationSystem`** (new, = renderer) + FreeKnight `SpriteFrames` import. No parry/block clip
  exists — accept a placeholder for the parry pose.
- **Enemy-attack model (G1):** generalize the attack/hitbox path off `input_state` so enemies and
  the echo can drive it; open/close an enemy hitbox window on telegraph→attack; facing from
  velocity/target for input-less entities.
- **Input actions (G3):** add `dash`, `parry`, `restart` (keyboard + gamepad) + `input_state`
  fields + reads + dash trigger + a `pause` handler.
- **`ParrySystem`** (new, G4): timing window vs enemy attack; reflect-melee + reflect-projectile;
  new enemy **stagger** field.
- **Echo combat fix (G5):** kinematic non-physics entity, team tag, correct target/facing, aggro
  in `chase`, one spawn path.
- **`ProjectileSystem`** (new, G6) + ranged AI state for the Ashigaru.
- **`WallSystem`** (new): suppress gravity + climb while `on_wall`.
- **Level (split):** (a) TileMap + collision, (b) parallax, (c) camera follow+limits — reconcile
  direct-set `camera.position` (main._process) vs scene `position_smoothing` — (d) arena /
  checkpoint / level-complete trigger volumes.
- **Flow (G7):** checkpoint payload = **player position + per-arena enemy roster to re-spawn**
  (respawn resets the *current* arena so a mid-arena death isn't unwinnable/empty); death→respawn;
  pause; restart; win-state.
- **Game-feel:** `VFXManager` hitstop/shake/sparks; knockback impulse on hit (needs G0).

### 9.3 System execution order

Current: Input → Jump → Dodge → Movement → Combat → Momentum → Echo → Health → AI.

**Target** (note the split combat passes, round-3 F1):
Input → AI → **Parry** → **CombatInput** (opens player + enemy attack windows) → Jump → **Wall** →
Dodge → Movement → **PhysicsSync** → **Echo** (playback sets its hitbox flags) → **Projectile** →
**HitboxResolution** (single pass; reads all flags set above) → Momentum → Health → **Animation**
(last, renderer).

Invariant: **every flag-setter (player/enemy/echo) precedes the one HitboxResolution pass.** This
is what makes the "same-frame" claim actually true (the prior order falsely assumed it). Final
order locked in the plan.

### 9.4 Animation, momentum, and stagger contracts (round-3 F4/F5)

- **Who writes `sprite.animation`:** `AnimationSystem` derives it each frame from component state
  (priority: dodge/dash → attack(`weapon.attack_type`/combo) → airborne(`vel.y`) → run(`vel.x`) →
  idle), so EchoSystem's copied strings stay valid. No other system writes it.
- **Canonical animation set** (maps to FreeKnight clips): `idle, run, jump, fall, dash, roll,
  light_1..light_5, heavy_up, heavy_forward, heavy_down, hit, death, parry(placeholder), wall_slide`.
  The plan defines the exact `SpriteFrames` clip per name; missing clips (parry) fall back to a
  tinted idle/hit pose.
- **Momentum fix (precise):** replace the direct mutations in
  `CombatSystem._add_momentum` call sites — `_start_light_attack` (combat_system.gd:74) **and**
  `_start_heavy_attack` (combat_system.gd:106) — with a `MomentumSystem.add_momentum(...)` lookup
  (the pattern `DodgeSystem` already uses, dodge_system.gd:39-43), then delete the local helper so
  HUD/threshold signals fire from combat.
- **`stagger` is an explicit AI state.** Add `stagger` to the `AISystem` state machine: on parry
  (or heavy armor-break), set `ai.state = "stagger"` + a `stagger_timer`; `process` skips all other
  branches and zeroes `vel.x` until the timer expires, then returns to `chase`. Interrupts any
  in-progress telegraph/attack. ParrySystem (P2) targets this state.

### 9.5 Verification & run path (round-3 F7)

- **Run target:** the project main scene stays `scenes/main/main.tscn`; `main.gd._ready` loads the
  slice level scene **instead of** `_spawn_test_scene` (which is deleted). A tester runs the slice
  by launching the project (F5 in editor) — no menu required for the slice.
- **60 FPS** is measured via `Engine.get_frames_per_second()` shown on a debug overlay, on a named
  target machine (the dev desktop for now; min-spec deferred with mobile). Frame-time budget
  ≤16.6 ms. A drop below 55 FPS in normal play is a defect.
- **"Feels good"** is verified by a per-milestone **playtest checklist** (not vibes): each
  DoD bullets become a literal checklist a tester runs and signs off; the assembled complete slice
  gets a 2–3 person playtest for the holistic fun judgment. Combat feel notes (hitstop length,
  knockback distance, i-frame window) are recorded as tunable numbers in the plan, adjusted between
  playtests.
- **FreeKnight fps/scale:** the echo recording trims at a hardcoded 60 (echo_system.gd:68
  `max_record_time * 60`) — change it to use the physics tick
  (`Engine.physics_ticks_per_second`) so playback duration is tick-independent. The plan must state
  the FreeKnight authored frame rate and the sprite→world scale, and reconcile the 32×64 collision
  box with the actual sprite pixel size (scale the `AnimatedSprite2D`, keep the collision box as
  the gameplay hurtbox of record).

## 10. Build phases — one deliverable, dependency-ordered

**Decision (user, spec review):** the slice ships as **one complete deliverable** with the full §4
IN list (melee **+ traversal**, 3 enemies + elite, parry, Echo) and is evaluated **as a whole** —
the whole point is to feel all the core mechanics interacting (Echo + parry + traversal in real
encounters) before judging fun. There is **no scope re-decision gate**; we build the entire slice.

The phases below are a **dependency-ordered build sequence**, not evaluation gates. The physics
foundation (P0) genuinely must come first because it is currently broken (G0); each phase is
smoke-tested (does it run, no regressions) before the next builds on it, but the *deliverable and
the fun-evaluation playtest* are the complete slice at the end.

- **P0 — Physics & render foundation.** `PhysicsSyncSystem` + dodge/dash-as-velocity +
  `AnimationSystem`/player sprite + momentum/HUD single-path fix + pause-actually-pauses. Dash
  granted in the starting loadout. Smoke test: player runs/jumps/dashes on a tilemap floor at
  60 FPS, animated, pause freezes.
- **P1 — Two-way combat core.** Split combat passes (CombatInput + HitboxResolution); enemy gravity
  (F2); generalized attack path off `input_state`; Ronin Drone telegraphs + deals damage;
  hitstop/shake/knockback; respawn.
- **P2 — Echo + parry.** Echo combat-useful (team/targeting/aggro fix); `ParrySystem` + enemy
  stagger state.
- **P3 — Roster + traversal.** Wall-jump/wall-run (`WallSystem`); Cyber-Ashigaru +
  `ProjectileSystem`; Oni Mech + Elite Oni Mech.
- **P4 — Level + flow + polish.** Full handcrafted level (tilemap, parallax, camera follow+limits);
  checkpoint payload (player position + per-arena enemy roster) + respawn + win trigger; pacing and
  game-feel tuning pass.

**Evaluation:** the §11 Definition of Done is checked once, against the assembled slice, with a
2–3-person playtest. Internal smoke tests run continuously; the holistic "is it fun?" judgment is
made on the whole.

## 11. Definition of done

One DoD, checked against the **assembled complete slice** (§10 phases all done). Launch the level
and play it start-to-finish with keyboard **or** gamepad, at 60 FPS:
1. Traversal (wall-jump, wall-run, dash) feels responsive and clears the gaps.
2. All three enemy types **fight back** and read clearly via telegraphs.
3. Light / heavy / dodge / **parry** / Echo all function and feel weighty (hitstop + shake +
   knockback). *Caveat:* the FreeKnight set has no parry/block clip — parry ships with a
   placeholder pose; "feels weighty" is judged on hitstop/timing, not the parry animation.
4. The Echo is genuinely useful in at least one encounter (e.g. Ashigaru ledge fight).
5. Dying respawns at the most recent checkpoint **with the current arena's enemies restored** (not
   an empty/unwinnable arena).
6. Reaching the end shows a clear win state; **pause genuinely freezes gameplay** (ECS process-mode
   fix) and restart works.

Per-phase **smoke tests** (does it run, no regressions) gate each build phase internally, but the
DoD above is the single acceptance check for the slice as a whole.

## 12. Risks

| Risk | Mitigation |
|------|------------|
| Combat "feel" is subjective and easy to get wrong | Tune against real animated sprites + hitstop early; playtest each arena |
| FreeKnight anim set may not map 1:1 to our verbs | Map closest anims; accept placeholder gaps; note missing anims explicitly |
| Scope creep back toward the full game | This spec's IN/OUT list is the gate; deferred items stay deferred |
| ECS/Godot-node hybrid sync bugs (position authority) | Keep node-as-physics, ECS-as-state convention already established in `player_controller.gd` |

## 13. Out-of-band dependency

The slice depends on the salvaged art on `feat/import-art-assets` (PR #2, unmerged). This branch
is based on it. When PR #2 merges to `main`, rebase `feat/vertical-slice` onto `main`.

## Design Critique Log

Three rounds of independent adversarial review (a fresh subagent each round, each seeing the prior
round's revision). Summary of findings and resolutions.

### Critique Round 1
Reviewed the initial spec against the actual code. Findings (all resolved in §6 gaps G0–G7, §9):
- **F1 (critical):** `player_controller.gd` is never attached in `main.gd._spawn_player`, so
  `move_and_slide` never runs and `on_ground/on_wall` are never set → platforming is non-functional
  in the assembled scene, despite "✅ coded" labels. → Re-audited every state label (§6) to reflect
  *assembled-scene* behavior; made the physics bridge **G0/task-zero**.
- **F2:** wall-run "timers exist" overstates a single unread countdown — it's a from-scratch build.
  → Reclassified as build (`WallSystem`).
- **F3:** enemy damage is unbuilt, not "unwired" — enemies have no `input_state`, and
  `_process_hitboxes` defaults facing to right for input-less entities. → Added enemy-attack model
  + facing source (G1).
- **F4:** no input actions for dash/parry/restart; `pause` has no handler. → Enumerated input
  actions (G3).
- **F5:** Echo activation gating + the spawned echo attacks the *player* (no team tag). → G5.
- **F6:** parry is multiple interlocking builds; no parry clip in FreeKnight. → G4.
- **F7:** AnimationSystem must *be* the renderer; nothing reads the `sprite` component today. → G2.
- **F8/F9/F10:** projectile subsystem missing; death/respawn/pause/win unimplemented; TileMap level
  is several builds. → G6/G7, §9 level split.

### Critique Round 2
Pressure-tested round-1's fixes. Findings (resolved in §9.1 decisions, §10 milestones):
- **F1 (critical):** the proposed "attach controller" fix is *also* wrong — `ECS` autoload's
  `_physics_process` runs before node `_physics_process`, so systems read collision one frame stale.
  → Replaced with a single in-ECS **`PhysicsSyncSystem`** owning `move_and_slide` (§9.1, G0).
- **F2:** dodge/dash integrate position directly and will fight the bridge. → **G0b**: rewrite to
  set velocity only.
- **F3:** the Echo has no node / divergent spawn paths and writes position directly. → Declared a
  kinematic non-physics replay entity, exempt from PhysicsSync (G5).
- **F4:** double node ownership (factory vs AnimationSystem). → Pinned the ownership contract
  (§9.1): factory makes the physics node, AnimationSystem owns the visual child + damage-flash.
- **F5:** combat is point-distance with no real hitboxes, yet parry/projectile assume overlap. →
  Committed to **distance/AABB combat for the whole slice** (§9.1).
- **F6:** momentum desyncs the HUD (CombatSystem bypasses signals); 25% is trivially reachable. →
  **G9**: single momentum path through `MomentumSystem.add_momentum`.
- **F7:** the IN list is most of Phase 1 on an unverified base. → Added **§10 G0-gated milestones**
  (M0 hard gate; M1 = minimal loop-proving cut), preserving the user's scope as the target.
- **F8:** pause won't pause (`PROCESS_MODE_ALWAYS`); checkpoint can't restore destroyed enemies. →
  §9.1 pause fix; §9.2 checkpoint payload includes per-arena enemy roster.

### Critique Round 3
Pressure-tested round-2's fixes for newly-introduced problems. Findings (resolved in §9.1–9.5, §10):
- **F1 (critical):** the new system order re-created the stale-frame bug — the Echo sets its hitbox
  flags *after* the combat resolution pass. → Split `CombatSystem` into **CombatInput** (early) and
  **HitboxResolution** (single late pass); stated the invariant that all flag-setters precede it
  (§9.1, §9.3).
- **F2:** enemies have no `platformer`/gravity component → they'd float under PhysicsSync. → §9.1
  gravity applies to all physics bodies; M1 contract item.
- **F3:** echo physics predicate still ambiguous + an Area2D-vs-distance contradiction. → Pinned the
  PhysicsSync predicate (`CharacterBody2D` and not `tag_echo`); echo uses the **distance** pass; the
  slice introduces **zero** hitbox Area2D nodes (§9.1).
- **F4:** unspecified `sprite.animation` set, combo→anim mapping, and `stagger` semantics. → Added
  §9.4 contracts (AnimationSystem derives `animation`; canonical clip list; `stagger` as an explicit
  AI state).
- **F5:** leftover doc contradictions (Area2D, momentum call sites, dash-by-default). → Fixed inline;
  M0 grants dash in the loadout for objective testability.
- **F6:** M1's respawn depended on M4's arena/checkpoint system. → M1 uses a simple fixed-spawn
  respawn; full checkpoint payload moves to M4 (§10).
- **F7:** no verification approach / run path / FreeKnight scale. → Added §9.5 (run target, FPS via
  engine counter + budget, per-milestone playtest checklist, echo-trim uses physics tick, sprite
  scale vs 32×64 hurtbox).

**Axes round 3 judged sound:** the single-authority `PhysicsSyncSystem`, the momentum single-path
delete-and-reroute, the dodge/dash-as-velocity rewrite, the pause process-mode fix, and the M0
hard-gate concept.
