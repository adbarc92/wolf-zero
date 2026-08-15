# Idea Bank

Deliberately **not being built** for the shipped game (see
[ADR 0003](adr/0003-shipped-scope.md)). Nothing here is rejected on merit — it is
parked so that scope stays honest and the combat model actually ships.

Revisit after the game is out and there is evidence about what players want.

> Rule of thumb before pulling anything out of this file: does it make the
> *combat* better, or does it make the game *bigger*? Only the first kind earns
> its way back in before launch.

**How this file pairs with `Requirements.md`.** Every requirement marked `Parked`
in [`Requirements.md`](Requirements.md) appears here by ID, and every ID named
here still exists there. Nothing is deleted from the requirements document — the
Launch column says it is out of scope, this file says why and what would bring it
back. Anything here **without** an ID is a new idea that was never specified.

---

## Further repeatable modes

The Boss Gauntlet ships first (ADR 0003, `Requirements.md` §2.11). These are
wanted **eventually** — they are queued, not rejected. Each should only be built
once the Gauntlet has proven the repeatable loop is worth returning to.

**Time attack on campaign levels.** *(new — no requirement ID)*
Replay a campaign level scored on time plus style, with leaderboards. The
cheapest of all — zero new content, just scoring and a results screen — and it
showcases dash-jump and the "enemies are optional obstacles" design head on. The
open problem is co-op: a race between two players with independent cameras is
awkward, so it may be a solo-leaning mode.

**Wave survival arena.** *(new — no requirement ID)*
One arena, escalating waves, endless. Cheap, infinitely repeatable, co-op works
naturally. Held back because four of six enemy types die in about half a second,
so today it would test crowd navigation rather than the Momentum/Deathblow loop.
Becomes much more attractive if the roster gains more durable mid-tier enemies —
which the Gauntlet's elites (FR-BOS-008, FR-GNT-015) may well produce.

**Roguelike runs.** *(new — no requirement ID)*
Procedurally ordered arenas with run modifiers and meta-progression. By far the
strongest retention of the four, and the most on-trend for the audience. Also a
second game's worth of systems, which is precisely what ADR 0003 exists to
prevent before launch. The natural "what's next" after the game ships.

**Bonus / challenge levels.**
FR-MSN-002, CR-MSN-004 — six of them in v1.0. Six extra handcrafted levels is
the same cost as the entire remaining campaign, for content most players see
last or never.

---

## Progression systems

**Skill trees — BLADE / SHADOW / ECHO, 10 skills each.**
`Requirements.md` FR-SKL-001→007. The empty `skills_blade` / `skills_shadow` /
`skills_echo` dictionaries already sit in save data. 30 skills is 30 balance
problems and 30 icons, and it serves a long campaign the shipped game does not
have. If any of it returns, the ECHO branch is the interesting one because it
modifies a verb rather than a number.

**Three-currency economy — Neon Yen, Echo Fragments, Legacy Tokens.**
FR-CUR-001→006, with FR-EXP-002/003/004 (mission, combo and challenge XP) and
FR-EXP-007 (per-level stat boosts) as its feeders. Currency is *earned* today and
can never be spent; there is no shop, armory, or upgrade surface. An economy
needs all three of earn, spend, and a reason to care, and none of the three
exists. See `Requirements.md` §9.10 for the loose end this leaves behind: Skill
Points accrue at launch and buy nothing, deliberately unshown.

**Weapon roster — Vibro-Wakizashi, Neon Nodachi, Chain-Kusarigama, Cyber-Tessen.**
FR-WPN-002→010, each with unique animations and 5 upgrade tiers. The Cyber-Tessen
(parry bonus, defensive) is the one most aligned with the defensive conceit and
would be the first to revisit.

---

## Narrative

**The full story: Kira, the erased family, the Digital Shogun.**
FR-NAR-001 (mission briefings), FR-NAR-003 (data logs), FR-NAR-004 (boss
dialogue), FR-MSN-008 (pre-level briefings), and `CoreDesign.md` §11. Twelve
missions of briefings, boss dialogue, data-log collectibles, and a story climax.
**None of it exists in the build** — no character is named anywhere in the game.

**The Digital Shogun as final boss.**
FR-BOS-004. He is the climax of the plot above, and a final boss whose whole
point is a story beat costs more than it returns in a game that tells no story.
**Iron Daimyo** (FR-BOS-003) becomes the campaign's final boss instead. The
Shogun returns with the narrative, not before it.

The shipped game keeps only the minimum needed to make Neo Edo feel like a place
rather than a backdrop: named locations, named bosses, a one-line title card per
level (FR-NAR-006/007), and storytelling carried by the environment art
(FR-NAR-002). The full arc is a sequel-or-later concern.

---

## Traversal and level content

- **Grapple** (FR-MOV-006, and its level-side FR-PLT-006 highlighted grapple
  points) — `has_grapple` flag exists, nothing behind it
- **Air dash as a distinct unlocked verb** (FR-MOV-007) — dash already works
  airborne by accident; making it a real, separate ability is deferred
- **Moving, collapsing, and one-way platforms** (FR-PLT-002→004)
- **Hazards** — spikes, laser grids, electrified surfaces (FR-HAZ-001→005);
  physics layer 4 is reserved and unused
