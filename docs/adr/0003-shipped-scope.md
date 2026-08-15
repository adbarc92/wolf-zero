# 3. Ship a tight campaign plus a repeatable co-op mode

Date: 2026-08-15

## Status

Accepted

## Context

`Requirements.md` v1.0 specified a 12-mission commercial game: 4 bosses plus
mini-bosses, 5 weapons with unique animations and 5 upgrade tiers each, 30 skills
across 3 trees, 3 currencies, a full narrative arc with briefings and boss
dialogue, 6 environment tilesets, composed music per environment and per boss,
mission-select / loadout / skills / armory / results menus, localization, and
accessibility.

The build has 2 levels, 2 bosses, 1 weapon, 0 skills, no economy, no narrative,
and procedural music.

The whole of PRs #1–#17 landed between 2026-06-04 and 2026-06-21 — about three
weeks of active development. That produced the ECS combat model, 5 enemy types,
2 bosses, 2 levels, art/audio/environment integration, the mobile export
pipeline, and touch controls. Productive, but the remaining specification is a
funded-studio project rather than a continuation of that pace — and every
unbuilt system needs *designing* as well as building.

There is also a structural mismatch. Skill trees, a three-currency economy, and a
twelve-mission narrative all serve a **long campaign**. The audience plays in
10–20 minute commute bursts, and the co-op pillar is what would make them come
back. Monster Hunter — the closest precedent for this audience and this ad-hoc
play pattern — retained players through *repeatable hunts with friends*, not a
linear story.

## Decision

Ship **a tight campaign plus a repeatable mode**:

- **4–6 handcrafted levels** and **3–4 bosses**
- **A Boss Gauntlet** as the repeatable mode — the home of ad-hoc co-op and the
  retention loop
- **Skill trees, the three-currency economy, and the twelve-mission narrative are
  cut to near zero** for launch

The Gauntlet is bosses and elites fought back to back, scored on time and
defensive performance, with no health restored between fights. It was chosen over
the alternatives because it is nearly free — it reuses content the campaign
builds anyway — and because durable opponents are the only place the
Momentum/Deathblow loop is legible at all. Four of six enemy types die in about
half a second, so a wave-survival mode would have exercised crowd navigation
rather than the combat model the game is built on.

Time attack, wave survival, and roguelike runs are all wanted eventually and are
queued in the Idea Bank. None is built until the Gauntlet proves the repeatable
loop is worth returning to.

The combat model is the product. Replayability with a friend is the retention,
not a story.

Everything cut is recorded in [`docs/IDEA-BANK.md`](../IDEA-BANK.md) rather than
deleted, with the test for readmission: *does it make the combat better, or does
it just make the game bigger?*

## Consequences

**Good**

- The game can actually be finished.
- Effort concentrates on the thing that is already good and genuinely
  distinctive — the defensive combat model — plus the pillar with no design work
  yet, co-op.
- Level count drops from 12 to 4–6, so each level can carry real handcrafted
  quality, including the Neo-Edo identity art that is still missing.
- A repeatable mode gives ad-hoc co-op a reason to exist beyond "replay the
  campaign together", and matches commute-length sessions.
- Removes the need to design 30 skills, 3 currencies, and a 12-mission plot.

**Costs and risks**

- A large part of `Requirements.md` becomes out-of-scope-for-launch rather than
  merely unbuilt. The document needs a scope pass to say so.
- Less content overall, which affects perceived value at the $4.99–$9.99 mobile
  price point. The repeatable mode has to genuinely carry replay value.
- Cutting narrative means Neo Edo has to establish itself entirely through art,
  audio, and level design. The setting is a selling point, so this raises the bar
  on the identity art that has not been made yet.
- The repeatable mode is itself an unbuilt system and must not become the new
  scope creep.

## Alternatives considered

- **Full 12-mission game as specified.** Rejected: multi-year at current pace,
  with every unbuilt system needing design as well as implementation.
- **Tight linear campaign only, no repeatable mode.** Rejected: nothing to come
  back to, which wastes the co-op pillar.
- **Episodic — ship Act 1, extend later.** Rejected for now: risks reading as
  unfinished, and leaves progression and narrative in limbo between episodes.
  Remains a viable fallback if the campaign proves too large.
