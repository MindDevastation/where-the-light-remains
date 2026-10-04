# Content Status

## Current phase

Fresh-session remote recovery, 2026-10-04: ArchiveMain and S01 resumed from the
verified working branch. Connected S02 now passes 57 real controls/save/return
assertions, with 101 state and 109 S01 regressions. Eight native Low/Medium views
confirm the reused optical model, cold/warm room response and complete readable
Cyrillic modals, with rendered Continue text assertions. Source/evidence are durably published
on the working branch; `main` is unchanged. Boot/S00, final room art/audio and
GATE-VS1 remain open. See `ARCHIVE_RECONSTRUCTION.md` and its current receipts.

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

## Input focus / pause foundation — 2026-10-03 UTC

**PASS for the input service.** InputManager preserves requested mode across
focus/pause, releases capture and gameplay actions at boundaries, filters held
key repeats, and discards the first recapture motion. UI cursor starts visible.
Clean committed-source import, synthetic mode matrix and actual native X11
focus/capture checks pass. InputMap, mixer, read-only inspector, Archive and
Wing I geometry/physics regressions pass. See `INPUT_FOCUS.md` and
`evidence/input_focus/README.md`.

Exactly eight autoloads/actions remain; no puzzle states, skip timing, narrative,
art payloads or global budgets changed. Pause UI, player and playable world
routing remain later features. Windows/hardware input and target GPU acceptance
are still open. The next foundation feature is the basic player and interaction
ray, using the accepted collision envelope and the input owner's gate API.

## Player / interaction foundation — 2026-10-03 UTC

**PASS for the bounded controller.** GameRoot now owns an inactive first-person
player and minimal Russian reticle/E prompt. Explicit activation enables walk/
look; the next physics tick rechecks E range, nearest blocker and target state.
Six actual Archive passages at two yaws, wall stopping, heading/diagonal speed,
look/FOV/inversion, pause/focus gates and target races pass on clean committed
source. Actual Wing I grip selection/dispatch and 1920×1080 Forward+ prompt
review pass. See `PLAYER_INTERACTION.md` and `evidence/player_interaction/`.

Existing art binaries, shared maps and solve parameters stay unchanged. Initial
movement/capsule/reach numbers are explicit technical tuning values. The empty
root does not activate player/capture; the later router supplies a real world
and spawn. This completes another shell foundation step, not a playable Hub or
Wing I solution. Next: settings persistence/UI, then pause/transition UI.

## Settings foundation — 2026-10-03 UTC

**PASS for preferences and the reusable modal.** Typed ConfigFile load/atomic
replacement, preserved corrupt files and failed writes, actual Master/Music/SFX
gains, initial quality mappings and author-preserving graphics switches pass.
Russian Apply/Cancel/defaults/Esc and typed numeric input pass; actual 1280×720 and
1920×1080 TCP X11/Forward+ forms were inspected. Clean source import, player,
input, read-only debug, mixer and engine regressions pass. See `SETTINGS.md` and
`evidence/settings/`. The hidden production modal awaits main-menu/pause entry
points; no story, puzzle, art budget or target-hardware certification changed.
Next: pause UI and a reusable fade overlay for the later scene router.

## Pause / fade foundation — 2026-10-03 UTC

**PASS for the bounded shell.** Russian pause/settings nesting physically freezes
the player and preserves audio/files, held-key/recapture and requested modes.
Later input locks and removed pause scenes do not strand simulation. Explicit
awaited fade completes/cancels while paused and blocks GUI/key input. Actual
Forward+ pause/loading views inspected; clean source and previous input/player/
settings/debug/startup paths pass. See `PAUSE_FADE.md` and `evidence/pause_fade/`.
No automatic story transition/skip timing added. Next: typed SaveGame and validated
atomic JSON/backup/recovery, then scene routing and authored playable worlds.

## Logical SaveGame DTO — 2026-10-03 UTC

**PASS for the typed v1 format and isolated GameState transfer.** Actual JSON
round trips preserve exact discrete numbers and reject invalid field/order/type/
version/resource/cycle/size data. Applying invalid state changes nothing; valid
copies share no mutable nested containers. Clean import, existing player/input/
pause/read-only inspector and TCP X11/Forward+ startup regressions pass. See
`SAVE_SYSTEM.md` and `evidence/save_dto/`. No save files, settings or puzzle
parameters are introduced. Next: atomic disk write, backup/corruption recovery
and safe-exit error handling; Boot/Continue and world-domain validation follow.

