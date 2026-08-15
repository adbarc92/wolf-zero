# Swarm Handoff — Momentum rework + Requirements scope pass (2026-08-15)

Two lanes that can be built **at the same time**. Lane A is pure GDScript, Lane B
is pure Markdown; they share no owned files.

**Base:** `main` @ `78a4e22` — CI green (gdlint · import · GUT 234/234 · boot).
PRs #22–#25 are all merged. Zero open PRs at time of writing.

---

## Facts every lane needs

- **Godot is not on PATH.** Binary: `C:\Godot\Godot_v4.6.1-stable_win64_console.exe`
  (console build; a GUI build sits alongside it for actually playing).
- **Branch per lane. Never commit to `main`.** Open a PR; CI runs on it.
- Commands, from the repo root:
  ```
  # import (needed after adding any new class_name script)
  & C:\Godot\Godot_v4.6.1-stable_win64_console.exe --headless --path . --import

  # tests
  & C:\Godot\Godot_v4.6.1-stable_win64_console.exe --headless --path . `
      -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json

  # boot smoke
  & C:\Godot\Godot_v4.6.1-stable_win64_console.exe --headless --path . `
      res://scenes/main/main.tscn --quit-after 150

  # lint
  uvx --from "gdtoolkit==4.*" gdlint scripts test
  ```
- ⚠️ **Godot exits 0 even when the scene tree throws `SCRIPT ERROR`,** and GUT
  prints "All tests passed" even when a test file **fails to parse**. Read the
  output, don't trust the exit code.
- The governing decisions are [ADR 0001](../adr/0001-momentum-absorbs-posture.md),
  [ADR 0002](../adr/0002-co-op-is-solo-complete-with-independent-cameras.md),
  [ADR 0003](../adr/0003-shipped-scope.md). The vocabulary is
  [`CONTEXT.md`](../../CONTEXT.md) — **"posture" is not a Wolf Zero term; the
  concept is called Momentum.**

## Shared contracts

| File | Owner | Others may |
|---|---|---|
| `docs/Requirements.md` | **Lane B** | File status-change requests in their final report |
| `docs/STATUS.md` | **Lane B** | File session-log content in their final report |
| `CONTEXT.md` | **Lane B** | Request a term be sharpened; do not edit |
| `docs/adr/*` | **nobody** | Propose an amendment in the report; ADRs are not edited in-flight |

## Integration order

1. **Lane A** merges first (code).
2. **Lane B** merges last, folding in Lane A's requirement-status requests.
3. Reconcile: CI green on merged `main`, then the content lane starts.

---

### Lane A — Momentum absorbs posture · **ready**

- **Scope:** Implement ADR 0001 end to end. Momentum becomes *composure* for
  every combatant, blocking spends it, Breaking opens a Deathblow, and a full bar
  banks a Charge that Echo spends.

- **Owns (exclusive write):**
  - `scripts/ecs/components.gd`
  - `scripts/ecs/systems/momentum_system.gd`
  - `scripts/ecs/systems/parry_system.gd`
  - `scripts/ecs/systems/combat_system.gd`
  - `scripts/ecs/systems/echo_system.gd`
  - `scripts/ecs/systems/boss_system.gd`
  - `scripts/ecs/systems/dodge_system.gd`
  - `scripts/entities/entity_factory.gd`
  - `scripts/main/main.gd`
  - `scripts/autoload/game_events.gd`
  - `scripts/ui/hud.gd`
  - `scripts/ui/tutorial.gd`
  - `test/**` (all)

- **Reads (no write):** `docs/adr/0001-*`, `CONTEXT.md`, `docs/Requirements.md` §2.10

- **Depends on / blocks:** Nothing. Blocks the content lane (enemy tuning needs
  the new model settled).

#### What to build

**Momentum = composure, on every combatant.**
- Starts **empty**. Blocking **spends** it; parrying and landing attacks **build**
  it. Reaching zero = **Broken**: staggered, unable to act, open.
- Decay on idle stays (currently `decay_rate` 5/s after a 2s `decay_delay`).
- Filling to max **banks a Charge** and resets to a **floor, not zero** — ADR 0001
  suggests ~40 of 100 but the number is yours to pick and justify.

