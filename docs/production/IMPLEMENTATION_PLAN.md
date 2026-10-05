# Implementation plan

Status: **started**.

## Latest room models — 2026-10-05

- [x] Complete original 3 m front walls; actual LFS upload/retrieval, 171
  targeted assertions and eight inspected Low/Medium views pass.
- [x] Complete static Hearth bowl/pedestal and emitter housing; actual LFS
  upload/empty-store retrieval/reopened source, 145 targeted assertions, normal
  startup and ten inspected Low/Medium views pass. See `WING01_HEARTH_EMITTER.md`
  and `hearth-emitter-acceptance-1` for exact scope and camera compatibility audit.
- [ ] Canonical ceiling/ribs, authored beam/Star/Flame VFX, complete room/VS1,
  authored audio and physical target GPU. See `ROOM_ART_NEXT_BLOCK.md`.

Current recovery authority: `WORK_RECOVERY.md` and
`evidence/checkpoints/development.jsonl`; old network notes below are historical.


## Current bounded corridor art — 2026-10-05

Fresh recovery used remote `92afd6214d2a1564eda5bad7c13e227123038356`, not an
old local snapshot; development remains on the existing checkpoint branch.
Newest exact implementation/publication identities are in `WORK_RECOVERY.md`
and `evidence/checkpoints/gitdata_publications.jsonl`.

- [x] Place approved Wing I corridor wall bays/piers/room portal and 28 unit
  floor tiles without changing source assets, dimensions or safety guards.
  45 current capsule checks and 101 affected Archive state regressions pass;
  cache-free import and protected physical primary/backup hashes pass. Eight
  inspected Low/Medium views verify the bounded placement after correcting
  missing-sky ambient selection and coplanar Hub skin overlap. See
  `WING01_CORRIDOR_ART.md`. Full room/ceiling/palette/audio/target-GPU acceptance
  remains open; this does not close GATE-VS1 or unlock S03.
- [x] S00 source-comparison/cut-proposal page and 16 actual Chromium checks.
  Both source intervals/note/motif remain unselected; no shipping binding.
- [x] Bounded room side/back reuse: 19 unit module instances, old higher guards
  retained; 19 actual capsule/approach checks, 101 state and 60 S02 regressions
  pass. See `WING01_ROOM_ART.md`. Six inspected Low/Medium native views confirm
  readable stone/joins and existing cold/warm response with protected slots.
  120 shared floor tiles now cover the unchanged footprint; 27 current room,
  101 state and 60 S02 checks pass. Six new Low/Medium views verify floor/joins
  and cold/warm response. Captured draw-call/texture counters are software
  diagnostics only. Front/ceiling and full room acceptance remain open.
- [x] Front input audit followed by the completed bounded 3 m source/export and
  placement. Actual authenticated API/LFS transport now passes; the earlier
  HTTP 401/blocking note is superseded. Current ceiling/model follow-up is in
  `ROOM_ART_NEXT_BLOCK.md`.

## Source availability after the 2026-10-04 interruption

Fresh Work recovery selected remote checkpoint `5f196fd` on
`feature/04-archive-gameplay/checkpoints-2026-10-04`; no old snapshot was applied.
ArchiveMain/S01 had already been reconstructed and verified remotely. S02's
saved module patch and pending binding draft have now been restored/reviewed.
Current stable source includes connected ring/focus model grips, Star/Hearth,
physical save retry, quiet restore and continuous return walking. See
`ARCHIVE_RECONSTRUCTION.md` and checkpoint receipts for exact source identity.

- [x] Continue the unfinished T019 local gate/light-channel foundation: reusable
  graybox prefabs, four gate states, animated/instant restoration, explicit
  forward/return impulse, Low fallback without glow/volumetrics and local lifetime
  ownership. Seven clean commands PASS; 147 assertions in headless and Forward+,
  four inspected 1920×1080 views and exact protected-file/source hashes. See
  `ARCHIVE_ROUTE_PRESENTATION.md` and `evidence/archive_route/README.md`.
- [x] Reconstruct ArchiveMain/S01/S02 logic and connect T019. Current clean-copy
  checks: 101 state assertions, 110 S01 assertions and 60 S02 assertions including
  actual E rays, directory IO failure/retry, primary/backup, quiet reload and
  physical corridor/Hub return. Eight native Low/Medium views confirm the reused
  optics carrier, cold/warm response and readable complete Cyrillic modals;
  Continue text is also asserted in the captured pixels. Missing later
  wing ground stays blocked despite the logical next-route indication.
  Authored room art/audio and full VS1 remain open.
