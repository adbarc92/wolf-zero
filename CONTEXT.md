# Wolf Zero — Domain Language

The canonical meaning of the terms this project uses. A glossary, not a spec:
no implementation details, no decisions, no status. When a term here conflicts
with how code or docs use it, this file wins and the code is wrong.

---

## Combat

**Momentum**
Composure. The single combat meter, carried by every combatant. High Momentum
means in control; zero means Broken. It is both the offensive rhythm gauge and
Wolf Zero's expression of what Sekiro calls *posture* — there is only one bar.

Momentum decays over time when not fighting. It **starts empty**, so the opening
of a fight must be offensive: aggression is what funds the ability to defend.
Blocking spends it. Parrying and landing attacks build it. Filling it completely
banks a Charge and drops it back to a partial floor, never to zero — the player
is not left defenceless immediately after their best play.

**Broken**
The state of a combatant whose Momentum has reached zero: Staggered, unable to
act, and open. The player is Broken by blocking with nothing left to spend. An
enemy is Broken by the player's Parries draining theirs.

**Charge**
A stable unit banked by filling the Momentum bar. Unlike Momentum, a Charge does
not decay. Charges accumulate in a small pool and are the *only* gate on the
abilities they buy — an ability that costs a Charge has no separate cooldown.
The bar can be filled and banked repeatedly within a single encounter.

In co-op the Charge pool is shared between players, and is what the design
documents previously called the Shared Energy Core.

**Posture**
*Not a separate meter in Wolf Zero.* Where Sekiro tracks posture on a dedicated
gauge, Wolf Zero expresses the same idea through Momentum. Use "Momentum" in
code and docs; reserve "posture" for discussing the Sekiro reference itself.

**Parry**
A tap of the defensive input, timed to an incoming attack. Negates the damage
entirely, reflects some of it to the attacker, and staggers them.

**Block**
The defensive input held rather than tapped. A sustained stance, not a timed
one. Reduces incoming damage rather than negating it, and prevents knockback.

**Perilous attack**
An attack that ignores both Parry and Block. Only dodge invincibility avoids it.
Carries a distinct visual tell so the player can read it as "dodge, don't
defend".

**Stagger**
A temporary state in which a combatant cannot act and is open to attack.

**Deathblow**
The finish available against a Broken enemy. Against a regular enemy a Deathblow
kills outright, whatever health remains — defeating something by Breaking it is
genuinely faster than wearing its health down, which is what makes defence the
central verb rather than an alternative to attacking. Against a boss, a Deathblow
ends one phase; a Deathblow in the final phase kills.

---

## World and structure

**Level**
One playable stage, start to goal. The unit of progression: clearing a Level
advances to the next registered Level. Levels are the real progression unit —
"mission" is legacy vocabulary from the original design documents and should not
be used for new work.

**Arena**
A position-triggered encounter inside a Level. Crossing its trigger spawns its
roster of enemies. An Arena also serves as a checkpoint.

**Enemy**
An obstacle, not a gate. Enemies are **optional** — a skilled player is expected
to be able to navigate past most of them. Their density and placement are the
challenge, not a requirement to clear them.

---

## Co-op

**Ad-hoc co-op**
Two players on two co-located devices over local wireless. Not internet
matchmaking. Named for the handheld ad-hoc play culture the game is aimed at.

**Solo-complete**
The rule that every piece of content can be finished by one player, with no
compromise and no AI partner. Co-op is core to the product's identity, never to
its playability — a lone commuter is the most common context, and the game must
be whole for them.

**Proximity verb**
A co-op action that only exists when both players are near each other — linked
deflects, one player Breaking an enemy while the other lands the Deathblow.
Separation is free; the reward for converging is access to these.

**Gauntlet**
The repeatable mode: bosses and elites fought back to back, scored on time and
on defensive performance, with no health restored between them. Distinct from a
Level — a Gauntlet has no traversal and no goal line, only fights. It is where
ad-hoc co-op is expected to live.

**Echo**
A holographic duplicate of the player that replays the player's own recent
actions. It fights, draws enemy attention, and exists briefly before dissipating.
Deploying an Echo costs a Charge — that is its only cost and its only gate.

---

## Player

**Life**
One attempt within a run. Losing all Lives ends the run. Distinct from health,
which is depleted and restored within a single Life.

**Dash-jump**
Leaving the ground while dashing, carrying the dash's horizontal speed through
the whole jump arc. The primary traversal verb, in the Mega Man X sense.
