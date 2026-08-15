# Wolf-Zero: Requirements Document

## Document Information
| Field | Value |
|-------|-------|
| Version | 1.1 |
| Status | Reconciled against implementation |
| Last Updated | 2026-08-15 |
| Related Documents | CoreDesign.md, CODEBASE-DIGEST.md, STATUS.md |

> **v1.1 reconciliation note.** v1.0 shipped every one of ~230 requirements as
> `Draft` and never updated one, so the document could not answer the question a
> requirements document exists to answer: *what is left?* This revision sets a
> real status on every row by tracing against the code, adds §2.10 for systems
> that were built but never specified, and records the known divergences in §9.
>
> Statuses reflect the **vertical slice**, not a shipped game. Read alongside
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

---

## 1. Introduction

### 1.1 Purpose
This document defines all requirements for Wolf-Zero, a 2D side-scrolling hack-and-slash game with platforming elements. Requirements are categorized, prioritized, and assigned unique identifiers for traceability.

### 1.2 Scope
Wolf-Zero is a premium mobile-first game (iOS/Android) with Steam as a secondary platform. The game features a defensive combat conceit, a Holographic Echo time manipulation mechanic, level-based progression, and ad-hoc co-op multiplayer.

### 1.3 Requirement Priority Definitions
| Priority | Definition |
|----------|------------|
| **P0 - Critical** | Must have for launch. Game cannot ship without this. |
| **P1 - High** | Should have for launch. Significant impact if missing. |
| **P2 - Medium** | Nice to have for launch. Can be added post-launch. |
| **P3 - Low** | Future consideration. Not planned for initial release. |

### 1.4 Requirement Status Definitions
| Status | Definition |
|--------|------------|
| **Draft** | Specified, not started |
| **In Progress** | Partially implemented — see the note in the row |
| **Complete** | Implemented and covered by tests or verified in play |
| **Deferred** | Explicitly out of scope for the vertical slice |
| **Superseded** | The design changed; see §9 |

---

## 2. Functional Requirements

### 2.1 Player Character

#### 2.1.1 Movement
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-MOV-001 | Player shall move horizontally on a 2D plane | P0 | Complete |
| FR-MOV-002 | Player shall be able to jump with variable height based on input duration | P0 | Complete |
| FR-MOV-003 | Player shall be able to perform wall jumps on designated surfaces | P0 | Complete |
| FR-MOV-004 | Player shall be able to wall run horizontally along designated surfaces | P0 | Complete |
| FR-MOV-005 | Player shall be able to perform a ground dash | P0 | Complete — granted at spawn, not mission-gated (§9.1) |
| FR-MOV-006 | Player shall be able to grapple to designated points | P0 | Draft — `has_grapple` flag exists, no implementation |
| FR-MOV-007 | Player shall be able to perform an air dash | P1 | In Progress — dash has no ground check so it works airborne, but `has_air_dash` is unused |
| FR-MOV-008 | Player shall experience gravity when airborne | P0 | Complete |
| FR-MOV-009 | Player movement shall feel responsive with <50ms input latency | P0 | Complete — retuned to ~1-frame accel/decel |
| FR-MOV-010 | Player shall retain dash speed through a jump arc (dash-jump) | P0 | Complete — added 2026-08-15 |

#### 2.1.2 Combat - Basic Actions
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-CMB-001 | Player shall perform light attacks via tap input | P0 | Complete |
| FR-CMB-002 | Light attacks shall chain up to 5 consecutive hits | P0 | Complete |
| FR-CMB-003 | Player shall perform heavy attacks via directional swipe | P0 | Complete |
| FR-CMB-004 | Heavy attacks shall be directional (up, forward, down) | P0 | Complete |
| FR-CMB-005 | Heavy attacks shall break enemy armor | P0 | Complete |
| FR-CMB-006 | Player shall perform dodge with invincibility frames | P0 | Complete |
| FR-CMB-007 | Dodge i-frames shall last 0.2-0.3 seconds | P0 | Complete — window is 0.05s→0.25s of a 0.3s roll |
| FR-CMB-008 | Player shall perform parry via tap at moment of enemy impact | P0 | Complete |
| FR-CMB-009 | Successful parry shall reflect damage to attacker | P1 | Complete |
| FR-CMB-010 | Player shall perform aerial attacks while airborne | P0 | Complete |
| FR-CMB-011 | Player shall be able to launch enemies into the air | P1 | Draft |
| FR-CMB-012 | Player shall perform air combos on launched enemies | P1 | Draft |

#### 2.1.3 Momentum System
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-MOM-001 | System shall track player momentum as a 0-100% gauge | P0 | Complete |
| FR-MOM-002 | Momentum shall increase from successful attacks | P0 | Complete |
| FR-MOM-003 | Momentum shall increase from successful dodges | P0 | Complete |
| FR-MOM-004 | Momentum shall increase from successful parries | P0 | Complete |
| FR-MOM-005 | Momentum shall decay slowly when not in combat | P0 | Complete |
| FR-MOM-006 | At 25% momentum, Echo abilities shall unlock | P0 | Complete |
| FR-MOM-007 | At 50% momentum, attack damage shall increase by 20% | P0 | Complete |
| FR-MOM-008 | At 75% momentum, Echo duration shall extend | P1 | In Progress — threshold fires, no effect wired |
| FR-MOM-009 | At 100% momentum, ultimate attack shall become available | P1 | Draft — **threshold fires and nothing happens** |
| FR-MOM-010 | Ultimate attack shall consume all momentum when used | P1 | Draft |

