# Wolf Zero — Status

Canonical, living status document. The **State summary** is rewritten in place
each session; the **Session log** is appended newest-first. Dated files under
`docs/handoff/` are frozen history — this file is the current picture.

---

## State summary

_Last updated: 2026-08-15_

### TL;DR

The project now knows **what it is shipping**. Three ADRs landed on 2026-08-15
and a scope pass has propagated them through the documents: the game is **6
handcrafted levels, 4 bosses, and a repeatable Boss Gauntlet**, with ad-hoc
co-op that is solo-complete. Skill trees, the three-currency economy, the four
extra weapons and the twelve-mission narrative are **out of launch scope** and
parked in [`IDEA-BANK.md`](IDEA-BANK.md) — not deleted, not being built.

The build itself is still the two-level vertical slice: **233/233 tests pass**,
it boots clean headless, and **no human has ever looked at it**. That last point
has been true for two months and is still the highest-value thing anyone could
do with an hour.

Two things are in flight right now: the **ADR 0001 combat rework** (Momentum
absorbs posture; a full bar banks a Charge) and this **documentation scope
pass**, running as parallel lanes.

### The shipped shape (ADR 0003)

| | Target | Built |
|---|---|---|
| Levels | **6** (floor 4) | 2 |
| Bosses | **4** — Crimson Ronin, Oni Warlord, Geisha Network, Iron Daimyo (final) | 2 |
| Repeatable mode | **Boss Gauntlet** — scored on time and defence, no heals between fights | 0 |
| Co-op | **Ad-hoc, solo-complete, independent cameras** | 0 |
| Weapons | 1 (Plasma Katana) | 1 |
| Skills / currencies / narrative arc | **none** — parked | — |

Cut from the plan and recorded, with the readmission test *"does it make the
combat better, or does it just make the game bigger?"*: 30 skills, 3 currencies,
4 weapons, 12 missions of plot, grapple, launchers, hazards, interactables, Echo
upgrades, and every online co-op service.

### Readiness

| Area | State |
|---|---|
| Tests | **233/233 GUT passing** (verified 2026-08-15 on `main`) |
| Headless boot | `main.tscn` boots clean, exit 0 |
| Import | `--import` clean |
| CI | Green on PRs and pushes to `main` (import → GUT → boot smoke → gdlint) |
| Android export | Signed debug APK builds; **never run on a device** |
| Visual / audio | **Unverified** — no human has seen or heard the build |
| Scope | **Decided** — ADRs 0001/0002/0003, `Requirements.md` v1.2 |

### Open PRs

