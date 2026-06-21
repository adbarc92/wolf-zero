# Wolf-Zero — Swarm Handoff: Art Integration (Mattz Art samurai + ansimuz env)

> Orchestrator decomposition for swapping placeholder/FreeKnight art for the downloaded packs.
> The deliverable is this document; **no agents dispatched yet** — dispatch is opt-in and gated
> on the precondition below. Stamp: planned 2026-06-21.

## Precondition (read first — hard gate)
1. **PR #14 (`feat/neo-edo-swarm-integration`) must be merged to `main` first.** These lanes edit
   the very files that PR introduced/rewired — `scripts/render/character_frames.gd`,
   `scripts/render/scene_backdrop.gd`, the `assets/{audio,environment}/MANIFEST.md`, and the
   `main.gd` frame_set/parallax wiring. Branch each lane off the **post-#14 `main`** or they collide.
2. **The downloaded art must be on disk** before dispatch:
   - Mattz Art "Samurai Pack" bundle (player + enemy variants + Demon/Wolf Samurai for bosses + tileset).
   - ansimuz "Warped City" parallax layers (CC0; exclude the bundled music — separate license).
   - Record the unzip paths; the lanes need them. (Audio art is **out of scope here** — being
     researched separately; it becomes its own lane once a source is chosen.)

## Decisions locked (from the orchestrator Q&A)
- **Scope:** characters + environment. (Audio = separate research task, not a lane here.)
- **Boss look:** a **distinct sheet** (Demon/Wolf Samurai), not tinted-enemy reuse → adds a
  `CharacterFrames.boss()` set + a `main.gd` contract for Lane Z.
- **Missing `fall`/`roll`/`slide`/`crouch`:** **alias to substitutes now** (data-only in
  `character_frames.gd`), swap to real anims when commissioned.

## Two facts that shaped the decomposition (verified in code)
- `SpriteFramesBuilder.add_strip` slices **single-row horizontal strips only** (`region.y`
  hardcoded 0). If the Mattz sheets are multi-row **grids**, Lane C must add a grid-aware extractor.
- `AnimationSystem` (line ~118) only switches to a clip the SpriteFrames actually **has**, so a
  missing clip = the sprite holds its last frame (janky, never crashes). Missing clips can therefore
  be **aliased inside `character_frames.gd`** (data-only) — no `animation_system.gd` edit needed.

## Dependency analysis
| Surface | Independent? | Hot files | Verdict |
|---|---|---|---|
| Environment art drop-in | yes — `SceneBackdrop` is self-contained, loads by path | `scripts/render/scene_backdrop.gd`, `assets/environment/**` | **Lane B** (no shared files) |
| Character restyle (player+enemy+boss) | yes — `CharacterFrames` is the single swap point | `scripts/render/character_frames.gd`, `sprite_frames_builder.gd` | **Lane C** + contract to Z (boss + alignment) |
| Boss frame_set wiring | needs `main.gd` | `main.gd::_initialize_ecs`, `_spawn_boss` | **Lane Z** (owns main.gd) |
| Sprite scale/offset for new frame size | needs `animation_system.gd` | `animation_system.gd::_ensure_anim_node` | **Lane Z** |

**Contention points → Lane Z owns them:** `scripts/main/main.gd`, `scripts/ecs/systems/animation_system.gd`,
`project.godot`, `scenes/main/main.tscn`. Lanes B and C never write these — they file contract requests.

---

## Lanes

### Lane B — Environment art drop-in (ansimuz Warped City, CC0)   ·   ready (needs art on disk)
- Scope: Replace the placeholder PNGs with the real ansimuz Warped City parallax layers and adjust
  `SceneBackdrop` to the actual layer set.
- Owns (exclusive write): `assets/environment/**` (replace placeholders + their `.import`),
  `scripts/render/scene_backdrop.gd`, `test/unit/test_scene_backdrop.gd`
- Reads (no write): `assets/environment/MANIFEST.md` (the drop-in spec written by the last swarm),
  memory `wolf-zero-asset-candidates`