#### 2.1.4 Holographic Echo System
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-ECH-001 | System shall continuously record last 3 seconds of player actions | P0 | Complete |
| FR-ECH-002 | Player shall deploy Echo via dedicated input | P0 | Complete |
| FR-ECH-003 | Echo shall appear at player's current position on activation | P0 | Complete |
| FR-ECH-004 | Echo shall replay recorded actions as holographic duplicate | P0 | Complete |
| FR-ECH-005 | Echo playback duration shall be 3 seconds base | P0 | Complete |
| FR-ECH-006 | Echo cooldown shall be 8 seconds base | P0 | Complete |
| FR-ECH-007 | Echo shall deal damage to enemies on contact | P0 | Complete |
| FR-ECH-008 | Echo shall draw enemy aggro/attention | P0 | Complete |
| FR-ECH-009 | Echo shall be able to activate pressure plates | P1 | Draft — blocked on FR-INT-001 |
| FR-ECH-010 | Echo shall be visually distinct (translucent cyan, scan-lines) | P0 | Complete |
| FR-ECH-011 | Extended Memory upgrade shall increase recording to 4 seconds | P1 | Draft — save field exists, no unlock path |
| FR-ECH-012 | Rapid Recall upgrade shall reduce cooldown to 6 seconds | P1 | Draft — save field exists, no unlock path |
| FR-ECH-013 | Solid Echo upgrade shall enable physical object interaction | P1 | Draft — save field exists, no unlock path |
| FR-ECH-014 | Dual Echo upgrade shall allow two simultaneous Echoes | P2 | Draft — save field exists, no unlock path |
| FR-ECH-015 | Persistent Echo upgrade shall extend duration to 5 seconds | P2 | Draft — save field exists, no unlock path |

#### 2.1.5 Weapons
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-WPN-001 | Player shall start with Plasma Katana (balanced stats) | P0 | Complete |
| FR-WPN-002 | System shall support 4 additional unlockable weapons | P1 | Draft |
| FR-WPN-003 | Vibro-Wakizashi shall provide fast combos, quick Echo, low damage | P1 | Draft |
| FR-WPN-004 | Neon Nodachi shall provide high damage, wide arc, slow recovery | P1 | Draft |
| FR-WPN-005 | Chain-Kusarigama shall provide range, enemy pull, complex timing | P2 | Draft |
| FR-WPN-006 | Cyber-Tessen shall provide parry bonus, defensive playstyle | P2 | Draft |
| FR-WPN-007 | Each weapon shall have unique attack animations | P1 | Draft |
| FR-WPN-008 | Each weapon shall have 5 upgrade tiers | P1 | In Progress — tier data and cap implemented, no content |
| FR-WPN-009 | Weapon upgrades shall cost Neon Yen currency | P1 | Draft — no spend path |
| FR-WPN-010 | Player shall be able to switch weapons between missions | P1 | Draft |

#### 2.1.6 Health & Damage
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-HLT-001 | Player shall have a health pool displayed in HUD | P0 | Complete |
| FR-HLT-002 | Player health shall decrease when hit by enemies | P0 | Complete |
| FR-HLT-003 | Player shall die when health reaches zero | P0 | Complete |
| FR-HLT-004 | Player shall respawn at last checkpoint on death | P0 | Complete |
| FR-HLT-005 | Solo mode shall provide one auto-revive per checkpoint | P0 | Superseded — replaced by a 3-lives run model (§9.2) |
| FR-HLT-006 | Health pickups shall restore player health | P1 | Draft |
| FR-HLT-007 | Player shall have brief invincibility after taking damage | P0 | Complete |

### 2.2 Enemies

#### 2.2.1 Enemy Types
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-ENM-001 | Ronin Drone: Basic melee enemy with telegraphed attacks | P0 | Complete — but see §9.3, it has no archetype entry |
| FR-ENM-002 | Cyber-Ashigaru: Ranged enemy with low health | P0 | Complete |
| FR-ENM-003 | Oni Mech: Heavy armored enemy, slow attacks | P0 | Complete |
| FR-ENM-004 | Shinobi Ghost: Cloaking enemy with backstab attacks | P1 | Complete |
| FR-ENM-005 | Tech-Priest: Support enemy that buffs allies and summons | P1 | In Progress — heals allies, does not summon |
| FR-ENM-006 | All enemies shall have visible attack telegraphs | P0 | Complete |
| FR-ENM-007 | Enemies shall have distinct audio cues for attacks | P0 | In Progress — shared SFX, not per-enemy |
| FR-ENM-008 | Enemy health shall be reduced by 15% in solo mode | P0 | Complete |

#### 2.2.2 Boss Enemies
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-BOS-001 | Crimson Ronin: Tests parry timing mechanics | P0 | Complete — mid-boss of Level One |
| FR-BOS-002 | Geisha Network: Tests Echo usage for multi-target | P0 | Draft |
| FR-BOS-003 | Iron Daimyo: Tests platform combat, has phase transitions | P0 | Draft |
| FR-BOS-004 | Digital Shogun: Final boss testing all mechanics | P0 | Draft |
| FR-BOS-005 | Bosses shall have multiple distinct attack patterns | P0 | Complete |
| FR-BOS-006 | Bosses shall have phase transitions with visual/audio feedback | P0 | Complete |
| FR-BOS-007 | Bosses shall have clearly telegraphed vulnerable windows | P0 | Complete |
| FR-BOS-008 | Mini-bosses shall appear in mid-level arenas | P1 | Draft |
| FR-BOS-009 | Oni Warlord: perilous-heavy final boss, gates the win | P0 | Complete — built, previously unspecified |

#### 2.2.3 Enemy AI
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-EAI-001 | Enemies shall detect player within defined range | P0 | Complete |
| FR-EAI-002 | Enemies shall pathfind to player position | P0 | In Progress — direct pursuit only, no pathfinding |
| FR-EAI-003 | Enemies shall be distracted by Holographic Echo | P0 | Complete |
| FR-EAI-004 | Enemies shall have behavior states (idle, patrol, alert, combat) | P0 | Complete |
| FR-EAI-005 | Enemies shall coordinate group attacks when multiple present | P1 | Draft |