- [x] Shipping Boot/Main Menu and S00 graybox timeline: explicit protected New
  Game, read-only Continue, Settings/Exit, registered checkpoint resume, actual
  spark/door/camera handoff and opted-in cinematic pause. 33 Boot, 25 S00 and 17
  exact-entry/safe-Exit assertions pass. Fourteen native Low/Medium views and
  configured-main startup pass; authored prologue art/audio remain open.
- [ ] `GATE-VS1`: full S00→S01→S02, authored art/audio and target-hardware profile.
  S03 remains gated; no later-wing implementation starts from this component proof.
- [x] S00 first-spark semantic request and bounded lifetime. S00 forces silent
  entry and finite seeds; pause/quiet restore never repeat the event. Actual
  synthetic PCM and affected route/mixer/entry regression: 193 assertions pass
  in `evidence/audio_director/prologue-pcm-2/`. Removed requests cannot begin
  after foreign silence releases or cancel newer ownership. Source-note/motif
  selection, shipping derivatives/bindings and full art/audio acceptance stay open.

Historical milestone checkboxes below describe their accepted published baseline;
this availability note does not revoke those results or claim recovery of missing
later local features. Available changes are committed and checkpointed; the old
worktrees and accepted preflight suites are not reset or rerun.

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

- [x] Boot/Main Menu in Russian, shipping main entry, protected New Game history,
  Continue/Settings/Exit and registered S00/S01/S02 resume. See
  `ARCHIVE_RECONSTRUCTION.md`, `boot-main-readonly-1`, `boot-main-regression-1`
  and the bounded native component/main receipts.
- [x] SettingsManager validated ConfigFile preferences, atomic replacement and Russian draft/Apply/Cancel modal. Clean import, corrupt/type/range/version/write-failure cases, real bus gains, author-preserving graphics switches, native display modes and inspected 1280×720/1920×1080 Forward+ UI PASS; see `SETTINGS.md` and `evidence/settings/`. Main-menu/pause entry points and target-GPU profiling remain subsequent work.
- [x] InputManager focus/pause/capture handling: requested mode survives pause/focus; visible startup UI cursor, immediate gates, held/echo movement suppression and recapture-motion guard. Clean import and actual authenticated TCP X11 focus/capture checks PASS; see `INPUT_FOCUS.md` and `evidence/input_focus/`. Esc/pause UI and repeat-skip consumers remain separate work.
- [x] Russian pause panel with nested settings, gated fresh Esc, mode/lock restoration and explicit awaited/cancellable fade/loading overlay. Actual controller pause/held-key/recapture, GUI nesting/blocking, clear/free/removed-root cases and inspected Forward+ UI PASS; see `PAUSE_FADE.md` and `evidence/pause_fade/`. Cinematic pause/skip arbitration and scene-router transitions remain their own later systems.
- [x] Basic Player CharacterBody3D + interaction ray: inactive persistent player, gated walk/look, physics-revalidated E, explicit collider component and Russian focus prompt. Clean import, actual Archive traversal/wall stopping, input/target race checks, Wing I grip dispatch and actual Forward+ screenshot PASS; see `PLAYER_INTERACTION.md`. Playable story worlds, canonical puzzle controllers and scene-router spawn pipeline remain later work.

## Milestone 2 — state / saves / routing

- [x] Typed SaveGame v1 DTO/resource with bounded JSON-only state, exact numeric round trips and validated isolated GameState capture/apply. Clean import, invalid/version/order/resource/cycle cases, state/file integrity, prior shell/player/input and Forward+ startup PASS; see `SAVE_SYSTEM.md` and `evidence/save_dto/`. Disk persistence and registered-world validation remain later tasks.
- [x] Atomic validated JSON write/read + last-valid backup + read-only corruption fallback. Failed writes retain dirty/state/files; future schemas are protected; Russian retry/stay guards App and actual native close. Clean import, physical file/failure/recovery tests, successful dirty exits, GUI and Forward+ regressions PASS; see `SAVE_SYSTEM.md` and `evidence/atomic_save/`. Both-corrupt New Game choice UI and authored checkpoint triggers belong to Boot/world integration.
- [x] SceneRouter registered preload/checkpoint/fade/input/state/spawn pipeline. Clean acceptance passes actual checkpoint files, transactional cancellation/rollback, physics/callback restoration, native close recovery and same-world S14→15 presentation; see `SCENE_ROUTER.md` and `evidence/scene_router/`. Shipping worlds/registry, Boot/Continue and authored final choreography remain their own features. PR #41 is merged into the epic; its exact accepted tree and merged-epic startup/safe-exit gate pass. Integration follows the normal epic → main PR route.
- [x] ArchiveMain graybox + spawn/state restoration, S00/S01/S02 controls and fragment checkpoints. Current clean runtime and graphical evidence: `ARCHIVE_RECONSTRUCTION.md`. Authored art/audio and full VS1 remain separate acceptance.
- [x] AudioDirector dual-player crossfade + group/unique finite playlist, owned
  silence/duck locks and transactional stage intent. Actual generated PCM,
  latest queue, semantic/vocal guards, real route rollback and failed/stayed/
  successful App exit pass; native WM_DELETE_WINDOW and seamless framebuffer
  equality pass. See `AUDIO_DIRECTOR.md` and `evidence/audio_director/`.
  Shipping authored derivatives/bindings and final mix/hardware remain open.

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
- [x] Produce the bounded five-module Archive sample: editable source, five GLBs/wrappers, isolated primary/corner fixtures; actual source/import/physics/three-view Forward+/independent LFS retrieval PASS. See `evidence/modular_archive_kit/README.md`. Full ARCH inventory and target performance remain open.
- [x] Produce the bounded Wing I optical carrier with three separate ring pivots and a five-stop focus wheel. Source/import/physics, three actual Forward+ views and independent six-file LFS retrieval PASS; S02-001/S02-003 mechanical sample only. See `WING01_OPTICS_SAMPLE.md` and `evidence/wing01_optics/README.md`.
- [x] Import Archive structure and the Wing I carrier: scale, orientation, pivots, shared materials, authored collision and warnings verified. Wing I grip ray selection/joint following pass; shipping interaction and puzzle rules remain separate work.
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

