# Production Asset Index

Status: **implementation mapping for selected repository assets**.

Rule: every file inside a package listed as `CANONICAL` inherits that package's stage/role mapping unless a row explicitly marks it secondary/noncanonical. Concept art is visual reference only and never overrides the master mechanics/narrative.

## Concept art — environments

| Repository package | Stage | Primary manifest relation | Role | Status |
|---|---:|---|---|---|
| `assets/concept_art/environments/s00_prologue/**` | 0 | ARCH-001, ARCH-002, ARCH-017, ARCH-018, CAM-002 | exterior/night composition, approach readability | CANONICAL reference |
| `assets/concept_art/environments/s01_observatory/**` | 1,10–15 | ARCH-003, PROP-001/002, ARCH-014/015 | hub architecture/gameplay layout | CANONICAL reference |
| `assets/concept_art/environments/s02_wing_light/**` | 2 | S02 package + R-ARCHIVE | mood/layout only; mechanics follow canon rings/focus/hearth | CANONICAL reference |
| `assets/concept_art/environments/s03_wing_voice/**` | 3 | S03 package + MAT-015 | mood/layout; resonance visibility | CANONICAL reference |
| `assets/concept_art/environments/s05_wing_lightness/**` | 5 | S05 package | mood/layout; mobile/counterweight language | CANONICAL reference |
| `assets/concept_art/environments/s07_wing_reflection/**` | 7 | S07 package + MAT-016 | quiet reflection mood/layout | CANONICAL reference |
| `assets/concept_art/environments/s08_wing_sincerity/**` | 8 | S08-001…009 | constellation/crystal environment | CANONICAL reference |
| `assets/concept_art/environments/s10_return/**` | 10 | S10-001…005 | restored-hub state | CANONICAL reference |
| `assets/concept_art/environments/s11_final_puzzle/**` | 11 | S11-001…005 | final-puzzle readability | CANONICAL reference |
| `assets/concept_art/environments/s12_s15_finale/**` | 12–15 | R-FINAL / S12–S15 | finale presentation/mood | CANONICAL mood reference subject to narrative canon |

## Concept art — memories / characters

| Path | Stage | Role | Status |
|---|---:|---|---|
| `assets/concept_art/memories/s04_first_meeting/**` | 4 | raid-memory space, two-character/rune framing | CANONICAL reference; no combat/romance swell |
| `assets/concept_art/memories/s06_egg/egg_theft_v01.png` | 6 | stealth/egg framing alt A | CANONICAL candidate |
| `assets/concept_art/memories/s06_egg/egg_theft_v02.png` | 6 | stealth/egg framing alt B | CANONICAL candidate |
| `assets/concept_art/memories/s06_egg/egg_rescue.png` | 6 | scripted ledge/rescue framing | CANONICAL reference |
| `assets/concept_art/memories/s09_future/**` | 9 | fantasy→real possibility framing | CANONICAL reference; no promise/mutual outcome |
| `assets/concept_art/characters/char_a.png` | 4/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_b.png` | 4/6/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_c.png` | 4/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_d.png` | 4/6/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/pair_character_mood_sheet.png` | 4/9 | pair staging/mood | REFERENCE, not reciprocity evidence |
| `assets/concept_art/_secondary/noncanonical_final_pair_scene.png` | — | retained mood artifact only | **NONCANONICAL — never use as ending outcome** |

## Concept art — hero props / UI / production sheets

All files under `assets/concept_art/hero_props/**` are approved modeling/shape references for the related central mechanism, five wing mechanisms, Egg, sigils, Future Record, modular kit and final table. Exact mechanics remain defined by `NARRATIVE_CANON.md` / master Level & Puzzle Design.

All files under `assets/concept_art/ui/**` are style/layout references only. Runtime UI must keep Cyrillic readability, accessibility, no-response final semantics and the master Text Package copy.

All files under `assets/concept_art/production_sheets/**` are global Art Bible references for material language, architectural shapes and lighting consistency.

## Music source masters

Runtime rule: source WAVs remain under `assets/audio/music/`; final Godot audio is processed/renamed/compressed into canonical runtime names.

### Group A — Archive / Observatory

Shared source masters: `Hub Motif`, `Mechanism Light`, `Activation Sequence`, `Archive Fragment`, `Resonant Puzzle`.

Unique mapping: S00 `Sparse Awakening vol.2` (+ supplemental `Sparse Awakening`, scripted-only); S01 `Archive Awakening`; S10 `The Light Path`; S11 `Resonant Assembly`.

### Group B — Warmth / Voice

Shared: `024_Silent Roads Beneath the Frost`, `034_Muted Pulse Under Falling White`, `080_Quiet Exhale Through Evergreens`.

Unique: S02 `Cold to Warm`; S03 `029_Cold Arterial Glow`.

### Group C — Raid Memories

Shared: `048_Horizon Veil`.

Unique: S04 `Remembered Stone Room`; S06 `Curious Sneaking Groove` + `The Great Dodging Dash` (state-driven exception).

### Group D — Lightness / Contrast

Shared: `Wooden Hall Puzzle v2`, `Quiet Corridor in Dusk`.

Unique: S05 `Buant Motion`; S07 `Controlled Tails`. S07 excludes `Wooden Hall Puzzle v2` during quiet reflection state.

### Group E — Sincerity / Future / Finale

Shared: `Quiet Exploration`, `Stone Chamber Echoes`, `Glass and Wind`, `Observatory Dawn`.

Unique: S08 `Candlelight Over Ledger Pages`; S09 `Unresolved Breath`; S12 `Quiet Pages, Steady Light`; S13 `Final Quiet of the Archive`; S14 `Silent Piano`; S15 `Starlit Motif` with supplemental `Pre-dawn Hush`, `Quiet Hope`.

## Runtime promotion checklist

Before any source master/reference is promoted to a shipping runtime asset:

1. confirm canonical role / stage;
2. record source/provenance/license;
3. apply runtime naming convention;
4. for audio: remove artifacts/pseudovocal, edit loop/stem boundaries, loudness/mix pass, compressed runtime export;
5. for 3D/art: validate material/texture/LOD/performance budgets;
6. update this index with the final runtime path and version.