### 2.3 Environment & Platforming

#### 2.3.1 Platform Types
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-PLT-001 | Static platforms shall support player weight and collision | P0 | Complete |
| FR-PLT-002 | Moving platforms shall transport player when standing | P0 | Draft |
| FR-PLT-003 | Collapsing platforms shall fall after player contact | P1 | Draft |
| FR-PLT-004 | One-way platforms shall allow jump-through from below | P0 | Draft |
| FR-PLT-005 | Wall-runnable surfaces shall be visually distinct | P0 | Draft — wall-running works, surfaces are not marked |
| FR-PLT-006 | Grapple points shall be visually highlighted | P0 | Draft — blocked on FR-MOV-006 |

#### 2.3.2 Environmental Hazards
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-HAZ-001 | Spike traps shall damage player on contact | P0 | Draft — physics layer 4 reserved, unused |
| FR-HAZ-002 | Laser grids shall damage player on contact | P0 | Draft |
| FR-HAZ-003 | Electrified surfaces shall damage player on contact | P1 | Draft |
| FR-HAZ-004 | Bottomless pits shall instantly kill player | P0 | Draft |
| FR-HAZ-005 | Hazards shall have visual and/or audio warnings | P0 | Draft |

#### 2.3.3 Interactive Objects
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-INT-001 | Pressure plates shall activate when player or Echo stands on them | P0 | Draft |
| FR-INT-002 | Switches shall toggle state when attacked | P0 | Draft |
| FR-INT-003 | Doors shall open/close based on trigger conditions | P0 | Draft |
| FR-INT-004 | Destructible objects shall break when attacked | P0 | Draft |
| FR-INT-005 | Cyber-Bamboo shall be climbable and cuttable | P1 | Draft |
| FR-INT-006 | Holographic bridges shall appear/disappear on timers or triggers | P1 | Draft |
| FR-INT-007 | Magnetic rails shall propel player at high speed | P2 | Draft |

### 2.4 Progression Systems

#### 2.4.1 Level / Mission System
> See §9.4. The build progresses through **levels** via a `Levels` registry. The
> mission API in `GameState` is dead code. These rows are written against levels.

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-MSN-001 | Game shall contain 12 main missions | P0 | In Progress — 2 levels built |
| FR-MSN-002 | Game shall contain 6 bonus/challenge missions | P2 | Draft |
| FR-MSN-003 | Levels shall unlock sequentially upon completion | P0 | Complete — `Levels.next_after` |
| FR-MSN-004 | Each level shall be 8-15 minutes in length | P0 | In Progress — unmeasured |
| FR-MSN-005 | Levels shall contain mid-level checkpoints | P0 | Complete — arena checkpoints |
| FR-MSN-006 | Completed levels shall be replayable | P0 | Draft — no level select |
| FR-MSN-007 | Results shall display time, score, and rewards | P0 | Draft |
| FR-MSN-008 | Briefings shall display before each level | P0 | Draft |

#### 2.4.2 Experience & Levels
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-EXP-001 | Player shall earn XP from defeating enemies | P0 | Complete |
| FR-EXP-002 | Player shall earn XP from completing missions | P0 | Draft |
| FR-EXP-003 | Player shall earn XP from achieving high combos | P1 | Draft |
| FR-EXP-004 | Player shall earn XP from completing challenges | P1 | Draft |
| FR-EXP-005 | Player level cap shall be 30 | P0 | Complete |
| FR-EXP-006 | Each level shall grant 1 Skill Point | P0 | Complete |
| FR-EXP-007 | Each level shall provide stat boosts | P0 | Draft — points granted, no stat effect |

#### 2.4.3 Skill Trees
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-SKL-001 | BLADE tree shall contain 10 combat-focused skills | P0 | Draft — empty dict in save data |
| FR-SKL-002 | SHADOW tree shall contain 10 mobility-focused skills | P0 | Draft — empty dict in save data |
| FR-SKL-003 | ECHO tree shall contain 10 time-mechanic skills | P0 | Draft — empty dict in save data |
| FR-SKL-004 | Skills shall be purchasable with Skill Points | P0 | Draft |
| FR-SKL-005 | Some skills shall have prerequisite skills | P1 | Draft |
| FR-SKL-006 | Player shall be able to view skill details before purchase | P0 | Draft |
| FR-SKL-007 | Player shall be able to respec skills | P2 | Draft |

#### 2.4.4 Currency & Economy
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-CUR-001 | Neon Yen shall be earned from mission completion | P0 | In Progress — earned from kills, not missions |
| FR-CUR-002 | Neon Yen shall be used for weapon upgrades | P0 | Draft — no spend path |
| FR-CUR-003 | Echo Fragments shall drop rarely from enemies | P1 | Draft |
| FR-CUR-004 | Echo Fragments shall unlock Echo skill upgrades | P1 | Draft |
| FR-CUR-005 | Legacy Tokens shall be earned from challenge completion | P2 | Draft |
| FR-CUR-006 | Legacy Tokens shall unlock cosmetic items | P2 | Draft |

### 2.5 Co-op Multiplayer

