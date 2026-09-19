# Music Library Index

Status: **curated runtime structure applied after the 2026-09-19 repeat audit**.

Core rule: each music group owns one shared pool used by every stage in that group, and every stage has a dedicated unique cue. Scripted scenes may temporarily lock out shuffle playback while remaining members of their group.

## Group ownership
- **A — Archive / Observatory:** Stages 0, 1, 10, 11
- **B — Warmth / Voice:** Stages 2, 3
- **C — Raid Memories:** Stages 4, 6
- **D — Lightness / Contrast:** Stages 5, 7
- **E — Sincerity / Future / Finale:** Stages 8, 9, 12, 13, 14, 15

## A — Archive / Observatory
Shared pool: `Hub Motif`, `Mechanism Light`, `Activation Sequence`, `Archive Fragment`, `Resonant Puzzle`.

Unique cues:
- S00: `Sparse Awakening vol.2` (supplemental: `Sparse Awakening`)
- S01: `Archive Awakening`
- S10: `The Light Path`
- S11: `Resonant Assembly`

`Archive Fragment` and `Resonant Puzzle` are intentionally retained and integrated into the A shared pool despite their lower repeat-audit ranking, per project direction.

## B — Warmth / Voice
Shared pool: `024_Silent Roads Beneath the Frost`, `034_Muted Pulse Under Falling White`, `080_Quiet Exhale Through Evergreens`.

Unique cues:
- S02: `Cold to Warm`
- S03: `029_Cold Arterial Glow`

## C — Raid Memories
Shared pool: `048_Horizon Veil`.

Unique cues:
- S04: `Remembered Stone Room`
- S06: `Curious Sneaking Groove` (stealth) + `The Great Dodging Dash` (chase). Stage 6 is the intentional two-cue exception.

## D — Lightness / Contrast
Shared pool: `Wooden Hall Puzzle v2`, `Quiet Corridor in Dusk`.

Unique cues:
- S05: `Buant Motion`
- S07: `Controlled Tails`

## E — Sincerity / Future / Finale
Shared pool: `Quiet Exploration`, `Stone Chamber Echoes`, `Glass and Wind`, `Observatory Dawn`.

Unique cues:
- S08: `Candlelight Over Ledger Pages`
- S09: `Unresolved Breath`
- S12: `Quiet Pages, Steady Light`
- S13: `Final Quiet of the Archive`
- S14: `Silent Piano`
- S15: `Starlit Motif` (supplemental scripted chain: `Pre-dawn Hush` → `Quiet Hope` → `Starlit Motif`)

## Runtime rule
Normal exploration stages play the unique cue first, then rotate through the group's shared pool via shuffle bag. No immediate repeats. Calm scenes may use 3–10 seconds of ambience-only breathing room between tracks. Typical crossfade is 4–7 seconds; active cues use 1.5–3 seconds.

Scripted exceptions:
- S06 locks music to stealth → silence/event → chase → rescue.
- S12–S15 use deterministic music during critical narrative beats; the E shared pool remains available only outside those locked moments.
- S14 forces 4–6 seconds of complete music silence after `Я люблю тебя`.

See `MUSIC_RUNTIME_POLICY.md` for the full playback contract.

## Removed after repeat audit
`012_April Snow Drift`, `Resonant Silence`, `084_Snowfield in D Minor`, `018_April Snow Drift`, `070_Moss Thaw`, `076_Rain on Moss`, `082_Felt Moonlight in C`, `099_Thawing Window`.

Removed files remain recoverable from Git history.
