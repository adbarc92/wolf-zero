# Wolf-Zero — Swarm Handoff: Neo Edo Identity & Content

> Orchestrator decomposition for the next phase. The deliverable is this document; **no agents
> have been dispatched.** Dispatching is opt-in (and gated — see Blocked items).
> Stamp: planned 2026-06-20 against `main` + open PRs #9–#13.

## Precondition (read first)
These lanes branch off `main` **after PRs #9–#13 are merged**. That is a hard gate:
- **#13 (level abstraction)** must be merged — Lane C (Level Two) needs the `Level` base class and
  `Levels` registry.
- #9 (cleanup), #10 (tests + AI fix), #11 (export), #12 (canonical touch buttons) should be merged
  so lanes don't re-collide with their diffs.
Merge order among #9–#13 doesn't matter (they're mutually independent), but **all five land before
this swarm starts.** Each lane branches off the resulting `main` (own branch/worktree).

Asset choices come from the vetted research in memory `wolf-zero-asset-candidates` — read it before
Lanes A/B.

## Dependency analysis
Candidate features for this phase and how they relate:

| Feature | Independent? | Hot files | Verdict |
|---|---|---|---|
| Audio overhaul (real SFX/music) | yes — audio scripts are self-contained, wired via signals | `scripts/audio/*` | **Lane A** (no shared files) |
| Environment art (tileset + parallax) | needs main.gd visual setup | `main.gd::_setup_parallax` | **Lane B** + contract to Z |
| Level Two | needs registry + progression | `levels.gd`, `main.gd` | **Lane C** + contracts |
| Tutorial / onboarding | needs one node added in main | `main.gd::_ready` | **Lane D** + contract |
| Character-frames plumbing (extract) | needs main.gd frame builders | `main.gd::_build_*_frames` | **Lane E** + contract to Z |
| Player/enemy sprite restyle | **blocked** — needs commissioned art | — | Blocked (Lane E unblocks the swap) |
| Music (synth-Japanese fusion) | **blocked** — paid pack/composer | — | Blocked (Lane A ships CC0 SFX) |
| On-device validation | **blocked** — hardware gate | — | Blocked |

**The one contention point is `main.gd`** — Lanes B, D, E all need a small wiring change there. None
of them edit it; each files an append-only **contract request** that **Lane Z** (the integration
owner) applies in a single pass. `scripts/levels/levels.gd` and `project.godot` are the other
shared files, also owned by Z.

---

## Lanes

### Lane A — Audio overhaul (SFX now, music later)   ·   ready
- Scope: Replace procedural-only audio with an asset-driven `AudioManager` — load real SFX files
  (CC0) for the existing event keys (`slash`, `hit`, `parry`, `block`, `death`, `jump`, `dodge`,
  `echo`, `hit_light`), falling back to procedural `SfxGenerator` if a file is missing.
- Owns (exclusive write): `scripts/audio/audio_manager.gd`, `scripts/audio/sfx_generator.gd`,
  `assets/audio/**` (new files), `test/unit/test_audio_manager.gd`
- Reads (no write): `scripts/autoload/game_events.gd`, `scripts/main/main.gd` (the `_on_sfx_*`
  handlers call `_audio.play("<key>")` — **keep that `play(key)` API stable** so main needs no edit)
- Shared contract: none — keeping the `play(key)` signature means zero `main.gd` change. (If music
  needs a state hook, connect to `GameState.state_changed`/`GameEvents` **inside AudioManager**, not
  in main.)
- Depends on / blocks: nothing. Fully parallel; merges any time.
- Done when: each event key plays its real SFX (or procedural fallback); `test_audio_manager`
  passes asserting lookup + fallback.
- Verify: `& C:\Godot\Godot_v4.6.1-stable_win64_console.exe --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`
- Notes / open questions: Use Kenney Impact/Interface (CC0) + TomMusic sword SFX. **Music is
  out of scope here** (needs the $4.99 SunnyMelodyLab pack or a composer — see Blocked). Convert WAV→OGG for mobile.

### Lane B — Environment art (CC0 tileset + parallax)   ·   ready
- Scope: Replace the MoonlitGraveyard parallax with the CC0 ansimuz "Warped City" cyberpunk
  backdrop, encapsulated in a self-contained `SceneBackdrop` node so `main.gd` just instantiates it.
- Owns (exclusive write): `assets/environment/**` (new, the CC0 art), `scripts/render/scene_backdrop.gd`
  (new — a `Node`/`ParallaxBackground` that builds the layers in its own `_ready`),
  `test/unit/test_scene_backdrop.gd` (new)
