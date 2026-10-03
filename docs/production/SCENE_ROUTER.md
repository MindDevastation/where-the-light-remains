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
