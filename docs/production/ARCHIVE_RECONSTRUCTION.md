# Resumed Archive reconstruction — 2026-10-04

This is a new, explicitly authorized reconstruction of missing controller/world
source. It does not reproduce or recertify the absent historical S02 commit
`cc63a5f9e14917f271941f2afff8d42162a00a38` or its reported 24-command acceptance.
The accepted isolated T019 source remains unchanged.

## State/world binding checkpoint

Reconstructed `ArchiveMain`, `ArchiveProgress` and `ArchiveStageController`:

- One persistent graybox hub, five entrance/channel pairs, first-wing corridor
  and room, finale placeholder and explicit safe checkpoint markers.
- Pure milestone/fragment projection with cross-validation. Contradictory saves,
  stale owned namespaces and unknown checkpoints are refused before application.
- Quiet restoration uses accepted gate/channel components; it does not replay
  opening animations, return impulses or pickups. Only eligible routes open.
- Structural previews cover Memory I completion, all wings and finale readiness.
  These previews are not later-wing gameplay implementations or save acceptance.

`evidence/archive_reconstruction/state-validation-1/results.json`: PASS, exact
source hashes, initially cache-free copy, clean import and 101 assertions from
the actual scene. Every spawn has capsule clearance and level collision ground.
Protected physical primary/backup files remain byte-identical. The test has no
GameState/dirty mutation; timeout and complete stdout/stderr are retained.

An initial runtime attempt exposed a reserved GDScript identifier and missing
explicit type; both were corrected. Editor scan alone was not treated as runtime
proof. No previous environment preflight or accepted T019 suite was repeated.

Still open: S01 interaction/awakening sequence, S02 rings/focus, fragment window,
actual checkpoint writes and reload, corridor/return interaction integration,
Boot/Continue, graphical scene review and authored art/audio/VS1 acceptance.
Current project entry remains the accepted shell; this state checkpoint does
not claim a complete playable slice. No S03 gameplay is registered.

## S01 interaction/progression checkpoint

`progression-validation-3/results.json`: PASS, clean-copy import, 109 S01/puzzle
and narrow-router assertions plus 101 state/world assertions on current bytes.
S01 uses actual ray-picked InteractionTargets and dispatched E events for panel,
quest lens, snap installation and activation. A seven-second, pauseable sequence
rotates the graybox astrolabe, briefly activates five channels, dims four and
commits S02 on the same world instance without a loading frame/fade/teleport.
An actual `archive_awakened` primary/backup checkpoint is written before entry.
Physical proximity opens the eligible Wing I gate. Invalid progression and a
later input owner preserve original state/world/player; the load API still
refuses a saved DTO for IN_PLACE.

The narrow `request_progression_stage` method is required because committing a
prepared milestone before the old router transaction would expose unaccepted
state to save/exit. It uses the existing transaction instead. No new autoload,
save version or global story logic was introduced.

`progression-validation-2` retains an attempted old seamless-fixture regression
failure: published `archive_kit_sample.tscn` is not materialized in this partial
checkout. S01 and state checks passed in that attempt. The same-instance,
no-loading-frame, camera/feet, saved-DTO refusal and cancellation contracts are
now tested on the actual reconstructed Archive in validation 3; that missing
engineering fixture is not labelled a runtime regression or a new PASS.

Ring/focus state modules cover all 64 ring combinations, a unique full
connection, reversible discrete steps, locked completion, five focus stops and
Star-before-focus gating. Their scene target choices (rings 1/2/3, focus 2) are
new reconstructed graybox authoring parameters, not recovered historical bytes.
They are not yet connected to the S02 room or fragment window. Graphical review,
authored art/audio, hints, full S00/Boot and VS1 acceptance remain open.

## S02 recovered binding — 2026-10-04 19:15 UTC

Fresh Work checkout resumed from remote receipt `5f196fd`; seven fragment files
were absent and recovered only from its saved patch. The separately labelled
pending binding was reviewed as an untested draft. The room now reuses the
materialized accepted Wing I optical carrier, with real ring/focus grip targets,
a segmented beam, emitter, Star, Hearth and cold-to-warm room light.

Acquisition checks actual solved/locked controllers and found order before
publishing milestones. Failed physical IO retains logical acquisition, dirty
state and a Russian Retry modal. Retry writes before presenting the fragment;
pickup/checkpoint events cannot replay. Quiet load restores solved states, the
safe spawn and warm light without animation or another fragment modal. Hidden
final order/letters remain resource metadata. Recovered copy is retained from
the recovery draft; final wording still follows the master narrative authority.

`slice-validation-1` records a test-fixture parse failure (Dictionary vs Array
comparison), bounded by the external timeout. The fixture was corrected to
inspect the typed captured DTO. `slice-validation-2`: clean-copy import and 53
actual S02 assertions PASS, including real E rays, a physical directory IO
obstacle, Retry, primary/backup writes and Star/Hearth reload. The next receipt
adds changed-scene/S01 regressions. No authored room art, Boot/S00, full VS1,
Windows or physical-GPU acceptance is inferred from this headless result.

Shell Git push in this fresh session lacks a credential helper. The authorized
GitHub Git-data connector publishes exact staged trees on the same working
branch with `force=false`; ordinary fetch/ls-remote independently verifies SHA,
parent and staged-tree identity. `tools/checkpoint_gitdata.py` prepares a reviewed
source/evidence delta snapshot and verifies each guarded local fast-forward.
It excludes immutable masters/object packs/toolchains and is not a full archive.
The token-dependent old coordinator is not claimed active in this environment;
event checkpoints are invoked explicitly. The 19:17→19:39 interval exceeded
the owner's 15-minute limit; `evidence/checkpoints/cadence_20261004.json` records
the breach and shorter publication blocks. No uninterrupted cadence is claimed.