Audit checkpoint: `92fa0f29e5156a5926c44ad24696a49e3d1137ca`.
Material/evidence checkpoint: `feb658a02c41d334804620b1b6ad303df83b864a`.
Feature merged through [PR #23](https://github.com/MindDevastation/where-the-light-remains/pull/23)
into Art Foundation at `93a8e116adac4bad4c04dc16fd795ea64450437e`.
The merged tree exactly matched the validated feature. Authenticated X11 TCP /
Vulkan Forward+ GameRoot/eight-autoload/safe-exit smoke passed again on that
merged epic; actual output: `evidence/visual_rebaseline_v2/integration_epic_smoke.log`.
The stable slice follows the normal epic-to-main route; Git merge history records
the final integration SHA. Unbuilt art and target-hardware gates remain open.

## Modular sample checkpoint — 2026-10-03 UTC

Feature: `feature/03-art-foundation/modular-archive-kit`, base main/Art Foundation
`c6773f203717b0058a3ec3aee4a3e26bb1190f1f`. Existing production docs and successful
preflights were read first; the confirmed local Blender and authenticated Xvfb
TCP/MIT-MAGIC-COOKIE/X11/Vulkan Forward+ paths were reused. Standing Extra High /
highest available request applies; no agent-side model switch is claimed.

Five original structural parts implement the current v2 kit/shape/hub A/B/C
direction while preserving all eight technical JSON keys and fourteen prior
runtime/config fingerprints. Source/export checkpoint: `1e3adf1a500c9fbf7a5ad1497588e7df1dd1015b`.
Actual source reopen, import/material identity, 15 capsule traversals, 810 floor
rays, solid blockers, four yaws, wall replacement and covered corner PASS.
Three final actual views were inspected: front, reverse, right-angle close view.
The 63-part primary pad is 4,284 triangles against 23,568; counters 25/27/18 draw
calls are software previews, not target performance acceptance.

Six new LFS payloads uploaded, then independently retrieved from GitHub into a
fresh remote shallow clone with no alternates/shared LFS store. All hashes and
sizes match; retrieved Blender/import/physics/authenticated graphical startup
and full Git/LFS fsck PASS. Previous ordinary-Git HEAD hydration workaround was
applied before LFS scanning, without rewriting refs. Evidence and commands:
`evidence/modular_archive_kit/README.md`.

The four ARCH inventory rows remain PARTIAL; no Hub layout, player, puzzle or
shipping UI is invented. Next safe feature is the bounded Wing I hero mechanism
brief/sample with canonical gameplay pivots, then the representative playable
vertical slice. Physical target-GPU profiling still gates bulk modeling.

Archive sample integration: [PR #25](https://github.com/MindDevastation/where-the-light-remains/pull/25)
merged the validated feature `774b50c52c062173d36a5f37f8ea07c05f393b16` into
Art Foundation at `9f95ed22b97a9e732d0a8f2adb5e352e3f5d034b`. Trees match exactly.
Authenticated X11 TCP/Vulkan Forward+ GameRoot/eight-autoload/safe-exit smoke
PASS on that merged epic; actual output is
`evidence/modular_archive_kit/integration_epic_smoke.log`. The stable slice follows
the normal epic-to-main route; Git merge history retains the final integration SHA.

## Wing I optical articulation sample — 2026-10-03 UTC

Feature: `feature/03-art-foundation/wing01-optics-sample`, from synchronized
main/Art Foundation `e978c0d813b94d1299d8376879c75ec309012d3c`. Existing production
docs, canonical S02 sequence and successful evidence were read first. Confirmed
Blender and authenticated Xvfb TCP/MIT-MAGIC-COOKIE/X11/Vulkan Forward+ were
reused; minimum capability probes passed before target checks. Standing Extra
High / highest available request applies; no agent-side model switch is claimed.

Bounded carrier implements separate mechanical S02-001/S02-003 parts: editable
source, fixed frame, three concentric ring GLBs and five-stop wheel, script-free
Godot wrapper with independent joints, moving grip Areas and simple blocking
shapes. Source checkpoint `a3c11209d7218fe2ba08b402bac054d6d49f7cc8`.
Actual source topology/UV/normals/pivots and source/GLB meter bounds pass. Runtime:
8,636 triangles / 16 shared surfaces, 40 independent poses, 48 real selection
rays, five distinct focus positions and two whole-assembly yaws. Three real
1920×1080 Forward+ views inspected; isolated rendered parts/pose changes pass.

Six exact LFS pointers/payloads uploaded, independently retrieved and hash-checked
in a remote shallow clone with no alternates/shared LFS store. The confirmed
ordinary-Git hydration path restored all 555 HEAD blobs before LFS scanning.
Actual retrieved Blender/Godot/import/physics/graphical GameRoot startup and
Git/LFS fsck pass. Core fourteen fingerprints, existing architecture contract,
all shared material/map resources and global budgets remain unchanged. Evidence:
`evidence/wing01_optics/README.md`.

S02 remains PARTIAL. No emitter/star/Hearth optical response, solve rules, rewards,
shipping interaction/UI or save state is invented. The canonical split defines
the sequence/count but not ring detent counts/solve angles/focal distances;
those dependent controller inputs remain open. Next safe work: canonical
interaction/controller brief and the representative playable slice. Physical
target-GPU profiling continues to gate bulk production.

Wing I sample integration: [PR #27](https://github.com/MindDevastation/where-the-light-remains/pull/27)
merged validated feature `d799a3e4009c4f1700df66acddb7102b18f75758` into Art
Foundation at `aae7cc58b25c36bc6517217641cfba4627e6a50f`, with exact tree equality.
Merged-epic graphical GameRoot startup/safe exit and the previous Archive
physics/material baseline pass; evidence is under `evidence/wing01_optics/`.
The final documentation-only checkpoint follows the standing ordinary
epic→main integration policy; it changes no accepted runtime or payload.

## SceneRouter integration recovery — 2026-10-03 UTC

Feature [PR #41](https://github.com/MindDevastation/where-the-light-remains/pull/41)
merged accepted checkpoint `c050d9f7a6f02a0b2be5f5497264ee8d0171c226` into
`epic/02-state-saves` at `1bbd933b10f6cc7bbb7b946e75b53170f763c13a` before the
environment disconnected. The recovered remote merge tree equals the feature
exactly. All 55 accepted evidence hashes match. The real native X11 close test,
including failed-write GUI recovery and primary/backup verification, had already
passed and was reused, together with the accepted 18 headless / 11 graphical /
5 isolated exit results. No acceptance suite was restarted.

The recreated workspace contained an older snapshot and no surviving Godot/Xvfb
process. Recovery restored the branch, existing credential helper, xkbcomp link
and ten missing runtime payloads using their recorded SHA-256/size identities.
Fresh import and the required merged-epic GameRoot/eight-autoload/safe-exit smoke
pass on authenticated TCP X11/Vulkan Forward+. All 242 archived tracked files
remain unchanged, with eleven exact runtime payloads. Actual recovery and merge
gate evidence: `evidence/scene_router/resume_manifest.json`,
`integration_epic_smoke.log`; session: `SESSION_2026-10-03_16-40.md`.

Main integration is tracked in
[PR #42](https://github.com/MindDevastation/where-the-light-remains/pull/42);
Git merge history records its final SHA. AudioDirector is the next independent
implementation task.

S00 final protected-file check, 2026-10-04 23:47 UTC:
`evidence/audio_director/prologue-pcm-protected-saves-1/` passes cache-free import
and 41 actual event/PCM/ownership/quiet-load checks on the current source with
two existing read-only save fixtures. Both primary/backup SHA values remain
`a8f464dc403b93c60fb7fd60a658335505e4506c5344ec05f1f487120372d757`.
No runtime errors/warnings or shipping source-audio bindings. The two S00
opening proposals in `audio/REVIEW_INDEX.md` are ready for listening; first-note
and common motif selection remain pending, so GATE-VS1 stays open.
