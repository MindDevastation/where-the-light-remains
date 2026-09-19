# Audio Reaudit — 2026-09-19

Scope: 43 current WAV files = 26 previously curated + 17 newly added tracks.

Method: technical signal analysis (duration, RMS/dynamic range, spectral centroid, percussive ratio, sparseness, loop compatibility) plus CLAP semantic audio embedding against Groups A–E and Stage 0–15 descriptions. This is a production-screening pass; final approval still requires in-engine listening with SFX/text timing.

No exact binary duplicates were found among the 43 current files.

## New 17 — verdict

| Track | Verdict | Recommended role | Key evidence |
|---|---|---|---|
| Sparse Awakening vol.2.wav | KEEP | Stage 0 primary opening cue / possible awakening transition | Highest Stage 0 score (0.5768); also strongest Stage 1 candidate among current set (0.4636); sparse 0.385 |
| Sparse Awakening.wav | RESERVE | Quieter Stage 0 alternate / first seconds before spark | Quieter and sparser than vol.2 (RMS -25.31 dBFS, sparse 0.448), but weaker semantic Stage 0 fit (0.4782) |
| Remembered Stone Room.wav | KEEP | Stage 4 First Meeting primary | Group C 0.6644; Stage 4 0.6651; loop 0.875; clearly stronger than old 048_Horizon Veil (Stage 4 0.5151) |
| Buant Motion.wav | KEEP | Stage 5 Laughter / Lightness primary | Group D 0.6894 vs old Wooden Hall Puzzle v2 0.5830; loop 0.891; brighter/more active |
| Curious Sneaking Groove.wav | KEEP | Stage 6a Egg stealth | Group D 0.6527; percussive ratio 0.271; loop 0.870; unique mischievous rhythmic role |
| The Great Dodging Dash.wav | KEEP | Stage 6b Egg chase | Best current Stage 6b candidate (0.3976); 152 BPM; high percussion 0.314; loop 0.969; uniquely action-capable |
| Controlled Tails.wav | KEEP | Stage 7 active/reflective puzzle state | Group D 0.7022; Stage 7 0.5504; loop 0.855; can pair with quieter old Quiet Corridor in Dusk for solved state |
| Unresolved Breath.wav | KEEP | Stage 9 ending / Stage 13→14 transition | Group E 0.5843; Stage 9 0.5841; sparse 0.422; low percussion 0.103; Stage 14 0.3515 |
| Silent Piano.wav | KEEP | Stage 14 confession bed | Best new dedicated near-silence cue; Stage 14 0.3532; sparse 0.424; dynamic range 15.69 dB; low percussion 0.116 |
| Pre-dawn Hush.wav | KEEP | Stage 15 pre-dawn opening / optional Stage 13 transition reserve | Stage 15 0.6228; sparse 0.435; dynamic range 16.18 dB; low percussion 0.107 |
| Quiet Hope.wav | KEEP | Stage 15 dawn emotional middle / late-game quiet layer | Stage 15 0.6380; sparse 0.442; very low percussion 0.081; dynamic range 14.72 dB |
| Starlit Motif.wav | KEEP | Stage 15 resolved motif / optional late Archive reprise | Stage 15 0.6386; loop 0.938; strongest melodic/loopable new late-game candidate |
| Glass and Wind.wav | RESERVE | Stage 15 final ambient tail / post-wide-shot atmosphere | Group A 0.5426; sparse 0.420; low percussion 0.112; weaker loop 0.604 but loop is not required for a tail cue |
| Observatory Dawn.wav | RESERVE | Stage 15 alternate one-shot | Appropriate broad E/A profile, but Stage 15 0.4645 and loop 0.638 are weaker than Pre-dawn Hush / Quiet Hope / Starlit Motif |
| Stone Chamber Echoes.wav | RESERVE | Stage 9 fantasy-half alternate / transition bed | Very high Stage 9 score 0.6374, but low dynamic range 6.29 dB and weaker loop 0.633; function overlaps Quiet Exploration + Unresolved Breath |
| Archive Fragment.wav | REMOVE | No unique production role | Group C/E ambiguity, loop 0.645, moderate density; redundant against stronger Archive, memory and future cues |
| Resonant Puzzle.wav | REMOVE | No unique production role | Percussive 0.267 and only Stage 11 0.4666; existing Stage 11 pool and Stage 3 pool are both stronger |

## Recommended replacements in the previously curated 26

- Replace `048_Horizon Veil.wav` at Stage 4 with `Remembered Stone Room.wav`.
- Replace `Wooden Hall Puzzle v2.wav` at Stage 5 with `Buant Motion.wav`.
- Demote/remove `Resonant Silence.wav` from Stage 3: Stage 3 semantic score is only 0.1707 and percussive ratio 0.355. Prefer `029_Cold Arterial Glow.wav` (Stage 3 0.3751, loop 0.938) and `024_Silent Roads Beneath the Frost.wav` (Stage 3 0.3774, sparse 0.478).
- Keep `Quiet Corridor in Dusk.wav` only as the quieter solved/reflection state for Stage 7 if `Controlled Tails.wav` is used during active puzzle play.
- `Final Quiet of the Archive.wav` is no longer required as the main Stage 13–14 solution once `Unresolved Breath.wav` and `Silent Piano.wav` are accepted.
- The five old Stage 15 placeholder candidates (`018_April Snow Drift`, `070_Moss Thaw`, `076_Rain on Moss`, `082_Felt Moonlight in C`, `099_Thawing Window`) can be retired after in-engine confirmation of the new bespoke dawn sequence. `Hub Motif.wav` remains the thematic anchor and should not be removed.
- `084_Snowfield in D Minor.wav` becomes optional once Stage 9 uses `Quiet Exploration.wav` + `Unresolved Breath.wav`.

## Recommended stage map after reaudit

| Stage | Primary music |
|---|---|
| 0 | `Sparse Awakening vol.2.wav` (v1 reserve for an even quieter opening) |
| 1 | `Archive Awakening.wav` → `Hub Motif.wav` |
| 2 | `Cold to Warm.wav` |
| 3 | `029_Cold Arterial Glow.wav` + `024_Silent Roads Beneath the Frost.wav` |
| 4 | `Remembered Stone Room.wav` |
| 5 | `Buant Motion.wav` |
| 6a | `Curious Sneaking Groove.wav` |
| 6b | `The Great Dodging Dash.wav` |
| 7 | `Controlled Tails.wav` → optional `Quiet Corridor in Dusk.wav` solved state |
| 8 | `Candlelight Over Ledger Pages.wav` |
| 9 | `Quiet Exploration.wav` → `Unresolved Breath.wav` |
| 10 | `The Light Path.wav` |
| 11 | `Resonant Assembly.wav` + `Mechanism Light.wav`; `Activation Sequence.wav` reserve |
| 12 | `Quiet Pages, Steady Light.wav` |
| 13 | `Unresolved Breath.wav` / silence-controlled transition |
| 14 | `Silent Piano.wav`, forcibly faded/stopped for the canonical 4–6 s silence after the confession |
| 15 | `Pre-dawn Hush.wav` → `Quiet Hope.wav` → `Starlit Motif.wav`; `Glass and Wind.wav` optional final ambience |

## Result

The new batch closes all previously identified functional gaps. No additional generic ambient tracks are required. The only remaining music task is in-engine sequencing, trimming/loop-point editing, loudness normalization and confirmation that the Stage 15 material actually carries or references the `Hub Motif` melodic DNA.
