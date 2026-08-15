# Wolf-Zero — Codebase Digest (for agents)

> Audience: an agent extending / owning this code.
> Source: HEAD `954bac5` (Merge #17, Central City backdrop) · digested 2026-06-20, refreshed 2026-08-13 for PRs #9–#17.
> Verified 2026-08-13 with Godot 4.6.1 (`C:\Godot`): GUT suite **221/221 pass** (61 scripts, 623 asserts); main scene boots headless clean (exit 0); `--import` clean.
> Purpose of this digest: extension / ownership.

## TL;DR
A **Godot 4.6 (Mobile renderer)** 2D cyberpunk hack-and-slash ("Neo Edo"), built on a **custom dictionary-based ECS** in GDScript (14 systems). The shipped artifact is a **two-level vertical slice**: Level One runs right through 4 arenas (2 mobs → mixed roster → Crimson Ronin boss → Oni Warlord finale) to a goal line, then advances to Level Two ("Tetsu Spire") via the `Levels` registry. Signature mechanic is the **parry** (press = reflect+stagger; hold = block/chip), with a **Momentum** gauge and a **Holographic Echo** (record-and-replay clone). Real vendored art/audio/environment replaced the placeholders in June (PRs #15–#17). Heavy test coverage via **GUT** (61 test scripts). The one thing to know first: **systems run in a fixed registration order in [`main.gd:74`](../scripts/main/main.gd#L74) and that order is load-bearing** (e.g. Parry before Combat, PhysicsSync before Echo/Combat).

> ⚠️ **The build has never been visually validated.** Everything above is verified headlessly — imports, tests, boot — which proves structure, not appearance. Character feet alignment, parallax fog placement, and audio balance are all unconfirmed. See [`docs/STATUS.md`](STATUS.md).

## Where to look (navigation index)
| I need to… | Go to |
|------------|-------|
| Understand the ECS core (entities/components/systems) | [`scripts/ecs/ecs.gd`](../scripts/ecs/ecs.gd) |
| See every component's data shape + defaults | [`scripts/ecs/components.gd`](../scripts/ecs/components.gd) |
| Change system execution order / boot the game | [`scripts/main/main.gd:74`](../scripts/main/main.gd#L74) |
| Add/spawn an enemy archetype | [`main.gd:21`](../scripts/main/main.gd#L21) (`archetype()`) + `_spawn_enemy` |
| Tune a level (platforms, arenas, roster, win) | [`scripts/levels/level_one.gd`](../scripts/levels/level_one.gd), [`level_two.gd`](../scripts/levels/level_two.gd) |
| **Add** a level | Subclass [`level.gd`](../scripts/levels/level.gd), register in [`levels.gd`](../scripts/levels/levels.gd) (`_make` + `_ORDER`). No `main.gd` change needed |
| Swap character sprites / add anim clips | [`scripts/render/character_frames.gd`](../scripts/render/character_frames.gd) — one-file edit by design |
| Tune the parallax backdrop (sky, fog bands) | [`scripts/render/scene_backdrop.gd`](../scripts/render/scene_backdrop.gd) (`LAYERS`: scale/offset/scroll) |
| First-run onboarding prompts | [`scripts/ui/tutorial.gd`](../scripts/ui/tutorial.gd) (gated on `player_data.tutorial_seen`) |
| Build for Android / iOS | [`docs/EXPORT.md`](EXPORT.md), `export_presets.cfg` |
| Current project state & next steps | [`docs/STATUS.md`](STATUS.md) |
| Touch combat / damage / armor / knockback | [`scripts/ecs/systems/combat_system.gd`](../scripts/ecs/systems/combat_system.gd) |
| Touch parry/block window | [`scripts/ecs/systems/parry_system.gd`](../scripts/ecs/systems/parry_system.gd) + resolution in [`combat_system.gd:199`](../scripts/ecs/systems/combat_system.gd#L199) |
| Wire UI / cross-system messages | [`scripts/autoload/game_events.gd`](../scripts/autoload/game_events.gd) (signal bus) |
| Save/load, progression, run/life flow, state enum | [`scripts/autoload/game_state.gd`](../scripts/autoload/game_state.gd) |
| Boss phases/patterns | [`scripts/ecs/systems/boss_system.gd`](../scripts/ecs/systems/boss_system.gd) |
| Mobile/touch input | [`scripts/autoload/input_manager.gd`](../scripts/autoload/input_manager.gd), [`scripts/ui/touch_controls.gd`](../scripts/ui/touch_controls.gd) |
| VFX (hitstop, shake, sparks) | [`scripts/autoload/vfx_manager.gd`](../scripts/autoload/vfx_manager.gd) |
| Sprite animation / frame strips | [`scripts/ecs/systems/animation_system.gd`](../scripts/ecs/systems/animation_system.gd), [`scripts/render/sprite_frames_builder.gd`](../scripts/render/sprite_frames_builder.gd) |
| The full (stale) design/task backlog | [`docs/Requirements.md`](Requirements.md), [`docs/DevTasks.md`](DevTasks.md) |

## Architecture
**Shape:** single Godot app. Custom ECS, *not* an addon. **Hybrid** model — each ECS entity is an int ID that optionally owns a Godot `CharacterBody2D` node (`create_entity_with_node`) for physics/rendering; `PhysicsSyncSystem` bridges ECS `position`/`velocity` ↔ the node.

- **Entities** = ints. **Components** = plain `Dictionary` keyed by string name (no classes), built from static factories in `components.gd`. **Systems** = `ECSSystem` subclasses with `process(delta)`, run from `ECS._physics_process`.
- 5 **autoloads** (singletons) declared in [`project.godot`](../project.godot): `ECS`, `GameEvents` (signal bus), `GameState` (save/progression), `InputManager` (touch/gesture), `VFXManager`.
- Decoupling is via **`GameEvents` signals**, not direct calls — systems emit, `main.gd` relays to UI/audio.

| Unit | Path | Purpose |
|------|------|---------|
| ECS core | `scripts/ecs/ecs.gd`, `ecs_system.gd`, `components.gd` | Entity/component/system registry |
| Systems (14) | `scripts/ecs/systems/` | Input, AI, Boss, Parry, Jump, Dodge, Movement, PhysicsSync, Echo, Combat, Projectile, Momentum, Health, Animation |
| Autoloads | `scripts/autoload/` | game_events, game_state, input_manager, vfx_manager |
| Main controller | `scripts/main/main.gd` | Boots ECS, spawns player/enemies/bosses, camera, win/death flow |
| Level data | `scripts/levels/` | `level.gd` base class + `levels.gd` registry + `level_one.gd`, `level_two.gd` |
| UI | `scripts/ui/` | hud, screen_manager, touch_controls, debug_overlay, win_label, tutorial |
| Audio | `scripts/audio/` | audio_manager (asset-driven, procedural fallback) + sfx_generator |
| Render helpers | `scripts/render/` | sprite_frames_builder (slices PNG strips), character_frames (per-character clip table), scene_backdrop (parallax) |
| Tests | `test/unit/` (51), `test/integration/` (10) | GUT specs — 221 tests |
| Scenes | `scenes/main/main.tscn` (main scene), `scenes/ui/hud.tscn` | — |

## Key flows
### Boot → play
`main._ready()` → registers 14 systems in order ([`main.gd:74`](../scripts/main/main.gd#L74)) → builds SpriteFrames via `CharacterFrames` → adds AudioManager, ScreenManager, TouchControls, DebugOverlay, and (first run only) `Tutorial` → `GameState.current_state = MENU`. Press jump/accept on MENU → [`_start_level`](../scripts/main/main.gd#L146) → `_level = Levels.create(GameState.current_level_id)`, spawn player at `_level.spawn`, build platforms, set camera limits from `_level.extent_x`/`floor_y`.

Nothing in `main.gd` names a concrete level: it holds a `_level: Level` and asks the registry. Adding a level is a subclass plus a registry entry.

### Frame loop
`ECS._physics_process(delta)` ([`ecs.gd:35`](../scripts/ecs/ecs.gd#L35)) iterates `_systems` in registration order, calling `system.process(delta)` if enabled. Order matters: Input → AI/Boss (decide intent) → Parry (open window) → Jump/Dodge/Movement (kinematics) → PhysicsSync (write to node, run `move_and_slide`, read back) → Echo → Combat (hitboxes/damage, **reads parry state**) → Projectile → Momentum → Health → Animation.

### Attack → damage → death (the core combat path)
`CombatSystem._process_attack_inputs` starts an attack (sets `weapon.hitbox_active`) → `_process_hitboxes` ([`combat_system.gd:142`](../scripts/ecs/systems/combat_system.gd#L142)) finds opposing-team targets in a front-facing box → `_apply_damage` ([`:199`](../scripts/ecs/systems/combat_system.gd#L199)) resolves in priority: **parry** (negate + reflect ≥10 + stagger attacker, unless `weapon.unblockable`) → **block** (chip = `damage * 0.3`) → normal hit (combo bonus, armor, knockback, i-frames, VFX). On HP ≤ 0 emits `entity_died` → `main._on_entity_died` adds a `dying` component (death anim), then `_finish_*_death` respawns player at checkpoint (costs a life via `GameState.lose_life`) or despawns enemy (+XP/currency). Final-boss death → `win_run`.

### Win condition → next level
In `main._process`: crossing each arena's `trigger_x` calls `_activate_arena` (spawns roster); a level is won when the **final arena is cleared AND the player passes the goal** (`_level.is_level_won(px, final_cleared)`). On a win, `Levels.next_after(GameState.current_level_id)` decides whether to advance to the next level or end the run in VICTORY.

## Contracts (integration surface)
### ECS API (the thing systems/spawners call) — [`ecs.gd`](../scripts/ecs/ecs.gd)
`create_entity()`, `create_entity_with_node(node)`, `destroy_entity(id)`, `add_component(id, type, data)`, `get_component(id, type)`, `has_component(s)`, `get_entities_with(type)`, `get_entities_with_all([types])`, `register_system(sys)`, `get_system(Class)`, `set_system_enabled(Class, bool)`, `clear_all()`.

### Components (string keys) — factories in [`components.gd`](../scripts/ecs/components.gd)
`position, velocity, sprite, collision, health, weapon, projectile, momentum, echo_data, echo_instance, input_state, platformer, parry, dodge, ai, boss, enemy` + tags `tag_player/tag_enemy/tag_echo/tag_projectile/tag_interactable/tag_hazard`, `dying`. Each is a flat Dict of tunable fields (e.g. `parry.parry_window=0.2`, `weapon.combo_max=5`, `platformer.jump_force`).

### GameEvents signals (UI/audio integration) — [`game_events.gd`](../scripts/autoload/game_events.gd)
Player (`player_spawned/damaged/died`), combat (`enemy_killed`, `parry_success`), momentum (`momentum_changed`, `*_threshold_*_reached`), echo (`echo_ready/activated/ended`), state (`game_paused/resumed/over`, `mission_*`), UI (`ui_update_health/momentum/echo_cooldown`, `ui_show_message/damage_number`, `lives_changed`, `boss_spawned/health/defeated`).

### Input actions — [`project.godot`](../project.godot) `[input]`
`move_left/right` (A/D), `jump` (Space), `crouch` (S), `attack_light` (J), `attack_heavy` (K), `dodge` (Shift), `dash` (C), `echo_activate` (Q), `parry` (L), `pause` (Esc), `restart` (R). All have gamepad bindings; touch synthesizes these via `TouchControls`.

### Config & environment
| Item | Value | Notes |
|------|-------|-------|
| Engine | Godot **4.6**, `renderer=mobile` | `config/features=("4.6","Mobile")` |
| Main scene | `res://scenes/main/main.tscn` | |
| Viewport | 1920×1080, stretch `canvas_items`/`expand`, handheld orientation 4 (landscape) | |
| Save file | `user://save_data.json` (JSON, unencrypted) | [`game_state.gd:113`](../scripts/autoload/game_state.gd#L113) |
| Physics layers | 1 player,2 enemy,3 platform,4 hazard,5 interactable,6 projectile,7 hitbox,8 hurtbox | |
| GUT addon | `addons/gut` enabled | test runner |

## Build · run · test
- **Godot binary:** not on PATH; installed at `C:\Godot\Godot_v4.6.1-stable_win64_console.exe` (console build — use this for CLI stdout). GUI build alongside it.
- **Run (editor):** open `project.godot` in Godot 4.6, press F5.
- **Run (CLI):** `& C:\Godot\Godot_v4.6.1-stable_win64_console.exe --headless --path .` (verified: boots clean, exit 0).
- **Test:** GUT, config in `.gutconfig.json` (dirs `test/unit`, `test/integration`, `should_exit:true`). CLI (verified, 221/221 pass): `& C:\Godot\Godot_v4.6.1-stable_win64_console.exe --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`
- **Import:** `--headless --path . --import`. New `class_name` scripts need this before other scripts can reference them.
- **CI:** [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) runs import → GUT → boot smoke on every PR and push to `main`. The import and boot steps grep their own logs, because **Godot exits 0 even when the scene tree throws `SCRIPT ERROR`**.
- **Mobile export:** `export_presets.cfg` is in-repo; the Android preset is template-based (no Gradle/JDK needed). See [`docs/EXPORT.md`](EXPORT.md).
- **Package manager:** none. (Vestigial Vite scaffolding was removed 2026-06-20.)

## Gotchas & invariants
- **System registration order is load-bearing** ([`main.gd:74`](../scripts/main/main.gd#L74)). Parry must precede Combat (parry state is read during damage); PhysicsSync must precede Combat/Echo (positions must be synced). Reordering silently breaks mechanics.
- **Components are untyped Dicts** — a typo'd key fails silently (returns `null`/default), no compile error. Mutating a Dict returned by `get_component` mutates the live component (intended; that's how systems write state).
- **`unblockable` weapons** (perilous attacks) bypass both parry and block — only dodge i-frames avoid them ([`combat_system.gd:202`](../scripts/ecs/systems/combat_system.gd#L202)).
- **Enemy type `ronin_drone`** used in `level_one.arenas()` and `level_two.arenas()` has **no explicit case** in `main.archetype()` — it falls through to the default branch (HP50/dmg18). Easy to mistake for a bug; also means Level Two's difficulty curve was never actually tuned for it.
- **`DodgeSystem._process_dodge()` types its `health` param `Dictionary`** but guards with `if health:` — an entity with `dodge` + `input_state` and no `health` throws every frame. Unreachable today (only the player gets a dodge component), but the guard is a lie.
- **`max(0, <float>)` returns an `int` in GDScript.** `dodge_cooldown` silently changes type when it floors; the pattern recurs in momentum and lives handling.
- **Pixel-art filter:** the project default is Linear; character and backdrop sprites set `TEXTURE_FILTER_NEAREST` in code. New on-screen sprites must do the same or they render blurry.
- **The TomMusic SFX pack (~372 MB) is gitignored**; only the 4 used oggs are committed. If you `git add -A` on a new branch, confirm you are not staging it.
- **Two-boss finale:** `boss.is_final` gates the win. `crimson_ronin` has `final:false`, `oni_warlord` `final:true` ([`main.gd:398`](../scripts/main/main.gd#L398)); the `Components.boss()` default `is_final=true` is overridden per-spawn.
- **`DevTasks.md` statuses are all `TODO` but are STALE** — the slice has implemented far more than the doc reflects (combat, parry, echo, momentum, 2 bosses, 5 enemy types, HUD, audio, touch). Treat that doc as the *original full-game backlog*, not current status.
- `.godot/` is the Godot import cache (generated). `_archive/` (repo parent) holds older prototypes (`Godot-CyberRonin`, `wolf-zero-1`) — not the live project.

## Open questions / unverified
- **Visual and audio fidelity is entirely unverified** — the single largest open risk. Headless checks prove the game loads, ticks, and exits cleanly; they say nothing about whether feet touch the floor, whether the fog bands sit at a sensible height, or whether the SFX are audible and balanced. See [`docs/STATUS.md`](STATUS.md) for the specific knobs.
- **On-device behaviour is unverified.** A signed Android debug APK builds, but has never been installed or run.
- Echo record/playback fidelity, AI behavior breadth (`shinobi`/`support`), and boss pattern coverage inferred from signals/components, not traced line-by-line.
- ~~test status unverified~~ **RESOLVED**: 221/221 GUT tests pass, main scene boots headless clean (Godot 4.6.1), import clean.
- ~~Mobile build pipeline not present~~ **RESOLVED 2026-06-20 (PR #11)**: `export_presets.cfg` is in-repo and produces a signed Android debug APK. See [`docs/EXPORT.md`](EXPORT.md).
