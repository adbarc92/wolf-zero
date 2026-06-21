# Audio Asset Manifest — Lane A (SFX)

The `AudioManager` (`scripts/audio/audio_manager.gd`) is **asset-driven**. For each
event key it probes, in priority order:

1. `res://assets/audio/sfx/<key>.ogg`  ← preferred for mobile
2. `res://assets/audio/sfx/<key>.wav`

If neither file exists, it falls back to the procedural `SfxGenerator.make(<key>)`,
so the game always has audio. **Today every key uses the procedural fallback** — the
suite passes purely on fallback. Drop the files below in to upgrade any key; no code
change is needed.

## Drop-in target paths (one file per event key)

Convert each downloaded WAV to OGG for mobile, e.g.:

```
ffmpeg -i source.wav -c:a libvorbis -q:a 4 assets/audio/sfx/<key>.ogg
```

(Or import the WAV in Godot and leave it as `.wav` — the loader accepts either.)

| Event key   | Target path                              | Suggested CC0 source |
|-------------|------------------------------------------|----------------------|
| `slash`     | `assets/audio/sfx/slash.ogg`             | TomMusic "RPG Sword & Shield" — sword swing/whoosh (CC0, freesound.org user `TomMusic`) |
| `hit`       | `assets/audio/sfx/hit.ogg`               | Kenney **Impact Sounds** (CC0) — `impactPunch_heavy_001.ogg` |
| `hit_light` | `assets/audio/sfx/hit_light.ogg`         | Kenney **Impact Sounds** (CC0) — `impactPunch_medium_000.ogg` |
| `jump`      | `assets/audio/sfx/jump.ogg`              | Kenney **Interface Sounds** (CC0) — `select_006.ogg` (short blip) |
| `dash`      | `assets/audio/sfx/dash.ogg`              | Kenney **Impact Sounds** (CC0) — `footstep_concrete_004.ogg` / whoosh |
| `dodge`     | `assets/audio/sfx/dodge.ogg`             | Kenney **Interface Sounds** (CC0) — `select_002.ogg` (down-blip) |
| `parry`     | `assets/audio/sfx/parry.ogg`             | TomMusic "RPG Sword & Shield" — metallic clang/parry (CC0) |
| `block`     | `assets/audio/sfx/block.ogg`             | Kenney **Impact Sounds** (CC0) — `impactWood_medium_000.ogg` (thud) |
| `echo`      | `assets/audio/sfx/echo.ogg`              | Kenney **Interface Sounds** (CC0) — `confirmation_001.ogg` (chime) |
| `death`     | `assets/audio/sfx/death.ogg`             | Kenney **Interface Sounds** (CC0) — `error_006.ogg` (descending) |

## Where to fetch (all CC0 / public domain)

- **Kenney Impact Sounds** — https://kenney.nl/assets/impact-sounds (License: CC0 1.0)
- **Kenney Interface Sounds** — https://kenney.nl/assets/interface-sounds (License: CC0 1.0)
- **TomMusic RPG Sword & Shield SFX** — https://freesound.org/people/TomMusic/
  (filter to CC0 packs; sword swing + metal clang). License: CC0 1.0.

Download the pack ZIP, pick the closest sound for each key, convert WAV→OGG with the
ffmpeg command above, and place it at the target path. The `AudioManager` will pick it
up automatically on next run (it prefers `.ogg` over `.wav`, and a real file over the
procedural fallback).

## Notes

- Keep files mono and short (< 0.5 s for impacts/blips) to match the procedural
  voices they replace.
- Music is **out of scope** for this lane — `SfxGenerator.music()` provides the
  procedural bed and `AudioManager.set_music_enabled()` toggles it.
