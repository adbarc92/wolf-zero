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

## Getting Started

1. Open project in Godot 4.2+
2. Run `main.tscn` scene
3. Use WASD to move, Space to jump, J to attack, K for heavy attack, Shift to dodge, Q for Echo

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
