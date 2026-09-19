# Project Bible implementation index

**Master source:** Project Bible v1.8 / Performance Budget v1.0.

This repository uses split implementation documents so contributors do not need to infer canonical behavior from asset folders or concept images.

## Precedence

1. Explicit later decision marked **APPROVED OVERRIDE** in this repository.
2. Master Project Bible v1.8.
3. Repository canonical splits under `docs/design/`.
4. `PROJECT_SUMMARY.md`.
5. Concept art and generated references.

Concept art is reference material, not authority for gameplay/narrative behavior.

## Canonical splits

- Narrative / stages / final-sequence constraints → `NARRATIVE_CANON.md`
- Engine architecture / saves / scene routing / settings / performance → `TECHNICAL_BASELINE.md`
- Audio artistic and runtime constraints → `AUDIO_BASELINE.md` plus `assets/audio/music/MUSIC_RUNTIME_POLICY.md`
- Required asset inventory → `REQUIRED_ASSET_TABLE.md`
- Actual approved asset files → `docs/production/ASSET_INDEX.md`
- QA/release acceptance → `docs/production/QA_CHECKLIST.md`

## Approved override: music playlist model

The master defines music as one evolving adaptive system using stage states, stems/loops and authored silence. The approved implementation additionally groups normal exploration music into shared style pools:

`Stage = GroupSharedPool + StageUniqueCue`

This override does **not** override authored silence, event-state music, Egg sequencing, finale sequencing, ducking, or the requirement that `AudioDirector` owns global playback.
