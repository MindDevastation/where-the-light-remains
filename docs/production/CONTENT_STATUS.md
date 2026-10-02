# Content Status

## Current phase

**Implementation preflight / initial implementation.**

## Ready

- [x] Title: Where the Light Remains
- [x] Narrative baseline and Stage 0–15 flow
- [x] Puzzle/fail/recovery baseline
- [x] Final text/tone baseline in master
- [x] Art Bible / Asset Manifest / required asset table
- [x] Technical architecture + performance budget
- [x] QA baseline
- [x] Selected environment/wing/finale concept art uploaded
- [x] Character/memory reference sheets uploaded
- [x] Egg memory references uploaded
- [x] Curated music package uploaded and grouped
- [x] Music runtime policy and stage mapping
- [x] Production asset folders normalized under `assets/`
- [x] Repository-level asset index created
- [x] Initial Godot project/core service scaffold allowed and started

## Open production inputs

- [ ] Final ambience package
- [ ] Final SFX package and processing pass
- [ ] Exact per-track/source provenance confirmation where not known
- [ ] Runtime OGG/stem/loop exports and loudness pass
- [ ] Final avatar/model production source
- [ ] Remaining personal secret content beyond approved slots
- [ ] Final third-party credits/attribution list
- [ ] Optional credits vocal-song decision
- [ ] Exact minimum CPU/RAM validation machine

## Implementation status

Implementation is **GO for preflight and vertical-slice work**. Do not treat concept art as gameplay authority; use the canonical design splits/master. First technical milestone remains Hub → Wing I → fragment → save/load → return, then profile on GTX 1060-class hardware.

## Visual rebaseline v2 — 2026-10-02 UTC / 2026-10-03 Moscow

**PARTIAL.** Owner-approved visual direction: Hybrid Warcraft Observatory;
mechanics/narrative/accessibility/performance authority unchanged. Pack `cabe792`
contains 45 named v2 slots + two zone A/B/C sets. All 167 incoming PNGs and all
62 legacy PNGs inspected; exact mappings/hash inventory retained in
`VISUAL_REBASELINE_V2.md` and its JSON. Legacy references are explicitly superseded.

Existing audit covered six shared materials and one technical .blend/GLB cube
family: KEEP 6, REMATERIAL 1. The bounded foundation migration is validated:
wood aged response, six additional shared resources, 12 resources / 20 original
1K maps in total, updated modular visual references and isolated lighting review.
Blender/GLB regression, editor import, startup/contracts, deterministic maps and
four real X11/Vulkan/Forward+ graphical reviews PASS. Evidence:
`evidence/visual_rebaseline_v2/README.md` and `MATERIAL_PREFLIGHT.md`.

Worlds/puzzles/characters/shipping UI are unimplemented, not assets to rebuild.
No production scene/light/UI or gameplay/save contract was replaced. This cannot
certify the full visual game or GTX1060 performance. Missing Secrets-Achievements C and exact
assignments for six unmatched additional concepts block only dependent work.
Final avatar/casting, gameplay briefs and target hardware remain open inputs.
Target hardware is BLOCKER only for physical-GPU certification; the software
renderer passes the graphical capability/material gate. Next safe roadmap step:
the bounded five-module Archive sample using the updated v2 brief. Its actual
mesh/collision/art/LFS gates and representative performance gate still apply.
