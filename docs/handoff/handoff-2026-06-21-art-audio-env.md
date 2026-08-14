# Handoff — Art / Audio / Environment integration (2026-06-21)

> For the next session. The art+audio+environment swap is **merged to `main` and
> verified headless**, but the visual/on-device validation has **not** been done —
> that is the main job next time. Then move on to the foreground city tileset.

## TL;DR state

- **`main` is green:** `--import` clean · **GUT 151/151** · headless boot of
  `main.tscn` exit 0, no errors. (Godot 4.6.1.)
- **3 PRs merged today:** [#15 art](https://github.com/adbarc92/wolf-zero/pull/15) ·
  [#16 audio](https://github.com/adbarc92/wolf-zero/pull/16) ·
  [#17 environment](https://github.com/adbarc92/wolf-zero/pull/17). No open PRs.
- Merged feature branches can be deleted (local + remote): `feat/mattz-art-samurai`,
  `feat/audio-cc0-sfx`, `feat/environment-central-city`.

## What shipped (see commits/PRs for detail — not repeated here)

- **Characters** → Mattz Art samurai. player 96×96 / enemy (Samurai #2) 96×64 /
  **boss** (Demon Samurai) 128×108, distinct boss sheet. Missing clips aliased.
  Key files: [character_frames.gd](../../scripts/render/character_frames.gd),
  [animation_system.gd](../../scripts/ecs/systems/animation_system.gd) (feet-anchor +
  nearest filter), boss wiring in [main.gd](../../scripts/main/main.gd).
- **Audio** → all 10 SFX keys ship real files (8 Kenney CC0 + 4 TomMusic sword;
  slash/hit/parry/block are sword). Mapping + licenses:
  [assets/audio/sfx/CREDITS.md](../../assets/audio/sfx/CREDITS.md). Manager unchanged
  ([audio_manager.gd](../../scripts/audio/audio_manager.gd) is asset-driven).
- **Environment** → Anokolisa "Central City" parallax: sky + 2 fog bands in
  [scene_backdrop.gd](../../scripts/render/scene_backdrop.gd). Map/license:
  [assets/environment/MANIFEST.md](../../assets/environment/MANIFEST.md).

## ⚠️ PRIORITY NEXT TIME: visual / on-device validation

Headless verified *structure* (loads, boots, tiles, clips exist) but **not look**.
Launch the game and eyeball these — each has a concrete knob to turn:

1. **Character feet alignment.** Confirm player/enemy/boss feet sit on the floor (no
   sinking/floating) across idle/run/jump/attack, and the sprite scale reads right at
   phone size. Knob: `FLOOR_ANCHOR` + `offset.y = FLOOR_ANCHOR - fh/2` in
   `animation_system.gd::_ensure_anim_node`. Boss has `node.scale` 1.8–2.3 on top.
2. **Environment fog placement.** The `SceneBackdrop.LAYERS` `scale`/`offset` values are
   a **first pass set without a viewport**. Check: sky covers the 1920×1080 frame, the
   two fog bands sit low and read as depth (not floating mid-screen), parallax speeds
   feel right. Knobs: the `scale`/`offset`/`scroll` per layer.
3. **Audio in-game.** Actually *hear* the 10 keys fire on the right events; confirm the
   sword slash/hit/parry/block land and volume is balanced (`sfx_db = -6.0`,
   music bed `-16.0`). Verify OGG plays on an Android build.

Use the **`run`** skill to launch the app, or build a debug APK for device
(`docs/EXPORT.md`). There's no automated visual harness — this is manual.

## Next steps (after validation), roughly in priority order

- **Foreground Central City tileset → real level geometry.** The big one. The pack's
  `Buildings`/`Props`/`Tiles` (`assets/Sidescroller Shooter - Central City/.../Assets/`)
  are a tileset, currently unused. Building actual platforms/level art from them is a
  separate lane (likely TileMap work in the level/scene system).
- **Distant-building parallax layer.** Backdrop is sky+fog only; compose a far-skyline
  silhouette from the building/prop tiles (or source another pack) for more depth.
- **Samurai neon recolor** (commission) — swap BASE files under `assets/samurai/*`,
  the `CharacterFrames` alias rows stay.
- **Real `fall`/`roll`/`slide`/`crouch` anims** — replace the current aliases in
  `character_frames.gd` when commissioned.
- **Neo-Edo identity overlay** (torii / lanterns / kanji neon) — the highest-leverage
  identity investment; layers on top of the generic-cyberpunk base.
- **Music** is still the procedural bed (`SfxGenerator.music()`) — out of scope so far.

## Notes / gotchas for the next agent

- **Godot binary:** `C:\Godot\Godot_v4.6.1-stable_win64_console.exe` (not on PATH).
  - Import: `--headless --path . --import`
  - Tests: `--headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`
  - Boot: `--headless --path . res://scenes/main/main.tscn --quit-after 150`
- **Vendored art is tracked but heavy.** `assets/MattzArt/` (extracted, zips gitignored)
  and `assets/Sidescroller Shooter - Central City/` are in the repo. The TomMusic pack
  (`assets/Free Fantasy SFX Pack By TomMusic/`, ~372 MB) is **gitignored** — only the 4
  used oggs are committed under `assets/audio/sfx/`. ⚠️ The TomMusic gitignore rule lives
  in `main`'s `.gitignore` now (merged via #16) — but if you branch and `git add -A`,
  double-check you're not staging that 372 MB pack.
- **Pixel-art filter:** project default is Linear; character + backdrop sprites set
  `TEXTURE_FILTER_NEAREST` in code. If you add new on-screen sprites, set it too (or set
  a project-wide `rendering/textures/canvas_textures/default_texture_filter = Nearest`).
- The original swarm plan that scoped this work:
  [docs/SWARM-HANDOFF-art-integration.md](../SWARM-HANDOFF-art-integration.md).
- **Aseprite files** (`*.aseprite`) and `*.png~` backups are committed inside the Central
  City pack — harmless clutter; prune if you care about repo size.

## Suggested skills

- **`run`** — launch the game to do the visual/audio validation above (primary task).
- **`brainstorming`** — before starting the foreground tileset / level-geometry lane
  (it's a real feature with design choices).
- **`swarm-handoff`** — the remaining next-steps (tileset, distant layer, neon recolor,
  identity overlay) are largely independent and could be decomposed/parallelised.
- **`diagnose`** / **`systematic-debugging`** — if the visual pass surfaces a bug.
- **`superpowers:verification-before-completion`** — before claiming any visual fix done.
