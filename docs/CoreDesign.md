# Wolf-Zero: Core Design Document

## Executive Summary

**Wolf-Zero** is a 2D side-scrolling hack-and-slash game with platforming elements, set in Neo Edo—a cyberpunk reimagining of feudal Japan. The game targets mobile platforms (iOS/Android) as primary, with Steam as secondary. Designed for 10-20 minute play sessions, it features gesture-based combat, a unique Holographic Echo time mechanic, and optional co-op multiplayer.

**Core Pillars:**
1. **Fluid Combat** — Fast, responsive hack-and-slash with momentum-based combos
2. **Holographic Echo** — Signature time manipulation mechanic for combat and puzzles
3. **Session-Friendly** — Discrete missions designed for commuter play
4. **Neo Edo Atmosphere** — Distinctive cyberpunk-feudal aesthetic fusion

---

## 1. Game Overview

### 1.1 Genre & Inspirations
- **Genre:** 2D Side-scrolling Hack-and-Slash / Action Platformer
- **Primary Inspirations:**
  - *Katana Zero* — Tight combat, time manipulation, stylish presentation
  - *Ninja Gaiden* — Technical precision, challenging combat
  - *Dead Cells* — Mobile-friendly action, satisfying progression

### 1.2 Target Platforms
| Platform | Priority | Notes |
|----------|----------|-------|
| iOS | Primary | Touch-optimized, gesture controls |
| Android | Primary | Touch-optimized, gesture controls |
| Steam (PC) | Secondary | Controller + keyboard support |

### 1.3 Session Design
- **Target Session:** 10-20 minutes
- **Mission Length:** 8-15 minutes average
- **Save System:** Auto-save at mission start, checkpoints mid-mission
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

### 2.3 Key Locations (Mission Settings)
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
- Builds through successful attacks, dodges, and parries
- Decays slowly when not in combat
- **Thresholds:**
  - 25% — Unlock Echo abilities
  - 50% — Enhanced attack damage (+20%)
  - 75% — Extended Echo duration
  - 100% — Ultimate attack available

#### 3.1.4 Weapon System
**Starting Weapon:** Plasma Katana (balanced speed/damage)

**Unlockable Weapons:**
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
5. **Cooldown:** 8 seconds base (reduced by upgrades)

#### 3.2.2 Combat Applications
- **Pincer Attack:** Attack enemy, dodge behind, deploy Echo facing their back
- **Combo Extension:** Echo continues combo while player repositions
- **Distraction:** Echo draws enemy aggro while player flanks
- **Double Damage:** Time Echo attacks to sync with player for burst damage

#### 3.2.3 Platforming Applications
- **Weight Triggers:** Echo can hold pressure plates
- **Sequence Puzzles:** Player and Echo activate switches in sequence
- **Timed Gaps:** Echo holds a platform while player crosses

#### 3.2.4 Upgrade Path
| Upgrade | Effect | Unlock |
|---------|--------|--------|
| Extended Memory | Record 4 seconds | Mission 3 |
| Rapid Recall | 6 second cooldown | Mission 5 |
| Solid Echo | Echo can interact with physical objects | Mission 7 |
| Dual Echo | Deploy two Echoes simultaneously | Mission 10 |
| Persistent Echo | Echo lasts 5 seconds | Mission 12 |

### 3.3 Platforming

#### 3.3.1 Movement Abilities
| Ability | Input | Unlocked |
|---------|-------|----------|
| Wall Jump | Swipe up at wall | Start |
| Wall Run | Swipe along wall | Start |
| Dash | Double-tap direction | Mission 2 |
| Grapple | Tap grapple point | Mission 4 |
| Air Dash | Swipe direction mid-air | Mission 6 |

#### 3.3.2 Environmental Interactions
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
Each boss requires mastery of a game mechanic:

1. **Crimson Ronin** (Mission 3) — Teaches parry timing
2. **The Geisha Network** (Mission 6) — Tests Echo usage for multi-target
3. **Iron Daimyo** (Mission 9) — Platform combat, phase transitions
4. **Digital Shogun** (Mission 12) — All mechanics, Echo essential

---

## 4. Progression Systems

### 4.1 Mission Structure

**Total Missions:** 12 main + 6 bonus/challenge

**Mission Format:**
```
Briefing → Infiltration/Platforming → Combat Encounters → Mini-Boss/Puzzle → Boss → Results
```

**Mission Flow Example (Mission 4: Undergrid Canals):**
1. Briefing: Target data courier in the undergrid
2. Stealth platforming through patrol routes (3 min)
3. Combat encounter: Clear checkpoint (2 min)
4. Puzzle: Echo-based lock sequence (2 min)
5. Combat gauntlet: Waves before boss door (3 min)
6. Boss: Courier's cyber-bodyguard (4 min)
7. Results: XP, currency, unlocks

### 4.2 Player Progression

#### 4.2.1 Experience & Levels
- XP earned from: Kills, combos, mission completion, challenges
- Level cap: 30
- Each level grants: 1 Skill Point + stat boost

#### 4.2.2 Skill Trees
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