- Reads (no write): `scripts/main/main.gd` (`_setup_parallax`/`_add_layer` — to replicate the layer
  pattern), `wolf-zero-asset-candidates` memory
- Shared contract: `scripts/main/main.gd` → owner **Lane Z** → request: "replace `_setup_parallax()`
  + `_add_layer()` with `add_child(SceneBackdrop.new())`; remove the MoonlitGraveyard `load()` paths."
- Depends on / blocks: nothing blocks the build; Z applies the wiring at integration.
- Done when: `SceneBackdrop` renders the new layers standalone; a test asserts it builds the expected
  layer count; boot is clean after Z wires it.
- Verify: `--headless --import` (new `class_name`), then the gut command above; headless boot clean.
- Notes / open questions: ansimuz Warped City is **CC0** (verify the bundled-music exception). It's
  generic cyberpunk — **no Japanese motifs**; the Neo-Edo overlay (torii/lanterns/kanji neon) is a
  separate Blocked/commission item, not this lane.

### Lane C — Level Two   ·   ready (requires #13 merged)
- Scope: A second playable level as a `Level` subclass, registered so it's reachable after Level One.
- Owns (exclusive write): `scripts/levels/level_two.gd` (new — `class_name LevelTwo extends Level`),
  `test/unit/test_level_two.gd` (new)
- Reads (no write): `scripts/levels/level.gd`, `scripts/levels/level_one.gd` (the pattern)
- Shared contract:
  - `scripts/levels/levels.gd` → owner **Lane Z** → request: 'add `"level_two"` to `_ORDER` after
    `"level_one"`; add a `create()` match arm `"level_two": return LevelTwo.new()`.'
  - progression (`scripts/main/main.gd` / `scripts/autoload/game_state.gd`) → owner **Lane Z** →
    request: 'on level win, advance via `Levels.next_after(current_level_id)` and restart into it (or
    show results if none).'
- Depends on / blocks: **#13 merged** (Level base + registry). Otherwise independent.
- Done when: `LevelTwo` supplies spawn/metrics/platforms/arenas/goal; `test_level_two` asserts arena
  gating + win like `test_level_one`; after Z's wiring the level is reachable.
- Verify: `--headless --import` (new `class_name LevelTwo`), then the gut command above.
- Notes / open questions: **Level design is the open question** — platform layout, arena triggers,
  enemy roster/placement, difficulty. Balance can't be validated headless; ship sane numbers and
  flag for on-device tuning. Reuse existing enemy archetypes/bosses; no new combat code.

### Lane D — Tutorial / onboarding prompts   ·   ready
- Scope: First-run prompts that teach the three unlearnable mechanics — parry, Echo, momentum —
  triggered by gameplay events, shown once.
- Owns (exclusive write): `scripts/ui/tutorial.gd` (new — a `CanvasLayer`/`Control` that listens to
  `GameEvents` and shows/dismisses prompts), `test/unit/test_tutorial.gd` (new — pure trigger-state logic)
- Reads (no write): `scripts/autoload/game_events.gd`, `scripts/ui/hud.gd`,
  `scripts/autoload/game_state.gd`
- Shared contract: `scripts/main/main.gd` → owner **Lane Z** → request: '`add_child(Tutorial.new())`
  in `_ready` (gate on a first-run flag).' If persistence is wanted, request a `player_data` flag in
  GameState from Z rather than editing it.
- Depends on / blocks: nothing.
- Done when: prompts fire at sensible triggers (e.g. first enemy detected → parry; momentum reaches
  the echo threshold → Echo) and dismiss after being shown; trigger-state logic unit-tested.
- Verify: the gut command above (test the prompt state machine in isolation).
- Notes / open questions: **Trigger design is the open question** (which event teaches what, and
  when). Keep copy short — commute/one-handed audience.

### Lane E — Character-frames plumbing (refactor, no art change)   ·   ready
- Scope: Extract `main.gd::_build_player_frames()`/`_build_enemy_frames()` (+ the `FK`/`FK2` path
  consts) into a data-driven `CharacterFrames` module, **keeping the current FreeKnight art**. This
  turns the eventual sprite swap into a one-file data edit and unblocks the commissioned-art lane.
- Owns (exclusive write): `scripts/render/character_frames.gd` (new — `class_name CharacterFrames`
  with `static func player() -> SpriteFrames` / `enemy() -> SpriteFrames` and a data table of
  (anim, path, fps, loop)), `test/unit/test_character_frames.gd` (new)
- Reads (no write): `scripts/main/main.gd` (the two builder funcs to port verbatim),
  `scripts/render/sprite_frames_builder.gd`
