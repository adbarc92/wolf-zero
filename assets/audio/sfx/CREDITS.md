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
| `hit`       | Kenney Impact     | `impactPunch_heavy_001.ogg`  |
| `hit_light` | Kenney Impact     | `impactPunch_medium_000.ogg` |
| `jump`      | Kenney Interface  | `select_006.ogg`             |
| `dash`      | Kenney Impact     | `footstep_concrete_004.ogg`  |
| `dodge`     | Kenney Interface  | `select_002.ogg`             |
| `parry`     | TomMusic (sword)  | `Sword Parry 1.ogg`          |
| `block`     | Kenney Impact     | `impactWood_medium_000.ogg`  |
| `echo`      | Kenney Interface  | `confirmation_001.ogg`       |
| `death`     | Kenney Interface  | `error_006.ogg`              |

## Notes

- `slash`/`parry` are real sword swing + sword-on-sword parry from the TomMusic pack.
  The 372 MB source pack is git-ignored; only these two oggs are committed (under this
  dir). Sword **hit** and **blocked** variants exist in the same pack if we later want
  to upgrade `hit`/`block` off the Kenney stand-ins.
- Music is still the procedural bed (`SfxGenerator.music()`); not sourced here.
