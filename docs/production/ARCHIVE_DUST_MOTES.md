# VFX-006 bounded brief — 2026-10-07

Status: **IMPLEMENTATION BRIEF**, pending current technical/native acceptance.
This independent mandatory family does not depend on the ARCH-011 decision.
No stair/canonical layout change or future stage production is included.

## Selection / authority

Current inventory marks VFX-006 MISSING: one low-cost quality-scalable dust/soft
atmosphere system, stages0–15. Native beam/Star/Hearth/spark are separate accepted
effects. ARCH-011 is owner-dependent; ARCH-013 has no assigned recess placement
or reveal contract, so cutting accepted walls would invent layout. ARCH-017
requires a new DCC/LFS family; this session has connected GitHub text/binary Git
publication but no private CLI LFS upload credential. Do not create an unuploaded
family or silently put GLBs in ordinary Git. Missing architecture remains open.
VFX-006 can be authored as native editable Godot scene/script/shader and used
without new DCC geometry, LFS payloads, narrative, mechanics or global budgets.

Canonical references: REQUIRED_ASSET_TABLE VFX-006, TECHNICAL_BASELINE Low/effects
and pause, NARRATIVE_CANON S00–S02, QA_CHECKLIST readability and audio independence.
Visual references: VISUAL_REBASELINE_V2 current S01 ca004 gameplay A/B/C, S02
wi002 gameplay A/B/C and v2 lighting guide. Warm/cool lived-in archive remains
the surrounding target; dust is a restrained secondary effect, not emissive
route clues, magical spark or evidence of full style acceptance.

## Contract before production

- One reusable native `archive_dust_motes.tscn`, shader and wrapper. Billboard
  quads with authored radial feathering, no bitmap/3D source asset needed.
- Two actual current volumes, unit pivot/+Y/metric coordinates: Hub centered
  `(3,2,0)`, S02 centered `(1.8,2,−22)`, each box half extents `(2,1,2)`.
  No S00 placement. Clouds stay inside existing rooms and do not alter targets,
  collision, room topology, channel/beam clocks or lighting.
- Neutral pale warm dust, low alpha; no glow/emission/light/shadow, no icons,
  glyphs, streaks, interaction, audio or save fields. Particle footprint .025 m;
  slow drift <=.04 m/s with fade-in/out. Bounded lifetime/drift included in AABB.
- Per-volume counts Low12 / Medium36 / High48 (two volumes at most96 particles,
  two billboard triangles each). Existing `effects=false` hides/stops decoration.
  Low retains routes/puzzle clues regardless of particle reduction/removal.
- Presentation clock pauses with the scene tree, including focus pause; no
  tween/timer/autoload added. Reuse settings_changed subscription with automatic
  disconnect on free; quality resources local to each instance.
- Visibility follows current world `stage_id`: disabled in S00, enabled in
  S01/S02. An ordinary local update observes quiet stage projection too; it
  does not emit a stage event or mutate progression to display dust.
- Required acceptance: actual Godot import/startup, resource/quality/visibility/
  pause/lifetime checks, both instance bounds, all changed-area progression,
  protected primary/backup and exact prior art identities. Native Forward+ Low
  and Medium paired on/off views (S00, Hub asleep/awake, S02 cold/warm), individually
  inspected, with GPU readback evidence of nonempty particles. Software timing
  does not accept physical target GPU. Future-stage reuse and full style remain
  PARTIAL; no full VFX/global art/GATE-VS1 closure from one local family.