**Charges.**
- Small non-decaying pool, cap ~3. The **only** gate on what they buy.
- **Echo costs 1 Charge.** Delete its 8s cooldown *and* its momentum gate — it is
  currently double-gated at `momentum_system.gd:26` plus
  `echo_data.cooldown_duration`.

**Delete the thresholds.** `threshold_echo` 25, `threshold_damage` 50 (the +20%
damage bonus), `threshold_duration` 75. Under a bar that oscillates between the
floor and max these flicker several times a fight. `threshold_ultimate` 100
becomes the bank trigger. Their `GameEvents` signals and the HUD flashes that
listen to them go too.

**Enemy Momentum + Deathblow.**
- Player **parries drain enemy Momentum**; at zero the enemy is Broken.
- Deathblow on a Broken regular enemy **kills outright**, whatever health remains.
- Deathblow on a Broken boss **ends one phase**; in the final phase it kills.
  `boss.phase` and `BossSystem`'s transitions already exist to build on.

#### Known traps

- **Enemies have no `momentum` component today.** `main._spawn_enemy` doesn't add
  one. You must add it — and note that `MomentumSystem` processes everything with
  a `momentum` component, so enemies will start decaying too. Decide whether
  enemy Momentum should decay and say so.
- **Four of six enemy types die in 2–3 light hits (~0.5s)** — Cyber-Ashigaru 25hp,
  Tech-Priest 29, Shinobi Ghost 34, Ronin Drone 42, against 15+(combo×2) damage.
  Their Momentum will almost never matter. **This is expected and accepted**
  (ADR 0001, Consequences) — do not "fix" it by inflating their health.
- `parry.block_damage_mult` (0.3) becomes questionable once blocking costs
  Momentum. Decide whether chip damage survives alongside the Momentum cost or is
  replaced by it, and record which.
- These test files touch momentum/blocking and **will need rewriting**:
  `test_momentum_decay`, `test_momentum_routing`, `test_block`, `test_perilous`,
  `test_echo_record_playback`, `test_parry_resolution`, `test_tutorial`.
- `input_manager.gd` and `tutorial.gd` reference momentum — check before assuming
  the blast radius is only the ECS.

- **Done when:**
  - Blocking drains Momentum and reaching zero Breaks the player.
  - Parrying drains enemy Momentum; Breaking a regular enemy allows a Deathblow
    that kills it outright regardless of remaining health.
  - Breaking a boss removes exactly one phase.
  - Filling the bar banks a Charge and resets to the floor; Echo spends a Charge
    and has no cooldown and no momentum gate.
  - No `threshold_echo` / `threshold_damage` / `threshold_duration` remains
    anywhere in `scripts/`.
  - New GUT coverage for: block drain, Break, Deathblow kill, boss phase removal,
    Charge bank + floor reset, Echo spend, and Echo refusal at zero Charges.

- **Verify:** `gdlint` clean · `--import` clean · full GUT suite green with no
  `Failed to load script` in the output · boot smoke with no `SCRIPT ERROR`.
  Report the actual test totals, not "tests pass".

- **Open questions to decide and document:** the floor value; the Charge cap;
  Momentum cost per blocked hit; enemy Momentum drain per parry; whether enemy
  Momentum decays; whether block chip damage survives; whether the Deathblow is
  automatic on Break or a separate input.

---

### Lane B — Requirements scope pass · **ready**

- **Scope:** Bring the documentation in line with ADR 0003. Every requirement
  gets a launch disposition, so the docs describe *the game being shipped* rather
  than the 12-mission game that was originally specified.

- **Owns (exclusive write):**
  - `docs/Requirements.md`
  - `docs/CoreDesign.md`
  - `docs/STATUS.md`
  - `docs/IDEA-BANK.md`
  - `CONTEXT.md`

- **Reads (no write):** `docs/adr/*`, `scripts/**`, `docs/CODEBASE-DIGEST.md`

- **Depends on / blocks:** Independent, but **merges last** so it can absorb Lane
  A's requirement-status requests.

#### What to build

**Give every requirement a launch disposition.** v1.1 answered *"is it built?"*.
It must now also answer *"is it in the shipped game?"*. Anything cut is marked
and cross-referenced to `IDEA-BANK.md` rather than deleted.

