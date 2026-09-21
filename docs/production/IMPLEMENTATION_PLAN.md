# Implementation plan

Status: **started**.

Execution policy: `docs/production/ASTRA_WORKFLOW.md` is mandatory for implementation work.

## Global implementation constraints

- Shipping game language: **Russian**. All player-facing UI, prompts, hints, settings labels, narrative copy, achievement text and baseline credits are Russian.
- Branching: `main` → `epic/<id>-<name>` → `feature/<epic>/<feature>`.
- Commit regularly in coherent reviewable increments.
- Integrate stable validated progress into `main` regularly so project progress remains observable from GitHub.
- If required data, tools, permissions, runtime capability, canonical copy or assets are missing, **pause the dependent task**. Do not invent replacements or claim unperformed validation.
- Canonical precedence and merge validation rules are defined in `ASTRA_WORKFLOW.md`.
- Default Astra reasoning level: **High**. Tasks listed in the reasoning-escalation policy require a pause and owner switch to Extra High / highest available before continuing.
- 3D source/runtime work follows `docs/production/THREE_D_PRODUCTION_PIPELINE.md`.
- Git LFS policy follows `docs/production/LFS_POLICY.md`.

## Milestone 0 — preflight

- [x] Normalize asset roots under `assets/`.
- [x] Curate music and define runtime playlist policy.
- [x] Add canonical design split docs and QA baseline.
- [x] Create repository asset index.
- [x] Create initial Godot project.
- [x] Create 8-autoload core service scaffold.
- [x] Lock product language baseline to Russian.
- [x] Define Astra branch/commit/integration/blocker workflow.
- [x] Lock Godot minor **4.7**, verified with the standard **4.7.2 stable** executable (`4.7.2.stable.official.ed1daf0bf`).
- [x] Engine preflight: real editor import, GameRoot/eight-autoload startup checks, headless and Forward+ smoke tests, safe exit and native window close. See `ENGINE_PREFLIGHT.md` for evidence and scope.
- [x] Configure forward Git LFS rules for future heavy 3D binaries (`*.blend`, `*.glb`, `*.fbx`) without rewriting existing WAV history. Destructive audio-history migration is no longer a prerequisite for 3D production.
- [!] Before the first real LFS-backed 3D binary is merged, validate pointer creation, LFS payload upload, `git lfs fsck`, fresh-clone retrieval and Blender/Godot open/import as applicable.
- [x] Build valid InputMap in project settings: physical WASD/E/H and logical Esc for pause/skip. Real Godot event-dispatch checks, clean import and startup regression passed; see `INPUT_MAP.md`. Gameplay consumers and hold-to-skip policy remain in their later systems.
- [x] Create audio bus layout: Master → Music/Main/Stems, SFX/Critical/World, Ambience, UI, VO_RESERVED. Automatic loading, real mixer routing and Music/SFX parent gain/mute passed in Godot 4.7.2; see `AUDIO_BUSES.md`. Playback, settings UI and final mix remain later work.
- [x] Add opt-in, read-only development stage/save/audio/scene/performance inspection. Godot 4.7.2 clean import, InputMap/audio-bus regressions, graphical Cyrillic, state/file integrity and actual release startup with/without debug resources passed; see `DEBUG_TOOLS.md`. Exactly eight autoloads remain; target-hardware profiling and full save/audio implementations remain later milestones.

## Milestone 1 — boot / shell

- [ ] Boot/Main Menu in Russian.
- [ ] SettingsManager full ConfigFile read/write with Russian UI labels.
- [ ] InputManager focus/pause/capture handling.
- [ ] Pause/Fade UI in Russian.
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
- all player-facing slice text is Russian and Cyrillic-safe;
- 1080p60 profiling on target-class hardware.

## Epic 03 — 3D art foundation

The 3D stream runs in parallel with code under the active forward-only LFS policy.

Foundation acceptance:
- [x] 3D production pipeline documented.
- [x] Source/runtime folder split documented (`assets/3d/` vs `game/art/`).
- [x] Forward Git LFS policy configured for future `.blend/.glb/.fbx` files.
- [x] Verify actual Blender version/CLI/export capabilities: Blender 4.5.14 LTS background CLI, source save and disposable GLB probe PASS. See `BLENDER_PREFLIGHT.md`. Git authentication and LFS upload negotiation now PASS; full LFS fsck/fresh-clone acceptance remains BLOCKED on ordinary-Git object availability in the partial clone.
- [ ] Validate the first real LFS-backed 3D binary end-to-end: pointer, payload upload, `git lfs fsck`, fresh clone and payload retrieval.
- [ ] Build and validate Blender→GLB→Godot export contract.
- [ ] Create compact shared material library baseline.
- [ ] Produce one modular Archive kit sample.
- [ ] Produce one Wing I hero mechanism sample with gameplay pivots.
- [ ] Import samples in Godot and validate scale, orientation, pivots, materials, collision and warnings.
- [ ] Run representative performance check before mass asset production.

No bulk modeling starts before the export/import sample and first real LFS object are accepted.

## Milestone 4+

Add remaining Archive wings one by one, then Memory I, Egg memory with runtime checkpoints, Memory III, final state machine 10–14 and seamless dawn epilogue. Art production proceeds in parallel using the approved 3D pipeline. Do not expand core APIs or asset complexity without measured need.

## Branch execution map

Initial implementation sequence:

```text
main
└── epic/00-foundation
    ├── feature/00-foundation/engine-preflight
    ├── feature/00-foundation/input-map
    ├── feature/00-foundation/audio-buses
    ├── feature/00-foundation/lfs-forward-config
    └── feature/00-foundation/debug-tools

main
└── epic/01-shell
    ├── feature/01-shell/main-menu
    ├── feature/01-shell/settings
    ├── feature/01-shell/input-focus
    ├── feature/01-shell/pause-fade-ui
    └── feature/01-shell/player-interaction

main
└── epic/02-state-routing
    ├── feature/02-state-routing/save-game
    ├── feature/02-state-routing/save-manager
    ├── feature/02-state-routing/scene-router
    ├── feature/02-state-routing/archive-main
    └── feature/02-state-routing/audio-director

main
└── epic/03-art-foundation
    ├── feature/03-art-foundation/pipeline-spec
    ├── feature/03-art-foundation/blender-export
    ├── feature/03-art-foundation/material-library
    ├── feature/03-art-foundation/modular-archive-kit
    └── feature/03-art-foundation/import-validation
```

The old destructive `feature/00-foundation/lfs-history-migration` plan is superseded as a production prerequisite. A future audio-history cleanup may be performed separately only if repository-size pressure justifies the destructive rewrite.

Later environment/hero/memory art epics are created only after the Art Foundation sample proves the pipeline. Do not invent unresolved implementation requirements merely to populate the branch tree.
