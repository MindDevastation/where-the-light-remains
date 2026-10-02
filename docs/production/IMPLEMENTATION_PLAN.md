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
- [x] First real LFS-backed 3D binary gate: pointers, real upload, independent fresh-clone retrieval, exact payload hashes, full Git/LFS fsck and retrieved-copy Blender/Godot checks PASS (2026-09-22). See `LFS_POLICY.md`.
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
- [x] Verify actual Blender version/CLI/export capabilities: Blender 4.5.14 LTS background CLI, source save and disposable GLB probe PASS. See `BLENDER_PREFLIGHT.md`. Git authentication and full local `git lfs fsck` PASS after verified recovery of missing ordinary-Git objects. First-binary pointers, real upload (2/2), independent retrieval and retrieved-copy Blender/Godot checks now PASS. Completing ordinary-Git HEAD hydration resolved the fresh-clone pull blocker. Integration is tracked in PR #15. Technical gates and the renewed PR write permission check PASS; the previous HTTP 403 is resolved. Feature integration follows PR #15 and the merged-epic smoke gate.
- [x] Validate the first real LFS-backed 3D binary end-to-end: pointer, payload upload, independent retrieval, manifest hashes and producing/fresh-clone fsck PASS. See `LFS_POLICY.md`.
- [x] Validate the approved Blender→GLB→Godot static export contract with a minimal one-meter fixture: scale/Y-up, transforms, pivot, normals, UV, material and separate script-free wrapper. See `EXPORT_SAMPLE.md`; production art/performance acceptance remains separate.
- [x] Restore authenticated Xvfb TCP / Godot X11 / Vulkan Forward+ graphical preflight, with pinned local packages and repeatable runner. Engine and six-specimen material capability tests PASS; see `MATERIAL_PREFLIGHT.md` and 2026-09-23 evidence. The previous AF_UNIX-based environment blocker was an incorrect inference from a TCP-disabled invocation.
- [x] Create compact shared material library baseline: six shared resources, eleven original 1K maps, neutral/warm/cool graphical review and 4x4 tiling PASS. See `MATERIAL_LIBRARY.md`, `MATERIAL_PREFLIGHT.md` and 2026-10-02 evidence. Full MAT inventory variants/quality tiers and representative target-hardware acceptance remain open.
- [x] Define the modular Archive sample brief and assembly contract: five module types, grid/pivots, passage/collision/UV rules, file ownership and acceptance sequence. See `MODULAR_ARCHIVE_KIT.md`, the versioned JSON and dimensioned drawing. Analytical compatibility is checked; no mesh/physics/art acceptance is implied.
- [ ] Produce one modular Archive kit sample using `MODULAR_ARCHIVE_KIT.md`; author the five meshes, wrappers and isolated assembly, then execute its actual import/collision/visual/LFS gates.
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
    ├── feature/03-art-foundation/modular-kit-contract
    ├── feature/03-art-foundation/visual-rebaseline-v2
    ├── feature/03-art-foundation/modular-archive-kit
    └── feature/03-art-foundation/import-validation
