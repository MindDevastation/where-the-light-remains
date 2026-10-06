# Wing I room — bounded side/back and floor placement

This step reuses the accepted modular kit in the existing 10 x 12 m graybox
room. There is no new source mesh, export pipeline, shared material, lighting
budget, puzzle layout or progression rule. It is not full room art acceptance.

| Part | Positions X/Y/Z, meters | Yaw | Scale |
| --- | --- | ---: | ---: |
| Left 4 m wall bays | (-5, 0, -17/-21/-25) | 90° | 1 |
| Right 4 m wall bays | (5, 0, -17/-21/-25) | 270° | 1 |
| Back bays, 4/2/4 m | (-3/0/3, 0, -27) | 0° | 1 |
| Side/corner piers | (-5/5, 0, -15/-19/-23/-27) | 0° | 1 |
| Back seam piers | (-1/1, 0, -27) | 0° | 1 |
| 120 floor tiles | X=-4.5 through 4.5, Z=-15.5 through -26.5, Y=0; 1 m spacing | 0° | 1 |

Exactly one pier owns each junction. Old side/back skins are hidden, while
their higher 5.5 m safety colliders remain. Front skins and ceiling,
emitter/Hearth authoring and other production variants remain unfinished.

`evidence/archive_reconstruction/room-wall-headless-1/` passes cache-free import,
19 actual shipping-capsule checks and 101 Archive state regressions. Both
Star/Hearth spawns and all four real grip approaches are unobstructed; kit
colliders stop escape at both sides and the back. Existing physical primary/
backup fixtures remain unchanged. Puzzle and five-route bindings are intact.

`room-wall-s02-regression-1/` separately passes 60 actual S02 assertions in
test-owned slots: real E/grip controls, ordered fragments, actual disk obstacle/
retry/primary/backup, quiet reload and grounded return through the corridor to
Hub. Both private projects are removed and logs contain no errors/warnings.

`room-wall-native-1/` passes cache-free import, Low/Medium Forward+ and unchanged
existing physical slot hashes. All six actual player images were inspected:
stone wall faces and the corner/junction are readable, and the existing cold
blue/warm Hearth lighting remains visibly distinct. The warm image applies
only the validated local quiet presentation projection, without changing
GameState/dirty state or saving; the separate 60-check suite verifies real
persisted progression. Private Godot/Xvfb/project resources close afterward.

Reproduce only this affected view family with
`tools/validate_corridor_presentation.py --scope room` and the documented Godot/
graphics-prefix arguments. Native graphics use software llvmpipe, not a target
GPU profile. This accepts bounded placement, not full VS1 art.

`room-floor-headless-1/` now passes 27 room assertions plus 101 Archive checks.
The approved unit tiles cover exactly the old 10 x 12 m slab at Y=0; its solid
fallback remains and only its skin is hidden. Isolated seam rays exclude all
non-tile bodies. The actual player lands and walks both directions across row
and column seams with the fallback disabled only in the private test. Spawns,
all four grip approaches and wall stopping remain valid. Existing physical
primary/backup hashes are unchanged. The separately test-owned 60-check S02
suite passes again in `room-floor-s02-regression-1/` after this collision change.

`room-floor-native-1/` passes clean import and Low/Medium; six images were
inspected. Floor texture/joins and existing cold/warm response remain readable,
without observed overlap patches. Per captured frame: cold overview 24 draw
calls, corner 5, warm overview 26; texture counters 22,533,120 bytes Low and
26,127,360 Medium. These software-renderer counters are diagnostics, not a
representative timing/target-hardware profile. No source mesh/material was edited.

Next: inspect approved front-wall/ceiling/emitter/Hearth inputs and the remaining
module variants against the preserved layout before starting their art block.
Front/ceiling,
full emitter/Hearth art, authored audio/mix and target GPU remain open.

## Entrance junction closure — 2026-10-05

Two approved, unit-scale 4 m piers now own the junctions at (-2, 0, -15)
and (2, 0, -15), one owner each. Temporary front skins move only 0.15 m
in Z to align with the portal; both original 3 x 5.5 x 0.3 m safety guards
stay at their original positions and remain visible/collidable. No wall
source/export, room width, portal collider or puzzle binding changes.

