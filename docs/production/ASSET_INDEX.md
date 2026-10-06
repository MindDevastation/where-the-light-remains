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
| `assets/concept_art/memories/s04_first_meeting/Gameplay-memory space/zone_environment_a/b/c.png` | 4 | current raid-memory shell | V2 visual reference; canonical noncombat mechanics unchanged |
| `assets/concept_art/memories/s04_first_meeting/` old nonsuffixed images | 4 | historical pair/rune framing | LEGACY supporting only; no final casting |
| `assets/concept_art/memories/s06_egg/egg_theft_v01.png` | 6 | updated theft action mood | Current single supporting reference; canon controls staging/mechanics |
| `assets/concept_art/memories/s06_egg/egg_theft_v02.png` | 6 | old alternate theft framing | SUPERSEDED / LEGACY; current v01 supplies broad mood |
| `assets/concept_art/memories/s06_egg/egg_rescue.png` | 6 | updated ledge/rescue action mood | Current single supporting reference; no character/rig acceptance |
| `assets/concept_art/memories/s06_egg/zone_environment_a/b/c.png` | 6 | current Egg-memory shell | V2 visual reference; canonical stealth/chase/rescue mechanics unchanged |
| `assets/concept_art/memories/s09_future/pair_keyframe.png` | 9 | palette/costume support only | Updated reference; seated couple pose NONCANONICAL narrative staging |
| `assets/concept_art/memories/s09_future/` old key/gameplay art | 9 | historical future framing | LEGACY supporting; no new environment triplet or approved mutual outcome |
| `assets/concept_art/characters/char_a.png` | 4/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_b.png` | 4/6/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_c.png` | 4/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_d.png` | 4/6/9 | character reference option | REFERENCE |
| `assets/concept_art/characters/char_e.png`, `char_f.png`, `char_g.png`, `char_j.png` | unresolved | new character reference options | REFERENCE candidates; exact casting/rig requires owner input |
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

## Modular Archive sample — 2026-10-03

Five original modules are available as validated sample assets. Shared editable
source: `assets/3d/blender/archive_kit/archive_kit_sample.blend`. Runtime exports
are under `game/art/meshes/archive_kit/`; script-free wrappers under
`game/worlds/archive/modules/`. That original sample did not add world instances;
current gameplay placement is recorded below.

| Inventory | GLB | Wrapper | Coverage |
|---|---|---|---|
| ARCH-004 | `sm_archive_wall_2m.glb`, `sm_archive_wall_4m.glb` | `archive_wall_2m.tscn`, `archive_wall_4m.tscn` | Two sample widths; full wall family PARTIAL |
| ARCH-005 | `sm_archive_arch_4m.glb` | `archive_arch_4m.tscn` | One arch variant; PARTIAL |
| ARCH-006 | `sm_archive_floor_1m.glb` | `archive_floor_1m.tscn` | One floor variant; PARTIAL |
| ARCH-009 | `sm_archive_pier_4m.glb` | `archive_pier_4m.tscn` | One pier variant; PARTIAL |

Original project geometry; existing `m_observatory_stone.tres` and
`m_aged_brass.tres` reused without unique maps/material copies. Actual source,
GLB/import, dimensions/anchors, UVs, collision, three-view Forward+ review and
independent authenticated LFS upload/retrieval PASS. Primary: 63 instances,
4,284 triangles, 68 surfaces. The dimensioned drawing remains a design artifact;
real sample/evidence are separate. Full inventory, representative gameplay and
target performance remain open. See `MODULAR_ARCHIVE_KIT.md` and
`evidence/modular_archive_kit/README.md`.

## V2 material migration — current runtime resources

The existing wood resource and its roughness map are rematerialized; five
compatible originals and the export fixture are kept. Shared library now has
12 resources and 20 maps. Six additions are owner-approved visual families,
not a change to the 185-row master inventory or global performance budget.

| Inventory / owner scope | Runtime resource | Status |
|---|---|---|
| Owner v2 dark iron | `game/art/materials/m_dark_iron.tres` | Shared foundation; bounded Wing I hardware integration PASS; full prop family pending |
| Owner v2 aged leather | `game/art/materials/m_aged_leather.tres` | Shared foundation; book/seating integration pending |
| MAT-010 / owner crimson | `game/art/materials/m_crimson_textile.tres` | Shared weave/tint; original glyph/decor integration pending |
| Owner v2 deep navy | `game/art/materials/m_navy_textile.tres` | Same maps as crimson; no unique prop set |
| MAT-006 | `game/art/materials/m_clear_glass.tres` | Clear substrate; real overlapping optics/Low tiers pending |
| MAT-015 | `game/art/materials/m_resonance_teal.tres` | Emission family variant; pulse/feedback gameplay pending |

No production `.blend`/GLB, hero/world scene or shipping UI screen was created or
replaced by this migration. The technical cube remains validation-only. Actual
validation and limitations: `VISUAL_REBASELINE_V2.md` / `MATERIAL_PREFLIGHT.md`.
The modular brief now points to all three current kit/shape/hub views; technical
interfaces and sample ceilings remain unchanged.

## Wing I optical carrier — 2026-10-03

| Inventory | Source / runtime | Coverage |
|---|---|---|
| S02-001 | `assets/3d/blender/wing01/wing01_optics_sample.blend`; `game/art/meshes/wing01/sm_wing01_ring_outer.glb`, `sm_wing01_ring_middle.glb`, `sm_wing01_ring_inner.glb`, `sm_wing01_frame.glb` | Three original concentric rings and fixed mount; mechanical sample PASS; functional optical mechanism PARTIAL |
| S02-003 | Same source; `game/art/meshes/wing01/sm_wing01_focus.glb` | Five-stop wheel geometry/joint/raised markers PASS; focal distances and shipping controller pending |

Script-free reusable carrier:
`game/gameplay/puzzles/wing01/wing01_optics_sample.tscn`. Four independent +Z
pivots, moving grip Areas and authored primitive blocking collision; no solver,
fragment reward, shipping input or save state. Stone/brass/walnut/iron reuse the
exact existing resources. No new textures or imported animations. Nine pinned
v2 Heat-Light/S02 room A/B/C references inform shape/material context; the canon
still requires rings → emitter/star → five-position focus → Hearth.

Actual source/export/import/physics, three-view Forward+ review and independent
LFS upload/retrieval PASS: `WING01_OPTICS_SAMPLE.md` and
`evidence/wing01_optics/README.md`. S02-002/004/005/006/007, full room/gameplay and
physical target-GPU profiling remain open. This is not complete S02 inventory.

## Current Archive gameplay usage — 2026-10-05

Accepted wall/arch/pier/floor modules populate the Wing I corridor and room
side/back/floor. Two original authored 3 m front modules now close both front
spans while higher safety guards remain. Actual LFS retrieval, 171 targeted
assertions and eight inspected front views pass (`front-wall-acceptance-1`).

The optical carrier remains connected to real E controls, rings/focus, ordered
Star/Hearth, atomic save retry, quiet resume and grounded Hub return. Gameplay
foundation is accepted; S02-001/003 full art coverage remains PARTIAL.

| Requirement | New source/runtime asset | Accepted scope |
|---|---|---|
| S02-002 | `wing01_hearth_emitter.blend` / `sm_wing01_emitter.glb` | Static brass/iron/glass emitter housing; final beam/Star VFX pending |
| S02-004 | Same editable source / `sm_wing01_hearth.glb` | Hollow brass bowl/stone pedestal plus bounded three-tongue Flame; full art acceptance pending |

Both script-free wrappers preserve mechanics, original colliders and shared
materials. Three LFS payloads were uploaded and independently retrieved into an
initially empty store; exact hashes/sizes and reopened retrieved source pass.
145 targeted assertions, normal startup and ten inspected Low/Medium captures
pass. See `WING01_HEARTH_EMITTER.md` and `hearth-emitter-acceptance-1`.

Canonical ceiling/ribs, remaining inventory/VFX, full ARCH/VS1, authored audio
and target GPU remain open. Current follow-up: `ROOM_ART_NEXT_BLOCK.md`.
The old API/LFS transport blocker is superseded by actual successful transfers.

## Hearth Flame presentation update — 2026-10-06

`game/art/vfx/hearth_flame.tscn` uses one reproducible Godot-native ArrayMesh
resource, three tongues/240 triangles and existing shared emissive gold. Geometry
is regenerated by `tools/create_hearth_flame_mesh.gd`, not created on scene entry.
Visibility/control/puzzle collision remain in the existing world. 161 targeted
assertions and ten inspected Low/Medium captures pass without warnings.
`WING01_HEARTH_FLAME.md` and `hearth-flame-acceptance-1` seal bounded proof.
Ceiling/ribs and final beam/Star, full art/VS1/audio/hardware remain open.
New LFS writes currently require credential restoration; existing downloads and
code/evidence connector checkpoints work after workspace maintenance.


## Isolated ceiling construction sample — 2026-10-06

| Requirement | Original source/runtime | Accepted scope |
|---|---|---|
| ARCH-007 variants | `wing01_ceiling_sample.blend`; `sm_wing01_ceiling_rib_10m.glb` / `sm_wing01_ceiling_rib_12m.glb` | Two fixed spans, 2568 triangles each; script-free wrappers and connection anchors |
| Supporting upper transition | Same source; `sm_wing01_ceiling_transition.glb` | 1688 triangles; wall-top supports/panels, rectangle-to-ellipse corner infill, spring belt and shared collar |

Bounded technical sample PASS: 6824 triangles / nine shared Stone/Iron/Brass
surfaces, actual four-object LFS upload and independent empty-store retrieval,
retrieved Blender reopen/cache-free import/50 capsule/anchor/state assertions,
startup and eight inspected Low/Medium captures. The first native rim defect is
retained; corrected source separates coplanar iron/stone underside planes.
See `WING01_CEILING_ACCEPTANCE.md` and `ceiling-acceptance-1`. Shipping room and
all 347 previous game source IDs are unchanged. Curved dome infill/sky, remaining
ribs/gallery, full ARCH-007 integration/world art/VS1 and target GPU remain open.
