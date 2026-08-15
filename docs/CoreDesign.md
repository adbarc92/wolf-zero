# Wolf-Zero: Core Design Document

## Executive Summary

**Wolf-Zero** is a 2D side-scrolling hack-and-slash game with platforming elements, set in Neo Edo—a cyberpunk reimagining of feudal Japan. The game targets mobile platforms (iOS/Android) as primary, with Steam as secondary. Designed for 10-20 minute play sessions, it features a defensive combat model, a Holographic Echo mechanic, and ad-hoc co-op multiplayer.

**Core Pillars** *(restated 2026-08-15)*:
1. **X-Class Mobility** — Mega Man X traversal: dash, dash-jump, wall-kick, ~1-frame response
2. **Sekiro-Class Defence** — Defence is the conceit. Timing, not attrition, decides fights
3. **Ad-Hoc Co-op** — Device-to-device play is core to the product's identity
4. **Session-Friendly** — Short, restart-cheap runs designed for commuter play
5. **Neo Edo Atmosphere** — Distinctive cyberpunk-feudal aesthetic fusion

> ### What this document is, as of 2026-08-15
>
> This is the **full design**, written for a 12-mission commercial game.
> [ADR 0003](adr/0003-shipped-scope.md) cuts most of it from launch. The shipped
> game is:
>
> - **6 handcrafted levels** (the ADR allows 4–6; planning targets 6, floor 4)
> - **4 bosses**: Crimson Ronin and Oni Warlord are built; Geisha Network and
>   Iron Daimyo remain, with Iron Daimyo as the finale
> - **A Boss Gauntlet** (§4.4) — the repeatable mode, and the home of ad-hoc co-op
> - **Skill trees, the three-currency economy, the four extra weapons and the
>   twelve-mission narrative arc are post-launch.**
>
> Sections describing cut content are labelled **POST-LAUNCH** in place rather
> than deleted, and are parked in [`IDEA-BANK.md`](IDEA-BANK.md). The launch
> scope of every individual requirement lives in
> [`Requirements.md`](Requirements.md); this document is the *design*, that one
> is the *scope*. Domain vocabulary is fixed by [`CONTEXT.md`](../CONTEXT.md).
>
> Three ADRs also changed the design itself, and the body text below now reflects
> them:
>
> - **[ADR 0001](adr/0001-momentum-absorbs-posture.md)** — Momentum absorbs
>   posture. One bar, blocking spends it, a full bar banks a **Charge**. The
>   25/50/75/100 thresholds and the Echo cooldown are gone (§3.1.3, §3.2).
> - **[ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md)** —
>   Co-op is solo-complete with fully independent cameras (§6).
> - **[ADR 0003](adr/0003-shipped-scope.md)** — the scope above.
>
> The Holographic Echo was pillar #2 in v1.0 and is now unlisted. ADR 0001 gives
> it an identity it lacked — the thing you buy with a Charge earned by fighting
> well — but it is no longer claimed as *the* signature mechanic. The defensive
> combat model is.

---

## 1. Game Overview

### 1.1 Genre & Inspirations
- **Genre:** 2D Side-scrolling Hack-and-Slash / Action Platformer
- **Primary Inspirations:**
  - *Mega Man X (X4-X6)* — Dash-centric traversal, instant response, boss gauntlets
  - *Sekiro* — Posture-based defence; deflect and break rather than whittle down
  - *Ninja Gaiden* — Technical precision, challenging combat
  - *Dead Cells* — Mobile-friendly action, satisfying progression

  *Katana Zero* was the v1.0 reference and has been retired: it implies one-hit
  lethality and time manipulation, which is not the direction.

### 1.2 Target Platforms
| Platform | Priority | Notes |
|----------|----------|-------|
| iOS | Primary | Touch-optimized, on-screen buttons (§5.1) |
| Android | Primary | Touch-optimized, on-screen buttons (§5.1) |
| Steam (PC) | Secondary | Controller + keyboard support |

### 1.3 Session Design
- **Target Session:** 10-20 minutes
- **Level Length:** 8-15 minutes average ("mission" is legacy vocabulary — see `CONTEXT.md`)
- **Gauntlet Run Length:** under 15 minutes, start to results
- **Save System:** Auto-save at level start, checkpoints mid-level
- **Quick Resume:** Instant pause/resume for interrupted sessions

### 1.4 Monetization
- **Model:** Premium (one-time purchase)
- **Price Point:** $4.99-$9.99 mobile / $14.99-$19.99 Steam
- **No ads, no IAP, no gacha**

---

## 2. Setting: Neo Edo

### 2.1 World Concept
Neo Edo exists in an alternate timeline where the Tokugawa Shogunate never fell. Instead, it evolved into a techno-feudal megastate where:

- **Megacorporations** replaced traditional daimyo clans
- **Cybernetic enhancement** is commonplace but regulated by social class
- **Traditional aesthetics** persist alongside advanced technology
- **The old ways** (bushido, honor codes) clash with corporate ruthlessness

### 2.2 Visual Identity
| Element | Historical | Cyberpunk Fusion |
|---------|------------|------------------|
| Architecture | Pagodas, torii gates, castle walls | Neon-lit, holographic overlays, fusion reactors |
| Weapons | Katana, naginata, shuriken | Plasma edges, vibroblades, smart-tracking |
| Clothing | Hakama, haori, kabuto | Fiber-optic threading, integrated HUDs |
| Environment | Cherry blossoms, bamboo, paper screens | Holographic flora, cyber-bamboo, smart-glass |

### 2.3 Key Locations (Level Settings)

*Six locations for six levels, though the shipped game may reuse an environment
across two levels rather than build all six (CR-ENV-004). Level One is the Neon
Yoshiwara equivalent and Level Two is Tetsu Spire, an industrial ascent not in
this list.*
1. **Neon Yoshiwara** — Entertainment district, dense verticality, crowd cover
2. **The Rust Pagodas** — Abandoned temple complex, decayed tech, environmental hazards
3. **Cyber-Daimyo Tower** — Corporate fortress, security systems, boss arena
4. **Undergrid Canals** — Sewers and waterways, stealth-focused, tight corridors
5. **The Floating Market** — Platform-heavy, moving surfaces, NPC crowds
6. **Shogun's Digital Garden** — Final area, reality-bending, time distortions

---

## 3. Core Gameplay

### 3.1 Combat System

#### 3.1.1 Basic Combat Loop
```
Attack → Chain Combos → Build Momentum → Execute Special → Reset
```

#### 3.1.2 Attack Types
| Action | Gesture (Mobile) | Effect |
|--------|------------------|--------|
| Light Attack | Tap | Quick slash, chain up to 5x |
| Heavy Attack | Swipe (direction) | Slower, armor-breaking, directional |
| Dodge | Swipe opposite enemy | i-frames, repositioning |
| Parry | Tap at impact | Perfect timing reflects damage |
| Jump | Swipe up | Aerial state, enables air combos |
| Holographic Echo | Two-finger tap | Activate signature mechanic |

#### 3.1.3 Momentum Gauge

*(Rewritten for [ADR 0001](adr/0001-momentum-absorbs-posture.md). The 25/50/75/100
threshold model this section previously described is deleted, not deferred.)*

**Momentum is composure**, and every combatant has it. High is in control; zero
is **Broken** — staggered, unable to act, open.

- **Attacking and parrying build** it. **Blocking spends** it.
- The bar **starts empty**, so the opening of a fight must be offensive.
  Aggression is what funds the ability to defend; turtling from frame one is not
  available.
- The player is Broken by blocking with nothing left to spend. An enemy is Broken
  by the player's parries draining theirs.
- Filling the bar completely **banks a Charge** and drops back to a partial
  floor, never to zero. It can be filled and banked several times in one fight.
- It decays over time when not fighting.

**Charges** are a small, non-decaying pool and the *only* gate on the abilities
they buy — an ability costing a Charge has no separate cooldown. Deploying an
Echo costs one Charge. In co-op the pool is **shared** between players (§6.3.1).

A **Deathblow** is available against a Broken enemy: it kills a regular enemy
outright whatever health remains, and ends one phase of a boss. Breaking
something is genuinely faster than wearing it down — that is what makes defence
the central verb rather than an alternative to attacking.

#### 3.1.4 Weapon System
**Starting Weapon:** Plasma Katana (balanced speed/damage). **At launch this is
the entire roster.**