> **Priority under review.** v1.0 treated co-op as a P1/P2 enhancement. The
> stated vision (2026-08-15) is that **ad-hoc co-op is core**, which would
> promote much of this section to P0 and change the architecture. Priorities
> below are left at v1.0 values pending that decision — see §9.5.

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-COP-001 | All content shall be completable in solo mode | P0 | Complete |
| FR-COP-002 | Local co-op shall support 2 players on one device (tablet) | P1 | Deferred |
| FR-COP-003 | Ad-hoc / online co-op shall support 2 players | P1 | Deferred |
| FR-COP-004 | Co-op shall support friend invites | P1 | Deferred |
| FR-COP-005 | Co-op shall support matchmaking | P2 | Deferred |
| FR-COP-006 | Host migration shall occur on primary player disconnect | P1 | Deferred |
| FR-COP-007 | Cross-platform co-op: Mobile↔Mobile, Steam↔Steam | P2 | Deferred |
| FR-CPM-001 | Shared Energy Core shall power both players' abilities | P1 | Deferred |
| FR-CPM-002 | Energy Core shall regenerate 25% faster in co-op | P1 | Deferred |
| FR-CPM-003 | Linked Attacks: Same enemy hit within 0.5s = damage bonus | P1 | Deferred |
| FR-CPM-004 | Echo Overlap: Both Echoes in same space = AOE burst | P2 | Deferred |
| FR-CPM-005 | Launcher Combo: One player launches, other air combos | P2 | Deferred |
| FR-REV-001 | Downed state shall last 10 seconds before death | P1 | Deferred |
| FR-REV-002 | Partner shall revive downed player (3 second channel) | P1 | Deferred |
| FR-REV-003 | Partner revives shall be unlimited in co-op | P1 | Deferred |
| FR-REV-004 | If both players downed, respawn at checkpoint | P1 | Deferred |
| FR-SOL-001 | Enemy health reduced 15% in solo mode | P0 | Complete |
| FR-SOL-002 | Echo cooldown reduced 20% in solo mode | P0 | Draft |
| FR-SOL-003 | Co-op puzzles shall have alternate solo solutions | P0 | Deferred |
| FR-SOL-004 | AI companion unlockable (optional) | P2 | Deferred |

### 2.6 User Interface

#### 2.6.1 HUD
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-HUD-001 | Health bar shall display at top-left (slim profile) | P0 | Complete |
| FR-HUD-002 | Momentum gauge shall display at bottom-center | P0 | Complete |
| FR-HUD-003 | Echo cooldown indicator shall display near character | P0 | Complete |
| FR-HUD-004 | Mission objective shall display at top-center, fade after 3s | P0 | In Progress — message system exists, no objectives |
| FR-HUD-005 | HUD shall be minimal and non-intrusive | P0 | Complete |
| FR-HUD-006 | HUD elements shall scale appropriately for device | P0 | In Progress — unverified on device |
| FR-HUD-007 | Lives remaining shall display in the HUD | P0 | Complete — previously unspecified |
| FR-HUD-008 | Boss health bar shall display while a boss is active | P0 | Complete — previously unspecified |

#### 2.6.2 Menus
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-MNU-001 | Title screen shall display on game launch | P0 | Complete |
| FR-MNU-002 | Main menu shall provide access to all game modes | P0 | In Progress — title/pause/victory/defeat only |
| FR-MNU-003 | Mission select shall show locked/unlocked status | P0 | Draft |
| FR-MNU-004 | Loadout screen shall allow weapon and skill selection | P0 | Draft |
| FR-MNU-005 | Options menu shall provide settings access | P0 | Draft — settings dict exists, no UI |
| FR-MNU-006 | Skills menu shall display all skill trees | P0 | Draft |
| FR-MNU-007 | Armory menu shall display weapons and upgrades | P0 | Draft |
| FR-MNU-008 | Co-op lobby shall allow friend invite and matchmaking | P1 | Deferred |
| FR-MNU-009 | Results screen shall display after mission completion | P0 | Draft |
| FR-MNU-010 | Pause menu shall be accessible during gameplay | P0 | Complete |

#### 2.6.3 Controls UI
| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-CTL-001 | **On-screen buttons** shall be the default control scheme on mobile | P0 | Complete — **reversed from v1.0** (§9.6) |
| FR-CTL-002 | Virtual joystick shall appear on left thumb touch | P0 | In Progress — directional buttons, no analog stick |
| FR-CTL-003 | Gesture control scheme shall remain available as an alternative | P2 | Deferred — code retained but dormant |
| FR-CTL-004 | Button size and position shall be customizable | P1 | Draft |
| FR-CTL-005 | Gesture sensitivity shall be adjustable | P1 | Draft |
| FR-CTL-006 | Every core verb shall be reachable one-handed on a phone | P0 | In Progress — unverified on device |

### 2.7 Save System

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-SAV-001 | Game shall auto-save at level start | P0 | Draft |
| FR-SAV-002 | Game shall auto-save at checkpoints | P0 | Draft |
| FR-SAV-003 | Game shall save player progression (level, skills, currency) | P0 | Complete |
| FR-SAV-004 | Game shall save level unlock status | P0 | In Progress — `current_level_id` persists |
| FR-SAV-005 | Game shall support quick resume from interrupted sessions | P0 | Draft |
| FR-SAV-006 | Cloud save shall sync across devices (same platform) | P2 | Draft |
| FR-SAV-007 | Multiple save slots shall not be required (single profile) | P0 | Complete |

### 2.8 Audio

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-AUD-001 | Game shall play background music appropriate to game state | P0 | In Progress — procedural bed only |
| FR-AUD-002 | Music shall transition dynamically (exploration→combat→boss) | P1 | Draft |
| FR-AUD-003 | Sound effects shall play for all player actions | P0 | Complete — 10 event keys |
| FR-AUD-004 | Sound effects shall play for enemy attacks (parry timing cues) | P0 | Complete |
| FR-AUD-005 | Sound effects shall have stereo positioning | P1 | Draft |
| FR-AUD-006 | Echo activation shall have reverb/time-stretch audio effect | P1 | Draft |
| FR-AUD-007 | Low health state shall have audio indicator | P1 | Draft |
| FR-AUD-008 | Volume controls for music, SFX, and master shall be available | P0 | Draft — values exist, no UI |

