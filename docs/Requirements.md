# Wolf-Zero: Requirements Document

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.2 |
| Status | Reconciled against implementation and scoped to ADR 0003 |
| Last Updated | 2026-08-15 |
| Related Documents | CoreDesign.md, CODEBASE-DIGEST.md, STATUS.md, IDEA-BANK.md, docs/adr/ |

> **v1.1 reconciliation note.** v1.0 shipped every requirement as `Draft` and
> never updated one, so the document could not answer the question a requirements
> document exists to answer: *what is left?* v1.1 set a real status on every row
> by tracing against the code, added §2.10 for systems that were built but never
> specified, and recorded the known divergences in §9.
>
> **v1.2 scope note.** v1.1 answered *"is it built?"*. It could not answer *"is
> it in the shipped game?"* — and after [ADR 0003](adr/0003-shipped-scope.md)
> those are different questions. v1.2 adds a **Launch** column to every table
> (§1.4), rewrites §2.5 co-op around [ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md),
> adds §2.11 for the Boss Gauntlet, and marks the ADR-resolved divergences in §9.
>
> Build status reflects the **vertical slice**. Launch disposition reflects the
> **shipped game** ADR 0003 defines: 6 handcrafted levels (floor 4), 4 bosses
> (floor 3), and a Boss Gauntlet. Nothing cut is deleted — every parked row is
> recorded in [`IDEA-BANK.md`](IDEA-BANK.md). Read alongside
> [`STATUS.md`](STATUS.md), which is the living state of the project.

---

