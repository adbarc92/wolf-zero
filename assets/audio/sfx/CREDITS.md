# SFX Credits

All shipped sound effects are **CC0 1.0 (public domain)** by **Kenney** (https://kenney.nl).
Crediting Kenney is appreciated but not required. Source packs:

- **Impact Sounds** — https://kenney.nl/assets/impact-sounds (CC0 1.0)
- **Interface Sounds** — https://kenney.nl/assets/interface-sounds (CC0 1.0)

## Per-key mapping (event key → source file)

| Event key   | Source pack | Source file                 |
|-------------|-------------|-----------------------------|
| `slash`     | Impact      | `impactMetal_light_002.ogg` |
| `hit`       | Impact      | `impactPunch_heavy_001.ogg` |
| `hit_light` | Impact      | `impactPunch_medium_000.ogg`|
| `jump`      | Interface   | `select_006.ogg`            |
| `dash`      | Impact      | `footstep_concrete_004.ogg` |
| `dodge`     | Interface   | `select_002.ogg`            |
| `parry`     | Impact      | `impactMetal_heavy_000.ogg` |
| `block`     | Impact      | `impactWood_medium_000.ogg` |
| `echo`      | Interface   | `confirmation_001.ogg`      |
| `death`     | Interface   | `error_006.ogg`             |

## Notes

- `slash` and `parry` use metallic impacts as CC0 stand-ins for a dedicated sword
  pack (the MANIFEST's suggested TomMusic sword/clang lives on freesound, which needs
  authenticated download). Swap them in later for a sharper blade tone — drop the new
  file at the same path, no code change.
- Music is still the procedural bed (`SfxGenerator.music()`); not sourced here.