## Physical return / graphical review checkpoint

`return-validation-3/results.json`: PASS, exact current clean-copy source;
57 S02 assertions, 101 state and 109 S01 assertions. The persistent player
walks from the Hearth checkpoint through room/corridor/completed gate into the
Hub with continuous ground. An actual return trigger pulses the shared channel
once without mutating save data. Logical Wing II readiness remains visible;
its unbuilt passage cannot open into absent ground.

`modal-validation-1/results.json`: clean-copy import and 57/101/109 assertions
PASS with explicit modal button focus release. `slice-graphical-4/review.json`:
eight inspected 1920×1080 Low/Medium native Forward+ views PASS, including
readable intact Star/Hearth modals and rendered Continue text. The fixture
verifies 806 bright interior text pixels in all four actual modal captures.
The earlier missing-button annotation was an incorrect visual assessment:
reinspection and raw PNG pixel counts establish the button in all twelve
historical captures. `modal_assessment_correction.json` supersedes that annotation;
original evidence is retained. The redundant WIP redraw request was removed.
No software-renderer FPS is used as target-hardware evidence. Boot/S00, authored
room art/audio and GATE-VS1 remain open.

## Explicit checkpoint resume

`SceneRouter.request_resume_stage` validates the checkpoint and uses the normal
transactional world instantiation/safe-spawn path even when the registry stage
uses IN_PLACE for live progression. Generic saved IN_PLACE entry remains rejected;
live S01→S02 retains the existing world/player without a loading cut.
`resume-validation-1`: clean import and 60 actual S02 assertions PASS with the
shipping IN_PLACE registry, including cold entry, Star/Hearth primary reload,
safe spawns and no duplicate pickups/writes. S01 and router pipeline/transaction/
seamless regressions also PASS. Registry paths are never read from save files.

## S00 graybox timeline

S00 is now a registered supported stage in the persistent Archive. The local
`ArchivePrologue` owns an exterior camera, first spark and sliding main doors;
trimmed Hub wall ends form a real clear entrance. The exterior floor has physical
edge guards. No separate world/loading cut is used for S00→S01. The terminal
camera matches the persistent player's transform and configured FOV before the
IN_PLACE transaction enables first-person input. Pause freezes the timeline;
accepted completion writes `prologue_completed` once. Quiet S01 load skips S00.
Timings and primitive presentation remain engineering graybox parameters, with
no new narrative copy, authored art/audio or release skip policy invented.

`prologue-validation-1` retains the bounded failed scene-resource parse: .tscn
constructors require a leading zero for decimal literals. The resource and
fixture early failure handling were corrected; `prologue-validation-2` records
the targeted clean-source S00/state/S01/S02 run. Native S00 review and Boot are
the next unfinished block. Explicit New Game must preserve prior files and
protect future schemas/actual IO obstacles before any reset. GATE-VS1 still
blocks later wings.

## Explicit New Game persistence

`SaveManager.write_new_game` is an explicit confirmed disk-only operation for a
fresh S00 DTO. It never applies global state or clears dirty state. Before either
slot replacement it copies both existing files byte-for-byte into a unique
`user://savegame_history` directory, verifies SHA-256 and flushes a manifest.
Both fresh temporary saves are validated before replacement; partial replacement
rolls changed slots back from the preserved originals. Future schemas and actual
IO obstacles are rejected before history/replacement. Unconfirmed/non-fresh calls
cannot change slots. Ordinary read/flush never invokes this operation.

`new-game-validation-1` passes 57 isolated physical New Game assertions and the
atomic Save IO regression; its App exit invocation lacks the fixture's required
isolated-root CLI argument and fails its guard. The delta runner now supplies
that argument. `new-game-validation-2` is the exact-source targeted receipt for
New Game, ordinary Save IO and actual dirty App exit. Boot UI is still next; no
automatic reset or deletion on startup is introduced.

## Boot component integration

`core/boot/boot.tscn` supplies a Russian menu around the persistent GameRoot and
the owned S00/S01/S02 registry. Startup reads/prepares domain state without
applying saves or touching their bytes. Continue loads the registered safe spawn;
backup use is visible. Existing valid/corrupt progress requires a cancelable New
Game confirmation; a fresh empty slot starts directly from the New Game button.
Unknown schemas/IO obstacles block reset. S00 opts into the shared Esc pause and
nested Settings; the cinematic/player cameras share live configured FOV. Known
checkpoint IDs inconsistent with their stage/fragments cannot load into a locked
wing. Boot frees its registry entries with its root.

`boot-validation-1` retains a typed-variable parse failure, corrected by explicit
bool annotation and early fixture cleanup. `boot-validation-2` runs the menu but
its same-frame SpinBox value assignment leaves the old editable text; the test
now enters text in the actual FOV editor before Apply. `boot-validation-3` is the
current targeted Boot/S00/state/S01/S02/pause receipt. The shipping main scene is
still the old shell in this component checkpoint. Next: native menu/S00 review,
then enable Boot as the main scene and verify actual startup/exit. Full VS1 and
authored room art/audio/hardware acceptance remain open.


## Boot native component review

`boot-review-validation-1` passes the exact-source Boot and S00 targeted cases.
`boot-graphical-1/visual_review.json` accepts fourteen actual 1920x1080 views
(seven each at Low/Medium) for menu layout, New Game confirmation and graybox
S00 exterior/spark/doorway/S01 handoff. Both bounded software Vulkan processes
exit successfully with no runtime errors or warnings. The graybox camera path
and menu are visible; authored observatory art/audio and physical GPU/FPS
acceptance remain open. Next: enable Boot as the shipping main scene and verify
normal startup and the actual safe exit path.
