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

The owner renewed development for 13:19:55–16:19:55 UTC. See
`SESSION_2026-10-03_13-19.md`; the earlier deadline above is historical.

## Historical prototype checkpoint

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
- Preload cancellation/timeout cleanup now passes real delayed engine-loader
  tests. Caller cancellation is prompt; engine worker cancellation is not
  available through Godot's public API. Retain and nonblockingly collect its
  terminal result, including failed requests, before accepting another load.
  See `preload_cleanup.log` and its committed source in the manifest.
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

## Accepted core — renewed window, 2026-10-03 UTC

**PASS** on source `1b30a7af44469e141c0fa63eba29b2822916b424`.
Fresh archive, 242 unchanged game/tools/required art-contract files and fourteen
existing LFS identities verified. Eighteen headless fixtures, eleven authenticated
TCP X11/Forward+ fixtures and five isolated real exit processes pass. Graphics
source `a1aedb9d21a37efeafbaffd53e1f8e1dfa1f839d` has the exact accepted production
and tools trees; only a cleanup smoke changed afterward and reran graphically.
Exact commands/source hashes/results are retained in `evidence/scene_router/`.
The established headless malformed ConfigFile case emits its one expected parser
diagnostic; every graphical run and all other accepted checks have no errors.

`register_stage(StageDefinition)` stores an isolated authored path/mode/player/
presentation definition. Save data cannot choose paths. `WorldScene` validates
full stage identity, every declared spawn/checkpoint transform and its own logical
namespace before application. Derived validators must be pure; failure must leave
logical state unchanged and previously valid state must remain restorable. `_ready`
may construct presentation, but must not advance progression or write global
state/save/audio. Processing/physics callbacks, including ALWAYS children, freeze
during preparation; this is not a sandbox for arbitrary signal/timer side effects.

`request_registered_stage(id, saved = null, checkpoint_before = false)` serializes
input lock, requested dirty checkpoint, threaded preload, fade, physical world
replacement, logical state, exact feet spawn, audio stage and input release.
Requested checkpoint writes the old accepted state before preload. Failed writes
preserve the world, dirty state and files; successful writes retain the prior valid
backup. Loaded DTOs do not automatically mark dirty; accepted normal progression
does. There is exactly one target stage event after acceptance.

Old worlds stay available for rollback and their callbacks stay disabled. Candidate
callbacks freeze after `_ready`, while authored active colliders retain query
presence and rigid bodies become static. Authored disabled REMOVE colliders stay
absent. Spawn requires an unobstructed capsule and valid floor support. Reattached
physics settles before the player resumes; exact authored process/disable modes
restore. Nested world/slot transforms, absent/steep support, blocked capsule,
apply failures and rollback are checked in the real physics engine.

Input mode revisions and fade request revisions protect later owners. Removal,
rebind and freed player at preload/fade-in/physics/fade-out cancel safely. A changed
binding or dead context releases owned capture to UI. `App.request_safe_exit()`
first cancels/awaits the route before flushing: an unaccepted target can never be
saved by native close. Real IO failure leaves the Russian dialog usable; Stay
restores accepted gameplay. Pending worker completion is tracked and collected
nonblockingly, including FAILED engine tokens. Godot exposes no worker cancellation
API; canceled/timed-out callers return promptly and new loads/registry mutations
remain busy until the tracked worker reaches a terminal result.

Presentation defaults to the existing technical fade API; durations are not
authored narrative timings. Explicit IN_PLACE and the mandatory S14→15 path require
the same registered scene and declared supported stages on the current world.
They apply the next namespace/stage on the same instance, preserving player
feet/head/camera without preload, frame yield, fade or loading overlay. A missing
shared-world contract returns ERR_UNAVAILABLE before locking or replacing anything.
IN_PLACE is progression only; an explicit saved DTO is rejected instead of ignoring
its spawn/checkpoint. Boot/load uses an authored ordinary entry definition.
The engineering S14→15 before/after Forward+ framebuffers are byte-identical.

No shipping stage registry, automatic world, Boot/Main Menu, story/puzzle parameter,
credits choreography, music silence implementation or new 3D binary was invented.
Authored content and AudioDirector silence/chains remain separate. Linux llvmpipe
acceptance does not certify Windows, physical GPU frame budgets, power-loss saves
or permanently stalled engine workers. The earlier prototype/open-task paragraphs
above remain historical and are superseded by this accepted core section.
