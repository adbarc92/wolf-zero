# 2. Co-op is solo-complete, with fully independent cameras

Date: 2026-08-15

## Status

Accepted

## Context

Ad-hoc co-op is one of the three product pillars, but the documents contradicted
themselves about what that meant. `Requirements.md` FR-COP-001 was P0 and
asserted "all content shall be completable in solo mode"; `CoreDesign.md` §6.1
said co-op "enhances the experience but is never required"; the stated vision
said co-op is *core*. Those cannot all be priorities.

The audience settles it. The target player is 14–25 and playing **on a commute**,
which is usually alone. Ad-hoc co-op requires two co-located people with two
devices — a school or social context, not a train seat. A game that *requires*
co-op is unplayable in its own most common context.

Monster Hunter on PSP is the proven resolution for this exact audience and
constraint: completable solo, while co-op was the cultural centre and the reason
it spread.

Separately, the co-op camera model was undecided, and it constrains every level
built from here. The mobility pillar effectively forces it: dash-jump moves the
player at 800 px/s, a screen is roughly 1920 world units, and Level One is 5200
across — two players moving apart are a full screen apart in about 2.4 seconds.

## Decision

**Co-op is solo-complete and co-op-elevated.** Identical content either way. Solo
is never the lesser experience and requires no AI companion. "Core" means core to
the product's identity and word-of-mouth, not core to playability.

**Cameras are fully independent.** Each device follows its own player. Players
separate freely; there is no leash and no shared view.

Consequences that follow directly:

- Co-op is expressed through **proximity verbs** — linked deflects, one player
  Breaking while the other Deathblows — so converging is a tactical choice
  rather than a constraint.
- The **Charge pool is shared** between players (see ADR 0001), which is the
  Shared Energy Core `CoreDesign.md` §6.3.1 already specified.
- **Arenas activate on the first player to cross the trigger** and stay active
  until cleared or both players have left.

## Consequences

**Good**

- Resolves the FR-COP-001 contradiction without weakening either pillar.
- No AI companion to build (FR-SOL-004 can be dropped).
- Independent cameras keep the mobility pillar intact; a leash on an 800 px/s
  character would fight the game's best verb constantly.
- Two phones means no one is looking at a shared screen anyway, so a shared
  camera would have been solving a problem that does not exist here.
- Splitting up to travel and converging to fight gives co-op a real texture
  beyond "same content, two people".

**Costs and risks**

- `_level.arena_to_activate(px, ...)` takes a single player position and has no
  answer for two. It needs a multi-player signature.
- Encounter design must work when players arrive at different times, or when one
  player is elsewhere entirely.
- Two independent cameras mean neither player necessarily sees the other's
  situation, so any "partner in trouble" feedback has to be explicit in the HUD.
- Proximity verbs are invisible to a solo player, so they must be genuinely
  optional rather than the best way to fight.

## Alternatives considered

- **Co-op-first, solo-adapted.** Rejected: the common case (a lone commuter)
  would play a version the design treats as a compromise, and it requires
  building a competent AI partner.
- **Separate solo and co-op modes.** Rejected: roughly doubles content against
  very limited production capacity.
- **Some content co-op-only.** Rejected: strands solo players behind a wall they
  may never pass.
- **Leashed or shared camera.** Rejected: taxes dash-jump, the verb the mobility
  pillar rests on.