### 2.9 Narrative

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-NAR-001 | Mission briefings shall provide story context | P0 | Draft |
| FR-NAR-002 | Environmental storytelling shall be present in levels | P1 | Draft |
| FR-NAR-003 | Data logs (collectibles) shall expand lore | P2 | Draft |
| FR-NAR-004 | Boss encounters shall include character dialogue | P1 | Draft |
| FR-NAR-005 | No unskippable cutscenes (maintain session flow) | P0 | Complete — vacuously; there are no cutscenes |

> **The entire narrative layer is unbuilt.** Kira, the Digital Shogun, and the
> erased-family premise exist only in `CoreDesign.md` §11. Nothing in the game
> references them.

### 2.10 Defensive Combat (built, previously unspecified)

> The most developed system in the game had **two** requirement rows in v1.0
> (FR-CMB-008/009). It is the stated core conceit, so it is specified here.

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-DEF-001 | One input shall serve both parry and block: tap parries, hold blocks | P0 | Complete |
| FR-DEF-002 | Parry window shall be 0.2s with a 0.5s cooldown | P0 | Complete |
| FR-DEF-003 | A successful parry shall negate all damage | P0 | Complete |
| FR-DEF-004 | A successful parry shall reflect damage to the attacker | P0 | Complete |
| FR-DEF-005 | A successful parry shall stagger the attacker (1.0s, 1.4s bosses) | P0 | Complete |
| FR-DEF-006 | A successful parry shall award momentum | P0 | Complete |
| FR-DEF-007 | Blocking shall reduce incoming damage to 30% chip | P0 | Complete |
| FR-DEF-008 | Blocking shall prevent knockback and stagger | P0 | Complete |
| FR-DEF-009 | Blocking shall reduce movement speed to 15% | P0 | Complete |
| FR-DEF-010 | Perilous (unblockable) attacks shall bypass both parry and block | P0 | Complete |
| FR-DEF-011 | Perilous attacks shall be avoidable only by dodge i-frames | P0 | Complete |
| FR-DEF-012 | Perilous attacks shall carry a distinct visual tell | P0 | In Progress — tint flash; readability unverified |
| FR-DEF-013 | Defence shall operate on a posture economy, not health chip | P0 | **Draft — the open design question. See §9.7** |

---

## 3. Non-Functional Requirements

### 3.1 Performance

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR-PRF-001 | Mobile: 60 FPS target at native resolution | P0 | Draft — never measured on device |
| NFR-PRF-002 | Steam: 60-144 FPS at 1080p-4K | P0 | In Progress — runs on desktop, unmeasured |
| NFR-PRF-003 | Input latency shall be <50ms | P0 | In Progress — unmeasured |
| NFR-PRF-004 | Loading times shall be <5 seconds per level | P1 | Complete — levels are code-defined, instant |
| NFR-PRF-005 | Game shall not exceed 500MB install size (mobile) | P1 | Complete — APK is far under |
| NFR-PRF-006 | Game shall not exceed 2GB install size (Steam) | P1 | Complete |
| NFR-PRF-007 | Memory usage shall not exceed 1GB RAM (mobile) | P0 | Draft — unmeasured |
| NFR-PRF-008 | Battery drain shall be optimized for mobile play | P1 | Draft |

### 3.2 Usability

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR-USE-001 | Tutorial shall teach all core mechanics | P0 | In Progress — first-run prompts only |
| NFR-USE-002 | New mechanics shall be introduced with in-game prompts | P0 | In Progress |
| NFR-USE-003 | Game shall be playable with one hand (simplified mode) | P2 | Draft |
| NFR-USE-004 | All UI text shall be readable on mobile screens | P0 | Draft — unverified on device |
| NFR-USE-005 | Touch targets shall be minimum 44x44 points | P0 | In Progress — unverified on device |
| NFR-USE-006 | Game shall support landscape orientation only | P0 | Complete |

### 3.3 Accessibility

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR-ACC-001 | Colorblind modes shall be available (3 presets) | P1 | Draft — setting exists, no effect |
| NFR-ACC-002 | Screen shake toggle shall be available | P1 | Draft — setting exists, no effect |
| NFR-ACC-003 | High contrast mode shall be available | P2 | Draft |
| NFR-ACC-004 | Subtitle size options shall be available | P1 | Draft |
| NFR-ACC-005 | Auto-dodge assist option shall be available | P2 | Draft |
| NFR-ACC-006 | Haptic feedback toggle shall be available | P0 | Draft — setting exists, no effect |
| NFR-ACC-007 | Visual indicators shall complement audio cues | P0 | In Progress |

### 3.4 Reliability

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR-REL-001 | Game shall recover gracefully from crashes (save intact) | P0 | In Progress |
| NFR-REL-002 | Game shall handle network disconnection gracefully | P1 | Deferred |
| NFR-REL-003 | Game shall handle app backgrounding without data loss | P0 | Draft — unverified on device |
| NFR-REL-004 | Game shall handle phone calls/notifications without crash | P0 | Draft — unverified on device |
| NFR-REL-005 | Co-op shall handle player disconnect with host migration | P1 | Deferred |

### 3.5 Security

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR-SEC-001 | Save data shall be protected from trivial modification | P1 | Draft — plaintext JSON |
| NFR-SEC-002 | Online communication shall use secure protocols | P1 | Deferred |
| NFR-SEC-003 | No sensitive user data shall be collected beyond gameplay | P0 | Complete |
| NFR-SEC-004 | Game shall comply with platform privacy requirements | P0 | Draft |

### 3.6 Localization

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| NFR-LOC-001 | Game shall support English at launch | P0 | Complete |
| NFR-LOC-002 | UI shall support localization-ready text system | P1 | Draft — strings are hardcoded |
| NFR-LOC-003 | Japanese localization shall be available at launch | P2 | Draft |
| NFR-LOC-004 | Additional languages shall be addable post-launch | P2 | Draft |
| NFR-LOC-005 | All text shall avoid hardcoded strings | P1 | Draft — currently violated throughout |

