# Content Status

## Current phase

**Pre-production / content preparation.**

The game design package is substantially complete, but implementation is intentionally on hold until the selected visual and music packages are uploaded.

## Ready

- [x] Game title: **Where the Light Remains**
- [x] Narrative baseline
- [x] Stage flow 0–15
- [x] Puzzle design / fail-state / recovery rules
- [x] Final text package
- [x] Tone audit
- [x] Art Bible
- [x] Audio Direction
- [x] AUDIO_PLAN
- [x] Asset Manifest
- [x] Godot technical architecture baseline
- [x] Performance budget
- [x] QA checklist
- [x] Concept-art generation prompt package

## In preparation before implementation

- [ ] Selected environment concept art
- [ ] Selected hero-prop concept art
- [ ] Selected UI concepts
- [ ] Character concept sheets based on game-model screenshots
- [ ] Memory-scene keyframes
- [ ] Final selected music tracks / stems
- [ ] Final ambience package
- [ ] Final SFX package / library selections
- [ ] Audio file naming and stage mapping
- [ ] Concept-art file naming and stage/asset-ID mapping

## External / personal inputs still open

- [ ] Remaining personal secret content
- [ ] Final avatar/model production source
- [ ] Final third-party licenses / attribution list
- [ ] Optional credits vocal song decision
- [ ] Exact minimum CPU/RAM validation machine

## Codex status

**HOLD.**

Do not add or execute Codex task instructions yet.

The intended handoff sequence is:

1. upload music;
2. upload selected concept art;
3. create `ASSET_INDEX.md` mapping every selected file to stage and asset ID;
4. review the complete package for conflicts/missing inputs;
5. then add Codex execution documents and begin repository preflight.

## Folder intake rules

### Concept art

Use `assets/concept_art/` and group files by production purpose rather than by generation session.

Recommended future structure:

```text
assets/concept_art/
├── environments/
├── hero_props/
├── ui/
├── characters/
├── memories/
└── production_sheets/
```

### Audio

Use:

```text
assets/audio/
├── music/
├── ambience/
└── sfx/
```

Raw exploratory generations should not be mixed with approved production selections. If needed, add a `_candidates/` subfolder locally and commit only selected files or explicitly versioned candidates.
