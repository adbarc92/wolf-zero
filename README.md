Entities
These are the main game objects, each just an ID with attached components:

Player Characters (Co-op Pair): Two players with distinct roles (e.g., stealth vs. brute).
Cybernetic Companions: One per player (e.g., clockwork raven, jade dragon drone).
Enemies: Regular foes (cyborg knights) and bosses (e.g., Leonardo mech).
Environment: Platforms, traps (laser grids), destructible objects, NPC crowds.
History Hacking Device: Shared tool for altering levels.
Components
Data containers that define entity properties:

Position: (x, y) coordinates for location.
Velocity: Speed and direction for movement.
Sprite: Visual representation (e.g., neon samurai, crumbling bridge).
Health: Hit points for players/enemies.
Weapon: Damage and type (e.g., plasma katana, nano-pistol).
Augmentation: Cybernetic abilities (e.g., jet boost, magnetic boots).
Input: Stores player controls (movement, attacks, co-op actions).
EnergyCore: Shared resource for co-op abilities (amount and state).
Faction: Player role/style (e.g., Cyber-Shogunate stealth).
Behavior: AI logic for companions (e.g., follow, attack).
Upgrade: Companion mods (e.g., Tesla coils, grapple).
Owner: Links companion to a player.
AI: Enemy attack patterns and era-shifting logic.
Phase: Boss states (e.g., shielded, vulnerable).
Collision: Hitbox and type (solid, hazardous).
DynamicState: Environment state (e.g., peaceful vs. battlefield).
CrowdBehavior: NPC states (neutral, rioting, allied).
HackState: History hacking effect (e.g., plague, cannons).
Cooldown: Limits hacking device usage.
Systems
Logic that processes entities with specific components:

Input System:
Uses: Input, Velocity, Weapon, Augmentation, EnergyCore.
Does: Reads controls, updates movement/attacks, manages co-op core trading.
Movement System:
Uses: Position, Velocity, Augmentation.
Does: Updates positions, handles gravity, applies platforming boosts.
Collision System:
Uses: Position, Collision.
Does: Resolves overlaps (platforms, traps, damage), supports co-op lifts.
Combat System:
Uses: Weapon, Health, Position, Phase.
Does: Applies damage, updates health, shifts boss phases.
Augmentation System:
Uses: Augmentation, EnergyCore.
Does: Activates cyber abilities, manages co-op core sharing.
Companion System:
Uses: Behavior, Owner, Upgrade, Position.
Does: Controls companion AI (attack, assist platforming) for both players.
History Hacking System:
Uses: HackState, DynamicState, Cooldown.
Does: Alters environments/enemies, splits co-op roles (hack vs. fight).
Crowd System:
Uses: CrowdBehavior, Position.
Does: Updates NPC behavior (riot, ally) based on player actions.
Rendering System:
Uses: Position, Sprite.
Does: Draws visuals (neon pagodas, cyber-knights) for both players.
Time Trial System:
Uses: Global state, player Position.
Does: Tracks time, triggers hazards, unlocks rewards for co-op finishes.
How It Fits Together
Gameplay: Players slash through cyberpunk historical cities (e.g., neon Edo Tokyo), platform across dynamic levels, and fight era-shifting foes. Co-op shines with shared EnergyCore, companion teamwork, and split tasks (hacking vs. combat).
ECS Flow: Systems run each frame—Input → Movement → Collision → Combat → Augmentation → Companion → History Hacking → Crowd → Rendering—processing relevant entities.
Unique Features: History hacking, faction roles, cybernetic companions, and neon-charged bosses all emerge naturally from component combos and system logic.
This summary keeps everything tight and ready to expand. Want to tweak an entity (like a specific boss) or zoom in on a system’s details? Let me know!