- **Interactables** — pressure plates, switches, doors, destructibles,
  cyber-bamboo, holographic bridges, magnetic rails (FR-INT-001→007)
- **Echo puzzle content** (FR-ECH-009) — blocked on interactables existing

If one of these turns out to be what makes a campaign level interesting rather
than merely longer, that is a legitimate reason to pull it back early — one-way
platforms are the likeliest candidate.

---

## Combat extensions

**Launchers and air combos.**
FR-CMB-011 (launch enemies into the air) and FR-CMB-012 (air combos on launched
enemies), plus their co-op derivative FR-CPM-005 (Launcher Combo: one player
launches, the other air-combos). A whole second combat vocabulary, and one that
pulls toward juggling and attrition rather than the timing-and-Break loop the
game is built on.

## Echo upgrades

FR-ECH-011→015: Extended Memory, Rapid Recall, Solid Echo, Dual Echo, Persistent
Echo. Save-data fields exist with no unlock path. Note that Rapid Recall
(FR-ECH-012, "reduce cooldown to 6 seconds") no longer has anything to reduce —
[ADR 0001](adr/0001-momentum-absorbs-posture.md) removed the Echo cooldown and
made a Charge its only gate. **Dual Echo** is the one worth revisiting first —
two Echoes is a genuinely different verb, and it has obvious co-op resonance.

## Ultimate attack

FR-MOM-009/010. The 100% momentum threshold currently fires and nothing happens.
Superseded by Charges (ADR 0001), but a Charge-funded ultimate remains an
obvious future spend.

---

## Online co-op services

[ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md) scopes
co-op to **two co-located devices on local wireless**. Everything that assumes a
server, an account or the internet is parked with it:

- **Friend invites** (FR-COP-004) and **matchmaking** (FR-COP-005) — both need
  accounts and a service; ad-hoc pairing is local discovery (FR-COP-008)
- **Host migration** (FR-COP-006, TR-NET-004, NFR-REL-005) — with exactly two
  players there is no one to migrate to; the shipped behaviour is to degrade to
  solo (FR-COP-011)
- **NAT traversal** (TR-NET-005) — nothing traverses a NAT on the same wireless
  network
- **Cross-platform co-op** (FR-COP-007) — Mobile↔Mobile and Steam↔Steam
- **Same-device local co-op** (FR-COP-002) — split control zones on a tablet. A
  different mode with different control problems, not a cheaper version of
  ad-hoc

**Echo Overlap** (FR-CPM-004) — two Echoes in the same space produce an AOE
burst. A real proximity verb, but not one ADR 0002 names, and it needs VFX work
the shipping three (linked attack, linked deflect, Deathblow handoff) do not.

**AI companion.**
FR-SOL-004. Rendered unnecessary by ADR 0002 — the game is solo-complete with no
compensation needed. Only revisit if solo play proves to feel lonely rather than
focused.

---

## Menus and UI surfaces

Each of these is parked because the system behind it is parked. A linear 6-level
campaign with one weapon and no skills has nothing to select, equip, spend or
browse.

- **Mission select** (FR-MNU-003) and its **level thumbnails** (CR-UI-007) —
  campaign replay is a fresh run (FR-MSN-006)
- **Loadout screen** (FR-MNU-004) — one weapon, no skills
- **Skills menu** (FR-MNU-006) and **skill tree icons** (CR-UI-004)
- **Armory** (FR-MNU-007), **weapon icons** (CR-UI-005), **currency icons**
  (CR-UI-006)
- **Gesture control scheme** (FR-CTL-003) and **gesture sensitivity**
  (FR-CTL-005) — the code is retained but dormant; on-screen buttons are the
  shipped default (§9.6)

---

## Platform and service work

- **Cloud saves** (FR-SAV-006), and the platform services behind them:
  Game Center (PR-IOS-004), iCloud sync (PR-IOS-005), Play Games achievements
  (PR-AND-003), Play save sync (PR-AND-004), Steam achievements (PR-STM-005),
  Steam Cloud (PR-STM-006)
- **Steam Deck verification** (PR-STM-007)
- **Localization beyond English** — Japanese is the obvious first, given the
  setting and audience (NFR-LOC-003, NFR-LOC-004). Note that the enabling work,
  a localization-ready string system (NFR-LOC-002/005, TR-DAT-004), *does* ship
- **Product analytics** (BR-ANL-001→003) — completion rates, session duration,
  retention. Crash reporting (BR-ANL-004) ships; funnels do not
- **Marketing tooling** — trailer capture (BR-MKT-001), photo mode (BR-MKT-002)
- **Accessibility beyond the basics**: high contrast (NFR-ACC-003), subtitle
  sizing (NFR-ACC-004), auto-dodge assist (NFR-ACC-005), one-handed simplified
  mode (NFR-USE-003)

---

## Pre-pivot concepts

An entire earlier direction — history hacking, multi-era cities (Victorian
London, Renaissance Venice), cybernetic companions, crowd riot systems, faction
roles, Leonardo da Vinci and Cleopatra as bosses — lives in
[`docs/archive/`](archive/README.md). Kept for history. Nothing there is planned.
