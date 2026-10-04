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
event checkpoints are invoked explicitly within the owner's 15-minute limit.
