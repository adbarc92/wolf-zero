# Idea Bank

Deliberately **not being built** for the shipped game (see
[ADR 0003](adr/0003-shipped-scope.md)). Nothing here is rejected on merit — it is
parked so that scope stays honest and the combat model actually ships.

Revisit after the game is out and there is evidence about what players want.

> Rule of thumb before pulling anything out of this file: does it make the
> *combat* better, or does it make the game *bigger*? Only the first kind earns
> its way back in before launch.

---

## Progression systems

**Skill trees — BLADE / SHADOW / ECHO, 10 skills each.**
`Requirements.md` FR-SKL-001→007. The empty `skills_blade` / `skills_shadow` /
`skills_echo` dictionaries already sit in save data. 30 skills is 30 balance
problems and 30 icons, and it serves a long campaign the shipped game does not
have. If any of it returns, the ECHO branch is the interesting one because it
modifies a verb rather than a number.

**Three-currency economy — Neon Yen, Echo Fragments, Legacy Tokens.**
FR-CUR-001→006. Currency is *earned* today and can never be spent; there is no
shop, armory, or upgrade surface. An economy needs all three of earn, spend, and
a reason to care, and none of the three exists.

**Weapon roster — Vibro-Wakizashi, Neon Nodachi, Chain-Kusarigama, Cyber-Tessen.**
FR-WPN-002→010, each with unique animations and 5 upgrade tiers. The Cyber-Tessen
(parry bonus, defensive) is the one most aligned with the defensive conceit and
would be the first to revisit.

**XP stat boosts and the level-30 curve.**
FR-EXP-007. Levelling grants skill points that currently buy nothing.

---

## Narrative

**The full story: Kira, the erased family, the Digital Shogun.**
`CoreDesign.md` §11. Twelve missions of briefings, boss dialogue, data-log
collectibles, and a story climax. **None of it exists in the build** — no
character is named anywhere in the game.

The shipped game keeps only the minimum needed to make Neo Edo feel like a place
rather than a backdrop. The full arc is a sequel-or-later concern.

---

## Traversal and level content

- **Grapple** (FR-MOV-006) — `has_grapple` flag exists, nothing behind it
- **Air dash as a distinct unlocked verb** (FR-MOV-007) — dash already works
  airborne by accident; making it a real, separate ability is deferred
- **Moving, collapsing, and one-way platforms** (FR-PLT-002→004)
- **Hazards** — spikes, laser grids, electrified surfaces (FR-HAZ-001→005);
  physics layer 4 is reserved and unused
- **Interactables** — pressure plates, switches, doors, destructibles,
  cyber-bamboo, holographic bridges, magnetic rails (FR-INT-001→007)
- **Echo puzzle content** (FR-ECH-009) — blocked on interactables existing

---

## Echo upgrades

FR-ECH-011→015: Extended Memory, Rapid Recall, Solid Echo, Dual Echo, Persistent
Echo. Save-data fields exist with no unlock path. **Dual Echo** is the one worth
revisiting first — two Echoes is a genuinely different verb, and it has obvious
co-op resonance.

## Ultimate attack

FR-MOM-009/010. The 100% momentum threshold currently fires and nothing happens.
Superseded by Charges (ADR 0001), but a Charge-funded ultimate remains an
obvious future spend.

---

## Platform and service work

- Cloud saves, achievements (Game Center / Play Games / Steam)
- Cross-platform co-op
- Steam Deck verification
- Localization beyond English — Japanese is the obvious first, given the setting
  and audience (NFR-LOC-003)
- Analytics (BR-ANL-*)
- Accessibility beyond the basics: high contrast, auto-dodge assist, subtitle
  sizing, one-handed mode

---

## AI companion

FR-SOL-004. Rendered unnecessary by ADR 0002 — the game is solo-complete with no
compensation needed. Only revisit if solo play proves to feel lonely rather than
focused.

---

## Pre-pivot concepts

An entire earlier direction — history hacking, multi-era cities (Victorian
London, Renaissance Venice), cybernetic companions, crowd riot systems, faction
roles, Leonardo da Vinci and Cleopatra as bosses — lives in
[`docs/archive/`](archive/README.md). Kept for history. Nothing there is planned.
