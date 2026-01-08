Here it! Here’s a concise summary of all the **entities**, **components**, and **systems** we’ve designed for your cyberpunk historical side-scroller hack-and-slash game with platforming and co-op, built using an ECS architecture. This captures the core structure and unique features while keeping it modular and teamwork-focused.

---

### **Entities**

These are the main game objects, each just an ID with attached components:

1. **Player Characters (Co-op Pair)**: Two players with distinct roles (e.g., stealth vs. brute).
2. **Cybernetic Companions**: One per player (e.g., clockwork raven, jade dragon drone).
3. **Enemies**: Regular foes (cyborg knights) and bosses (e.g., Leonardo mech).
4. **Environment**: Platforms, traps (laser grids), destructible objects, NPC crowds.
5. **History Hacking Device**: Shared tool for altering levels.

---

### **Components**

Data containers that define entity properties:

1. **Position**: (x, y) coordinates for location.
2. **Velocity**: Speed and direction for movement.
3. **Sprite**: Visual representation (e.g., neon samurai, crumbling bridge).
4. **Health**: Hit points for players/enemies.
5. **Weapon**: Damage and type (e.g., plasma katana, nano-pistol).
6. **Augmentation**: Cybernetic abilities (e.g., jet boost, magnetic boots).
7. **Input**: Stores player controls (movement, attacks, co-op actions).
8. **EnergyCore**: Shared resource for co-op abilities (amount and state).
9. **Faction**: Player role/style (e.g., Cyber-Shogunate stealth).
10. **Behavior**: AI logic for companions (e.g., follow, attack).
11. **Upgrade**: Companion mods (e.g., Tesla coils, grapple).
12. **Owner**: Links companion to a player.
13. **AI**: Enemy attack patterns and era-shifting logic.
14. **Phase**: Boss states (e.g., shielded, vulnerable).
15. **Collision**: Hitbox and type (solid, hazardous).
16. **DynamicState**: Environment state (e.g., peaceful vs. battlefield).
17. **CrowdBehavior**: NPC states (neutral, rioting, allied).
18. **HackState**: History hacking effect (e.g., plague, cannons).
19. **Cooldown**: Limits hacking device usage.

---

### **Systems**

Logic that processes entities with specific components:

1. **Input System**:
    - Uses: `Input`, `Velocity`, `Weapon`, `Augmentation`, `EnergyCore`.
    - Does: Reads controls, updates movement/attacks, manages co-op core trading.
2. **Movement System**:
    - Uses: `Position`, `Velocity`, `Augmentation`.
    - Does: Updates positions, handles gravity, applies platforming boosts.
3. **Collision System**:
    - Uses: `Position`, `Collision`.
    - Does: Resolves overlaps (platforms, traps, damage), supports co-op lifts.
4. **Combat System**:
    - Uses: `Weapon`, `Health`, `Position`, `Phase`.
    - Does: Applies damage, updates health, shifts boss phases.
5. **Augmentation System**:
    - Uses: `Augmentation`, `EnergyCore`.
    - Does: Activates cyber abilities, manages co-op core sharing.
6. **Companion System**:
    - Uses: `Behavior`, `Owner`, `Upgrade`, `Position`.
    - Does: Controls companion AI (attack, assist platforming) for both players.
7. **History Hacking System**:
    - Uses: `HackState`, `DynamicState`, `Cooldown`.
    - Does: Alters environments/enemies, splits co-op roles (hack vs. fight).
8. **Crowd System**:
    - Uses: `CrowdBehavior`, `Position`.
    - Does: Updates NPC behavior (riot, ally) based on player actions.
9. **Rendering System**:
    - Uses: `Position`, `Sprite`.
    - Does: Draws visuals (neon pagodas, cyber-knights) for both players.
10. **Time Trial System**:
    - Uses: Global state, player `Position`.
    - Does: Tracks time, triggers hazards, unlocks rewards for co-op finishes.

---

### **How It Fits Together**

- **Gameplay**: Players slash through cyberpunk historical cities (e.g., neon Edo Tokyo), platform across dynamic levels, and fight era-shifting foes. Co-op shines with shared `EnergyCore`, companion teamwork, and split tasks (hacking vs. combat).
- **ECS Flow**: Systems run each frame—Input → Movement → Collision → Combat → Augmentation → Companion → History Hacking → Crowd → Rendering—processing relevant entities.
- **Unique Features**: History hacking, faction roles, cybernetic companions, and neon-charged bosses all emerge naturally from component combos and system logic.

This summary keeps everything tight and ready to expand. Want to tweak an entity (like a specific boss) or zoom in on a system’s details? Let me know!