Sections that ADR 0003 cuts to near zero — confirm each against the ADR rather
than assuming this list is complete:
- `FR-SKL-001→007` (30 skills), all `FR-CUR-*` (three currencies)
- `FR-WPN-002→010` (four extra weapons)
- All `FR-NAR-*` — the whole narrative layer
- `FR-ECH-011→015` (Echo upgrades)
- `FR-MSN-001` — 12 missions becomes **4–6 levels**
- `FR-MOV-006` grapple, `FR-CMB-011/012` launchers and air combos
- `FR-EXP-002/003/004/007`
- `FR-MNU-003/004/006/007` (mission select, loadout, skills, armory)

**Add what the ADRs created and no requirement covers:**
- **Boss Gauntlet** — a new section. Bosses and elites back to back, scored on
  time and defensive performance, no health restored between fights, the home of
  ad-hoc co-op.
- **Co-op per ADR 0002** — §2.5 currently reads as v1.0. Solo-complete is the
  rule, cameras are fully independent, co-op is expressed through proximity
  verbs and a shared Charge pool. Re-prioritise accordingly and resolve the §9.5
  divergence, which this closes.

**Reconcile `CoreDesign.md`.** Its body still describes 12 missions, the mission
list in Appendix A, skill trees, the weapon roster, and the Echo upgrade path as
if all were shipping. §6.1 still carries the "never required" co-op banner that
ADR 0002 supersedes.

**Rewrite the `STATUS.md` state summary** to describe the shipped shape and the
current plan, and append a session entry.

#### Known traps

- v1.1's status vocabulary is *build* state (Draft / In Progress / Complete /
  Deferred / Superseded). Launch scope is a **second, orthogonal axis** — a
  requirement can be `Complete` and still out of scope, or `Draft` and still P0.
  Don't overload one column to mean both; pick a representation and state it in
  §1.4.
- `Requirements.md` §9 already lists nine divergences. ADR 0002 closes §9.5 and
  ADR 0001 closes §9.7 — mark them resolved rather than leaving them open.
- Do **not** change any requirement's *build* status to reflect Lane A's work.
  Lane A will file those as contract requests; apply them at integration.

- **Done when:**
  - Every requirement has an unambiguous launch disposition.
  - No row is both P0 and pointed at the Idea Bank.
  - Every cut section cross-references `IDEA-BANK.md`, and every Idea Bank entry
    traces back to a requirement ID or is explicitly new.
  - Boss Gauntlet requirements exist.
  - §2.5 co-op matches ADR 0002; §9.5 and §9.7 are marked resolved.
  - `CoreDesign.md` contains no surviving claim that 12 missions, skill trees,
    the economy, or the 4 extra weapons are launch content.
  - `STATUS.md` describes the shipped shape.

- **Verify:** No automated check exists for prose. Do this instead, and paste the
  results: (1) grep `Requirements.md` for any `P0` row whose disposition is
  Idea Bank — expect zero hits; (2) grep `CoreDesign.md` for `12 main`,
  `skill tree`, `Neon Yen` and confirm each surviving hit is explicitly labelled
  post-launch; (3) confirm every `FR-` ID named in `IDEA-BANK.md` still exists in
  `Requirements.md`.

- **Open questions to decide and document:** how launch scope is represented
  (extra column, strikethrough, a dedicated section, priority `P3`); whether
  4 or 6 levels is the target, since ADR 0003 gives a range and content planning
  needs a number; whether the narrative floor is "no story at all" or "enough
  Neo Edo flavour to make the setting land".

---

## What the content lane needs from these

The follow-on content work (levels 3–6, remaining bosses, foreground tileset)
**should not start until both lanes are merged**:

- From **Lane A** — enemy tuning is meaningless until Momentum, Breaking, and
  Deathblow exist, since Deathblow changes time-to-kill for every durable enemy.
- From **Lane B** — the level count. ADR 0003 says 4–6; content needs one number.

Also outstanding and **not** in either lane: arena `trigger_x` distances were
tuned before the player got roughly 2× faster (PR #23), and ADR-era design makes
enemies optional obstacles rather than gates. That needs a level-design pass, not
a number tweak, and belongs to the content lane.
