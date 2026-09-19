# Implementation plan

Status: **started**.

## Milestone 0 — preflight

- [x] Normalize asset roots under `assets/`.
- [x] Curate music and define runtime playlist policy.
- [x] Add canonical design split docs and QA baseline.
- [x] Create repository asset index.
- [x] Create initial Godot project.
- [x] Create 8-autoload core service scaffold.
- [ ] Lock exact Godot 4.x minor version after verifying the development machine/editor.
- [ ] Perform a real Git LFS history migration for large audio/3D assets before adding more heavy binaries; do not merely add LFS attributes to unmigrated blobs.
- [ ] Build valid InputMap in editor/project settings.
- [ ] Create audio bus layout: Master → Music/Main/Stems, SFX/Critical/World, Ambience, UI, VO_RESERVED.
- [ ] Add development-only debug stage/save/audio/performance tools.

## Milestone 1 — boot / shell

- [ ] Boot/Main Menu.
- [ ] SettingsManager full ConfigFile read/write.
- [ ] InputManager focus/pause/capture handling.
- [ ] Pause/Fade UI.
- [ ] Basic Player CharacterBody3D + interaction ray.

## Milestone 2 — state / saves / routing

- [ ] Typed SaveGame v1 DTO/resource.
- [ ] Atomic JSON write + backup + validation + corruption fallback.
- [ ] SceneRouter preload/fade/input-lock/apply-state pipeline.
- [ ] ArchiveMain graybox + spawn/state restoration.
- [ ] AudioDirector dual-player crossfade + group/unique playlist skeleton + silence locks.

## Milestone 3 — vertical slice

Target: `S01 Hub → S02 Wing I → Star/Hearth fragments → save/load → return`.

Acceptance:
- no navigation stall >~10–15 s in fresh tester;
- puzzle uses discrete states and visual feedback;
- fragment collection is idempotent;
- save/load restores solved state;
- music/SFX do not mask interaction feedback;
- 1080p60 profiling on target-class hardware.

## Milestone 4+

Add remaining Archive wings one by one, then Memory I, Egg memory with runtime checkpoints, Memory III, final state machine 10–14 and seamless dawn epilogue. Do not expand core APIs without measured need.
