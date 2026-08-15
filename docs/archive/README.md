# Archived documents

These are **superseded**. They are kept for history only. Nothing here
describes the game that is being built — do not use them to answer questions
about the design, the architecture, or what the game is.

For current information:

| You want | Read |
|---|---|
| Where the project stands | [`docs/STATUS.md`](../STATUS.md) |
| How the code is actually structured | [`docs/CODEBASE-DIGEST.md`](../CODEBASE-DIGEST.md) |
| The game design | [`docs/CoreDesign.md`](../CoreDesign.md) |
| The requirements | [`docs/Requirements.md`](../Requirements.md) |

---

## Why these were archived (2026-08-15)

Both files are **raw, unedited chat transcripts** — `Architecture.md` still
opens with "Here it!" and closes with "Let me know!" — and both describe a
**different game** than the one that was built.

They come from an early exploration of a *history-hacking, multi-era, two-player
co-op* concept: Victorian London, Renaissance Venice, a Leonardo da Vinci mech
boss, Cleopatra with scarab bots, a Crowd Riot system, Cybernetic Companions, a
shared Energy Core, and Faction roles.

Wolf Zero pivoted to **single-era Neo Edo**, built around the Holographic Echo
and a defensive combat conceit. None of the entities, components, or systems
listed in `Architecture.md` — `Augmentation`, `EnergyCore`, `Faction`, `Owner`,
`HackState`, `CrowdBehavior`, `DynamicState`, `History Hacking System`,
`Crowd System`, `Time Trial System`, `Companion System` — exist anywhere in the
codebase, and its component list contradicts `CoreDesign.md` §7.

`Architecture.md` was the more dangerous of the two: its filename implied it was
the technical source of truth, so anyone told to "read the architecture doc" was
sent somewhere very wrong. The real architecture lives in
[`docs/CODEBASE-DIGEST.md`](../CODEBASE-DIGEST.md).

`Features.md` additionally contains its entire content **twice, verbatim**.