---

## 4. Technical Requirements

### 4.1 Architecture

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| TR-ARC-001 | Game shall use Entity-Component-System (ECS) architecture | P0 | Complete |
| TR-ARC-002 | Systems shall execute in defined order per frame | P0 | Complete |
| TR-ARC-003 | Components shall be data-only containers | P0 | Complete — untyped dictionaries |
| TR-ARC-004 | Entities shall be lightweight identifiers with component references | P0 | Complete — integer IDs |

### 4.2 Core Systems

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| TR-SYS-001 | InputSystem: Process player input to game actions | P0 | Complete |
| TR-SYS-002 | MovementSystem: Apply velocity, gravity, constraints | P0 | Complete |
| TR-SYS-003 | CollisionSystem: Detect and resolve entity collisions | P0 | Superseded — PhysicsSyncSystem + AABB in CombatSystem (§9.8) |
| TR-SYS-004 | CombatSystem: Process attacks, damage, combos | P0 | Complete |
| TR-SYS-005 | EchoSystem: Record, playback, manage Echoes | P0 | Complete |
| TR-SYS-006 | AISystem: Enemy behavior trees, pathfinding | P0 | In Progress — behaviors yes, pathfinding no |
| TR-SYS-007 | MomentumSystem: Track and update momentum gauge | P0 | Complete |
| TR-SYS-008 | AnimationSystem: State machine, sprite updates | P0 | Complete |
| TR-SYS-009 | RenderSystem: Draw all visible entities | P0 | Superseded — Godot's renderer via hybrid nodes |
| TR-SYS-010 | AudioSystem: Sound effects, music playback | P0 | Complete — `AudioManager`, not an ECS system |
| TR-SYS-011 | ParrySystem: Own the parry window and blocking state | P0 | Complete — previously unspecified |
| TR-SYS-012 | BossSystem: Boss phases, patterns, stagger | P0 | Complete — previously unspecified |
| TR-SYS-013 | JumpSystem / DodgeSystem / ProjectileSystem / HealthSystem | P0 | Complete — previously unspecified |
| TR-SYS-014 | PhysicsSyncSystem: single authority bridging ECS and Godot bodies | P0 | Complete — previously unspecified |

### 4.3 Core Components

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| TR-CMP-001 | Position: (x, y) world coordinates | P0 | Complete |
| TR-CMP-002 | Velocity: Speed and direction vector | P0 | Complete |
| TR-CMP-003 | Sprite: Visual representation + animation state | P0 | Complete |
| TR-CMP-004 | Health: Current/max HP, shield values | P0 | In Progress — no shield concept |
| TR-CMP-005 | Weapon: Damage, range, combo data | P0 | Complete |
| TR-CMP-006 | Input: Player control state | P0 | Complete |
| TR-CMP-007 | Momentum: Gauge value, thresholds | P0 | Complete |
| TR-CMP-008 | EchoData: Recording buffer, playback state | P0 | Complete |
| TR-CMP-009 | Collision: Hitbox, collision layers | P0 | Complete |
| TR-CMP-010 | AI: Behavior tree reference, state | P0 | In Progress — state machine, not a behavior tree |

### 4.4 Networking (Co-op)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| TR-NET-001 | Ad-hoc / peer-to-peer connection for co-op | P1 | Deferred |
| TR-NET-002 | State synchronization for player positions and actions | P1 | Deferred |
| TR-NET-003 | Lag compensation for combat fairness | P1 | Deferred |
| TR-NET-004 | Host migration on disconnect | P1 | Deferred |
| TR-NET-005 | NAT traversal for connection establishment | P1 | Deferred |

### 4.5 Data Management

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| TR-DAT-001 | Player progress stored in local save file | P0 | Complete |
| TR-DAT-002 | Level data loaded from asset files | P0 | Superseded — levels are GDScript subclasses (§9.9) |
| TR-DAT-003 | Enemy/weapon stats data-driven (not hardcoded) | P0 | In Progress — archetype table in `main.gd`, not data files |
| TR-DAT-004 | Localization strings stored in separate files | P1 | Draft |

---

## 5. Content Requirements

### 5.1 Levels

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| CR-MSN-001 | Level One (Neon Yoshiwara-equivalent, 4 arenas, two-boss finale) | P0 | Complete |
| CR-MSN-002 | Level Two "Tetsu Spire" (5 arenas) | P0 | Complete — previously unspecified |
| CR-MSN-003 | Missions 3-12 per the CoreDesign mission list | P0 | Draft |
| CR-MSN-004 | 6 Bonus/Challenge missions | P2 | Draft |

### 5.2 Environments

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| CR-ENV-001 | Parallax backdrop (sky + fog bands) | P0 | Complete — Anokolisa "Central City"; placement unverified |
| CR-ENV-002 | Foreground tileset for real level geometry | P0 | Draft — tiles vendored but unused |
| CR-ENV-003 | Neo-Edo identity overlay (torii, lanterns, kanji neon) | P0 | Draft — current art is generic cyberpunk |
| CR-ENV-004 | Remaining environment tilesets per mission list | P1 | Draft |

### 5.3 Characters & Animations

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| CR-CHR-001 | Player character sprite sheet | P0 | Complete — Mattz Art samurai, 96×96 |
| CR-CHR-002 | Player idle, run, jump, fall animations | P0 | In Progress — `fall` is an alias |
| CR-CHR-003 | Player attack animations (light combo, heavy directional) | P0 | Complete |
| CR-CHR-004 | Player dodge, parry, wall-run, block animations | P0 | In Progress — roll/slide/crouch are aliases |
| CR-CHR-005 | Holographic Echo visual effect | P0 | Complete |
| CR-CHR-006 | 5 standard enemy sprite sheets and animations | P0 | In Progress — one sheet, tinted per type |
| CR-CHR-007 | Boss sprite sheets and animations | P0 | In Progress — one shared Demon Samurai sheet |

