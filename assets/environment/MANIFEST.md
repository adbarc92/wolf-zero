# Environment Art — Anokolisa "Sidescroller Shooter — Central City"

Source pack: **Sidescroller Shooter — Central City** by **Anokolisa**
— https://anokolisa.itch.io/sidescroller-shooter-central-city

License: free for **commercial** use and modification; **attribution appreciated**
(credit Anokolisa). No standalone resale/redistribution as an asset pack. (Confirmed
by the author in the itch.io comments — there is no separate license file in the pack.)
This is permissive enough to bundle inside the project; please keep Anokolisa in the
game credits.

The full pack lives at `assets/Sidescroller Shooter - Central City/` (buildings, props,
tilesets + the background layers). `SceneBackdrop` only uses the **background** layers,
copied here under clean names; the buildings/props/tiles are a foreground **tileset**
for level geometry (a separate level-art task), not parallax.

## Parallax layers (far → near)

`SceneBackdrop` (`scripts/render/scene_backdrop.gd`) loads these **by path** from this
directory. Swapping art is a data-only edit to `SceneBackdrop.LAYERS`.

| File (this dir)                | Role                         | Pack source (Background/) |
| ------------------------------ | ---------------------------- | ------------------------- |
| `central-city-sky.png`         | back / purple-neon sky       | `Base Color.png` (480×320) |
| `central-city-fog-mid.png`     | mid fog band (tiles horiz.)  | `Mid Fog.png` (16×144)     |
| `central-city-fog-front.png`   | near fog band (tiles horiz.) | `Frontal Fog.png` (16×144) |

The fog strips are 16 px wide and tile horizontally via `motion_mirroring`; the sky is a
gradient scaled to cover the 1920×1080 viewport.

## Notes / scope

- **Visual tuning pending:** the per-layer `scale`/`offset` in `SceneBackdrop.LAYERS` are
  a sensible first pass set without a running viewport. Fine-tune the fog band heights and
  vertical placement on-screen / on-device.
- **No distant city silhouette layer.** This pack's city is meant to be *built from tiles*
  in the foreground, so the backdrop is sky + fog only. A distant-building parallax layer
  would need to be composed from the `Buildings`/`Background Props` tiles (future work) or
  sourced from another pack.
- Still GENERIC cyberpunk — the Neo-Edo overlay (torii / lanterns / kanji neon) remains a
  separate identity pass on top of this base.
