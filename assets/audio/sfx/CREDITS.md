# SFX Credits

Shipped sound effects come from two packs, both free for commercial use:

- **Kenney** (https://kenney.nl) — **CC0 1.0 (public domain)**, crediting appreciated:
  - **Impact Sounds** — https://kenney.nl/assets/impact-sounds
  - **Interface Sounds** — https://kenney.nl/assets/interface-sounds
- **TomMusic** "Free Fantasy 200 SFX Pack" — https://tommusic.itch.io/free-fantasy-200-sfx-pack
  — free for commercial/personal use, credit appreciated, **no resale or
  redistribution as a standalone asset** (NOT CC0; fine bundled inside this project).

## Per-key mapping (event key → source file)

| Event key   | Source pack       | Source file                  |
|-------------|-------------------|------------------------------|
| `slash`     | TomMusic (sword)  | `Sword Attack 1.ogg`         |
| `hit`       | TomMusic (sword)  | `Sword Impact Hit 1.ogg`     |
| `hit_light` | Kenney Impact     | `impactPunch_medium_000.ogg` |
| `jump`      | Kenney Interface  | `select_006.ogg`             |
| `dash`      | Kenney Impact     | `footstep_concrete_004.ogg`  |
| `dodge`     | Kenney Interface  | `select_002.ogg`             |
| `parry`     | TomMusic (sword)  | `Sword Parry 1.ogg`          |
| `block`     | TomMusic (sword)  | `Sword Blocked 1.ogg`        |
| `echo`      | Kenney Interface  | `confirmation_001.ogg`       |
| `death`     | Kenney Interface  | `error_006.ogg`              |

## Notes

- `slash`/`hit`/`parry`/`block` are all real sword SFX from the TomMusic pack (swing,
  impact hit, parry, block). The 372 MB source pack is git-ignored; only the four used
  oggs are committed (under this dir). The remaining keys use Kenney CC0.
- Music is still the procedural bed (`SfxGenerator.music()`); not sourced here.