#### 4.2.3 Currency & Upgrades
- **Neon Yen:** Mission rewards, used for weapon upgrades
- **Echo Fragments:** Rare drops, used for Echo skill unlocks
- **Legacy Tokens:** Challenge completion, used for cosmetics

### 4.3 Weapon Upgrades
Each weapon has 5 upgrade tiers:

| Tier | Cost | Bonus |
|------|------|-------|
| I | 500 | +10% damage |
| II | 1500 | +15% damage, +effect |
| III | 3500 | +20% damage, enhanced effect |
| IV | 7000 | +25% damage, new ability |
| V | 15000 | +30% damage, mastery perk |

---

## 5. Controls

### 5.1 Mobile (Primary)

#### 5.1.1 Gesture Controls (Default)
| Action | Gesture |
|--------|---------|
| Move | Left thumb virtual joystick (appears on touch) |
| Light Attack | Tap right side |
| Heavy Attack | Swipe right side (directional) |
| Jump | Swipe up |
| Dodge | Swipe opposite threat direction |
| Holographic Echo | Two-finger tap |
| Pause | Tap pause icon (top corner) |

#### 5.1.2 Virtual Button Controls (Alternative)
For players preferring traditional mobile controls:
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
Co-op enhances the experience but is never required. All content is completable solo.

### 6.2 Co-op Modes

#### 6.2.1 Local Co-op (Mobile)
- Same device, split control zones
- Player 1: Left side controls
- Player 2: Right side controls
- Recommended for tablets

#### 6.2.2 Online Co-op
- Matchmaking or friend invite
- Peer-to-peer connection
- Host migration on disconnect
- Cross-platform: Mobile ↔ Mobile, Steam ↔ Steam

### 6.3 Co-op Mechanics

#### 6.3.1 Shared Energy Core
- Single energy pool for both players
- Powers special abilities and Echoes
- Requires coordination on usage
- Regenerates faster in co-op (+25%)

#### 6.3.2 Combo Synergy
- **Linked Attacks:** Hitting same enemy within 0.5s = damage bonus
- **Echo Overlap:** Both Echoes in same space = AOE burst
- **Launcher Combo:** One player launches, other air combos

#### 6.3.3 Revive System
- Downed state (10 seconds to revive)
- Partner can revive (3 second channel)
- Solo: Auto-revive once per checkpoint
- Co-op: Unlimited partner revives

### 6.4 Solo Adaptations
When playing solo:
- Enemy health reduced by 15%
- Echo cooldown reduced by 20%
- Some co-op puzzles have alternate solo solutions
- AI companion available (optional, unlocked Mission 5)

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
Momentum        - Gauge value, thresholds
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
- Echo cooldown (small icon, near character)
- Mission objective (top-center, fades after 3s)

### 10.2 Menu Flow
```
Title → Main Menu → Mission Select → Loadout → Mission → Results → Mission Select
                 ↓
              Options / Skills / Armory / Co-op Lobby
```

### 10.3 Accessibility Options
- Colorblind modes (3 presets)
- Screen shake toggle
- One-handed mode (simplified controls)
- Auto-dodge assist
- Subtitle size options
- High contrast mode

---

## 11. Narrative Framework

### 11.1 Story Synopsis
You are **Kira**, a former corporate enforcer whose family was erased from the Neo Edo registry—officially, they never existed. The Holographic Echo device, stolen from your former employers, is both weapon and evidence. Each mission brings you closer to the truth: the Digital Shogun is rewriting history itself, and your family's deletion was just a test run.

### 11.2 Story Delivery
- **Briefings:** Short text/voice before missions
- **Environmental:** Visual storytelling in levels
- **Data Logs:** Optional collectibles expand lore
- **Boss Dialogue:** Character moments during fights
- **No cutscenes:** Maintains session flow

### 11.3 Themes
- Memory and identity in a digital age
- Tradition vs. progress
- The cost of corporate power
- Personal honor in a dishonorable world

---

## 12. Development Priorities

### Phase 1: Core Foundation
- Player movement and combat
- Holographic Echo system
- 1 complete level (Neon Yoshiwara)
- Basic enemy types (3)
- Mobile gesture controls

### Phase 2: Content Expansion
- Remaining 11 missions
- All enemy types
- All bosses
- Weapon variety
- Skill trees

### Phase 3: Polish & Multiplayer
- Co-op implementation
- Steam port
- Audio/visual polish
- Accessibility features
- Localization

### Phase 4: Launch & Support
- Platform submissions
- Marketing materials
- Day-one patch readiness
- Post-launch content planning

---

## Appendix A: Mission List

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
| Gesture controls feel imprecise | Medium | High | Extensive playtesting, alternative control scheme |
| Co-op networking issues | Medium | Medium | Design solo-first, co-op as enhancement |
| Scope creep | High | High | Strict phase gates, MVP focus |
| Mobile performance | Low | High | ECS optimization, scalable quality |
| Market saturation | Medium | Medium | Unique Echo mechanic as differentiator |

---

*Document Version: 1.0*
*Last Updated: 2026-01-08*
