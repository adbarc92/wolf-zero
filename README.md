# Wolf-Zero

A cyberpunk hack-and-slash game set in Neo Edo, built with Godot 4 and a custom ECS architecture.

## Project Structure

```
wolf-zero/
├── assets/                    # Game assets
│   ├── audio/                 # Music and SFX
│   ├── sprites/               # Character and environment sprites
│   └── icon.svg               # Game icon
│
├── docs/                      # Design documentation
│   ├── CoreDesign.md          # Core game design document
│   ├── Requirements.md        # Full requirements specification
│   ├── DevTasks.md            # Development task breakdown
│   ├── Architecture.md        # ECS architecture overview
│   └── Features.md            # Feature brainstorming
│
├── scenes/                    # Godot scenes
│   ├── main/                  # Main game scene
│   ├── levels/                # Level scenes
│   ├── ui/                    # UI scenes
│   └── entities/              # Entity prefab scenes
│
├── scripts/                   # GDScript source code
│   ├── autoload/              # Global autoload scripts
│   │   ├── game_events.gd     # Global event bus
│   │   ├── game_state.gd      # Save/load, progression
│   │   └── input_manager.gd   # Touch/gesture input
│   │
│   ├── ecs/                   # Entity Component System
│   │   ├── ecs.gd             # Core ECS manager (autoload)
│   │   ├── ecs_system.gd      # Base system class
│   │   ├── components.gd      # Component definitions
│   │   └── systems/           # System implementations
│   │       ├── input_system.gd
│   │       ├── movement_system.gd
│   │       ├── jump_system.gd
│   │       ├── combat_system.gd
│   │       ├── momentum_system.gd
│   │       ├── echo_system.gd
│   │       ├── health_system.gd
│   │       ├── dodge_system.gd
│   │       └── ai_system.gd
│   │
│   ├── entities/              # Entity helpers
│   │   ├── entity_factory.gd  # Factory for creating entities
│   │   └── player_controller.gd # Godot physics bridge
│   │
│   └── main/                  # Main game controller
│       └── main.gd
│
└── project.godot              # Godot project file
```

## ECS Architecture

Wolf-Zero uses a custom Entity Component System for game logic:

### Entities
Lightweight integer IDs that represent game objects.

### Components
Pure data containers (dictionaries) attached to entities:
- `position` - World coordinates
- `velocity` - Movement speed/direction
- `health` - HP and invincibility
- `weapon` - Damage, combos, attack state
- `momentum` - Combat resource gauge
- `echo_data` - Holographic Echo recording
- `platformer` - Jump, dash, wall-run abilities
- `input_state` - Player input
- `ai` - Enemy behavior

### Systems
Logic processors that run each frame:
1. `InputSystem` - Read player input
2. `JumpSystem` - Handle jumping/wall-jumping
3. `DodgeSystem` - Handle dodge rolls
4. `MovementSystem` - Apply physics
5. `CombatSystem` - Process attacks/damage
6. `MomentumSystem` - Track momentum gauge
7. `EchoSystem` - Record and playback echoes
8. `HealthSystem` - Manage HP/invincibility
9. `AISystem` - Enemy behavior

## Requirements

- [Godot Engine 4.2+](https://godotengine.org/download) (Standard or .NET version)
- macOS, Windows, or Linux

## Getting Started

### Installation

1. **Download Godot 4.2+** from [godotengine.org](https://godotengine.org/download)
   - Choose the "Standard" version (GDScript)
   - Extract/install to your preferred location

2. **Clone or download this repository**
   ```bash
   git clone <repository-url>
   cd wolf-zero
   ```

3. **Open the project in Godot**
   - Launch Godot Engine
   - Click "Import" and navigate to the `wolf-zero` folder
   - Select `project.godot` and click "Import & Edit"

### Running the Game

**From Godot Editor:**
- Press `F5` to run the main scene
- Or click the "Play" button in the top-right corner

**From Command Line (if Godot is in PATH):**
```bash
# macOS
/Applications/Godot.app/Contents/MacOS/Godot --path .

# Windows
godot.exe --path .

# Linux
godot --path .
```

### Test Scene

The game starts with a test scene containing:
- A cyan player character (left side)
- A red enemy drone (right side)
- Several platforms to jump on

**Try these to test combat effects:**
1. Move toward the enemy with A/D
2. Press J repeatedly to perform light attack combos
3. Watch for: cyan slash arcs, brief freeze (hitstop), screen shake, and sparks on hit
4. Build up to 4+ combo hits for critical effects (longer freeze, yellow sparks)

## Controls (Keyboard)

| Action | Key |
|--------|-----|
| Move | A/D |
| Jump | Space |
| Light Attack | J |
| Heavy Attack | K |
| Dodge | Shift |
| Echo | Q |
| Pause | Escape |

## Mobile Controls

- **Left side**: Virtual joystick for movement
- **Right side tap**: Light attack
- **Right side swipe**: Heavy attack / Dodge
- **Swipe up**: Jump
- **Two-finger tap**: Activate Echo

## Troubleshooting

**"Scene not found" error:**
- Ensure you opened the project via "Import" in Godot, not just the folder

**No visuals / black screen:**
- Check that `scenes/main/main.tscn` is set as the main scene in Project Settings

**Controls not working:**
- Verify input mappings in Project > Project Settings > Input Map
- Keys: A/D (move), Space (jump), J (light attack), K (heavy attack)

**Godot version errors:**
- This project requires Godot 4.2+. Earlier versions (3.x or 4.0/4.1) may have compatibility issues