- Shared contract: `scripts/main/main.gd` → owner **Lane Z** → request: 'in `_initialize_ecs`, set
  `anim.frame_sets = {"player": CharacterFrames.player(), "enemy": CharacterFrames.enemy()}` and
  delete the inline `_build_*_frames`/`FK`/`FK2`.'
- Depends on / blocks: unblocks the (Blocked) sprite-restyle work later.
- Done when: `CharacterFrames.player()`/`enemy()` return SpriteFrames with the **same animation set
  as today**; a test asserts the expected animation names exist; after Z's wiring, boot/animation is
  unchanged.
- Verify: `--headless --import` (new `class_name`), then the gut command above; boot clean.
- Notes / open questions: pure refactor — visuals must be byte-for-byte identical to today.

### Lane Z — Integration & shared-file owner   ·   integrates LAST
- Scope: Owns every hot shared file; applies the contract requests from B/C/D/E in one pass; runs
  the reconciliation build/test.
- Owns (exclusive write): `scripts/main/main.gd`, `scripts/levels/levels.gd`, `project.godot`,
  `scenes/main/main.tscn`
- Reads (no write): every lane's delivered new files
- Shared contract: this lane **is** the owner; it collects all requests.
- Depends on / blocks: depends on A–E having produced their new files + requests. Merges last.
- Done when: merged whole boots clean, full GUT suite green, Android debug export still builds, and
  the shared files hold exactly the union of requested edits (nothing clobbered).
- Verify: `--headless --import`; full gut; headless boot; `--export-debug "Android" build/wolf-zero-debug.apk` (per docs/EXPORT.md).
- Notes / open questions: apply requests verbatim; if two requests touch adjacent lines in main.gd
  (`_ready` for Tutorial vs `_setup_parallax` for SceneBackdrop), they're in different functions —
  no real conflict.

---

## Shared contracts
| File | Owner | Requesters & what they ask |
|---|---|---|
| `scripts/main/main.gd` | Lane Z | B: swap parallax→`SceneBackdrop`. D: add `Tutorial` node. E: call `CharacterFrames`. C: win→advance level. |
| `scripts/levels/levels.gd` | Lane Z | C: register `level_two` (order + create arm). |
| `scripts/autoload/game_state.gd` | Lane Z | C: progression field/wiring. D (optional): first-run flag. |
| `project.godot` / `main.tscn` | Lane Z | none expected; reserved to Z if an autoload/scene change surfaces. |

## Integration order
1. **Lane A** — merge any time (no shared files).
2. **Lanes B, C, D, E** — build in parallel; each delivers new owned files + a contract request. Merge their new files (no overlap by construction).
3. **Lane Z** — last. Apply all contract requests to the owned shared files, then reconcile: `--import` → full GUT → boot → Android export.

## Blocked items (not lanes — external gates)
- **Player/enemy sprite restyle** (neon cyber look + the missing `fall`/`roll`/`slide`/`crouch`
  anims) — blocked on commissioned/acquired art. Lane E makes the swap a single-file data change
  once art exists. See `wolf-zero-asset-candidates`.
- **Neo-Edo background overlay** (torii, paper lanterns, vertical kanji neon) — blocked on commission;
  the single highest-leverage identity investment. Lane B ships the generic-cyberpunk CC0 base.
- **Music** (synth + koto/taiko fusion) — blocked on the SunnyMelodyLab paid pack or a composer;
  Lane A ships CC0 SFX now.
- **On-device validation** (frame pacing, touch ergonomics) — blocked on hardware. The build (#11)
  and touch scheme (#12) are ready; they need a real phone to validate feel before more is built on top.

## Rules of the road (give these to every dispatched agent verbatim)
1. **Stay in your lane.** Write only files your lane owns. Need a change elsewhere? Record a contract
   request in your final report; do not edit another lane's files.
2. **Branch/worktree per lane.** Never commit to `main`.
3. **Shared files are append-only, single-owner.** Only Lane Z writes `main.gd`/`levels.gd`/`project.godot`/`main.tscn`.
4. **Don't widen scope.** Build only your lane's items; report anything else you find.
5. **Verify before claiming done.** Run your verify check; paste the real output. New `class_name`
   scripts require `--headless --import` before the suite will resolve them.
6. **Report for integration.** End with: files changed, contract requests, verify output, anything
   affecting another lane.

## Not dispatched
This document is the deliverable. Fanning out the swarm is expensive and gated on the precondition
(#9–#13 merged) plus the Blocked items — say the word to dispatch once those are resolved, and I'll
run the lanes (worktree-isolated) and integration myself.