## Atomic saves / safe exit — 2026-10-03 UTC

**PASS for the bounded persistence service.** Validated temp/flush/readback/
backup/replace, read-only corruption recovery, future-schema protection and dirty
failure semantics pass against actual files. App and real X11 native close commit
before successful quit; save failure leaves a Russian retry/stay modal and intact
state. Actual Forward+ view inspected, 199 clean tracked files unchanged and prior
DTO/input/player/pause/debug/startup regressions pass. See `SAVE_SYSTEM.md` and
`evidence/atomic_save/`. Boot/Continue, explicit both-corrupt New Game UI/policy,
world checkpoints, routing and Windows/physical hardware remain later work.
Next: bounded SceneRouter preload/state/spawn/fade pipeline.

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

At the v2 audit revision, worlds/puzzles/characters/shipping UI were unimplemented.
The subsequent bounded architecture sample below adds reusable modules; full
stage worlds, puzzles, characters and shipping UI remain unimplemented.
No production scene/light/UI or gameplay/save contract was replaced. This cannot
certify the full visual game or GTX1060 performance. Missing Secrets-Achievements C and exact
assignments for six unmatched additional concepts block only dependent work.
Final avatar/casting, gameplay briefs and target hardware remain open inputs.
Target hardware is BLOCKER only for physical-GPU certification; the software
renderer passes the graphical capability/material gate. The subsequent bounded
Archive structure and the subsequent Wing I mechanical carrier below pass their
bounded sample gates. Next roadmap work is the interaction/controller brief and
representative playable slice. Exact solve parameters remain an open dependent
input; representative target performance still precedes bulk production.

## Modular Archive sample — 2026-10-03 UTC

**PASS for the bounded sample; ARCH inventory PARTIAL.** One editable Blender
source, five GLBs, five script-free Godot wrappers and two isolated fixtures:
2 m/4 m wall, pointed arch, 1 m floor, stepped pier. Actual mesh/UV/material
identity checks, 15 capsule passages, floor continuity, wall replacement, four
yaws and right-angle junction pass. Three real Forward+ views inspected; six
LFS payloads uploaded and independently retrieved with exact hashes. Retrieved
Blender/Godot/physics/startup and Git/LFS fsck pass. Evidence:
`evidence/modular_archive_kit/README.md`; source checkpoint
`1e3adf1a500c9fbf7a5ad1497588e7df1dd1015b`.

The primary pad is 4,284 triangles, 63 instances and 68 authored surfaces. This
is reusable architecture foundation, not a playable Hub or final whole-world
visual approval. GameRoot, services, controls, saves and canonical text remain
unchanged. The Wing I carrier below completes the next bounded art step;
gameplay vertical slice and representative physical-GPU profiling remain open.

## Wing I optical carrier — 2026-10-03 UTC

**PASS for the bounded sample; S02 inventory PARTIAL.** Editable Blender source,
five GLBs and a script-free Godot carrier: fixed frame, three independent
concentric rings and a five-stop focus wheel. 8,636 triangles / 16 shared surfaces;
stone/brass/walnut/iron resources reused. Source/GLB meter bounds, topology/UVs,
40 independent poses, 48 actual grip rays and primitive blocking pass. Three
real 1920×1080 Forward+ views inspected; six LFS payloads uploaded and independently
retrieved/hash-checked. Retrieved Blender/import/physics/graphical startup and
Git/LFS fsck pass. Evidence: `evidence/wing01_optics/README.md`; source checkpoint
`a3c11209d7218fe2ba08b402bac054d6d49f7cc8`.

This supplies the mechanical carriers for S02-001/S02-003. Emitter/star target,
Hearth activation, fragments, cold-to-warm room state and playable interaction /
save restoration remain unimplemented. Exact ring states/solve angles/focus
distances require canonical controller inputs; test poses assign none of them.
No shipping input/UI, GameRoot/service/save contract, shared map or global budget
changed. Next: canonical interaction/controller brief and the playable slice;
physical target-GPU profiling still gates bulk production.