```

The old destructive `feature/00-foundation/lfs-history-migration` plan is superseded as a production prerequisite. A future audio-history cleanup may be performed separately only if repository-size pressure justifies the destructive rewrite.

Later environment/hero/memory art epics are created only after the Art Foundation sample proves the pipeline. Do not invent unresolved implementation requirements merely to populate the branch tree.

## Art Foundation integration checkpoint — 2026-09-22

Blender export / first real LFS feature merged through PR #15 into Art Foundation
at 758c4f17769de45899110572d9856b3773cd3420. Clean Godot 4.7.2 import, eight-autoload startup/safe exit, GLB wrapper/geometry smoke and LFS fsck passed on that merged epic.
Main integration is tracked in PR #16. Actual output: evidence/art_epic_smoke_2026-09-22.log.

Next feature: feature/03-art-foundation/material-library. The six-family baseline
follows the approved production policy. Target-hardware performance is not yet
applicable to this technical fixture; no such PASS is claimed.

## Graphical recovery checkpoint — 2026-09-23

Feature: `feature/03-art-foundation/graphics-preflight`, based on Art Foundation
and main `126c92394a6d35b8553b3e005c9202b9c8112ba7`. Restored the previously
verified authenticated TCP path and recorded clean import, graphical engine,
material contribution/Cyrillic/screenshot and GLB regression PASS.
`ASTRA_WORKFLOW.md` now requires evidence-first recovery before an environment
BLOCKER. Reusable installer, package lock and runner are tracked in Git.
No production material assets or target-hardware performance were accepted.
Next production feature remains `feature/03-art-foundation/material-library`.

Recovery feature merged through PR #17 into Art Foundation at
`0fae10ccffe03132cbbddce9b1029e9b42408440`. Its tree exactly matched the validated
feature; graphical engine startup/eight-autoload/safe-exit smoke passed again
on the merged epic. Actual output: `evidence/graphics_epic_smoke_2026-09-23.log`.
The stable slice integrates through the normal epic-to-main PR route; merge
commits in Git identify the final integration SHA.

## Shared material checkpoint — 2026-10-02

Feature: `feature/03-art-foundation/material-library`, based on synchronized
Art Foundation/main `28198315e0ae1d50a4e08b150a7dc2c7b03c8c28`.
Implemented the approved six-family baseline under `game/art/materials/` with
original periodic maps, tracked import settings and an isolated Russian review
script. Source and usage contract: `MATERIAL_LIBRARY.md`; runtime mapping:
`ASSET_INDEX.md`. Existing startup/autoload/gameplay behavior is unchanged.

Actual validation: deterministic map regeneration, import/parse, authenticated
Xvfb TCP engine smoke, X11/Vulkan/Forward+ material contribution/Cyrillic checks,
three light presets and 4x4 tile inspection PASS. Final source revision and
actual output are in `evidence/material_library_2026-10-02.log`.

This closes the shared baseline task only. Stone variation, memory text/imprints,
crystal quality tiers and gameplay feedback integration remain inventory work;
target-hardware performance remains unmeasured. The next planned feature is
`feature/03-art-foundation/modular-archive-kit`: begin with its asset brief and
cross-stage modular architecture review under `ASTRA_WORKFLOW.md` section 9,
before producing the sample. No bulk modeling is authorized by this checkpoint.

Merged through PR #19 into Art Foundation at
`16ba54f2acdc2fed5ea41ea6cfae112e8b7cf983`. The merged tree exactly matched the
validated feature. Graphical engine startup/eight-autoload/safe-exit smoke passed
again on that epic; actual output: `evidence/material_epic_smoke_2026-10-02.log`.
This stable slice follows the normal epic-to-main PR route; Git merge history
records the final integration SHA.

## Modular contract checkpoint — 2026-10-02

Feature: `feature/03-art-foundation/modular-kit-contract`, from synchronized
main/Art Foundation `1a7171cb756cfc0e208312ebbf9257af634a898a`.
The existing kit, architectural sheet and hub reference were retrieved at that
commit, hash-verified and inspected. The sample now has a concrete five-module
brief, machine-readable dimensions/placements and a dimensioned front/plan view.
Analytical checks cover straight/corner joins at four rotations, 4 m to 2+2 m
substitution, support on the floor and a three-lane clearance envelope.

This completes the architecture/brief step. It does not complete sample modeling,
runtime physics, visual art acceptance, payload transfer or representative GPU
profiling. Next executable work is the bounded five-part sample in
`feature/03-art-foundation/modular-archive-kit`, following the acceptance sequence
in `MODULAR_ARCHIVE_KIT.md`. The same contract supplies its dimensions and paths;
do not redesign the grid or repeat solved environment investigations from zero.

Contract merged through PR #21 into Art Foundation at
`e1f0e0e19d2f0dde91192296a7ffa02539e43119`. The merged tree exactly matched the
validated feature. Authenticated X11 TCP / Vulkan Forward+ engine startup,
eight-autoload and safe-exit smoke passed on the merged epic; actual output:
`evidence/modular_contract_epic_smoke_2026-10-02.log`. The contract follows the
normal epic-to-main integration route; Git merge history records its final SHA.

## Visual rebaseline v2 checkpoint — 2026-10-02 UTC

Latest owner task replaces the earlier visual reference baseline with Hybrid
Warcraft Observatory. Feature `feature/03-art-foundation/visual-rebaseline-v2`
starts from synchronized Art Foundation/main `cabe792717828dfe54009219a7f6cc4e0fb5e5e6`.

- [x] Review canonical docs and successful production/environment evidence first.
- [x] Inspect/hash/decode all 167 incoming images and inspect/map all 62 old PNGs.
- [x] Record 45 named v2 slots and two nonstandard zone A/B/C sets; retain old payloads as explicit LEGACY.
- [x] Audit 9 additional concepts: 0 promoted, 3 exact-duplicate supporting, 6 UNMATCHED pending exact owner assignment.
- [x] Inspect actual implementation: six materials and technical cube; no production worlds, hero props or shipping UI screens yet.
- [x] Complete safe P0 wood/material-family/review-light migration and validation: one existing wood resource rematerialized, six shared resources added, 12 resources / 20 reproducible 1K maps; four actual Forward+ graphical reviews PASS.
- [x] Rebaseline existing modular brief visual refs without changing dimensions/physics/budgets; exact technical JSON contract retained.
- [ ] Supply Secrets-Achievements C before that slot's full-reference acceptance.
- [ ] Assign exact slots for unmatched additional 1/5/6/7/8/9 before production use.

`VISUAL_REBASELINE_V2.md` is the migration matrix; `ADDITIONAL_CONCEPTS_REVIEW.md`
records every additional decision. Do not continue the old visual baseline or
manufacture missing stage scenes merely to claim migration completion. Return
to bounded modular sample after the safe foundation slice; representative target
hardware profiling still precedes bulk production.

Bounded foundation gate PASS: Blender/source reopen, GLB technical regression,
Godot import/parse, minimal graphical startup/safe exit, 14 unchanged runtime
fingerprints, material/framebuffer/Cyrillic/4×4 tile review and map reproduction.
Actual evidence and source hashes: `evidence/visual_rebaseline_v2/README.md`.
No production worlds, hero mechanisms, shipping UI or gameplay interactions
exist to migrate/test; no such acceptance is claimed. Physical GTX1060-class
performance is BLOCKER for target certification only. Overall visual rebaseline
remains PARTIAL. The next safe feature is the already specified five-module
Archive sample under the v2 references, with its normal asset acceptance gates.