| # | Title | State |
|---|---|---|
| [#26](https://github.com/adbarc92/wolf-zero/pull/26) | `docs:` swarm handoff for the momentum rework + requirements scope pass | Open |
| — | `feat:` ADR 0001 momentum/Charge rework (Lane A) | In flight |
| — | `docs:` scope pass (Lane B — this document) | In flight |

### Known gaps

- **Visual/on-device validation has never happened.** Character feet alignment,
  fog-band scale/offset, and whether the 10 SFX keys actually sound right are all
  open. Details and the exact knobs: [`docs/handoff/handoff-2026-06-21-art-audio-env.md`](handoff/handoff-2026-06-21-art-audio-env.md).
- **The two largest launch systems are unbuilt and undesigned in code**: the Boss
  Gauntlet (`Requirements.md` §2.11) and ad-hoc co-op (§2.5). Both depend on the
  ADR 0001 combat model settling first.
- `_level.arena_to_activate(px, …)` takes a **single player position** and has no
  answer for two (ADR 0002, FR-COP-010).
- `GameState`'s **mission API is dead code** — progression runs on `Levels`.
  `CONTEXT.md` settles the vocabulary; the dead API should be deleted (§9.4).
- **Skill Points accrue and buy nothing** — deliberate, and deliberately not
  shown to the player (§9.10). Anything that surfaces them at launch is a bug.
- **Foreground Central City tileset is vendored but unused** — level geometry is
  still code-defined platforms, not tile art.
- **Music is still the procedural bed** (`SfxGenerator.music()`).
- **No analog touch joystick**; on-device control layout untuned.
- `level_two` references a `ronin_drone` enemy type that is not a named
  archetype, so it silently falls back to default stats (works; minor balance
  miss).
- `DodgeSystem._process_dodge()` types its `health` parameter `Dictionary` but
  guards with `if health:`; `max(0, <float>)` returns an **int** in GDScript.
  Both harmless today, both still there.

### Next steps

1. **Land the ADR 0001 combat rework.** It gates the Gauntlet's scoring, every
   co-op proximity verb, and the Break/Deathblow loop the game is sold on.
2. **Launch the game and look at it.** Still the highest-value action available,
   and still nobody has done it.
3. **Build Levels Three to Six**, with Geisha Network in Level 3 and Iron Daimyo
   closing Level 6. This is the largest remaining block of work.
4. **Build the Boss Gauntlet** (FR-GNT-001→015) — reuse only, no bespoke content.
5. **Build ad-hoc co-op** alongside the Gauntlet, not after it. Local pairing,
   independent cameras, shared Charge pool, proximity verbs, partner HUD.
6. Neo-Edo identity art (torii / lanterns / kanji neon) — with the narrative
   cut, the setting has to land entirely through art, audio and level design.

---

## Session log

### 2026-08-15 — Scope pass: the documents now say what ships

Second lane of a two-lane parallel swarm (the other is implementing ADR 0001 in
`scripts/`). This lane touched Markdown only.

- **`Requirements.md` → v1.2.** Added a **Launch** column to all 46 requirement
  tables as an axis *independent of* build status, with an explicit vocabulary
  (`Ship` / `Ship (reduced)` / `Parked` / `Removed`) and two invariants: no row
  is both P0 and parked, and every parked row is named in the Idea Bank. 377
  rows now carry a disposition — 258 Ship, 11 reduced, 101 parked, 7 removed.
- **Added §2.11 Boss Gauntlet** (FR-GNT-001→015): back-to-back bosses and elites,
  no heals between fights, Charges carry, scored on time *and* defence, under 15
  minutes, no bespoke content.
- **Rewrote §2.5 co-op for ADR 0002** — solo-complete, fully independent cameras,
  proximity verbs, shared Charge pool, local pairing. Added FR-COP-008→011,
  FR-CPM-006→008 and FR-HUD-009 (partner status, needed precisely because the
  cameras are independent). Online services parked.
- **Closed two long-running contradictions**: §9.5 (co-op priority) resolved by
  ADR 0002, §9.7 (defence is HP chip, not posture) resolved by ADR 0001. §9.1 and
  §9.4 also marked resolved; §9.10 and §9.11 added for the loose ends the scope
  pass itself created.
- **`CoreDesign.md` → v1.1.** Rewrote the momentum gauge, Echo cost, movement
  unlock table, boss roster and the whole of §6 co-op; labelled skill trees, the
  economy, weapon upgrades, Echo upgrades and the narrative arc **POST-LAUNCH**
  in place; replaced Appendix A's 12-mission list with a 6-level plan (the old
  list survives as A.1, labelled); added §4.4 describing the Gauntlet.
- **`IDEA-BANK.md`** now cross-references every parked requirement by ID in both
  directions — verified by script: 114 IDs cited, 0 missing from
  `Requirements.md`; 101 parked rows, 0 uncited.
- **`CONTEXT.md`**: added **Elite** — the durable mid-tier enemy the Gauntlet is
  built from, and the answer to "most of the roster dies in half a second".

**Decisions taken** (the ADRs left these open and content planning needs one
answer each):

- **Launch scope is a separate column**, not a priority value or strikethrough.
  Overloading priority would have destroyed the "is it built?" signal v1.1 was
  written to create.
- **6 levels, not 4.** Four levels at 8–15 minutes is ~40 minutes of campaign at
  a $4.99–$9.99 price point, which is the commercial risk ADR 0003 already flags.
  4 levels and 3 bosses is recorded as the *floor* if production slips.
- **The narrative floor is "enough Neo Edo to make the setting land"**, not zero:
  named places, named bosses, a one-line title card per level, environmental
  storytelling. The plot is parked. ADR 0003 cuts the story and in the same
  breath makes the setting carry the game — silence would have failed that.

State delta: the requirements document can now answer *"is it in the shipped
game?"* for every row, which it could not before. No code changed; tests
verified green at 233/233 on `main` before and unaffected by this lane.

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
with real assets. #18–#21 added CI, test coverage, this status file, and gdlint.
#22–#25 added lint to CI, Mega Man X-style movement and dash-jump, the v1.1
requirements reconciliation, and the three ADRs that set the shipped scope.