**Unlockable Weapons — POST-LAUNCH** *(cut by [ADR 0003](adr/0003-shipped-scope.md);
parked as `Requirements.md` FR-WPN-002→010, [IDEA-BANK](IDEA-BANK.md#progression-systems).
The Cyber-Tessen is the one to revisit first — a parry-bonus weapon is the one
most aligned with the defensive conceit.)*

| Weapon | Style | Strength | Weakness |
|--------|-------|----------|----------|
| Vibro-Wakizashi | Speed | Fast combos, quick Echo | Low damage per hit |
| Neon Nodachi | Power | High damage, wide arc | Slow recovery |
| Chain-Kusarigama | Range | Distance control, pull enemies | Complex timing |
| Cyber-Tessen | Technical | Parry bonus, defensive | Requires precision |

### 3.2 Holographic Echo System

The signature mechanic of Wolf-Zero. Players can summon a holographic copy of their recent actions.

#### 3.2.1 Core Functionality
1. **Recording:** Last 3 seconds of player actions are continuously recorded
2. **Activation:** Two-finger tap deploys the Echo at current position
3. **Playback:** Echo replays recorded actions as a holographic duplicate
4. **Duration:** 3 seconds of playback, then Echo dissipates
5. **Cost:** one **Charge** — no cooldown, no momentum threshold. Per
   [ADR 0001](adr/0001-momentum-absorbs-posture.md) the Charge *is* the gate;
   the old 8-second cooldown is deleted

#### 3.2.2 Combat Applications
- **Pincer Attack:** Attack enemy, dodge behind, deploy Echo facing their back
- **Combo Extension:** Echo continues combo while player repositions
- **Distraction:** Echo draws enemy aggro while player flanks
- **Double Damage:** Time Echo attacks to sync with player for burst damage

#### 3.2.3 Platforming Applications — POST-LAUNCH
*(All three need interactive objects — pressure plates, switches, timed
platforms — which are themselves parked (FR-INT-001→007, FR-ECH-009). Launch
levels use the Echo as a combat tool only.)*

- **Weight Triggers:** Echo can hold pressure plates
- **Sequence Puzzles:** Player and Echo activate switches in sequence
- **Timed Gaps:** Echo holds a platform while player crosses

#### 3.2.4 Upgrade Path — POST-LAUNCH
*(Cut by [ADR 0003](adr/0003-shipped-scope.md); parked as FR-ECH-011→015. The
unlock column is doubly obsolete: there are no missions 7, 10 or 12, and Rapid
Recall has no cooldown left to reduce. Dual Echo is the one worth revisiting
first — two Echoes is a genuinely different verb with obvious co-op resonance.)*

| Upgrade | Effect | Unlock (obsolete) |
|---------|--------|--------|
| Extended Memory | Record 4 seconds | Mission 3 |
| Rapid Recall | 6 second cooldown | Mission 5 |
| Solid Echo | Echo can interact with physical objects | Mission 7 |
| Dual Echo | Deploy two Echoes simultaneously | Mission 10 |
| Persistent Echo | Echo lasts 5 seconds | Mission 12 |

### 3.3 Platforming

#### 3.3.1 Movement Abilities

**Every verb is granted at spawn.** There is no unlock ladder — a 6-level
campaign is too short to spend levels dispensing movement, and the two abilities
that were gated latest are the two that are parked
(`Requirements.md` §9.1).

| Ability | Input | Launch |
|---------|-------|----------|
| Wall Jump | Swipe up at wall | Granted at start |
| Wall Run | Swipe along wall | Granted at start |
| Dash | Double-tap direction | Granted at start |
| Dash-jump | Jump while dashing | Granted at start — the primary traversal verb |
| Grapple | Tap grapple point | **POST-LAUNCH** (FR-MOV-006) |
| Air Dash | Swipe direction mid-air | **POST-LAUNCH** as a distinct verb (FR-MOV-007) |

#### 3.3.2 Environmental Interactions — POST-LAUNCH
*(FR-INT-001→007, parked. Launch levels are built from static platforms,
wall-run surfaces and enemy placement.)*

- **Cyber-Bamboo:** Climbable, can be cut to create platforms
- **Holographic Bridges:** Appear/disappear on timer or triggers
- **Magnetic Rails:** High-speed traversal sections
- **Destructible Screens:** Slice to reveal paths or trap enemies

### 3.4 Enemy Design

#### 3.4.1 Enemy Types
| Type | Behavior | Counter Strategy |
|------|----------|------------------|
| Ronin Drone | Basic melee, telegraphed | Standard attacks |
| Cyber-Ashigaru | Ranged, low health | Close gap quickly |
| Oni Mech | Heavy armor, slow | Heavy attacks, parry |
| Shinobi Ghost | Cloaks, backstabs | Audio cues, Echo bait |
| Tech-Priest | Buffs allies, summons | Prioritize first |

#### 3.4.2 Boss Design Philosophy
Each boss requires mastery of a game mechanic. The launch roster is **four**:

1. **Crimson Ronin** (Level 1, mid-boss) — Teaches parry timing. *Built.*
2. **Oni Warlord** (Level 1, finale) — Perilous-heavy; teaches "dodge, don't
   defend". *Built, and never specified in v1.0.*
3. **The Geisha Network** (Level 3) — Tests Echo usage for multi-target
4. **Iron Daimyo** (Level 6) — Platform combat, phase transitions. **The final
   boss of the shipped campaign.**

**Digital Shogun — POST-LAUNCH.** He was the climax of the narrative arc (§11),
and a final boss whose whole point is a story beat costs more than it returns in
a game that tells no story. Parked as FR-BOS-004.

Bosses matter more than they did in the v1.0 design: they are the only opponents
durable enough for the Momentum/Break/Deathblow loop to be legible — four of six
enemy types die in about half a second — and they are the content the Boss
Gauntlet (§4.4) is built from. **Elite / mini-boss variants** of existing enemies
fill the gaps between them.

---

## 4. Progression Systems

### 4.1 Level Structure

**Total Levels: 6** (floor of 4 — see [ADR 0003](adr/0003-shipped-scope.md) and
`Requirements.md` §2.4.1). Two are built. The 12-main-plus-6-bonus structure is
post-launch and the old mission list is kept for reference in Appendix A.

**Level Format:**
```
Title card → Platforming → Arena encounters → Elite / mini-boss → Boss → Results
```

Each Level is a sequence of **Arenas** — position-triggered encounters that also
serve as checkpoints — ending at a goal line. Enemies are obstacles, not gates: a
skilled player is expected to be able to run past most of them.

**Level Flow Example (Level 6: the finale):**
1. Title card: place name, one line of flavour (no briefing, no plot)
2. Platforming approach (3 min)
3. Arena: mixed roster (2 min)
4. Arena: elite encounter (2 min)
5. Approach to the boss door (2 min)
6. Boss: Iron Daimyo, phased (4 min)
7. Results: time and score

**Post-launch, the same skeleton carried:** a briefing, an Echo-based lock
puzzle, and a currency-and-unlocks results screen. All three are parked
(FR-MSN-008, FR-ECH-009, FR-CUR-001→006).

### 4.2 Player Progression — POST-LAUNCH

> **The shipped game has no meta-progression.** ADR 0003 cuts skill trees and the
> three-currency economy; what remains is the campaign itself and your own skill.
> XP, the level-30 cap and Skill Points are built and still persist in the save
> file, but they buy nothing at launch and nothing displays them
> (`Requirements.md` §9.10). Everything in §4.2 and §4.3 is parked in
> [`IDEA-BANK.md`](IDEA-BANK.md#progression-systems).

#### 4.2.1 Experience & Levels — POST-LAUNCH
- XP earned from: Kills, combos, mission completion, challenges
- Level cap: 30
- Each level grants: 1 Skill Point + stat boost

#### 4.2.2 Skill Trees — POST-LAUNCH
*(FR-SKL-001→007. 30 skills is 30 balance problems and 30 icons in service of a
long campaign the shipped game does not have. The ECHO branch is the interesting
one if any of it returns — it modifies a verb rather than a number.)*

Three branches, 10 skills each:

**BLADE (Combat)**
- Combo extension
- Damage multipliers
- Parry windows
- Ultimate attacks

**SHADOW (Mobility)**
- Dash distance
- Wall run duration
- Grapple speed
- Air control

**ECHO (Time)**
- Cooldown reduction
- Duration extension
- Echo damage
- Multi-Echo

#### 4.2.3 Currency & Upgrades — POST-LAUNCH
*(FR-CUR-001→006. An economy needs earn, spend and a reason to care; only earn
exists. Neon Yen accrues in the save file at launch and is never shown or spent.)*

- **Neon Yen:** Mission rewards, used for weapon upgrades
- **Echo Fragments:** Rare drops, used for Echo skill unlocks
- **Legacy Tokens:** Challenge completion, used for cosmetics

### 4.3 Weapon Upgrades — POST-LAUNCH
*(FR-WPN-008/009. Tier data and the cap exist in code with no content and no
spend path. Costs are quoted in Neon Yen, which is itself post-launch.)*

Each weapon has 5 upgrade tiers:

| Tier | Cost | Bonus |
|------|------|-------|
| I | 500 | +10% damage |
| II | 1500 | +15% damage, +effect |
| III | 3500 | +20% damage, enhanced effect |
| IV | 7000 | +25% damage, new ability |
| V | 15000 | +30% damage, mastery perk |

### 4.4 Boss Gauntlet (the repeatable mode)

The campaign is finite; the Gauntlet is what brings a commuter back. It is the
retention loop and the home of ad-hoc co-op — see
[ADR 0003](adr/0003-shipped-scope.md) and `Requirements.md` §2.11 for the
requirements.

**Shape.** Bosses and elites fought back to back in one arena. No traversal, no
goal line, no platforming — only fights. **Health is not restored between them**,
and banked Charges carry over, so a run is one long resource decision rather than
a series of independent bouts.

**Scoring.** Elapsed time, and defensive performance — parries landed, enemies
Broken, hits taken. The second half of that is deliberate: it scores the thing
the game is about. A player who kills fast but blocks everything should not beat
a player who kills slower and parries.

**Why this and not wave survival.** It is nearly free — it reuses bosses,
elites and environment art the campaign builds anyway — and durable opponents are
the only place the Momentum/Deathblow loop is legible at all. Four of six enemy
types die in about half a second, so a wave mode would exercise crowd navigation
instead of the combat model. Time attack, wave survival and roguelike runs are
all wanted eventually and are queued in
[`IDEA-BANK.md`](IDEA-BANK.md#further-repeatable-modes); none is built until the
Gauntlet proves the loop is worth returning to.

**Constraints.** A full run fits inside a commute — under 15 minutes. It unlocks
once the player has beaten a boss in the campaign, so it is reachable in a first
session. It ships with **no bespoke content**: if the Gauntlet starts needing its
own bosses, arenas or systems, it has become the scope creep ADR 0003 exists to
prevent.

---

## 5. Controls

### 5.1 Mobile (Primary)

> **The default was reversed.** On-screen buttons (§5.1.2) are the shipped
> default on mobile; the gesture scheme below is retained in code but dormant and
> is post-launch (FR-CTL-001/003, `Requirements.md` §9.6).

#### 5.1.1 Gesture Controls — POST-LAUNCH
| Action | Gesture |
|--------|---------|
| Move | Left thumb virtual joystick (appears on touch) |
| Light Attack | Tap right side |
| Heavy Attack | Swipe right side (directional) |
| Jump | Swipe up |
| Dodge | Swipe opposite threat direction |
| Holographic Echo | Two-finger tap |
| Pause | Tap pause icon (top corner) |

#### 5.1.2 Virtual Button Controls (the shipped default)
Traditional mobile controls:
- Fixed virtual joystick (left)
- Attack button (A)
- Jump button (B)
- Dodge button (X)
- Echo button (Y)
- Heavy attack modifier (hold + A)

#### 5.1.3 Control Settings
- Gesture sensitivity adjustment
- Button size/position customization
- Haptic feedback toggle
- Auto-aim assist (adjustable)

### 5.2 Steam/PC (Secondary)

#### 5.2.1 Controller (Recommended)
| Action | Input |
|--------|-------|
| Move | Left Stick |
| Light Attack | X / Square |
| Heavy Attack | Y / Triangle |
| Jump | A / Cross |
| Dodge | B / Circle |
| Holographic Echo | LB / L1 |
| Grapple | RB / R1 |
| Pause | Start |

#### 5.2.2 Keyboard + Mouse
| Action | Input |
|--------|-------|
| Move | WASD |
| Light Attack | Left Click |
| Heavy Attack | Right Click |
| Jump | Space |
| Dodge | Shift |
| Holographic Echo | Q |
| Grapple | E |

---

## 6. Co-op System

### 6.1 Design Philosophy

*(Rewritten for
[ADR 0002](adr/0002-co-op-is-solo-complete-with-independent-cameras.md). The v1.0
"enhances but never required" text is superseded; the ADR records why.)*

**Co-op is solo-complete and co-op-elevated.** Identical content either way. Solo
is never the lesser experience and requires no AI companion.

"Core" means core to the **product's identity and word-of-mouth**, not core to
playability. The target player is 14–25 and on a commute, which is usually alone;
ad-hoc co-op needs two co-located people with two devices, which is a school or
social context. A game that *required* co-op would be unplayable in its own most
common context. Monster Hunter on PSP is the proven resolution for exactly this
audience: completable solo, while co-op was the cultural centre and the reason it
spread.

**Cameras are fully independent.** Each device follows its own player. There is
no leash and no shared view. The mobility pillar forces this — dash-jump moves
the player at 800 px/s and a screen is roughly 1920 units, so two players moving
apart are a full screen apart in about two seconds, and a leash would tax the
game's best verb constantly. Two phones also means nobody is looking at a shared
screen in the first place.

Three consequences run through the rest of this section: co-op is expressed
through **proximity verbs** rather than gated content; **Arenas activate on the
first player** to cross the trigger; and because neither player can see the
other's screen, "partner in trouble" has to be **explicit in the HUD**.

### 6.2 Co-op Modes

#### 6.2.1 Ad-hoc Co-op (the shipped mode)
- Two players, two co-located devices, local wireless
- Pairing is **local device discovery** — no account, no invite code, no server
- If the second device drops, the session degrades to solo rather than ending
- Its home is the **Boss Gauntlet** (§4.4), though the campaign supports it too

#### 6.2.2 Local same-device Co-op — POST-LAUNCH
*(FR-COP-002. Split control zones on a tablet is a different mode with different
control problems, not a cheaper version of ad-hoc.)*

- Same device, split control zones: P1 left, P2 right
- Recommended for tablets

#### 6.2.3 Online Co-op — POST-LAUNCH
*(FR-COP-004→007, TR-NET-004/005. Everything here assumes a service the shipped
game does not have. With exactly two players there is also no one to migrate a
host to — see [IDEA-BANK](IDEA-BANK.md#online-co-op-services).)*

- Matchmaking or friend invite
- Host migration on disconnect
- Cross-platform: Mobile ↔ Mobile, Steam ↔ Steam

### 6.3 Co-op Mechanics

#### 6.3.1 Shared Charge Pool (formerly the Shared Energy Core)
- A single **Charge** pool for both players — the same pool
  [ADR 0001](adr/0001-momentum-absorbs-posture.md) introduces, not a second
  resource
- Charges are banked by *either* player filling their Momentum bar, and spent by
  either on Echoes and Charge-gated abilities
- Requires coordination: spending is visible and contested
- **No co-op regeneration bonus.** Charges are earned by fighting well, not
  regenerated over time, so there is nothing to accelerate (FR-CPM-002, removed)

#### 6.3.2 Proximity verbs
Actions that exist only when the two players are near each other. Separation is
free; converging is what buys access to these. They must never be the *best* way
to fight, because a solo player cannot see them at all.

- **Linked Attacks:** both players hit the same enemy within 0.5s = damage bonus
- **Linked Deflect:** both parrying the same attack rewards both
- **Deathblow handoff:** one player Breaks an enemy, either may land the Deathblow
- **Echo Overlap** *(POST-LAUNCH, FR-CPM-004)*: both Echoes in the same space = AOE burst
- **Launcher Combo** *(POST-LAUNCH, FR-CPM-005)*: needs launchers, also parked

#### 6.3.3 Revive System
- Downed state (10 seconds), partner revives on a 3 second channel
- Revives draw on the **shared run life pool** — the 3-lives model the build
  already uses — rather than being unlimited
- If both players are downed, both respawn at the checkpoint and a life is spent
- **Solo has no downed state**: solo death spends a life and restarts at the
  checkpoint. The v1.0 "auto-revive once per checkpoint" is gone
  (`Requirements.md` §9.2)

### 6.4 Solo Adaptations
Solo is the default case, not a degraded one. The only adaptation is a balance
knob:

- Enemy health reduced by 15%
- **No AI companion** — ADR 0002 removes the need for one (FR-SOL-004, parked)
- **No co-op-gated content**, so nothing needs an alternate solo solution
- The Echo cooldown discount is gone with the cooldown itself (ADR 0001)

---

## 7. Technical Architecture (ECS)

### 7.1 Entity Types
| Entity | Description |
|--------|-------------|
| Player | Controlled character(s) |
| Enemy | AI-controlled hostiles |
| Echo | Holographic duplicate |
| Projectile | Ranged attacks, throwables |
| Platform | Static and dynamic surfaces |
| Interactable | Switches, doors, pickups |
| VFX | Particle systems, visual effects |

### 7.2 Core Components
```
Position        - (x, y) world coordinates
Velocity        - Speed and direction vector
Sprite          - Visual representation + animation state
Health          - Current/max HP, shield values
Weapon          - Damage, range, combo data
Input           - Player control state
Momentum        - Gauge value, banked Charges (ADR 0001)
EchoData        - Recording buffer, playback state
Collision       - Hitbox, collision layers
AI              - Behavior tree reference, state
```

### 7.3 Core Systems
```
1. InputSystem       - Process player input → actions
2. MovementSystem    - Apply velocity, gravity, constraints
3. CollisionSystem   - Detect/resolve collisions
4. CombatSystem      - Process attacks, damage, combos
5. EchoSystem        - Record, playback, manage Echoes
6. AISystem          - Enemy behavior, pathfinding
7. MomentumSystem    - Track/update momentum gauge
8. AnimationSystem   - State machine, sprite updates
9. RenderSystem      - Draw all visible entities
10. AudioSystem      - Sound effects, music
```

### 7.4 System Execution Order
```
Per Frame:
InputSystem → AISystem → MovementSystem → CollisionSystem →
CombatSystem → EchoSystem → MomentumSystem → AnimationSystem →
AudioSystem → RenderSystem
```

---

## 8. Audio Design

### 8.1 Music Style
**Genre:** Synth-Koto Fusion
- Traditional Japanese instruments (koto, shamisen, taiko)
- Layered with synthwave elements
- Dynamic intensity based on combat state

### 8.2 Audio States
| State | Music Character |
|-------|-----------------|
| Exploration | Ambient, sparse koto |
| Combat | Driving synth, taiko beats |
| Boss | Intense, full orchestration |
| Echo Active | Reverb filter, time-stretch |
| Low Health | Heartbeat pulse overlay |

### 8.3 Sound Design Principles
- **Clarity:** Distinct audio cues for enemy attacks (parry windows)
- **Feedback:** Satisfying impact sounds for hits
- **Spatial:** Stereo positioning for off-screen threats
- **Accessibility:** Visual indicators complement audio cues

---

## 9. Visual Style

### 9.1 Art Direction
**Style:** Stylized 2D with silhouette emphasis
- Characters: Sharp silhouettes with neon accent lighting
- Backgrounds: Layered parallax, ink-wash inspired with cyber elements
- Effects: Vibrant particle systems, screen-flash on impacts

### 9.2 Color Palette
| Element | Colors |
|---------|--------|
| Player | Cyan accents, white core |
| Enemies | Red/orange accents |
| Echo | Translucent cyan, scan-line effect |
| Environment | Deep purples, neon pinks, electric blues |
| UI | Clean white, accent color highlights |

### 9.3 Performance Targets
| Platform | Resolution | FPS |
|----------|------------|-----|
| Mobile | Native | 60 |
| Steam | 1080p-4K | 60-144 |

---

## 10. UI/UX

### 10.1 HUD Elements
**Minimal, non-intrusive:**
- Health bar (top-left, slim)
- Momentum gauge (bottom-center, fills toward edges)
- Lives remaining
- Boss health bar, while a boss is active
- Charge pool (shared, in co-op)
- Objective / prompt line (top-center, fades after 3s)
- **In co-op:** partner health, lives and downed state — the cameras are
  independent, so this is the only way a player learns their partner is in
  trouble

### 10.2 Menu Flow
```
Title → Main Menu → Campaign  → Level → Results → Main Menu
                  ↘ Gauntlet  → Run   → Results (time, score, best)
                  ↘ Co-op: find a nearby device
                  ↘ Options
```

**POST-LAUNCH:** Mission Select, Loadout, Skills, Armory (FR-MNU-003/004/006/007)
— each is parked because the system behind it is. A linear 6-level campaign with
one weapon and no skills has nothing to select, equip, spend or browse.

### 10.3 Accessibility Options
Shipping: colorblind modes (3 presets), screen shake toggle, haptic toggle,
visual indicators alongside audio cues.

**POST-LAUNCH:** one-handed simplified mode, auto-dodge assist, subtitle size
options, high contrast mode (NFR-USE-003, NFR-ACC-003→005).

---

## 11. Narrative Framework

> **What ships is the setting, not the story.** ADR 0003 cuts the plot, and the
> same ADR raises the bar on Neo Edo in the same breath: with no narrative, the
> setting has to land entirely through art, audio and level design — and the
> setting is a selling point. So the floor is **enough Neo Edo to make the place
> real**, not silence:
>
> - **Ships:** named locations, named bosses, a one-screen title card per level
>   (place name plus a single line of flavour), and storytelling carried by the
>   environment art (FR-NAR-002/006/007). Budget: about one line of text per
>   level. If it starts needing a writer, it has left scope.
> - **POST-LAUNCH:** everything in §11.1 and §11.2 below — Kira, the erased
>   family, the Digital Shogun, briefings, boss dialogue, data logs. **None of it
>   exists in the build**; no character is named anywhere in the game today.
>   Parked in [`IDEA-BANK.md`](IDEA-BANK.md#narrative).
>
> §11.3's themes still guide art direction even with no plot to carry them.

### 11.1 Story Synopsis — POST-LAUNCH
You are **Kira**, a former corporate enforcer whose family was erased from the Neo Edo registry—officially, they never existed. The Holographic Echo device, stolen from your former employers, is both weapon and evidence. Each mission brings you closer to the truth: the Digital Shogun is rewriting history itself, and your family's deletion was just a test run.

### 11.2 Story Delivery — POST-LAUNCH
- **Briefings:** Short text/voice before missions
- **Environmental:** Visual storytelling in levels — *this one ships*
- **Data Logs:** Optional collectibles expand lore
- **Boss Dialogue:** Character moments during fights
- **No cutscenes:** Maintains session flow — *this one ships, vacuously*

### 11.3 Themes
- Memory and identity in a digital age
- Tradition vs. progress
- The cost of corporate power
- Personal honor in a dishonorable world

---

## 12. Development Priorities

*(Rewritten for the shipped scope. `Requirements.md` §8.2 carries the same phases
mapped to requirement IDs.)*

### Phase 1: Core Foundation — substantially complete
- Player movement and combat, defensive model, Holographic Echo
- 2 levels, 5 enemy types, 2 bosses, HUD, touch controls, mobile export
- **Outstanding:** the ADR 0001 combat rework (Momentum absorbs posture, Charges,
  Broken, Deathblow). Everything after this depends on it

### Phase 2: Campaign content
- Levels Three to Six (four more)
- Geisha Network and Iron Daimyo; elite / mini-boss variants
- Neo-Edo identity art, per-level environments, level title cards
- Composed music replacing the procedural bed

### Phase 3: Boss Gauntlet
- Mode select, run structure, no-heal-between-fights, Charge carry-over
- Time and defensive scoring, results screen, persisted personal bests

### Phase 4: Ad-hoc co-op
- Local pairing, state sync, independent cameras, multi-player arena activation
- Shared Charge pool, proximity verbs, downed/revive, partner HUD
- Phases 3 and 4 are cheaper built together — the Gauntlet is where co-op lives

### Phase 5: Launch readiness
- **Run the game on an actual device** (nothing has ever been measured on one)
- Performance, accessibility settings, options UI, localization-ready strings
- Platform submissions, press kit, day-one patch readiness

---

## Appendix A: Level Plan

**Launch: 6 levels, 4 bosses.** Two levels are built. The floor, if production
slips, is levels 1–4 with three bosses, making Geisha Network the finale.

| # | Level | Setting | Boss | State |
|---|-------|---------|------|-------|
| 1 | Neon Yoshiwara | Entertainment district, dense verticality | Crimson Ronin (mid) → Oni Warlord | **Built** — 4 arenas |
| 2 | Tetsu Spire | Industrial ascent | — | **Built** — 5 arenas |
| 3 | — | Rust Pagodas or Floating Market | Geisha Network | To build |
| 4 | — | Undergrid Canals | — | To build |
| 5 | — | TBD | — | To build |
| 6 | — | Daimyo Tower | Iron Daimyo (final) | To build |
| — | Boss Gauntlet arena | reuses campaign art | all of the above, plus elites | To build |

### Appendix A.1: The original 12-mission list — POST-LAUNCH

*(Retained for reference. Cut by [ADR 0003](adr/0003-shipped-scope.md) and parked
in [`IDEA-BANK.md`](IDEA-BANK.md). Note how much of the column on the right is
itself parked — grapple, air dash, dual Echo, the AI companion and the story
climax are all post-launch, so most of these missions no longer have a reason to
exist as separate levels.)*

| # | Name | Setting | Boss | New Mechanic |
|---|------|---------|------|--------------|
| 1 | First Blood | Neon Yoshiwara | None (tutorial) | Basic combat |
| 2 | Shadow Protocol | Rust Pagodas | Mini-boss | Dash |
| 3 | The Red Gate | Floating Market | Crimson Ronin | Parry mastery |
| 4 | Undergrid | Canals | Courier Guard | Grapple |
| 5 | Ghost Network | Digital Garden | None (puzzle) | AI Companion |
| 6 | Painted Faces | Yoshiwara Deep | Geisha Network | Multi-Echo |
| 7 | Iron Will | Daimyo Tower Base | Mini-boss | Air Dash |
| 8 | The Ascent | Daimyo Tower Mid | None (gauntlet) | Vertical combat |
| 9 | Throne Room | Daimyo Tower Top | Iron Daimyo | Phase bosses |
| 10 | Memory Leak | Reality Fracture | Mini-boss | Dual Echo |
| 11 | True History | Shogun's Archive | None (revelation) | Story climax |
| 12 | Zero Hour | Digital Throne | Digital Shogun | All mechanics |

---

## Appendix B: Competitive Analysis

| Game | Strength to Adopt | Weakness to Avoid |
|------|-------------------|-------------------|
| Katana Zero | Precise combat feel, style | No mobile version, short length |
| Dead Cells | Mobile success, replayability | Roguelike fatigue, complexity |
| Ninja Gaiden | Depth, satisfaction | Punishing difficulty, dated feel |
| Grimvalor | Mobile hack-slash proof | Generic fantasy, less unique |

---

## Appendix C: Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Touch controls feel imprecise | Medium | High | On-screen buttons are the default (§9.6); playtesting on a real device |
| Co-op networking issues | Medium | Medium | Solo-complete by rule (ADR 0002) — co-op failing degrades to solo, it never blocks |
| Scope creep | High | High | ADR 0003 and the Launch column in `Requirements.md`; the Gauntlet ships with no bespoke content |
| The Gauntlet becomes the new scope creep | Medium | High | FR-GNT-009: reuse only. Named explicitly as a cost in ADR 0003 |
| Too little content at a premium price | Medium | Medium | 6 levels rather than 4, and a repeatable mode that has to genuinely carry replay value |
| Neo Edo does not land without a story | Medium | High | Identity art is P0 (CR-ENV-003); named places, named bosses, title cards |
| Mobile performance | Low | High | ECS optimization, scalable quality |
| **The build has never been run by a human** | — | High | Highest-priority action in `STATUS.md` |

---

*Document Version: 1.1*
*Last Updated: 2026-08-15 — scoped to ADR 0003; §3.1.3, §3.2 and §6 rewritten for ADRs 0001 and 0002*
