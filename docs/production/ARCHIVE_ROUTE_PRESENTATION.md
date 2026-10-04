# Shared Archive gates and light channels

Authority: master v1.8, `TASKS(1).md` T-019, canonical ARCH-014/015 and
ANIM-010 requirements, plus the existing player/collision/settings contracts.
This continues the unfinished T019 patch after the recorded source-loss recovery.

## Local ownership

`ArchiveGate` and `ArchiveLightChannel` are local Node3D components in
`worlds/archive/common/`. They own only presentation and their own short Tweens.
The world validates progression, assigns logical states, grants fragments,
selects semantic audio and writes saves. No autoload, input handler or persistent
field is added. Art hooks are reusable graybox prefabs, not final Archive meshes.

Gate states: dormant and unlocked retain collision; open and completed clear it.
`apply_state(state)` restores immediately and emits no opening/presentation signal.
`apply_state(state, true)` may animate a closed-to-open visual and emit
`opening_started` once. Collision changes at the safe deferred physics boundary;
the opening Tween moves only a temporary mesh, never the blocking body. A world
may bind the local signal to authored audio; these components play no audio.

Channel states: dormant hides the route, active uses the authored active material,
completed uses its warm completion material. Explicit `pulse(reverse = false)` or a changed
animated state runs one local marker along the authored mesh bounds. Emissive
geometry remains visible with glow and volumetrics off. Same-state assignment
and instant restoration never restart the pulse or play completion signals.
The reverse argument lets the same route carry a completion impulse back toward
the hub without altering geometry or the logical route state. Bounds are mapped
through the authored mesh transform, including offset, yaw and scale.

Any state replacement, detach or invalid/queued/replaced binding cancels the
component's own pending animation. Reparented visual nodes are not deleted or
moved after ownership is lost. Completion callbacks check revision and lifetime
before emitting; they have no subsequent state mutations. Bindings can be
validated in a detached candidate before the world accepts progression.

## Acceptance and scope

Target checks: five instances sharing the same prefab resources; all four gate
states physically blocking/clearing the real player capsule; rotated routes;
open/completed reload without replay; state/callback cancellation and foreign
ownership; malformed/missing/queued/replaced bindings; unchanged global
SaveGame/dirty/input and actual primary/backup files; actual Low Forward+ route
readability without volumetrics/glow. Only new component tests are run.

Status: **PASS for the isolated components**, source
`d757a084c0773c9108f4d1fcbb95eb60bebf3dfd`; seven clean commands, 147 assertions
in headless and Forward+, four inspected Low/Medium views and unchanged actual
slot files. See `evidence/archive_route/README.md` for complete receipts and scope.
T019 integration in the historically accepted newer ArchiveMain remains open
because that source is absent in this environment. The isolated proof does not close T018/T019 or GATE-VS1, restore
missing Boot/fragment controllers, or authorize starting S03. No target-GPU,
Windows, full audio/art or release-performance acceptance is implied.
