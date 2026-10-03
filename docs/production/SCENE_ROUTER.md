# Scene routing

## Implementation brief — 2026-10-03 UTC

Authority read: technical persistent-root / exclusive-router / transition order,
approved player capsule and input boundaries, accepted SaveGame/atomic-save and
pause/fade evidence. Reuse authenticated TCP X11 / Vulkan Forward+; eight autoloads.

Replace the synchronous scaffold with a registered StageDefinition and explicit
WorldScene logical-state/spawn contract, then a serialized threaded preload,
checkpoint-when-requested, fade/input-lock, WorldSlot replace, state application,
player spawn, audio stage and input restore pipeline. No automatic startup world,
Boot/Continue or invented sixteen-stage registry. Only authored definitions can
register scene paths; save data never supplies a path. Tests use engineering worlds.

Validate a deep copy, full registered stage identity, explicit checkpoint/default
spawn, upright unit-scale feet transform and world-specific logical state before
destructive work. Base world accepts empty state; derived controllers own approved
domain validation. Unsupported data must fail rather than guess puzzle states.
Retain old world/state/player/audio for rollback until replacement is accepted.
Overlap, cancellation, freed root, failed checkpoint/preload/apply and later input
locks must not strand simulation or overwrite the next owner's mode.

Exact same-mode lock ownership is an async risk: a later DISABLED request must
invalidate the router's release even when the enum value is unchanged. A monotonic
InputManager mode-request revision is the bounded ownership token; no new service.

Acceptance pending. Tasks remain open until actual clean import, controller/state/
spawn/rollback/ownership and authenticated graphical transition checks pass.
At the owner's 06:32:55 UTC deadline preserve the active feature checkpoint and
pause any unfinished implementation/acceptance; do not merge unfinished work.

## Current checkpoint — acceptance remains open

Feature `feature/02-state-saves/scene-router`. Contract source and latest prototype
identities and actual logs: `evidence/scene_router/manifest.json` and README.
Clean typed-contract import/preload/spawn/domain checks, 206 unchanged files,
input/pause and Forward+ startup pass. The later runtime prototype passes editor
import and actual headless/X11 initial transition, saved domain state/feet spawn,
overlap and invalid-checkpoint rejection, failed apply rollback, later same-mode
DISABLED cancellation, removed-root cleanup and physically blocked spawn tests.
Latest source also passes graphical startup. This is partial engineering evidence.

Candidate callbacks are frozen recursively; colliders retain physics presence
for capsule/ground queries, with rigid bodies made static during preparation.
Original process/disable modes restore after acceptance. The old arbitrary-scene
entry point now requires a matching registered path. No shipping stage registry
or automatic playable world is populated.

Remaining before feature acceptance/merge:

- Checkpoint write failure injection and real isolated successful checkpoint
  transition, including dirty/backup/state ordering.
- Preload cancellation/timeout resource cleanup and explicit failure coverage;
  no leaked outstanding threaded request when cancellation happens early.
- Cancellation after GameState commit/during fade-out, App exit failure during
  transition, rebind/root removal at each phase and exact event/audio/dirty rollback.
- Physics settling on rollback, absent/sloped support, nested/transformed spawn,
  authored disabled colliders and explicit child/rigid-body process restoration.
- Authored transition presentation policy, including the mandatory seamless
  Stage 14→15 path; the prototype currently uses explicit technical fades.
- Fresh full-prototype archive import, unchanged-file/payload proof and complete
  prior save/settings/player/input/pause/debug/graphical regression gate.

Production worlds/Boot/Continue and canonical controller parameters remain later
features. Prototype tests use engineering IDs/counters; none are story content.
The full SceneRouter implementation-plan checkbox stays open. No merge is planned
until these criteria pass. Resume from this checkpoint, using the verified local
toolchain and TCP X11 path; do not repeat solved environment work.