## Table of Contents
1. [Introduction](#1-introduction)
2. [Functional Requirements](#2-functional-requirements)
3. [Non-Functional Requirements](#3-non-functional-requirements)
4. [Technical Requirements](#4-technical-requirements)
5. [Content Requirements](#5-content-requirements)
6. [Platform Requirements](#6-platform-requirements)
7. [Business Requirements](#7-business-requirements)
8. [Traceability Matrix](#8-traceability-matrix)
9. [Known Divergences](#9-known-divergences)

> **Launch scope in one line:** a 6-level handcrafted campaign with 4 bosses,
> plus a repeatable Boss Gauntlet (§2.11) that is the home of ad-hoc co-op
> (§2.5). Skill trees, the three-currency economy, the extra weapon roster and
> the twelve-mission narrative are **Parked** — see [`IDEA-BANK.md`](IDEA-BANK.md).

---

## 1. Introduction

### 1.1 Purpose
This document defines all requirements for Wolf-Zero, a 2D side-scrolling hack-and-slash game with platforming elements. Requirements are categorized, prioritized, and assigned unique identifiers for traceability.

### 1.2 Scope
Wolf-Zero is a premium mobile-first game (iOS/Android) with Steam as a secondary platform. The game features a defensive combat conceit, a Holographic Echo mechanic, level-based progression, and ad-hoc co-op multiplayer.

The **shipped game** ([ADR 0003](adr/0003-shipped-scope.md)) is:

- a handcrafted campaign of **6 levels** — the ADR's range is 4–6; content
  planning targets **6**, and **4 levels / 3 bosses is the floor**, not the plan
- **4 bosses** (Crimson Ronin and Oni Warlord are built; Geisha Network and Iron
  Daimyo remain) plus mini-boss elites
- a **Boss Gauntlet** (§2.11) — the repeatable mode and the home of ad-hoc co-op
- co-op that is **solo-complete** ([ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md))

Skill trees, the three-currency economy, the four extra weapons and the
twelve-mission narrative arc are **out of launch scope**, parked in
[`IDEA-BANK.md`](IDEA-BANK.md) rather than deleted.

### 1.3 Requirement Priority Definitions
Priority is importance **within launch scope**. A row that is not in launch scope
carries `P3` (parked) or `—` (removed) — see §1.4.

| Priority | Definition |
|----------|------------|
| **P0 - Critical** | Must have for launch. Game cannot ship without this. |
| **P1 - High** | Should have for launch. Significant impact if missing. |
| **P2 - Medium** | Nice to have for launch. Can be added post-launch. |
| **P3 - Low** | Future consideration. Not planned for initial release. |

### 1.4 The two axes: Status (built?) and Launch (shipping?)

Every row carries **two independent judgements**. Do not read either from the
other. A requirement can be `Complete` and `Parked` (built, but not part of the
launch product — FR-MOM-006), or `Draft` and `P0 / Ship` (unbuilt and required —
FR-COP-003).

**Status — is it built?** (unchanged from v1.1)

| Status | Definition |
|--------|------------|
| **Draft** | Specified, not started |
| **In Progress** | Partially implemented — see the note in the row |
| **Complete** | Implemented and covered by tests or verified in play |
| **Deferred** | Explicitly out of scope for the vertical slice |
| **Superseded** | The design changed; see §9 |

**Launch — is it in the shipped game?** (new in v1.2)

| Launch | Definition | Priority it carries |
|--------|------------|---------------------|
| **Ship** | In the launch build as written | P0–P2 |
| **Ship (reduced)** | Ships in a smaller form than the row specifies; the row text says how | P0–P2 |
| **Parked** | Not in the launch build. Recorded in [`IDEA-BANK.md`](IDEA-BANK.md); may return post-launch | **P3** |
| **Removed** | The design no longer exists — superseded by an ADR, not parked | **—** |

Two rules keep the axes from collapsing into one:

1. **No row is both `P0` and `Parked`.** Parked rows are demoted to `P3` in the
   same edit that parks them.
2. **Every `Parked` row has an entry in [`IDEA-BANK.md`](IDEA-BANK.md)** naming
   its requirement ID, and every ID named there still exists here. Nothing is
   deleted; scope changes are recorded, not erased.

`Removed` is reserved for design that an ADR replaced outright — the momentum
thresholds and the Echo cooldown ([ADR 0001](adr/0001-momentum-absorbs-posture.md)),
the auto-revive (§9.2). Those are not waiting in the Idea Bank; they are gone.

---

## 2. Functional Requirements

### 2.1 Player Character

#### 2.1.1 Movement
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-MOV-001 | Player shall move horizontally on a 2D plane | P0 | Complete | Ship |
| FR-MOV-002 | Player shall be able to jump with variable height based on input duration | P0 | Complete | Ship |
| FR-MOV-003 | Player shall be able to perform wall jumps on designated surfaces | P0 | Complete | Ship |
| FR-MOV-004 | Player shall be able to wall run horizontally along designated surfaces | P0 | Complete | Ship |
| FR-MOV-005 | Player shall be able to perform a ground dash | P0 | Complete — granted at spawn, not mission-gated (§9.1) | Ship |
| FR-MOV-006 | Player shall be able to grapple to designated points | P3 | Draft — `has_grapple` flag exists, no implementation | Parked |
| FR-MOV-007 | Player shall be able to perform an air dash | P3 | In Progress — dash has no ground check so it works airborne, but `has_air_dash` is unused | Parked |
| FR-MOV-008 | Player shall experience gravity when airborne | P0 | Complete | Ship |
| FR-MOV-009 | Player movement shall feel responsive with <50ms input latency | P0 | Complete — retuned to ~1-frame accel/decel | Ship |
| FR-MOV-010 | Player shall retain dash speed through a jump arc (dash-jump) | P0 | Complete — added 2026-08-15 | Ship |

#### 2.1.2 Combat - Basic Actions
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-CMB-001 | Player shall perform light attacks via tap input | P0 | Complete | Ship |
| FR-CMB-002 | Light attacks shall chain up to 5 consecutive hits | P0 | Complete | Ship |
| FR-CMB-003 | Player shall perform heavy attacks via directional swipe | P0 | Complete | Ship |
| FR-CMB-004 | Heavy attacks shall be directional (up, forward, down) | P0 | Complete | Ship |
| FR-CMB-005 | Heavy attacks shall break enemy armor | P0 | Complete | Ship |
| FR-CMB-006 | Player shall perform dodge with invincibility frames | P0 | Complete | Ship |
| FR-CMB-007 | Dodge i-frames shall last 0.2-0.3 seconds | P0 | Complete — window is 0.05s→0.25s of a 0.3s roll | Ship |
| FR-CMB-008 | Player shall perform parry via tap at moment of enemy impact | P0 | Complete | Ship |
| FR-CMB-009 | Successful parry shall reflect damage to attacker | P1 | Complete | Ship |
| FR-CMB-010 | Player shall perform aerial attacks while airborne | P0 | Complete | Ship |
| FR-CMB-011 | Player shall be able to launch enemies into the air | P3 | Draft | Parked |
| FR-CMB-012 | Player shall perform air combos on launched enemies | P3 | Draft | Parked |

#### 2.1.3 Momentum System

> **[ADR 0001](adr/0001-momentum-absorbs-posture.md) rewrote this section's
> design.** Momentum absorbs posture: there is one bar, it starts empty,
> blocking spends it, parrying and attacking build it, zero is **Broken**, and
> filling it **banks a Charge**. The 25 / 50 / 75 thresholds are deleted
> (`Removed` below); the 100% ultimate is `Parked`
> ([IDEA-BANK](IDEA-BANK.md#ultimate-attack)). Requirements for Charges, Broken
> and Deathblow are being filed by the ADR 0001 implementation lane and are not
> pre-empted here. Build statuses below are pre-ADR-0001 and will move with that
> work.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-MOM-001 | System shall track player momentum as a 0-100% gauge | P0 | Complete | Ship |
| FR-MOM-002 | Momentum shall increase from **landing** an attack, not from swinging | P0 | Complete | Ship |
| FR-MOM-003 | Momentum shall increase from successful dodges | — | Complete | Removed |
| FR-MOM-004 | Momentum shall increase from successful parries | P0 | Complete | Ship |
| FR-MOM-005 | Momentum shall decay slowly when not in combat | P0 | Complete | Ship — player only; enemy Momentum does not decay (FR-MOM-015) |
| FR-MOM-006 | At 25% momentum, Echo abilities shall unlock | — | Complete | Removed |
| FR-MOM-007 | At 50% momentum, attack damage shall increase by 20% | — | Complete | Removed |
| FR-MOM-008 | At 75% momentum, Echo duration shall extend | — | In Progress — threshold fires, no effect wired | Removed |
| FR-MOM-009 | At 100% momentum, ultimate attack shall become available | P3 | Draft — **threshold fires and nothing happens** | Parked |
| FR-MOM-010 | Ultimate attack shall consume all momentum when used | P3 | Draft | Parked |
| FR-MOM-011 | Blocking shall spend Momentum equal to the raw incoming damage | P0 | Complete | Ship |
| FR-MOM-012 | Momentum reaching zero shall Break the combatant: staggered, unable to act, open | P0 | Complete | Ship |
| FR-MOM-013 | Filling the bar shall bank a Charge and reset Momentum to a partial floor, never zero | P0 | Complete | Ship |
| FR-MOM-014 | Charges shall accumulate in a capped, non-decaying pool | P0 | Complete | Ship |
| FR-MOM-015 | Enemies shall carry Momentum that starts full and is moved only by the player's parries | P0 | Complete | Ship |

> **Implemented 2026-08-15** (PR #28). Chosen values: bank floor **40/100**, Charge
> cap **3**, block cost **raw damage × 1.0**, parry drain **34** (so exactly three
> parries Break any enemy), Broken duration **2.0s** player / **2.5s** enemy.
> FR-MOM-003 is `Removed`: dodge is already paid for in i-frames, and its old +10
> undercut parry's +15.

#### 2.1.4 Holographic Echo System

> Echo ships as the base ability. Its **cooldown is `Removed`** — under
> [ADR 0001](adr/0001-momentum-absorbs-posture.md) deploying an Echo costs a
> **Charge**, and that is its only gate. The five upgrades (FR-ECH-011→015) and
> Echo puzzle content (FR-ECH-009, which needs interactables that are themselves
> parked) are in [IDEA-BANK § Echo upgrades](IDEA-BANK.md#echo-upgrades).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-ECH-001 | System shall continuously record last 3 seconds of player actions | P0 | Complete | Ship |
| FR-ECH-002 | Player shall deploy Echo via dedicated input | P0 | Complete | Ship |
| FR-ECH-003 | Echo shall appear at player's current position on activation | P0 | Complete | Ship |
| FR-ECH-004 | Echo shall replay recorded actions as holographic duplicate | P0 | Complete | Ship |
| FR-ECH-005 | Echo playback duration shall be 3 seconds base | P0 | Complete | Ship |
| FR-ECH-006 | Echo cooldown shall be 8 seconds base | — | Complete | Removed |
| FR-ECH-007 | Echo shall deal damage to enemies on contact | P0 | Complete | Ship |
| FR-ECH-008 | Echo shall draw enemy aggro/attention | P0 | Complete | Ship |
| FR-ECH-009 | Echo shall be able to activate pressure plates | P3 | Draft — blocked on FR-INT-001 | Parked |
| FR-ECH-010 | Echo shall be visually distinct (translucent cyan, scan-lines) | P0 | Complete | Ship |
| FR-ECH-011 | Extended Memory upgrade shall increase recording to 4 seconds | P3 | Draft — save field exists, no unlock path | Parked |
| FR-ECH-012 | Rapid Recall upgrade shall reduce cooldown to 6 seconds | — | Draft | Removed — there is no cooldown left to reduce (ADR 0001) |
| FR-ECH-013 | Solid Echo upgrade shall enable physical object interaction | P3 | Draft — save field exists, no unlock path | Parked |
| FR-ECH-014 | Dual Echo upgrade shall allow two simultaneous Echoes | P3 | Draft — save field exists, no unlock path | Parked |
| FR-ECH-015 | Persistent Echo upgrade shall extend duration to 5 seconds | P3 | Draft — save field exists, no unlock path | Parked |

#### 2.1.5 Weapons

> **Launch ships one weapon.** The Plasma Katana is the whole roster. The four
> unlockable weapons, their animations, their five upgrade tiers and their Neon
> Yen cost are parked — [IDEA-BANK § Weapon roster](IDEA-BANK.md#progression-systems).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-WPN-001 | Player shall start with Plasma Katana (balanced stats) | P0 | Complete | Ship |
| FR-WPN-002 | System shall support 4 additional unlockable weapons | P3 | Draft | Parked |
| FR-WPN-003 | Vibro-Wakizashi shall provide fast combos, quick Echo, low damage | P3 | Draft | Parked |
| FR-WPN-004 | Neon Nodachi shall provide high damage, wide arc, slow recovery | P3 | Draft | Parked |
| FR-WPN-005 | Chain-Kusarigama shall provide range, enemy pull, complex timing | P3 | Draft | Parked |
| FR-WPN-006 | Cyber-Tessen shall provide parry bonus, defensive playstyle | P3 | Draft | Parked |
| FR-WPN-007 | Each weapon shall have unique attack animations | P3 | Draft | Parked |
| FR-WPN-008 | Each weapon shall have 5 upgrade tiers | P3 | In Progress — tier data and cap implemented, no content | Parked |
| FR-WPN-009 | Weapon upgrades shall cost Neon Yen currency | P3 | Draft — no spend path | Parked |
| FR-WPN-010 | Player shall be able to switch weapons between missions | P3 | Draft | Parked |

#### 2.1.6 Health & Damage
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-HLT-001 | Player shall have a health pool displayed in HUD | P0 | Complete | Ship |
| FR-HLT-002 | Player health shall decrease when hit by enemies | P0 | Complete | Ship |
| FR-HLT-003 | Player shall die when health reaches zero | P0 | Complete | Ship |
| FR-HLT-004 | Player shall respawn at last checkpoint on death | P0 | Complete | Ship |
| FR-HLT-005 | Solo mode shall provide one auto-revive per checkpoint | — | Superseded — replaced by a 3-lives run model (§9.2) | Removed |
| FR-HLT-006 | Health pickups shall restore player health | P1 | Draft | Ship |
| FR-HLT-007 | Player shall have brief invincibility after taking damage | P0 | Complete | Ship |

### 2.2 Enemies

#### 2.2.1 Enemy Types
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-ENM-001 | Ronin Drone: Basic melee enemy with telegraphed attacks | P0 | Complete — but see §9.3, it has no archetype entry | Ship |
| FR-ENM-002 | Cyber-Ashigaru: Ranged enemy with low health | P0 | Complete | Ship |
| FR-ENM-003 | Oni Mech: Heavy armored enemy, slow attacks | P0 | Complete | Ship |
| FR-ENM-004 | Shinobi Ghost: Cloaking enemy with backstab attacks | P1 | Complete | Ship |
| FR-ENM-005 | Tech-Priest: Support enemy that buffs allies and summons | P1 | In Progress — heals allies, does not summon | Ship |
| FR-ENM-006 | All enemies shall have visible attack telegraphs | P0 | Complete | Ship |
| FR-ENM-007 | Enemies shall have distinct audio cues for attacks | P0 | In Progress — shared SFX, not per-enemy | Ship |
| FR-ENM-008 | Enemy health shall be reduced by 15% in solo mode | P0 | Complete | Ship |

#### 2.2.2 Boss Enemies

> **The launch roster is 4 bosses** (ADR 0003 allows 3–4; planning targets 4,
> with 3 as the floor): **Crimson Ronin** and **Oni Warlord** are built,
> **Geisha Network** and **Iron Daimyo** remain. **Iron Daimyo becomes the final
> boss.** The **Digital Shogun is parked** — he is the climax of a plot the
> shipped game does not tell, and a final boss whose whole point is a story beat
> costs more than it returns
> ([IDEA-BANK § Narrative](IDEA-BANK.md#narrative)).
>
> Mini-boss elites (FR-BOS-008) are promoted rather than cut: the Boss Gauntlet
> (§2.11) needs durable opponents between boss fights, and elites are tuned
> variants of enemies that already exist.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-BOS-001 | Crimson Ronin: Tests parry timing mechanics | P0 | Complete — mid-boss of Level One | Ship |
| FR-BOS-002 | Geisha Network: Tests Echo usage for multi-target | P0 | Draft | Ship |
| FR-BOS-003 | Iron Daimyo: Tests platform combat, has phase transitions — **final boss of the campaign** | P0 | Draft | Ship |
| FR-BOS-004 | Digital Shogun: Final boss testing all mechanics | P3 | Draft | Parked |
| FR-BOS-005 | Bosses shall have multiple distinct attack patterns | P0 | Complete | Ship |
| FR-BOS-006 | Bosses shall have phase transitions with visual/audio feedback | P0 | Complete | Ship |
| FR-BOS-007 | Bosses shall have clearly telegraphed vulnerable windows | P0 | Complete | Ship |
| FR-BOS-008 | Elite / mini-boss enemies shall appear in mid-level arenas and in the Gauntlet | P1 | Draft | Ship |
| FR-BOS-009 | Oni Warlord: perilous-heavy final boss, gates the win | P0 | Complete — built, previously unspecified | Ship |
| FR-BOS-010 | A Deathblow on a Broken boss shall end exactly one phase; in the final phase it shall kill | P0 | Complete | Ship |

> FR-BOS-010 implemented 2026-08-15 (PR #28). Phase remains a pure function of
> health, so a Deathblow works by dropping the boss to the next phase threshold
> rather than by adding separate bookkeeping. ⚠️ The implementation assumes
> **exactly two phases** (`BossSystem.PHASE_MAX = 2`); a three-phase boss requires
> changing `deathblow_health` and `phase_for_hp` together.

#### 2.2.3 Enemy AI
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-EAI-001 | Enemies shall detect player within defined range | P0 | Complete | Ship |
| FR-EAI-002 | Enemies shall pathfind to player position | P0 | In Progress — direct pursuit only, no pathfinding | Ship |
| FR-EAI-003 | Enemies shall be distracted by Holographic Echo | P0 | Complete | Ship |
| FR-EAI-004 | Enemies shall have behavior states (idle, patrol, alert, combat) | P0 | Complete | Ship |
| FR-EAI-005 | Enemies shall coordinate group attacks when multiple present | P1 | Draft | Ship |

### 2.3 Environment & Platforming

> **Most of this section is parked.** Launch levels are built from static
> platforms, wall-run surfaces and enemy placement — the vocabulary the 6-level
> campaign actually uses. Moving / collapsing / one-way platforms, every hazard,
> and every interactive object are in
> [IDEA-BANK § Traversal and level content](IDEA-BANK.md#traversal-and-level-content).
> If the campaign proves it needs one of them to make a level interesting, that
> is a good reason to pull it back — the test is in the Idea Bank preamble.

#### 2.3.1 Platform Types
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-PLT-001 | Static platforms shall support player weight and collision | P0 | Complete | Ship |
| FR-PLT-002 | Moving platforms shall transport player when standing | P3 | Draft | Parked |
| FR-PLT-003 | Collapsing platforms shall fall after player contact | P3 | Draft | Parked |
| FR-PLT-004 | One-way platforms shall allow jump-through from below | P3 | Draft | Parked |
| FR-PLT-005 | Wall-runnable surfaces shall be visually distinct | P0 | Draft — wall-running works, surfaces are not marked | Ship |
| FR-PLT-006 | Grapple points shall be visually highlighted | P3 | Draft — blocked on FR-MOV-006 | Parked |

#### 2.3.2 Environmental Hazards
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-HAZ-001 | Spike traps shall damage player on contact | P3 | Draft — physics layer 4 reserved, unused | Parked |
| FR-HAZ-002 | Laser grids shall damage player on contact | P3 | Draft | Parked |
| FR-HAZ-003 | Electrified surfaces shall damage player on contact | P3 | Draft | Parked |
| FR-HAZ-004 | Bottomless pits shall instantly kill player | P3 | Draft | Parked |
| FR-HAZ-005 | Hazards shall have visual and/or audio warnings | P3 | Draft | Parked |

#### 2.3.3 Interactive Objects
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-INT-001 | Pressure plates shall activate when player or Echo stands on them | P3 | Draft | Parked |
| FR-INT-002 | Switches shall toggle state when attacked | P3 | Draft | Parked |
| FR-INT-003 | Doors shall open/close based on trigger conditions | P3 | Draft | Parked |
| FR-INT-004 | Destructible objects shall break when attacked | P3 | Draft | Parked |
| FR-INT-005 | Cyber-Bamboo shall be climbable and cuttable | P3 | Draft | Parked |
| FR-INT-006 | Holographic bridges shall appear/disappear on timers or triggers | P3 | Draft | Parked |
| FR-INT-007 | Magnetic rails shall propel player at high speed | P3 | Draft | Parked |

### 2.4 Progression Systems

#### 2.4.1 Level / Mission System
> See §9.4. The build progresses through **levels** via a `Levels` registry. The
> mission API in `GameState` is dead code. These rows are written against levels;
> "mission" is legacy vocabulary (`CONTEXT.md`).
>
> **ADR 0003 cuts 12 missions to 6 levels.** Content planning targets 6 because
> a 4-level campaign at 8–15 minutes each is roughly 40 minutes of content at a
> $4.99–$9.99 price point, which the ADR already flags as the scope's main
> commercial risk. **4 levels and 3 bosses is the floor** the campaign may fall
> back to if levels five and six or the fourth boss slip — it is a fallback, not
> the plan. Missions 7–12 and the bonus missions are parked
> ([IDEA-BANK](IDEA-BANK.md)).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-MSN-001 | Game shall contain **6 handcrafted levels** (was 12 missions; floor of 4) | P0 | In Progress — 2 levels built | Ship (reduced) |
| FR-MSN-002 | Game shall contain 6 bonus/challenge missions | P3 | Draft | Parked |
| FR-MSN-003 | Levels shall unlock sequentially upon completion | P0 | Complete — `Levels.next_after` | Ship |
| FR-MSN-004 | Each level shall be 8-15 minutes in length | P0 | In Progress — unmeasured | Ship |
| FR-MSN-005 | Levels shall contain mid-level checkpoints | P0 | Complete — arena checkpoints | Ship |
| FR-MSN-006 | Completed levels shall be replayable | P2 | Draft — no level select | Ship (reduced) — campaign replay is a fresh run; per-level select is parked with FR-MNU-003 |
| FR-MSN-007 | Results shall display time and score | P1 | Draft | Ship (reduced) — no rewards line; there is no economy to pay out |
| FR-MSN-008 | Briefings shall display before each level | P3 | Draft | Parked |

#### 2.4.2 Experience & Levels

> XP, the level-30 curve and Skill Points are **built and stay in the save file**,
> but with skill trees parked they buy nothing, so **no launch UI surfaces them**
> — that is what `Ship (reduced)` means on these three rows. This is an honest
> loose end, recorded as §9.10; the alternative (deleting a working, tested,
> persisted system that the parked trees will want back) costs more than it
> saves. Mission/combo/challenge XP sources and stat boosts are parked
> ([IDEA-BANK § Progression systems](IDEA-BANK.md#progression-systems)).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-EXP-001 | Player shall earn XP from defeating enemies | P0 | Complete | Ship (reduced) |
| FR-EXP-002 | Player shall earn XP from completing missions | P3 | Draft | Parked |
| FR-EXP-003 | Player shall earn XP from achieving high combos | P3 | Draft | Parked |
| FR-EXP-004 | Player shall earn XP from completing challenges | P3 | Draft | Parked |
| FR-EXP-005 | Player level cap shall be 30 | P0 | Complete | Ship (reduced) |
| FR-EXP-006 | Each level shall grant 1 Skill Point | P0 | Complete | Ship (reduced) |
| FR-EXP-007 | Each level shall provide stat boosts | P3 | Draft — points granted, no stat effect | Parked |

#### 2.4.3 Skill Trees

> **Entirely parked by [ADR 0003](adr/0003-shipped-scope.md).** 30 skills is 30
> balance problems and 30 icons in service of a long campaign the shipped game
> does not have. The empty `skills_blade` / `skills_shadow` / `skills_echo`
> dictionaries stay in save data so nothing has to be migrated if they return.
> [IDEA-BANK § Skill trees](IDEA-BANK.md#progression-systems).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-SKL-001 | BLADE tree shall contain 10 combat-focused skills | P3 | Draft — empty dict in save data | Parked |
| FR-SKL-002 | SHADOW tree shall contain 10 mobility-focused skills | P3 | Draft — empty dict in save data | Parked |
| FR-SKL-003 | ECHO tree shall contain 10 time-mechanic skills | P3 | Draft — empty dict in save data | Parked |
| FR-SKL-004 | Skills shall be purchasable with Skill Points | P3 | Draft | Parked |
| FR-SKL-005 | Some skills shall have prerequisite skills | P3 | Draft | Parked |
| FR-SKL-006 | Player shall be able to view skill details before purchase | P3 | Draft | Parked |
| FR-SKL-007 | Player shall be able to respec skills | P3 | Draft | Parked |

#### 2.4.4 Currency & Economy

> **Entirely parked by [ADR 0003](adr/0003-shipped-scope.md).** An economy needs
> earn, spend, and a reason to care; only earn exists, and both spend surfaces
> (weapon upgrades, armory) are parked too. Neon Yen continues to accrue in the
> save file and is not shown anywhere at launch.
> [IDEA-BANK § Three-currency economy](IDEA-BANK.md#progression-systems).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-CUR-001 | Neon Yen shall be earned from mission completion | P3 | In Progress — earned from kills, not missions | Parked |
| FR-CUR-002 | Neon Yen shall be used for weapon upgrades | P3 | Draft — no spend path | Parked |
| FR-CUR-003 | Echo Fragments shall drop rarely from enemies | P3 | Draft | Parked |
| FR-CUR-004 | Echo Fragments shall unlock Echo skill upgrades | P3 | Draft | Parked |
| FR-CUR-005 | Legacy Tokens shall be earned from challenge completion | P3 | Draft | Parked |
| FR-CUR-006 | Legacy Tokens shall unlock cosmetic items | P3 | Draft | Parked |

### 2.5 Co-op Multiplayer

> **Rewritten for [ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md).**
> The v1.0 "co-op is a P1/P2 enhancement" framing is gone, and so is the §9.5
> contradiction. The decision:
>
> - **Solo-complete, co-op-elevated.** Identical content either way, no AI
>   companion, solo is never the lesser experience. "Core" means core to the
>   product's identity, not to playability — the common case is one commuter.
> - **Cameras are fully independent.** No leash, no shared view; players separate
>   freely and converge by choice.
> - **Co-op is expressed through proximity verbs** and a **shared Charge pool**
>   (ADR 0001) — not through content that needs two people.
> - **Ad-hoc means two co-located devices on local wireless.** Every requirement
>   that assumed an online service — matchmaking, friend invites, host migration,
>   cross-platform — is parked
>   ([IDEA-BANK § Online co-op services](IDEA-BANK.md#online-co-op-services)).
>
> Ad-hoc co-op is P0 for launch, and its home is the Boss Gauntlet (§2.11).
> Nothing here is built; the whole section is `Deferred` on the build axis and
> P0/P1 on the launch axis, which is exactly the largest gap in the project.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-COP-001 | All content shall be completable solo, with no AI companion and no reduced version | P0 | Complete | Ship |
| FR-COP-002 | Local co-op shall support 2 players on one device (tablet) | P3 | Deferred | Parked |
| FR-COP-003 | Ad-hoc co-op shall support 2 players on 2 co-located devices over local wireless | P0 | Deferred | Ship |
| FR-COP-004 | Co-op shall support friend invites | P3 | Deferred | Parked |
| FR-COP-005 | Co-op shall support matchmaking | P3 | Deferred | Parked |
| FR-COP-006 | Host migration shall occur on primary player disconnect | P3 | Deferred | Parked |
| FR-COP-007 | Cross-platform co-op: Mobile↔Mobile, Steam↔Steam | P3 | Deferred | Parked |
| FR-COP-008 | Pairing shall be local device discovery — no account, no invite code, no server | P0 | Draft | Ship |
| FR-COP-009 | Each device shall run a fully independent camera on its own player; no leash, no shared view | P0 | Draft | Ship |
| FR-COP-010 | An Arena shall activate on the first player to cross its trigger and stay active until cleared or both players have left | P0 | Draft — `_level.arena_to_activate(px, …)` takes one position | Ship |
| FR-COP-011 | A co-op session shall degrade to solo if the second device drops, without ending the run | P1 | Draft | Ship |
| FR-CPM-001 | The **Charge pool shall be shared** between players (the "Shared Energy Core") | P0 | Deferred | Ship |
| FR-CPM-002 | Energy Core shall regenerate 25% faster in co-op | — | Deferred | Removed — ADR 0001: Charges are banked by fighting, not regenerated |
| FR-CPM-003 | Linked Attacks: same enemy hit by both players within 0.5s = damage bonus | P1 | Deferred | Ship |
| FR-CPM-004 | Echo Overlap: Both Echoes in same space = AOE burst | P3 | Deferred | Parked |
| FR-CPM-005 | Launcher Combo: One player launches, other air combos | P3 | Deferred | Parked — depends on launchers (FR-CMB-011/012), also parked |
| FR-CPM-006 | Linked Deflect: both players parrying the same attack shall reward both | P1 | Draft | Ship |
| FR-CPM-007 | Deathblow handoff: either player may Deathblow an enemy the other Broke | P1 | Draft | Ship |
| FR-CPM-008 | Proximity verbs shall require both players to be near each other, and shall never be the only way to beat anything | P0 | Draft | Ship |
| FR-REV-001 | Downed state shall last 10 seconds before a life is spent | P1 | Deferred | Ship |
| FR-REV-002 | Partner shall revive downed player (3 second channel) | P1 | Deferred | Ship |
| FR-REV-003 | Revives shall draw on the shared run life pool rather than being unlimited | P1 | Deferred | Ship (reduced) — reconciled with the 3-lives run model (§9.2) |
| FR-REV-004 | If both players are downed, both respawn at the checkpoint and a life is spent | P1 | Deferred | Ship |
| FR-SOL-001 | Enemy health reduced 15% in solo mode | P0 | Complete | Ship |
| FR-SOL-002 | Echo cooldown reduced 20% in solo mode | — | Draft | Removed — ADR 0001 deleted the Echo cooldown |
| FR-SOL-003 | No content, puzzle or encounter shall be gated on a second player | P0 | Complete — vacuously; there is no co-op content yet | Ship |
| FR-SOL-004 | AI companion unlockable (optional) | P3 | Deferred | Parked — ADR 0002 removes the need for one |

### 2.6 User Interface

#### 2.6.1 HUD
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-HUD-001 | Health bar shall display at top-left (slim profile) | P0 | Complete | Ship |
| FR-HUD-002 | Momentum gauge shall display at bottom-center | P0 | Complete | Ship |
| FR-HUD-003 | Echo cooldown indicator shall display near character | P0 | Complete | Ship |
| FR-HUD-004 | Mission objective shall display at top-center, fade after 3s | P0 | In Progress — message system exists, no objectives | Ship |
| FR-HUD-005 | HUD shall be minimal and non-intrusive | P0 | Complete | Ship |
| FR-HUD-006 | HUD elements shall scale appropriately for device | P0 | In Progress — unverified on device | Ship |
| FR-HUD-007 | Lives remaining shall display in the HUD | P0 | Complete — previously unspecified | Ship |
| FR-HUD-008 | Boss health bar shall display while a boss is active | P0 | Complete — previously unspecified | Ship |
| FR-HUD-009 | In co-op the HUD shall show the partner's health, lives and downed state | P0 | Draft | Ship |

> FR-HUD-009 exists because [ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md)
> made the cameras independent: neither player can see the other's situation, so
> "partner in trouble" has to be explicit rather than visible on screen. The HUD
> readout for the Charge pool ADR 0001 introduces is being specified by the
> ADR 0001 implementation lane, not here.

#### 2.6.2 Menus

> **The launch menu set is title → continue campaign / Boss Gauntlet / options →
> results.** Mission select, loadout, skills and armory are parked with the
> systems behind them ([IDEA-BANK § Menus](IDEA-BANK.md#menus-and-ui-surfaces));
> a 6-level linear campaign with one weapon and no skills has nothing to select,
> equip, spend or browse.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-MNU-001 | Title screen shall display on game launch | P0 | Complete | Ship |
| FR-MNU-002 | Main menu shall provide access to campaign and Boss Gauntlet | P0 | In Progress — title/pause/victory/defeat only | Ship |
| FR-MNU-003 | Mission select shall show locked/unlocked status | P3 | Draft | Parked |
| FR-MNU-004 | Loadout screen shall allow weapon and skill selection | P3 | Draft | Parked |
| FR-MNU-005 | Options menu shall provide settings access | P0 | Draft — settings dict exists, no UI | Ship |
| FR-MNU-006 | Skills menu shall display all skill trees | P3 | Draft | Parked |
| FR-MNU-007 | Armory menu shall display weapons and upgrades | P3 | Draft | Parked |
| FR-MNU-008 | Co-op screen shall discover and pair a nearby device | P1 | Deferred | Ship (reduced) — local pairing only; invites and matchmaking are parked |
| FR-MNU-009 | Results screen shall display after a level and after a Gauntlet run | P1 | Draft | Ship |
| FR-MNU-010 | Pause menu shall be accessible during gameplay | P0 | Complete | Ship |

#### 2.6.3 Controls UI
| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-CTL-001 | **On-screen buttons** shall be the default control scheme on mobile | P0 | Complete — **reversed from v1.0** (§9.6) | Ship |
| FR-CTL-002 | Virtual joystick shall appear on left thumb touch | P0 | In Progress — directional buttons, no analog stick | Ship |
| FR-CTL-003 | Gesture control scheme shall remain available as an alternative | P3 | Deferred — code retained but dormant | Parked |
| FR-CTL-004 | Button size and position shall be customizable | P1 | Draft | Ship |
| FR-CTL-005 | Gesture sensitivity shall be adjustable | P3 | Draft | Parked |
| FR-CTL-006 | Every core verb shall be reachable one-handed on a phone | P0 | In Progress — unverified on device | Ship |

### 2.7 Save System

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-SAV-001 | Game shall auto-save at level start | P0 | Draft | Ship |
| FR-SAV-002 | Game shall auto-save at checkpoints | P0 | Draft | Ship |
| FR-SAV-003 | Game shall save player progression (level reached, XP, best Gauntlet results) | P0 | Complete — skill and currency fields persist but have no launch surface (§9.10) | Ship |
| FR-SAV-004 | Game shall save level unlock status | P0 | In Progress — `current_level_id` persists | Ship |
| FR-SAV-005 | Game shall support quick resume from interrupted sessions | P0 | Draft | Ship |
| FR-SAV-006 | Cloud save shall sync across devices (same platform) | P3 | Draft | Parked |
| FR-SAV-007 | Multiple save slots shall not be required (single profile) | P0 | Complete | Ship |

### 2.8 Audio

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-AUD-001 | Game shall play background music appropriate to game state | P0 | In Progress — procedural bed only | Ship |
| FR-AUD-002 | Music shall transition dynamically (exploration→combat→boss) | P1 | Draft | Ship |
| FR-AUD-003 | Sound effects shall play for all player actions | P0 | Complete — 10 event keys | Ship |
| FR-AUD-004 | Sound effects shall play for enemy attacks (parry timing cues) | P0 | Complete | Ship |
| FR-AUD-005 | Sound effects shall have stereo positioning | P1 | Draft | Ship |
| FR-AUD-006 | Echo activation shall have reverb/time-stretch audio effect | P1 | Draft | Ship |
| FR-AUD-007 | Low health state shall have audio indicator | P1 | Draft | Ship |
| FR-AUD-008 | Volume controls for music, SFX, and master shall be available | P0 | Draft — values exist, no UI | Ship |

### 2.9 Narrative

> **The narrative floor is "enough Neo Edo to make the setting land", not "no
> story at all".** [ADR 0003](adr/0003-shipped-scope.md) cuts the twelve-mission
> arc to near zero *and* notes in the same breath that "cutting narrative means
> Neo Edo has to establish itself entirely through art, audio, and level design.
> The setting is a selling point." A game with no plot is fine; a game with no
> sense of place is not, and place is the thing this one is being sold on.
>
> **Ships:** named locations, named bosses, a one-screen title card per level,
> and storytelling carried by the environment art.
> **Parked:** Kira, the erased family, the Digital Shogun, mission briefings,
> boss dialogue, data-log collectibles — the whole plot
> ([IDEA-BANK § Narrative](IDEA-BANK.md#narrative)). None of it exists in the
> build today; no character is named anywhere in the game.
>
> The budget this implies is roughly **one line of text per level and a name per
> boss**. If it starts needing a writer, it has left scope.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-NAR-001 | Mission briefings shall provide story context | P3 | Draft | Parked |
| FR-NAR-002 | Environmental storytelling shall be present in levels | P1 | Draft | Ship |
| FR-NAR-003 | Data logs (collectibles) shall expand lore | P3 | Draft | Parked |
| FR-NAR-004 | Boss encounters shall include character dialogue | P3 | Draft | Parked |
| FR-NAR-005 | No unskippable cutscenes (maintain session flow) | P0 | Complete — vacuously; there are no cutscenes | Ship |
| FR-NAR-006 | Each level shall open with a title card: the place name and one line of flavour | P1 | Draft | Ship |
| FR-NAR-007 | Bosses and elites shall be named on screen when the fight begins | P1 | Draft — boss bar exists (FR-HUD-008), carries no name | Ship |

### 2.10 Defensive Combat (built, previously unspecified)

> The most developed system in the game had **two** requirement rows in v1.0
> (FR-CMB-008/009). It is the stated core conceit, so it is specified here.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-DEF-001 | One input shall serve both parry and block: tap parries, hold blocks | P0 | Complete | Ship |
| FR-DEF-002 | Parry window shall be 0.2s with a 0.5s cooldown | P0 | Complete | Ship |
| FR-DEF-003 | A successful parry shall negate all damage | P0 | Complete | Ship |
| FR-DEF-004 | A successful parry shall reflect damage to the attacker | P0 | Complete | Ship |
| FR-DEF-005 | A successful parry shall stagger the attacker (1.0s, 1.4s bosses) | P0 | Complete | Ship |
| FR-DEF-006 | A successful parry shall award momentum | P0 | Complete | Ship |
| FR-DEF-007 | Blocking shall reduce incoming damage to 30% chip **and** spend Momentum equal to the raw damage (FR-MOM-011) | P0 | Complete | Ship |
| FR-DEF-008 | Blocking shall prevent knockback and stagger | P0 | Complete | Ship |
| FR-DEF-009 | Blocking shall reduce movement speed to 15% | P0 | Complete | Ship |
| FR-DEF-010 | Perilous (unblockable) attacks shall bypass both parry and block | P0 | Complete | Ship |
| FR-DEF-011 | Perilous attacks shall be avoidable only by dodge i-frames | P0 | Complete | Ship |
| FR-DEF-012 | Perilous attacks shall carry a distinct visual tell | P0 | In Progress — tint flash; readability unverified | Ship |
| FR-DEF-013 | Defence shall run on the Momentum economy: blocking spends it, zero Breaks you | P0 | Complete | Ship |
| FR-DEF-014 | A Deathblow on a Broken regular enemy shall kill it outright, whatever health remains | P0 | Complete | Ship |

> **Implemented 2026-08-15** (PR #28). [ADR 0001](adr/0001-momentum-absorbs-posture.md)
> answered FR-DEF-013 — **Momentum absorbs posture; there is one bar and blocking
> spends it** — and the implementation followed the same day. FR-DEF-007 now
> records both costs of a block. Chip damage survives *alongside* the Momentum
> cost, because `CONTEXT.md` defines Block as reducing damage rather than negating
> it. The Deathblow is automatic: any landed attack on a Broken target triggers
> it, and it is gated to the player's team, so a Broken player is exposed to
> ordinary damage rather than to instant death.

### 2.11 Boss Gauntlet (repeatable mode)

> **New in v1.2.** [ADR 0003](adr/0003-shipped-scope.md) makes the Gauntlet the
> shipped repeatable mode and the home of ad-hoc co-op, and no requirement
> covered it. `CONTEXT.md` defines it: *bosses and elites fought back to back,
> scored on time and on defensive performance, with no health restored between
> them. Distinct from a Level — a Gauntlet has no traversal and no goal line,
> only fights.*
>
> It was chosen because it is nearly free: it reuses bosses and elites the
> campaign builds anyway, and durable opponents are the only place the
> Momentum/Deathblow loop is legible — four of six enemy types die in about half
> a second, so wave survival would have tested crowd navigation instead
> ([IDEA-BANK § Further repeatable modes](IDEA-BANK.md#further-repeatable-modes)).
>
> **The whole mode is unbuilt.** It is also the single largest new system in
> launch scope, and ADR 0003 explicitly warns that it must not become the new
> scope creep — hence FR-GNT-009, which forbids bespoke content.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| FR-GNT-001 | Boss Gauntlet shall be selectable from the main menu as a mode separate from the campaign | P0 | Draft | Ship |
| FR-GNT-002 | A Gauntlet run shall present bosses and elite enemies back to back in a fixed order | P0 | Draft | Ship |
| FR-GNT-003 | Health shall not be restored between fights in a run | P0 | Draft | Ship |
| FR-GNT-004 | Banked Charges shall carry between fights within a run | P0 | Draft | Ship |
| FR-GNT-005 | A run shall be scored on elapsed time | P0 | Draft | Ship |
| FR-GNT-006 | A run shall be scored on defensive performance — parries landed, enemies Broken, hits taken | P0 | Draft | Ship |
| FR-GNT-007 | A run shall end on a results screen showing time, defensive score and personal best | P0 | Draft | Ship |
| FR-GNT-008 | Personal bests shall persist in the save file | P1 | Draft | Ship |
| FR-GNT-009 | The Gauntlet shall reuse campaign bosses, elites and environment art — **no bespoke content** | P0 | Draft | Ship |
| FR-GNT-010 | The Gauntlet shall be playable solo and in ad-hoc co-op, on identical content (FR-COP-001) | P0 | Draft | Ship |
| FR-GNT-011 | The Gauntlet shall unlock once the player has defeated a boss in the campaign | P1 | Draft | Ship |
| FR-GNT-012 | A full run shall be completable inside a commute session — target under 15 minutes | P0 | Draft | Ship |
| FR-GNT-013 | Losing all lives shall end the run and go to results, with no mid-run continue | P0 | Draft | Ship |
| FR-GNT-014 | A Gauntlet shall have no traversal and no goal line — a single arena, fights only | P0 | Draft | Ship |
| FR-GNT-015 | Elite enemies shall be tuned variants of existing archetypes, not new ones | P1 | Draft | Ship |

**Dependencies.** FR-GNT-002 needs the 4-boss roster (FR-BOS-001→004, FR-BOS-009)
and mini-boss elites (FR-BOS-008). FR-GNT-004 needs Charges
([ADR 0001](adr/0001-momentum-absorbs-posture.md)). FR-GNT-006 needs a Broken
state to count. FR-GNT-010 needs the whole of §2.5. Nothing in this section can
be finished before the ADR 0001 combat work lands.

---

## 3. Non-Functional Requirements

### 3.1 Performance

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| NFR-PRF-001 | Mobile: 60 FPS target at native resolution | P0 | Draft — never measured on device | Ship |
| NFR-PRF-002 | Steam: 60-144 FPS at 1080p-4K | P0 | In Progress — runs on desktop, unmeasured | Ship |
| NFR-PRF-003 | Input latency shall be <50ms | P0 | In Progress — unmeasured | Ship |
| NFR-PRF-004 | Loading times shall be <5 seconds per level | P1 | Complete — levels are code-defined, instant | Ship |
| NFR-PRF-005 | Game shall not exceed 500MB install size (mobile) | P1 | Complete — APK is far under | Ship |
| NFR-PRF-006 | Game shall not exceed 2GB install size (Steam) | P1 | Complete | Ship |
| NFR-PRF-007 | Memory usage shall not exceed 1GB RAM (mobile) | P0 | Draft — unmeasured | Ship |
| NFR-PRF-008 | Battery drain shall be optimized for mobile play | P1 | Draft | Ship |

### 3.2 Usability

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| NFR-USE-001 | Tutorial shall teach all core mechanics | P0 | In Progress — first-run prompts only | Ship |
| NFR-USE-002 | New mechanics shall be introduced with in-game prompts | P0 | In Progress | Ship |
| NFR-USE-003 | Game shall be playable with one hand (simplified mode) | P3 | Draft | Parked |
| NFR-USE-004 | All UI text shall be readable on mobile screens | P0 | Draft — unverified on device | Ship |
| NFR-USE-005 | Touch targets shall be minimum 44x44 points | P0 | In Progress — unverified on device | Ship |
| NFR-USE-006 | Game shall support landscape orientation only | P0 | Complete | Ship |

### 3.3 Accessibility

> The launch set is the one that is cheap and settings-driven: colourblind
> presets, screen shake, haptics, and visual cues alongside audio. High contrast,
> subtitle sizing, auto-dodge assist and the one-handed simplified mode
> (NFR-USE-003) are parked
> ([IDEA-BANK § Platform and service work](IDEA-BANK.md#platform-and-service-work)).
> Note that three of the shipping four are settings that already exist in the
> save file **with no effect wired** — the work is real.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| NFR-ACC-001 | Colorblind modes shall be available (3 presets) | P1 | Draft — setting exists, no effect | Ship |
| NFR-ACC-002 | Screen shake toggle shall be available | P1 | Draft — setting exists, no effect | Ship |
| NFR-ACC-003 | High contrast mode shall be available | P3 | Draft | Parked |
| NFR-ACC-004 | Subtitle size options shall be available | P3 | Draft | Parked |
| NFR-ACC-005 | Auto-dodge assist option shall be available | P3 | Draft | Parked |
| NFR-ACC-006 | Haptic feedback toggle shall be available | P0 | Draft — setting exists, no effect | Ship |
| NFR-ACC-007 | Visual indicators shall complement audio cues | P0 | In Progress | Ship |

### 3.4 Reliability

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| NFR-REL-001 | Game shall recover gracefully from crashes (save intact) | P0 | In Progress | Ship |
| NFR-REL-002 | Game shall handle network disconnection gracefully | P1 | Deferred | Ship |
| NFR-REL-003 | Game shall handle app backgrounding without data loss | P0 | Draft — unverified on device | Ship |
| NFR-REL-004 | Game shall handle phone calls/notifications without crash | P0 | Draft — unverified on device | Ship |
| NFR-REL-005 | Co-op shall handle player disconnect with host migration | P3 | Deferred | Parked |

### 3.5 Security

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| NFR-SEC-001 | Save data shall be protected from trivial modification | P1 | Draft — plaintext JSON | Ship |
| NFR-SEC-002 | Online communication shall use secure protocols | P1 | Deferred | Ship (reduced) |
| NFR-SEC-003 | No sensitive user data shall be collected beyond gameplay | P0 | Complete | Ship |
| NFR-SEC-004 | Game shall comply with platform privacy requirements | P0 | Draft | Ship |

### 3.6 Localization

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| NFR-LOC-001 | Game shall support English at launch | P0 | Complete | Ship |
| NFR-LOC-002 | UI shall support localization-ready text system | P1 | Draft — strings are hardcoded | Ship |
| NFR-LOC-003 | Japanese localization shall be available at launch | P3 | Draft | Parked |
| NFR-LOC-004 | Additional languages shall be addable post-launch | P3 | Draft | Parked |
| NFR-LOC-005 | All text shall avoid hardcoded strings | P1 | Draft — currently violated throughout | Ship |

---

## 4. Technical Requirements

### 4.1 Architecture

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| TR-ARC-001 | Game shall use Entity-Component-System (ECS) architecture | P0 | Complete | Ship |
| TR-ARC-002 | Systems shall execute in defined order per frame | P0 | Complete | Ship |
| TR-ARC-003 | Components shall be data-only containers | P0 | Complete — untyped dictionaries | Ship |
| TR-ARC-004 | Entities shall be lightweight identifiers with component references | P0 | Complete — integer IDs | Ship |

### 4.2 Core Systems

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| TR-SYS-001 | InputSystem: Process player input to game actions | P0 | Complete | Ship |
| TR-SYS-002 | MovementSystem: Apply velocity, gravity, constraints | P0 | Complete | Ship |
| TR-SYS-003 | CollisionSystem: Detect and resolve entity collisions | P0 | Superseded — PhysicsSyncSystem + AABB in CombatSystem (§9.8) | Ship |
| TR-SYS-004 | CombatSystem: Process attacks, damage, combos | P0 | Complete | Ship |
| TR-SYS-005 | EchoSystem: Record, playback, manage Echoes | P0 | Complete | Ship |
| TR-SYS-006 | AISystem: Enemy behavior trees, pathfinding | P0 | In Progress — behaviors yes, pathfinding no | Ship |
| TR-SYS-007 | MomentumSystem: Track and update momentum gauge | P0 | Complete | Ship |
| TR-SYS-008 | AnimationSystem: State machine, sprite updates | P0 | Complete | Ship |
| TR-SYS-009 | RenderSystem: Draw all visible entities | P0 | Superseded — Godot's renderer via hybrid nodes | Ship |
| TR-SYS-010 | AudioSystem: Sound effects, music playback | P0 | Complete — `AudioManager`, not an ECS system | Ship |
| TR-SYS-011 | ParrySystem: Own the parry window and blocking state | P0 | Complete — previously unspecified | Ship |
| TR-SYS-012 | BossSystem: Boss phases, patterns, stagger | P0 | Complete — previously unspecified | Ship |
| TR-SYS-013 | JumpSystem / DodgeSystem / ProjectileSystem / HealthSystem | P0 | Complete — previously unspecified | Ship |
| TR-SYS-014 | PhysicsSyncSystem: single authority bridging ECS and Godot bodies | P0 | Complete — previously unspecified | Ship |

### 4.3 Core Components

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| TR-CMP-001 | Position: (x, y) world coordinates | P0 | Complete | Ship |
| TR-CMP-002 | Velocity: Speed and direction vector | P0 | Complete | Ship |
| TR-CMP-003 | Sprite: Visual representation + animation state | P0 | Complete | Ship |
| TR-CMP-004 | Health: Current/max HP, shield values | P0 | In Progress — no shield concept | Ship |
| TR-CMP-005 | Weapon: Damage, range, combo data | P0 | Complete | Ship |
| TR-CMP-006 | Input: Player control state | P0 | Complete | Ship |
| TR-CMP-007 | Momentum: Gauge value, thresholds | P0 | Complete | Ship |
| TR-CMP-008 | EchoData: Recording buffer, playback state | P0 | Complete | Ship |
| TR-CMP-009 | Collision: Hitbox, collision layers | P0 | Complete | Ship |
| TR-CMP-010 | AI: Behavior tree reference, state | P0 | In Progress — state machine, not a behavior tree | Ship |

### 4.4 Networking (Co-op)

> Promoted to P0 by [ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md):
> ad-hoc co-op ships. The scope is **two co-located devices on local wireless** —
> no server, no NAT traversal, and no host to migrate to when one of two players
> leaves. Those rows are parked
> ([IDEA-BANK § Online co-op services](IDEA-BANK.md#online-co-op-services)).

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| TR-NET-001 | Ad-hoc / peer-to-peer connection for co-op | P0 | Deferred | Ship |
| TR-NET-002 | State synchronization for player positions and actions | P0 | Deferred | Ship |
| TR-NET-003 | Lag compensation for combat fairness | P1 | Deferred | Ship |
| TR-NET-004 | Host migration on disconnect | P3 | Deferred | Parked |
| TR-NET-005 | NAT traversal for connection establishment | P3 | Deferred | Parked |

### 4.5 Data Management

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| TR-DAT-001 | Player progress stored in local save file | P0 | Complete | Ship |
| TR-DAT-002 | Level data loaded from asset files | P0 | Superseded — levels are GDScript subclasses (§9.9) | Ship |
| TR-DAT-003 | Enemy/weapon stats data-driven (not hardcoded) | P0 | In Progress — archetype table in `main.gd`, not data files | Ship |
| TR-DAT-004 | Localization strings stored in separate files | P1 | Draft | Ship |

---

## 5. Content Requirements

### 5.1 Levels

> **The 6-level plan.** Two levels exist; four remain. Bosses are placed so the
> campaign opens and closes on one and the Gauntlet inherits a roster of four:
>
> | # | Level | Boss |
> |---|-------|------|
> | 1 | Neon Yoshiwara (built, 4 arenas) | Crimson Ronin (mid) → Oni Warlord |
> | 2 | Tetsu Spire (built, 5 arenas) | — |
> | 3 | — | Geisha Network |
> | 4 | — | — |
> | 5 | — | — |
> | 6 | — | Iron Daimyo (final) |
>
> **The floor is levels 1–4 with 3 bosses**, dropping levels 5–6 and Iron Daimyo,
> which makes Geisha Network the finale. That is a fallback if production slips,
> not the plan — see §2.4.1 for why 6 rather than 4.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| CR-MSN-001 | Level One (Neon Yoshiwara-equivalent, 4 arenas, two-boss finale) | P0 | Complete | Ship |
| CR-MSN-002 | Level Two "Tetsu Spire" (5 arenas) | P0 | Complete — previously unspecified | Ship |
| CR-MSN-003 | Levels Three–Six: four more handcrafted levels (was Missions 3–12) | P0 | Draft | Ship (reduced) |
| CR-MSN-004 | 6 Bonus/Challenge missions | P3 | Draft | Parked |
| CR-MSN-005 | Gauntlet arena — one arena reusing campaign environment art (§2.11) | P0 | Draft | Ship |

### 5.2 Environments

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| CR-ENV-001 | Parallax backdrop (sky + fog bands) | P0 | Complete — Anokolisa "Central City"; placement unverified | Ship |
| CR-ENV-002 | Foreground tileset for real level geometry | P0 | Draft — tiles vendored but unused | Ship |
| CR-ENV-003 | Neo-Edo identity overlay (torii, lanterns, kanji neon) | P0 | Draft — current art is generic cyberpunk | Ship |
| CR-ENV-004 | Environment tilesets for Levels Three–Six | P1 | Draft | Ship (reduced) — 6 levels, not 12; environments may repeat across levels |

### 5.3 Characters & Animations

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| CR-CHR-001 | Player character sprite sheet | P0 | Complete — Mattz Art samurai, 96×96 | Ship |
| CR-CHR-002 | Player idle, run, jump, fall animations | P0 | In Progress — `fall` is an alias | Ship |
| CR-CHR-003 | Player attack animations (light combo, heavy directional) | P0 | Complete | Ship |
| CR-CHR-004 | Player dodge, parry, wall-run, block animations | P0 | In Progress — roll/slide/crouch are aliases | Ship |
| CR-CHR-005 | Holographic Echo visual effect | P0 | Complete | Ship |
| CR-CHR-006 | 5 standard enemy sprite sheets and animations | P0 | In Progress — one sheet, tinted per type | Ship |
| CR-CHR-007 | Boss sprite sheets and animations | P0 | In Progress — one shared Demon Samurai sheet | Ship |

### 5.4 Audio Assets

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| CR-AUD-001 | Main menu music track | P0 | Draft | Ship |
| CR-AUD-002 | Exploration music tracks (per environment) | P0 | Draft | Ship |
| CR-AUD-003 | Combat music tracks | P0 | Draft | Ship |
| CR-AUD-004 | Boss music tracks | P0 | Draft | Ship |
| CR-AUD-005 | Attack sound effects (slash, hit, parry, block) | P0 | Complete — TomMusic sword set | Ship |
| CR-AUD-006 | Movement sound effects (footsteps, jump, dash) | P0 | Complete — Kenney CC0 | Ship |
| CR-AUD-007 | Echo activation/deactivation sound effects | P0 | Complete | Ship |
| CR-AUD-008 | UI sound effects (menu navigation, selection) | P0 | Draft | Ship |
| CR-AUD-009 | Enemy sound effects (attacks, death, alert) | P0 | In Progress — shared, not per-enemy | Ship |

> All music is still the procedural `SfxGenerator` bed. No composed tracks exist.

### 5.5 UI Assets

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| CR-UI-001 | HUD elements (health, momentum, Echo cooldown, lives, boss bar) | P0 | Complete — code-drawn | Ship |
| CR-UI-002 | Menu backgrounds and frames | P0 | Draft | Ship |
| CR-UI-003 | Button assets (standard, hover, pressed states) | P0 | Draft | Ship |
| CR-UI-004 | Skill tree icons | P3 | Draft | Parked |
| CR-UI-005 | Weapon icons | P3 | Draft | Parked |
| CR-UI-006 | Currency icons | P3 | Draft | Parked |
| CR-UI-007 | Level thumbnails | P3 | Draft | Parked |
| CR-UI-008 | Gauntlet results screen assets (time, score, personal best) | P1 | Draft | Ship |

---

## 6. Platform Requirements

> **Platform *services* are parked; platform *support* is not.** The game must
> run, install and comply on each platform (P0). Achievements, cloud save sync
> and Steam Deck verification are post-launch service work —
> [IDEA-BANK § Platform and service work](IDEA-BANK.md#platform-and-service-work).

### 6.1 iOS

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| PR-IOS-001 | Minimum iOS version: 14.0 | P0 | Draft | Ship |
| PR-IOS-002 | Support iPhone 8 and newer | P0 | Draft | Ship |
| PR-IOS-003 | Support iPad (6th gen) and newer | P0 | Draft | Ship |
| PR-IOS-004 | Support Game Center achievements | P3 | Draft | Parked |
| PR-IOS-005 | Support iCloud save sync | P3 | Draft | Parked |
| PR-IOS-006 | Comply with App Store guidelines | P0 | Draft | Ship |
| PR-IOS-007 | Support haptic feedback (Taptic Engine) | P1 | Draft | Ship |

> iOS export is **config-only**. Building requires macOS + Xcode, which the
> project has no access to. Nothing here has been exercised.

### 6.2 Android

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| PR-AND-001 | Minimum Android version: 8.0 (API 26) | P0 | Complete — minSdk 24, exceeds requirement | Ship |
| PR-AND-002 | Support devices with 3GB+ RAM | P0 | Draft — unverified | Ship |
| PR-AND-003 | Support Google Play Games achievements | P3 | Draft | Parked |
| PR-AND-004 | Support Google Play save sync | P3 | Draft | Parked |
| PR-AND-005 | Comply with Google Play guidelines | P0 | Draft | Ship |
| PR-AND-006 | Support controller input (optional) | P2 | Complete — gamepad bindings exist | Ship |
| PR-AND-007 | Signed debug APK shall build from the repo | P0 | Complete — template-based, no Gradle needed | Ship |
| PR-AND-008 | Build shall be verified running on a physical device | P0 | **Draft — never installed or run** | Ship |

### 6.3 Steam (PC)

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| PR-STM-001 | Minimum Windows: Windows 10 | P0 | Complete | Ship |
| PR-STM-002 | Minimum macOS: 11.0 (Big Sur) | P2 | Draft | Ship |
| PR-STM-003 | Support keyboard + mouse input | P0 | Complete | Ship |
| PR-STM-004 | Support controller input (Xbox, PlayStation) | P0 | Complete — bindings exist, untested | Ship |
| PR-STM-005 | Support Steam achievements | P3 | Draft | Parked |
| PR-STM-006 | Support Steam Cloud saves | P3 | Draft | Parked |
| PR-STM-007 | Support Steam Deck (verified) | P3 | Draft | Parked |
| PR-STM-008 | Support resolution scaling (1080p-4K) | P0 | Complete — canvas_items stretch | Ship |
| PR-STM-009 | Support variable refresh rate (60-144 FPS) | P1 | Draft | Ship |

---

## 7. Business Requirements

### 7.1 Monetization

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| BR-MON-001 | Premium pricing model (one-time purchase) | P0 | Draft | Ship |
| BR-MON-002 | No advertisements | P0 | Complete — none present | Ship |
| BR-MON-003 | No in-app purchases | P0 | Complete — none present | Ship |
| BR-MON-004 | No gacha/lootbox mechanics | P0 | Complete — none present | Ship |
| BR-MON-005 | Mobile price point: $4.99-$9.99 | P0 | Draft | Ship |
| BR-MON-006 | Steam price point: $14.99-$19.99 | P0 | Draft | Ship |

### 7.2 Analytics

> **Crash reporting ships; product analytics do not.** Shipping blind to crashes
> on hardware nobody has tested (PR-AND-008) is a different risk from shipping
> without retention funnels. BR-ANL-001→003 are parked
> ([IDEA-BANK § Platform and service work](IDEA-BANK.md#platform-and-service-work));
> BR-ANL-005 ships because it governs the one thing that does collect data.

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| BR-ANL-001 | Track mission completion rates | P3 | Draft | Parked |
| BR-ANL-002 | Track average session duration | P3 | Draft | Parked |
| BR-ANL-003 | Track player retention (D1, D7, D30) | P3 | Draft | Parked |
| BR-ANL-004 | Track crash reports and errors | P0 | Draft | Ship |
| BR-ANL-005 | Any data collected shall be privacy-compliant | P0 | Draft | Ship |

### 7.3 Marketing Support

| ID | Requirement | Priority | Status | Launch |
|----|-------------|----------|--------|--------|
| BR-MKT-001 | Gameplay trailer support (capture system) | P3 | Draft | Parked |
| BR-MKT-002 | Screenshot mode or photo mode | P3 | Draft | Parked |
| BR-MKT-003 | Press kit assets (logos, screenshots, key art) | P1 | Draft | Ship |

---

## 8. Traceability Matrix

### 8.1 Launch scope at a glance

Counts are of requirement rows (377 in total), not of work. Roughly a quarter of
the specification is out of launch scope.

| Launch | Rows | What it covers |
|--------|------|----------------|
| **Ship** | 258 | The 6-level campaign, 4 bosses, the Boss Gauntlet, ad-hoc co-op, platform support |
| **Ship (reduced)** | 11 | Rows that ship in a smaller form than written — the level count, results screens, co-op pairing, XP |
| **Parked** | 101 | Skills, economy, extra weapons, narrative arc, hazards, interactables, Echo upgrades, online services — all in [`IDEA-BANK.md`](IDEA-BANK.md) |
| **Removed** | 7 | Momentum thresholds and the Echo cooldown (ADR 0001), auto-revive (§9.2), co-op energy regen, solo Echo discount |

### 8.2 Requirements by phase, rewritten for the shipped scope

| Phase | Requirement Categories | State |
|-------|------------------------|-------|
| **Phase 1: Core Foundation** | FR-MOV, FR-CMB, FR-MOM, FR-ECH, FR-DEF, FR-ENM-001→003, FR-HUD-001→008, TR-ARC, TR-SYS, TR-CMP | **Substantially complete**, pending the ADR 0001 combat rework |
| **Phase 2: Campaign content** | CR-MSN-003, CR-ENV, CR-CHR, FR-BOS-002/003, FR-BOS-008, FR-MSN, FR-NAR-006/007 | **2 of 6 levels, 2 of 4 bosses** — the largest remaining block |
| **Phase 3: Boss Gauntlet** | FR-GNT-*, CR-MSN-005, CR-UI-008, FR-MNU-009 | **Not started** — depends on Phase 1's rework and Phase 2's bosses |
| **Phase 4: Ad-hoc co-op** | FR-COP, FR-CPM, FR-REV, FR-SOL, FR-HUD-009, TR-NET-001→003, FR-MNU-008 | **Not started** — nothing exists; the pillar with the least design done |
| **Phase 5: Launch readiness** | NFR-PRF, NFR-USE, NFR-REL, PR-*, BR-MON, CR-AUD, FR-MNU-005 | **Not started** — and blocked on the build being run on a device at all |

Phases 3 and 4 can overlap: the Gauntlet is where co-op is meant to live, so
building them together is cheaper than in sequence. Neither can start before the
ADR 0001 combat model settles, because both are scored on and expressed through
it.

### 8.3 Critical path

```
TR-ARC-* → TR-SYS-* → TR-CMP-*        [DONE]
    ↓
FR-MOV-* → FR-CMB-* → FR-MOM-*        [DONE, reworked by ADR 0001]
    ↓
FR-DEF-013 (Momentum absorbs posture) [DONE 2026-08-15 — unblocks Gauntlet
    ↓                                   scoring and every co-op proximity verb]
CR-MSN-003 → FR-BOS-002/003           [<-- THE CONTENT BOTTLENECK: 4 levels,
    ↓                                      2 bosses]
FR-GNT-*  +  FR-COP-*                 [BLOCKED on both of the above]
    ↓
NFR-PRF-* → PR-*                      [BLOCKED: nothing measured on device]
```

### 8.4 Dependency Summary

| Requirement | Depends On |
|-------------|------------|
| Combat (FR-CMB-*) | Movement (FR-MOV-*) |
| Echo System (FR-ECH-*) | Combat (FR-CMB-*) |
| Bosses (FR-BOS-*) | All combat mechanics |
| Boss Gauntlet (FR-GNT-*) | 4-boss roster, elites (FR-BOS-008), Charges + Broken (ADR 0001) |
| Gauntlet co-op (FR-GNT-010) | The whole of §2.5 |
| Co-op (FR-COP-*) | Core gameplay complete; multi-player arena activation (FR-COP-010) |
| Networking (TR-NET-001→003) | Co-op requirements defined — done, §2.5 |
| Proximity verbs (FR-CPM-003/006/007) | Broken and Deathblow (ADR 0001) |
| Platform submission (PR-*) | All P0 requirements complete |

---

## 9. Known Divergences

Where the implementation deliberately or accidentally differs from v1.0. Items
an ADR has since settled are marked **RESOLVED** and kept, not deleted — the
record of what was wrong is worth as much as the fix.

**9.1 Ability unlocks are not mission-gated. — RESOLVED by ADR 0003.** v1.0 gated dash on Mission 2, grapple on Mission 4, air dash on Mission 6. The slice grants dash at spawn (`main.gd`) and never implemented the others. With grapple and air dash parked and the campaign down to 6 levels, **the shipped model is "every verb is granted at spawn"** — there is no unlock ladder. The unused unlock flags in save data are now dead weight rather than an unfinished feature.

**9.2 Lives replaced auto-revive.** FR-HLT-005 specified one auto-revive per checkpoint. The build uses a 3-lives run model with in-place restart. This is a better fit for short commuter sessions but was never written down.

**9.3 `ronin_drone` has no archetype entry.** It is used by both levels but falls through `main.archetype()` to the default branch (HP 50 / dmg 18). It works, but Level Two's difficulty was never actually tuned for it.

**9.4 Missions vs levels — two progression models, one dead. — RESOLVED in doctrine, open in code.** `GameState` exposes a complete mission API (`current_mission`, `mission_progress`, `start_mission`, `complete_mission`, `is_mission_unlocked`) that **nothing calls**. `CONTEXT.md` settles the vocabulary: **Level is the progression unit; "mission" is legacy**, and this document is written against levels throughout. The dead API should be deleted — that is a code change, not a docs change, and is not made here.

**9.5 Co-op priority contradicts the stated vision. — RESOLVED by [ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md).** v1.0 treated co-op as a P1/P2 enhancement while the vision called it core, and FR-COP-001 asserted solo completability at P0. The resolution: **co-op is solo-complete and co-op-elevated.** "Core" means core to the product's identity and word-of-mouth, not to playability — the target player is on a commute, usually alone, and a game that *requires* a second co-located device is unplayable in its own most common context. Ad-hoc co-op is now P0 for launch (§2.5) *and* every piece of content is finishable by one player. Both were true all along; only the word "core" was doing two jobs.

**9.6 The default control scheme was reversed.** v1.0 FR-CTL-001 made gestures the mobile default. The shipped decision made on-screen buttons canonical and left gesture code dormant. FR-CTL-001/003 now record the shipped decision.

**9.7 Defence is HP chip, not posture. — RESOLVED by [ADR 0001](adr/0001-momentum-absorbs-posture.md).** The build had stagger but no posture meter; block was a flat 30% HP chip with no cost, which is close to strictly good. The resolution is **not** a posture bar: **Momentum absorbs posture, and there is one bar.** Blocking spends Momentum, parrying and attacking build it, zero is **Broken**, and filling the bar banks a **Charge**. Three meters on a commuter phone screen was the alternative, and Momentum's parry bonus already overlapped posture's entire reason to exist. FR-DEF-013 is decided; the implementation is in flight and owns the build statuses in §2.1.3 and §2.10. Note the vocabulary: **"posture" is not a Wolf Zero term** (`CONTEXT.md`) — the concept is Momentum, and "posture" is reserved for discussing the Sekiro reference.

**9.8 There is no CollisionSystem.** TR-SYS-003 specified one. The slice deliberately chose `PhysicsSyncSystem` (bridging to Godot's `move_and_slide`) plus distance/AABB checks inside `CombatSystem`, with no `Area2D` hitboxes. Deliberate, and it works.

**9.9 Levels are code, not data.** TR-DAT-002 specified asset-loaded level data. Levels are GDScript subclasses of `Level` registered in `Levels`. Adding a level is a subclass plus a registry line. Fine at 2 levels, and **fine at 6** — ADR 0003 removes the pressure that made this worth revisiting.

**9.10 Skill Points are granted with nothing to spend them on.** New in v1.2, created by the scope pass rather than by the code. XP, the level-30 cap and Skill Points are built, tested and persisted (FR-EXP-001/005/006, `Complete`), but skill trees are parked, so the points buy nothing. The launch choice is to **keep the system and surface none of it** — no XP bar, no level-up toast, no points counter — rather than delete a working system the parked trees will want back. Anything that displays a Skill Point count to the player at launch is a bug, not a feature.

**9.11 The narrative floor is deliberate, not an oversight.** ADR 0003 cuts the story, and the same ADR warns that Neo Edo must then land through art, audio and level design alone. §2.9 therefore ships place names, boss names, level title cards and environmental storytelling while parking the plot. A future reader finding "no story but named places" should read it as the decision it is.

---

## Appendix A: Glossary

> [`CONTEXT.md`](../CONTEXT.md) is the canonical domain glossary and wins on any
> conflict. This table is a local convenience.

| Term | Definition |
|------|------------|
| **Echo** | Holographic duplicate of player that replays recorded actions. Costs a Charge |
| **Momentum** | The single combat meter: composure. Blocking spends it, parrying and attacking build it |
| **Broken** | Momentum at zero — staggered, unable to act, open to a Deathblow |
| **Charge** | A stable unit banked by filling the Momentum bar. Does not decay. Shared between players in co-op |
| **Deathblow** | The finish available against a Broken enemy. Kills a regular enemy outright; ends one boss phase |
| **Neo Edo** | Game setting: cyberpunk feudal Japan |
| **ECS** | Entity-Component-System architecture pattern |
| **i-frames** | Invincibility frames during dodge animation |
| **Parry** | Perfectly timed defensive action that negates, reflects, and staggers |
| **Block** | Held defensive stance; spends Momentum, prevents knockback |
| **Perilous** | Unblockable attack; only dodge i-frames avoid it |
| **Posture** | **Not a Wolf Zero term.** Momentum expresses it; see ADR 0001 and §9.7 |
| **Level** | One playable stage, start to goal. The progression unit — "mission" is legacy |
| **Arena** | Trigger-bounded encounter within a level; also a checkpoint |
| **Gauntlet** | The repeatable mode: bosses and elites back to back, scored, no traversal (§2.11) |
| **Solo-complete** | Every piece of content is finishable by one player, with no compromise |
| **Proximity verb** | A co-op action that only exists when both players are near each other |

---

## Appendix B: Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-08 | Initial document creation |
| 1.1 | 2026-08-15 | Reconciled against implementation. Set a real status on every requirement (v1.0 left them all as `Draft`). Added §2.10 defensive combat, §9 known divergences, and requirements for systems built but never specified (Oni Warlord, lives, boss bar, ParrySystem, BossSystem, PhysicsSyncSystem, Level Two, dash-jump). Reversed FR-CTL-001 to match the shipped control scheme. Rewrote §2.4.1 around levels rather than missions. |
| 1.2 | 2026-08-15 | **Scope pass for [ADR 0003](adr/0003-shipped-scope.md).** Added the **Launch** column and its vocabulary (§1.4) as an axis independent of build status. Set a launch disposition on every row: 12 missions → **6 levels** (floor 4), 4 bosses (Digital Shogun parked), skills / economy / extra weapons / narrative arc parked to [`IDEA-BANK.md`](IDEA-BANK.md). Added **§2.11 Boss Gauntlet** (FR-GNT-001→015). Rewrote **§2.5 co-op** for [ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md) — solo-complete, independent cameras, proximity verbs, shared Charge pool; added FR-COP-008→011, FR-CPM-006→008, FR-HUD-009. Marked momentum thresholds and the Echo cooldown `Removed` per [ADR 0001](adr/0001-momentum-absorbs-posture.md). Narrative floor set at place names, boss names and title cards (FR-NAR-006/007). Marked §9.1, §9.4, §9.5, §9.7 resolved; added §9.10 and §9.11. Rewrote §8. |

---

*Document Version: 1.2*
*Status: Reconciled against implementation at commit `3b88231`; scoped to ADR 0003*
*Last Updated: 2026-08-15*