### 5.4 Audio Assets

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| CR-AUD-001 | Main menu music track | P0 | Draft |
| CR-AUD-002 | Exploration music tracks (per environment) | P0 | Draft |
| CR-AUD-003 | Combat music tracks | P0 | Draft |
| CR-AUD-004 | Boss music tracks | P0 | Draft |
| CR-AUD-005 | Attack sound effects (slash, hit, parry, block) | P0 | Complete — TomMusic sword set |
| CR-AUD-006 | Movement sound effects (footsteps, jump, dash) | P0 | Complete — Kenney CC0 |
| CR-AUD-007 | Echo activation/deactivation sound effects | P0 | Complete |
| CR-AUD-008 | UI sound effects (menu navigation, selection) | P0 | Draft |
| CR-AUD-009 | Enemy sound effects (attacks, death, alert) | P0 | In Progress — shared, not per-enemy |

> All music is still the procedural `SfxGenerator` bed. No composed tracks exist.

### 5.5 UI Assets

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| CR-UI-001 | HUD elements (health, momentum, Echo cooldown, lives, boss bar) | P0 | Complete — code-drawn |
| CR-UI-002 | Menu backgrounds and frames | P0 | Draft |
| CR-UI-003 | Button assets (standard, hover, pressed states) | P0 | Draft |
| CR-UI-004 | Skill tree icons | P0 | Draft |
| CR-UI-005 | Weapon icons | P0 | Draft |
| CR-UI-006 | Currency icons | P0 | Draft |
| CR-UI-007 | Level thumbnails | P0 | Draft |

---

## 6. Platform Requirements

### 6.1 iOS

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| PR-IOS-001 | Minimum iOS version: 14.0 | P0 | Draft |
| PR-IOS-002 | Support iPhone 8 and newer | P0 | Draft |
| PR-IOS-003 | Support iPad (6th gen) and newer | P0 | Draft |
| PR-IOS-004 | Support Game Center achievements | P2 | Draft |
| PR-IOS-005 | Support iCloud save sync | P2 | Draft |
| PR-IOS-006 | Comply with App Store guidelines | P0 | Draft |
| PR-IOS-007 | Support haptic feedback (Taptic Engine) | P1 | Draft |

> iOS export is **config-only**. Building requires macOS + Xcode, which the
> project has no access to. Nothing here has been exercised.

### 6.2 Android

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| PR-AND-001 | Minimum Android version: 8.0 (API 26) | P0 | Complete — minSdk 24, exceeds requirement |
| PR-AND-002 | Support devices with 3GB+ RAM | P0 | Draft — unverified |
| PR-AND-003 | Support Google Play Games achievements | P2 | Draft |
| PR-AND-004 | Support Google Play save sync | P2 | Draft |
| PR-AND-005 | Comply with Google Play guidelines | P0 | Draft |
| PR-AND-006 | Support controller input (optional) | P2 | Complete — gamepad bindings exist |
| PR-AND-007 | Signed debug APK shall build from the repo | P0 | Complete — template-based, no Gradle needed |
| PR-AND-008 | Build shall be verified running on a physical device | P0 | **Draft — never installed or run** |

### 6.3 Steam (PC)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| PR-STM-001 | Minimum Windows: Windows 10 | P0 | Complete |
| PR-STM-002 | Minimum macOS: 11.0 (Big Sur) | P2 | Draft |
| PR-STM-003 | Support keyboard + mouse input | P0 | Complete |
| PR-STM-004 | Support controller input (Xbox, PlayStation) | P0 | Complete — bindings exist, untested |
| PR-STM-005 | Support Steam achievements | P1 | Draft |
| PR-STM-006 | Support Steam Cloud saves | P1 | Draft |
| PR-STM-007 | Support Steam Deck (verified) | P2 | Draft |
| PR-STM-008 | Support resolution scaling (1080p-4K) | P0 | Complete — canvas_items stretch |
| PR-STM-009 | Support variable refresh rate (60-144 FPS) | P1 | Draft |

---

## 7. Business Requirements

### 7.1 Monetization

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| BR-MON-001 | Premium pricing model (one-time purchase) | P0 | Draft |
| BR-MON-002 | No advertisements | P0 | Complete — none present |
| BR-MON-003 | No in-app purchases | P0 | Complete — none present |
| BR-MON-004 | No gacha/lootbox mechanics | P0 | Complete — none present |
| BR-MON-005 | Mobile price point: $4.99-$9.99 | P0 | Draft |
| BR-MON-006 | Steam price point: $14.99-$19.99 | P0 | Draft |

### 7.2 Analytics

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| BR-ANL-001 | Track mission completion rates | P1 | Draft |
| BR-ANL-002 | Track average session duration | P1 | Draft |
| BR-ANL-003 | Track player retention (D1, D7, D30) | P1 | Draft |
| BR-ANL-004 | Track crash reports and errors | P0 | Draft |
| BR-ANL-005 | Analytics shall be privacy-compliant | P0 | Draft |

### 7.3 Marketing Support

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| BR-MKT-001 | Gameplay trailer support (capture system) | P2 | Draft |
| BR-MKT-002 | Screenshot mode or photo mode | P3 | Draft |
| BR-MKT-003 | Press kit assets (logos, screenshots, key art) | P1 | Draft |

---

## 8. Traceability Matrix

### 8.1 Requirements by Development Phase

