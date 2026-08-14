# Wolf Zero — Status

Canonical, living status document. The **State summary** is rewritten in place
each session; the **Session log** is appended newest-first. Dated files under
`docs/handoff/` are frozen history — this file is the current picture.

---

## State summary

_Last updated: 2026-08-13_

### TL;DR

The vertical slice is content-complete and green headlessly, but **nobody has
ever looked at it**. Real art, audio, and a parallax environment all landed in
June (PRs #14–#17) and were verified only by headless import, tests, and a boot
smoke — which prove structure, not appearance. The one thing standing between
here and a playable judgement is a human launching the game.

The repo was **archived on GitHub** between 2026-06-21 and 2026-08-13 and has
been unarchived; no code changed while it was read-only.

### Readiness

| Area | State |
|---|---|
| Tests | **221/221 GUT passing** (was 151 before the 2026-08-13 pass) |
| Headless boot | `main.tscn` boots clean, exit 0 |
| Import | `--import` clean |
| CI | Added 2026-08-13 — green, **awaiting merge** (PR #18) |
| Android export | Signed debug APK builds; **never run on a device** |
| Visual / audio | **Unverified** — no human has seen or heard the build |

### Open PRs

| # | Title | State |
|---|---|---|
| [#18](https://github.com/adbarc92/wolf-zero/pull/18) | `ci:` headless verification workflow | Green, awaiting merge |
| [#19](https://github.com/adbarc92/wolf-zero/pull/19) | `test:` cover ECS core, DodgeSystem, GameState | Verified locally; no CI run (workflow not on `main` yet) |

### Known gaps

- **Visual/on-device validation has never happened.** Character feet alignment,
  fog-band scale/offset, and whether the 10 SFX keys actually sound right are all
  open. Details and the exact knobs: [`docs/handoff/handoff-2026-06-21-art-audio-env.md`](handoff/handoff-2026-06-21-art-audio-env.md).
- **Foreground Central City tileset is vendored but unused** — level geometry is
  still code-defined platforms, not tile art.
- **Music is still the procedural bed** (`SfxGenerator.music()`).
- **No analog touch joystick**; on-device control layout untuned.
- `level_two` references a `ronin_drone` enemy type that is not a named
  archetype, so it silently falls back to default stats (works; minor balance
  miss).
- `DodgeSystem._process_dodge()` types its `health` parameter `Dictionary` but
  guards with `if health:` — a dodging entity without health would throw every
  frame. Not reachable today (only the player gets a dodge component).
- `max(0, <float>)` returns an **int** in GDScript; `dodge_cooldown` changes type
  when it floors. Harmless, but the pattern recurs elsewhere.

### Next steps

1. **Merge #18 and #19.** Rebase #19 afterwards so it gets a real CI run.
2. **Launch the game and look at it.** This is the highest-value action
   available and no amount of headless work substitutes for it.
3. Foreground Central City tileset → real level geometry (the big content lane).
4. Distant-building parallax layer for depth.
5. Commission work: samurai neon recolor, real `fall`/`roll`/`slide`/`crouch`
   anims, Neo-Edo identity overlay (torii / lanterns / kanji neon).

---

## Session log

### 2026-08-13 — Unattended infrastructure pass

Scoped and executed the infrastructure work that could run without supervision,
deliberately excluding anything needing human eyes or ears.

- **Discovered the GitHub repo was archived** (read-only) — no push, PR, or
  Actions run was possible. Unarchived it with the owner's go-ahead.
- **Added CI** ([#18](https://github.com/adbarc92/wolf-zero/pull/18)): first CI
  the repo has ever had. Cached Godot 4.6.1 → import → GUT → boot smoke, on PRs
  and pushes to `main`. Import and boot steps gate on their *logs*, because Godot
  exits 0 even when the scene tree throws `SCRIPT ERROR`. Green on first run
  (~2 min).
- **Expanded tests** ([#19](https://github.com/adbarc92/wolf-zero/pull/19)):
  151 → 221 tests, 510 → 623 asserts. Covered `ecs.gd`, `DodgeSystem`, and
  `GameState`, none of which had direct tests. Surfaced the `DodgeSystem` health
  typing issue and the `max(0, float)` int-return quirk noted above; neither was
  fixed, since the change was scoped to tests.
- **Housekeeping**: deleted 14 local branches already merged into `main`;
  committed the June handoff doc; created this file.
- **Deliberately did not** prune the 20 committed `.aseprite` files. They total
  101 KB and are the *editable sources* for the samurai/boss sprites and the
  layered fog bands — exactly what the open art-tuning tasks need. An earlier
  handoff suggested pruning them as clutter; that advice was wrong.

State delta: no CI → CI (pending merge); 151 → 221 tests; 16 local branches → 3.
Game behaviour unchanged — no game code was modified.

### Earlier sessions

Frozen history lives in `docs/handoff/` and the PR record. In brief: PRs #1–#8
built the vertical slice (physics, combat, parry/block/perilous, Echo, enemy
roster, two bosses, game shell). #9–#13 added cleanup, mechanics tests, the
mobile export pipeline, canonical touch controls, and the level abstraction.
#14 landed the Neo-Edo content swarm (Level Two, tutorial, audio manager,
`CharacterFrames`). #15–#17 replaced placeholder art, audio, and environment
with real assets.
