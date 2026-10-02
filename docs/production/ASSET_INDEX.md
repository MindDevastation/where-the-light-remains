# Production Asset Index

Status: **implementation mapping for selected repository assets**.

Rule: current visual authority is explicitly enumerated in `VISUAL_REBASELINE_V2.md` / `visual_rebaseline_v2.json`. Folder-wide labels below are historical stage/role mappings, not approval of legacy images or additional candidates. Concept art never overrides canonical mechanics/narrative.

## Visual rebaseline v2 — current authority

Incoming pack `cabe792`: 45 named v2 slots (134 images) + two zone A/B/C sets.
Complete old→new runtime/requirements mapping and limitations: [VISUAL_REBASELINE_V2.md](VISUAL_REBASELINE_V2.md).
All 167 incoming images and 62 old images inspected; old payloads retained as
SUPERSEDED / LEGACY. Additional review: 0 promoted, 3 supporting exact duplicates,
6 UNMATCHED; [ADDITIONAL_CONCEPTS_REVIEW.md](ADDITIONAL_CONCEPTS_REVIEW.md).
Secrets-Achievements angle C is missing; pause only dependent acceptance.
New/changed character sheets are candidates, not final casting/rig acceptance.
S09 pair pose remains noncanonical narrative staging.

## Concept art — environments (stage mapping; use explicit v2 images)

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

Explicit v2 files under `assets/concept_art/hero_props/**` are visual modeling/shape references for the related central mechanism, five wing mechanisms, Egg, sigils, Future Record, modular kit and final table. Exact mechanics remain defined by `NARRATIVE_CANON.md` / master Level & Puzzle Design.

Explicit v2 files under `assets/concept_art/ui/**` are style/layout references only; old nonsuffixed files are LEGACY. Runtime UI must keep Cyrillic readability, accessibility, no-response final semantics and the master Text Package copy.

Explicit v2 sets under `assets/concept_art/production_sheets/**` are global visual references; nonsuffixed sheets are LEGACY references for material language, architectural shapes and lighting consistency.

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

## Shared material baseline — 2026-10-02

Authored runtime baseline v1, feature `feature/03-art-foundation/material-library`.
Provenance, import settings, reuse contract and limitations: [MATERIAL_LIBRARY.md](MATERIAL_LIBRARY.md).
Original generated maps are tracked with their source and SHA-256 manifest;
the production sheet is a visual reference, not a texture source.

| Inventory | Runtime resource | Status |
|---|---|---|
| MAT-004 | `game/art/materials/m_observatory_stone.tres` | Shared base; further stone variation pending |
| MAT-001 | `game/art/materials/m_aged_brass.tres` | Shared aged brass base |
| MAT-003 | `game/art/materials/m_dark_walnut.tres` | One shared tileable wood set |
| MAT-007 | `game/art/materials/m_memory_glass.tres` | Frosted substrate; text/imprint integration pending |
| MAT-008 | `game/art/materials/m_crystal_glass.tres` | Built-in fake refraction; quality tiers pending |
| MAT-014 | `game/art/materials/m_archive_emissive_gold.tres` | Emission base; gameplay feedback integration pending |

All six are available for sample asset integration. Representative scene and
target-hardware acceptance remain open; these statuses do not promote the full
MAT inventory to final shipping acceptance.

## Modular sample design contract — 2026-10-02

`MODULAR_ARCHIVE_KIT.md` and `modular_archive_kit_v1.json` define the next bounded
sample: ARCH-004 walls (2/4 m), ARCH-005 arch, ARCH-006 floor and ARCH-009 pier.
They identify the canonical image blobs, planned source/runtime paths, shared
materials, snapping/collision rules and pending acceptance gates. The dimensioned
drawing is a design artifact. These planned meshes are not yet runtime assets;
the four ARCH inventory rows remain unaccepted.
