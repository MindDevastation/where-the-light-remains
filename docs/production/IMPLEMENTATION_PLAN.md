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

## Milestone 0 — preflight

- [x] Normalize asset roots under `assets/`.
- [x] Curate music and define runtime playlist policy.
- [x] Add canonical design split docs and QA baseline.
- [x] Create repository asset index.
- [x] Create initial Godot project.
- [x] Create 8-autoload core service scaffold.
- [x] Lock product language baseline to Russian.
- [x] Define Astra branch/commit/integration/blocker workflow.
- [ ] Lock exact Godot 4.x minor version after verifying the development machine/editor.
- [ ] Perform a real Git LFS history migration for large audio/3D assets before adding more heavy binaries; do not merely add LFS attributes to unmigrated blobs.
- [ ] Build valid InputMap in editor/project settings.
- [ ] Create audio bus layout: Master → Music/Main/Stems, SFX/Critical/World, Ambience, UI, VO_RESERVED.
- [ ] Add development-only debug stage/save/audio/performance tools.

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

## Milestone 4+

Add remaining Archive wings one by one, then Memory I, Egg memory with runtime checkpoints, Memory III, final state machine 10–14 and seamless dawn epilogue. Do not expand core APIs without measured need.

## Branch execution map

Initial implementation sequence:

```text
main
└── epic/00-foundation
    ├── feature/00-foundation/engine-preflight
    ├── feature/00-foundation/input-map
    ├── feature/00-foundation/audio-buses
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
```

Later epic/feature branches are created only when their scope is ready; do not invent unresolved implementation requirements merely to populate the branch tree.