`room-entrance-headless-1/` passes clean import, 39 room assertions and
45 corridor assertions. This includes six real capsule crossings in both
directions, independent pier-blocker rays, original front-guard dimensions,
unit-scale/on-grid ownership, floor seams, spawns and grip approaches. Existing
primary/backup fixture hashes stay unchanged; the private project is removed.

`room-entrance-native-2/` passes clean import and four actual Forward+ player
captures (front/reverse on Low/Medium), with unchanged physical slot hashes.
All four images are inspected; the portal/junction alignment and stone/floor
are readable. Front skins, ceiling and distant graybox boundaries remain
unfinished. `visual_review.json` seals the inspected captures. Family 1 retains
the missing environment xkbcomp-link failure; the documented link was restored
without changing the runner, and family 2 passed. Software Vulkan is not
target-GPU or complete room/VS1 acceptance.

The affected actual S02 progression/collision regression is recorded separately
in `room-entrance-s02-regression-1/`, using only test-owned save slots.


## Third-size front walls — 2026-10-05

Both fronts now reuse the new script-free `archive_wall_3m.tscn` at
(-3.5,0,-15)/(3.5,0,-15), yaw 0 and scale 1. Its centered odd-width pivot has X
phase 0.5; endpoint anchors meet existing integer piers. Only its 3 m variant
uses this phase. The original five-module contract and accepted binaries remain
unchanged. The higher front guards stay solid, with only their skins hidden.

Editable Blender source and exported GLB pass 212 triangles/one Stone surface,
closed positive volume, exact meter envelope, UV density and unit normals/
tangents. Both new objects were uploaded to LFS and downloaded from an independent
shallow Git clone with an initially empty LFS store; hashes/sizes and reopened
retrieved source pass. New imported geometry checks and actual capsule stopping
with fallback fronts disabled pass, alongside six entrance crossings.

`front-wall-headless-1` passes 49 room + 45 corridor assertions;
`front-wall-s02-regression-1` passes 60 real controls/save/reload/return + 17 entry/
safe-Exit assertions and normal startup. `front-wall-native-1` contains eight
inspected Low/Medium views: front/reverse entrance and close views of both spans.
Stone faces, trim and junctions remain readable. Read-only fixture save hashes
are unchanged. Open ceiling/unfinished Hub, full art acceptance, authored audio
and target GPU remain separate. See the exact-source aggregate acceptance receipt.

## Hearth bowl and emitter housing — 2026-10-05

The previous primitives now have original Blender-derived static models:
1208-triangle hollow brass Hearth bowl/stone pedestal and 1204-triangle brass,
iron and recessed-glass emitter. Script-free wrappers reuse shared materials.
Original collider, poses, optical axis, controls, flame, beams and state bindings
stay intact. Actual LFS upload, empty-store independent retrieval and reopened
retrieved source pass. See `WING01_HEARTH_EMITTER.md`.

145 assertions (19 model/integration, 49 room, 60 S02, 17 shipping entry), normal
startup and ten inspected Low/Medium captures pass. First close views required
camera-only framing corrections; their original evidence remains retained.
`hearth-emitter-acceptance-1` audits those two independent fixture-file changes
against the new native proof without claiming the earlier headless runs used
these revised cameras. All shipping geometry/physics/control hashes match.

Ceiling/ribs and final beam/Star/Flame VFX, full room art/VS1, authored audio and
physical target-GPU acceptance remain open. Existing front/entrance asset proofs
remain valid; they were not regenerated for this block.

## Local Hearth Flame — 2026-10-06

The old sphere is replaced by an opaque three-tongue Godot VFX scene, one shared
80-triangle mesh repeated three times, using the unchanged emissive gold family.
No new Blender/LFS payload or shared material mutation. Root path/pose,
colliders and progression are intact; visibility remains owned by ArchiveMain.
Cold/hidden resets and stops processing; pause freezes local phase. Explicit
scene dependencies/children clear the warning from threaded route loading.

161 assertions and normal startup pass without warnings, and ten actual
Low/Medium player views were inspected. Intermediate envelope/pause/load-warning
failures and a warning-free old-scene comparison remain in evidence. Exact
current acceptance: `hearth-flame-acceptance-1`. See `WING01_HEARTH_FLAME.md`.
Ceiling inputs: `WING01_CEILING_INPUTS.md` / `ceiling-inputs-1`; input audit only,
no authored roof or completed ARCH-007. Beam/Star/full room/audio/GPU remain open.
