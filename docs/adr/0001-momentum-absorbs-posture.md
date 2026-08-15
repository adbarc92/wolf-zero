# 1. Momentum absorbs posture; a full bar banks a Charge

Date: 2026-08-15

## Status

Accepted

## Context

Wolf Zero's stated formula is **Mega Man X + Sekiro**. Sekiro's defensive core is
a posture economy: blocking drains posture rather than health, a well-timed block
deflects and damages the *enemy's* posture, and a posture break opens a
deathblow.

The build had no posture. Block was a flat 30% health chip with no knockback and
no stagger, costing only 15% movement speed — close to strictly good, with no
reason not to hold it. Meanwhile a **Momentum** gauge already existed, built from
attacks (+5), dodges (+10) and parries (+15), decaying at 5/s after a 2s idle
delay, with thresholds at 25 (Echo unlock), 50 (+20% damage), 75 (Echo duration)
and 100 (an ultimate that was never built).

The naive fix — add a posture bar — would have given the player three combat
meters (health, momentum, posture) on a phone screen already showing health,
momentum, lives and a boss bar. Momentum and posture would also have been
rewarded by overlapping actions: parry fed momentum, and deflect is the
posture verb.

A second problem: Echo was gated **twice**, on a momentum threshold *and* an
8-second cooldown, for no design reason. Echo was simultaneously the most-built
system and the one with the least clear role.

## Decision

**Momentum absorbs posture. There is one bar.**

Momentum means **composure**, symmetrically for every combatant. High is in
control; zero is **Broken** — staggered, unable to act, open.

- **Blocking spends** Momentum. **Parrying and attacking build** it.
- The player is Broken by blocking with nothing left to spend.
- An enemy is Broken by the player's parries draining theirs.
- The bar **starts empty**, so the opening of a fight must be offensive.
  Aggression is what funds the ability to defend; turtling from frame one is not
  available.
- Filling it completely **banks a Charge** and resets to a partial floor, not to
  zero, so the player is not left defenceless immediately after their best play.

**Charges** are a small, non-decaying pool spent on abilities. Echo costs one
Charge and loses both its cooldown and its momentum gate. The 25 / 50 / 75
thresholds are deleted.

## Consequences

**Good**

- Block acquires the cost it never had. Holding it is now a resource decision.
- One bar, not three. The HUD keeps its current bar count.
- Echo gets an identity — the thing you buy by fighting well — and stops being
  double-gated.
- The Charge pool is structurally the **Shared Energy Core** that
  `CoreDesign.md` §6.3.1 specifies for co-op, so the co-op pillar inherits its
  resource rather than needing a new one.
- Aggression-funds-defence gives the opening of every fight a shape.

**Costs and risks**

- The 25 / 50 / 75 threshold effects are removed, including the +20% damage
  bonus. Under a bar that oscillates between the floor and 100, those thresholds
  would have flickered several times per fight rather than being states the
  player earns.
- `MomentumSystem`, `CombatSystem`, `ParrySystem`, `EchoSystem`, the HUD and
  every combat test are affected. This is the largest single change to the
  combat model since the slice was built.
- Momentum starting empty means the player cannot block at the very start of an
  encounter. This is intended, but it is unusual and will need teaching.
- Enemy Momentum is irrelevant for most of the roster: four of six enemy types
  die in two or three light attacks (~0.5s), well before an exchange can happen.
  Posture will only matter against Oni Mech, Elite Oni and bosses. This mirrors
  Sekiro, where mooks die instantly and posture is a miniboss-and-boss system,
  so it is accepted rather than solved.

## Alternatives considered

- **Posture alongside momentum (Sekiro-exact).** Rejected: three meters on a
  commuter phone screen, with momentum's parry bonus overlapping posture's
  entire reason to exist.
- **Enemies carry posture, the player does not.** Rejected: leaves block free
  for the player, which is the problem being solved.
- **Keep the 30% health chip and just add banking.** Rejected: does not adopt
  posture in any real sense; the Sekiro pillar would stay aspirational.
- **All damage drains momentum, not just blocked damage.** Rejected: risks a
  death spiral during a commute, which is the target play context.
- **Bar starts full (pure composure), overfill banks.** Rejected: "fills up
  several times" becomes "overfill", which is hard to show on a small bar and
  hard to teach.