| Phase | Requirement Categories | State |
|-------|------------------------|-------|
| **Phase 1: Core Foundation** | FR-MOV, FR-CMB, FR-MOM, FR-ECH, FR-DEF, FR-ENM-001→003, FR-HUD, TR-ARC, TR-SYS, TR-CMP | **Substantially complete** |
| **Phase 2: Content Expansion** | CR-MSN, CR-ENV, CR-CHR, FR-WPN, FR-SKL, FR-BOS, FR-ENM-004→005 | **Barely started** — 2 of 12 levels, 2 of 4+ bosses, 1 of 5 weapons, 0 of 30 skills |
| **Phase 3: Polish & Multiplayer** | FR-COP, FR-CPM, FR-REV, TR-NET, NFR-ACC, NFR-LOC, CR-AUD | **Not started** |
| **Phase 4: Launch & Support** | BR-*, PR-*, NFR-SEC | **Not started** |

### 8.2 Critical Path Requirements

```
TR-ARC-* → TR-SYS-* → TR-CMP-*        [DONE]
    ↓
FR-MOV-* → FR-CMB-* → FR-MOM-*        [DONE]
    ↓
FR-DEF-* → FR-ECH-* → FR-ENM-*        [DONE except FR-DEF-013 posture]
    ↓
CR-MSN-* → FR-MSN-*                   [<-- THE CURRENT BOTTLENECK]
    ↓
NFR-PRF-* → PR-*                      [BLOCKED: nothing measured on device]
```

### 8.3 Dependency Summary

| Requirement | Depends On |
|-------------|------------|
| Combat (FR-CMB-*) | Movement (FR-MOV-*) |
| Echo System (FR-ECH-*) | Combat (FR-CMB-*) |
| Bosses (FR-BOS-*) | All combat mechanics |
| Echo puzzles (FR-ECH-009) | Interactables (FR-INT-001) |
| Economy (FR-CUR-*) | A spend surface (FR-MNU-007) |
| Co-op (FR-COP-*) | Core gameplay complete |
| Networking (TR-NET-*) | Co-op requirements defined |
| Platform submission (PR-*) | All P0 requirements complete |

---

## 9. Known Divergences

Where the implementation deliberately or accidentally differs from v1.0.

**9.1 Ability unlocks are not mission-gated.** v1.0 gated dash on Mission 2, grapple on Mission 4, air dash on Mission 6. The slice grants dash at spawn (`main.gd`) and never implemented the others. The unlock flags survive in save data unused.

**9.2 Lives replaced auto-revive.** FR-HLT-005 specified one auto-revive per checkpoint. The build uses a 3-lives run model with in-place restart. This is a better fit for short commuter sessions but was never written down.

**9.3 `ronin_drone` has no archetype entry.** It is used by both levels but falls through `main.archetype()` to the default branch (HP 50 / dmg 18). It works, but Level Two's difficulty was never actually tuned for it.

**9.4 Missions vs levels — two progression models, one dead.** `GameState` exposes a complete mission API (`current_mission`, `mission_progress`, `start_mission`, `complete_mission`, `is_mission_unlocked`) that **nothing calls**. Real progression runs through `Levels.next_after(current_level_id)`. Either missions become the model and levels feed them, or the dead API should be deleted. Unresolved.

**9.5 Co-op priority contradicts the stated vision.** This document treats co-op as a P1/P2 enhancement and asserts "all content shall be completable in solo mode" (FR-COP-001, P0). The stated vision is that **ad-hoc co-op is core**. Those cannot both be true as priorities. Unresolved — see the design discussion.

**9.6 The default control scheme was reversed.** v1.0 FR-CTL-001 made gestures the mobile default. The shipped decision made on-screen buttons canonical and left gesture code dormant. FR-CTL-001/003 now record the shipped decision.

**9.7 Defence is HP chip, not posture.** The stated combat reference is **Sekiro**, whose defensive core is a posture economy: blocking drains posture rather than health, a well-timed block deflects and damages the *enemy's* posture, and a posture break opens a deathblow. Wolf Zero has stagger but **no posture meter** — block is a flat 30% HP chip. FR-DEF-013 captures the gap. This is the single largest design decision outstanding.

**9.8 There is no CollisionSystem.** TR-SYS-003 specified one. The slice deliberately chose `PhysicsSyncSystem` (bridging to Godot's `move_and_slide`) plus distance/AABB checks inside `CombatSystem`, with no `Area2D` hitboxes. Deliberate, and it works.

**9.9 Levels are code, not data.** TR-DAT-002 specified asset-loaded level data. Levels are GDScript subclasses of `Level` registered in `Levels`. Adding a level is a subclass plus a registry line. Fine at 2 levels; revisit before 12.

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **Echo** | Holographic duplicate of player that replays recorded actions |
| **Momentum** | Combat resource built through successful attacks/dodges/parries |
| **Neo Edo** | Game setting: cyberpunk feudal Japan |
| **ECS** | Entity-Component-System architecture pattern |
| **i-frames** | Invincibility frames during dodge animation |
| **Parry** | Perfectly timed defensive action that negates, reflects, and staggers |
| **Block** | Held defensive stance; reduces damage to chip, prevents knockback |
| **Perilous** | Unblockable attack; only dodge i-frames avoid it |
| **Posture** | Proposed Sekiro-style defensive resource. Not implemented — FR-DEF-013 |
| **Arena** | Trigger-bounded encounter within a level; also a checkpoint |

---

## Appendix B: Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-08 | Initial document creation |
| 1.1 | 2026-08-15 | Reconciled against implementation. Set a real status on every requirement (v1.0 left all ~230 as `Draft`). Added §2.10 defensive combat, §9 known divergences, and requirements for systems built but never specified (Oni Warlord, lives, boss bar, ParrySystem, BossSystem, PhysicsSyncSystem, Level Two, dash-jump). Reversed FR-CTL-001 to match the shipped control scheme. Rewrote §2.4.1 around levels rather than missions. |

---

*Document Version: 1.1*
*Status: Reconciled against implementation at commit `3b88231`*
*Last Updated: 2026-08-15*
