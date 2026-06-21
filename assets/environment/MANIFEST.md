# Environment Art — ansimuz "Warped City" parallax (CC0)

Source pack: **Warped City** by ansimuz — https://ansimuz.itch.io/warped-city
License: **Creative Commons Zero v1.0 Universal (CC0)** — no attribution required for the art.

> ⚠️ BUNDLED-MUSIC EXCEPTION: the Warped City download ships a music track
> (credited to Pascal Belisle) under a **separate** license. Do NOT vendor or
> ship that audio with this lane. This lane uses ONLY the parallax art layers.

## Current state of this directory

The PNGs currently committed here are **programmatically generated placeholders**
(simple cyberpunk-toned gradients) because the real CC0 art could not be fetched
from the network at build time. They exist so `SceneBackdrop` builds cleanly and
the unit test can assert the layer count.

`SceneBackdrop` (`scripts/render/scene_backdrop.gd`) loads its layers **by path**
from this directory. To swap in the real art, replace the placeholder files with
the real Warped City layers **using the exact same filenames** below — no code
change required.

## Layer files (far → near) — drop-in target paths

Warped City ships a 3-layer parallax. Map the pack's layers onto these filenames:

| Target file (this dir)                | Role                  | Warped City source layer (rename to this) |
| ------------------------------------- | --------------------- | ------------------------------------------ |
| `assets/environment/warped-city-sky.png`       | back / sky gradient   | the farthest sky/back layer  |
| `assets/environment/warped-city-far.png`       | mid distant cityscape | the middle distant-buildings layer |
| `assets/environment/warped-city-buildings.png` | near buildings        | the nearest buildings/foreground parallax layer |

(Exact source filenames vary by pack revision — ansimuz commonly names them
`back.png` / `middle.png` / `foreground.png` or `far-buildings.png` etc. Rename
whichever maps to each role above. Keep the target names on the left unchanged.)

## Notes / scope

- This is GENERIC cyberpunk art. No Japanese / Neo-Edo motifs (torii, lanterns,
  kanji neon) are part of this lane — that overlay is a separate, blocked
  commission item.