- Shared contract: **none.** `SceneBackdrop` loads by path and is self-contained. If the real pack
  has a different layer count than the 3 placeholders, update `SceneBackdrop.LAYERS` **and** the
  expected-count assertion in `test_scene_backdrop.gd` — both Lane-B-owned, so still zero shared edit.
- Depends on / blocks: needs the ansimuz art unzipped on disk. Otherwise fully parallel.
- Done when: `SceneBackdrop` builds the real layers; the test asserts the (possibly new) layer count;
  `--import` clean; headless boot shows the city instead of placeholder gradients.
- Verify: `--headless --path . --import`, then the GUT command, then headless boot clean.
- Notes / open questions: real layer **count + filenames** vs the 3 placeholders; whether layers are
  seamless-tiling (set `motion_mirroring` to the layer width) or full-scene; **do not ship the
  bundled music file** (separate license — the CC0 covers the art only — confirm in the pack's LICENSE).

### Lane C — Character restyle (Mattz Art samurai: player + enemies + boss)   ·   ready (needs art on disk)
- Scope: Repoint `CharacterFrames` from FreeKnight to the Mattz Art samurai bundle for `player()`,
  `enemy()`, and a **new `boss()`** set; alias the 4 missing anims; add a grid extractor if needed.
- Owns (exclusive write): `scripts/render/character_frames.gd`,
  `scripts/render/sprite_frames_builder.gd` (append a grid extractor **only if** the sheets are grids —
  Lane C is the sole writer of this util), `assets/<new samurai dirs>/**` (the imported art),
  `test/unit/test_character_frames.gd`
- Reads (no write): `scripts/ecs/systems/animation_system.gd` (the **clip names `derive_clip` can
  emit** — that is the set the data must cover: idle, run, jump, fall, jump_fall_inbetween, dash,
  roll, slide, hit, crouch, crouch_walk, crouch_attack, crouch_transition, wall_slide, wall_climb,
  turn_around, death, light_1..5, light_1..5_nomove, heavy*), `scripts/main/main.gd` (how
  `frame_sets` + `_spawn_boss` consume sets), memory `wolf-zero-asset-candidates`
- Shared contract: `scripts/main/main.gd` → owner **Lane Z** → request: 'in `_initialize_ecs` add
  `"boss": CharacterFrames.boss()` to `anim.frame_sets`; in `_spawn_boss` set `spr.frame_set = "boss"`
  (currently `"enemy"`).' **Plus** report the recommended `AnimatedSprite2D` **scale + offset** for the
  new frame size (FreeKnight was 120×80; Mattz is ~96×96) so Z can align the sprite to the 32×64
  collision box + floor.
- Depends on / blocks: needs the Mattz bundle unzipped on disk. **Unblocks the neon-recolor commission**
  (recolor later = swap the `FK`/`FK2` BASE art files, one-file-ish).
- Done when: `player()`/`enemy()`/`boss()` build from the samurai art; **every clip name
  `derive_clip` can emit is present** (real or aliased — `fall`→jump strip, `roll`→dash, `slide`→dash,
  `crouch`→idle, `crouch_walk`→run, etc.); the test asserts the full clip set incl aliases; `--import`
  clean; headless boot shows the samurai with no missing-clip holds during fall/roll/slide/crouch.
- Verify: `--headless --path . --import` (new art), then the GUT command, then headless boot clean.
- Notes / open questions (the agent must INSPECT the downloaded files):
  - **Strip vs grid** sheet format → decides whether `sprite_frames_builder` needs a grid extractor.
  - Exact per-anim **frame counts + fps**, and the **frame size** → drives the scale/offset request to Z.
  - **Which bundle characters map to which game roles:** player; enemies (`cyber_ashigaru`, `oni_mech`,
    `elite_oni`, `shinobi_ghost`, `tech_priest`, `ronin_drone`); bosses (`crimson_ronin`,
    `oni_warlord` → Demon/Wolf Samurai). Enemies still tint via archetype `tint`, so one enemy sheet
    recolored per-archetype is fine; the boss gets the distinct `boss()` sheet.
  - Confirm the **alias targets read acceptably** (roll/slide especially) before calling done.

### Lane Z — Integration & shared-file owner   ·   integrates LAST
- Scope: Owns the contended shared files; applies Lane C's boss + alignment requests; removes the
  now-dead placeholder/FreeKnight/MoonlitGraveyard assets; runs the reconciliation build/test.
- Owns (exclusive write): `scripts/main/main.gd`, `scripts/ecs/systems/animation_system.gd`,
  `project.godot`, `scenes/main/main.tscn`, and the **deletion** of obsolete asset dirs
  (`assets/FreeKnight_v1/**`, `assets/MoonlitGraveyard/**`) once nothing references them.
- Reads (no write): every lane's delivered new files
- Shared contract: this lane **is** the owner; it collects all requests.
- Depends on / blocks: depends on B + C having produced their files + requests. Merges last.
- Done when: merged whole boots clean showing **samurai + Warped City**; full GUT green; Android debug
  APK still builds; no dangling references to the old FreeKnight/MoonlitGraveyard paths anywhere.
- Verify: `--headless --path . --import`; full GUT; headless boot; `--export-debug "Android" build/wolf-zero-debug.apk`.
- Notes / open questions: apply the boss frame_set request and the sprite scale/offset verbatim from
  Lane C's report; grep for `FreeKnight`/`MoonlitGraveyard` before deleting those dirs to ensure no live refs.

---

## Shared contracts
| File | Owner | Requesters & what they ask |
|---|---|---|
| `scripts/main/main.gd` | Lane Z | C: add `"boss"` frame_set + `_spawn_boss` uses it; (info) sprite scale/offset for new frame size. |
| `scripts/ecs/systems/animation_system.gd` | Lane Z | C: apply the recommended `AnimatedSprite2D` scale/offset (alignment) if the new frame size needs it. |
| `project.godot` / `main.tscn` | Lane Z | none expected; reserved. |
| obsolete asset dirs | Lane Z | Z deletes `FreeKnight_v1/**` + `MoonlitGraveyard/**` after confirming no live refs. |

## Integration order
1. **Lane B** — merge any time (no shared files).
2. **Lane C** — build in parallel; delivers new owned files + the boss/alignment contract requests.
3. **Lane Z** — last. Apply the boss frame_set + alignment edits, delete dead art dirs, then reconcile:
   `--import` → full GUT → boot → Android export.

## After this swarm (external gates — not lanes)
- **Audio source** — under research now (separate subagent); becomes its own lane once a pack is chosen.
- **Neon recolor** of the samurai art (commission) — swaps the BASE art files; the alias rows stay.
- **Real `fall`/`roll`/`slide`/`crouch`** anims (commission) — replace the aliases with real strips.
- **Neo-Edo overlay** (torii / paper lanterns / vertical kanji neon) — commission; the single highest-
  leverage identity investment. Lane B ships the generic-cyberpunk CC0 base; the overlay layers on top.
- **On-device validation** — frame pacing + how the new sprite reads at phone size; needs hardware.

## Rules of the road (give these to every dispatched agent verbatim)
1. **Stay in your lane.** Write only files your lane owns. Need a change elsewhere? Record a contract
   request in your final report; do not edit another lane's files.
2. **Branch/worktree per lane.** Never commit to `main`. Worktrees isolate repo files only.
3. **Shared files are append-only, single-owner.** Only Lane Z writes `main.gd` /
   `animation_system.gd` / `project.godot` / `main.tscn` and deletes the old asset dirs.
4. **Don't widen scope.** Build only your lane's items; report anything else you find.
5. **Verify before claiming done.** Run your verify check; paste the real output. New `class_name`
   scripts and new art require `--headless --import` before the suite resolves them.
6. **Report for integration.** End with: files changed, contract requests (incl. the sprite
   scale/offset for Z), verify output, and anything affecting another lane.

## Not dispatched
This document is the deliverable. Dispatch is gated on PR #14 merged + the art unzipped on disk —
say the word once both hold and I'll run Lanes B/C (worktree-isolated) and the Lane Z integration myself.
