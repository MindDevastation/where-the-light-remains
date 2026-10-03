# Wing I optical articulation sample

Status: **PASS for the bounded S02-001/S02-003 mechanical carrier**. Full S02
inventory/gameplay and physical-GPU performance remain open. Actual acceptance:
[`evidence/wing01_optics/README.md`](evidence/wing01_optics/README.md).

## Authority and scope

`NARRATIVE_CANON.md`, `REQUIRED_ASSET_TABLE.md` S02-001/S02-003 and the
current v2 Heat-Light references control this sample. Three concentric optical
rings precede emitter/star alignment, the five-position focus wheel and Hearth
activation; Star precedes Hearth. The v2 crystal silhouette cannot replace the
three rings or the sequence. This feature supplies the mechanical carriers for
S02-001 and S02-003. Emitter/target, optical response, Hearth bowl, fragments,
solution conditions, save data and a playable Wing I remain separate work.

The checked repository does not supply exact solve angles, ring detent counts,
focus distances or fragment presentation copy. Test poses are engineering
checks, not a puzzle solution. Five equally spaced wheel positions demonstrate
the specified count; they do not assign canonical focal distances. No invented
glyphs, solution hints, narration or shipping controls are added.

## Visual direction and dimensions

Use the A/B/C Heat-Light hero shapes for a substantial brass optical apparatus
on a stepped stone plinth, walnut supports and dark iron fittings. Room views
provide material context only. Original geometry, shared materials and visible
negative space separate three coaxial vertical rings. A fourth decorative ring
is prohibited. Plain asymmetric grip hardware makes each moving ring visible.
The five focus stops are raised hardware markers on the fixed frame.

Godot meters, +Y up, front -Z. Ground-center assembly origin. Ring joint center
is (0, 1.72, 0), axis local +Z; outer/middle/inner radii .89/.70/.51 m, radial
width .07 m. Grip centers and the focus joint are pinned in the JSON contract.
The base is 1.92 m wide, .98 m deep; side supports reach 1.88 m. The assembled
ring crown reaches 2.645 m. Focus wheel radius .19 m, axis local +Z, joint
(.68, .59, -.56). The .19 m wheel radius is its rim centerline; outside rim
radius is .2175 m. The sample is a freestanding mechanism, not a room layout.

## Ownership and export

`wing01_optics_v1.json` is the versioned local contract. One editable source
under `assets/3d/blender/wing01/`, five separate GLBs under
`game/art/meshes/wing01/`, one script-free wrapper under
`game/gameplay/puzzles/wing01/` and isolated CLI tests. Fixed frame and four
independent movable meshes. Blender source objects are assembled at deliberate
joint origins; unit scale/zero rotation. Selected GLBs export each joint at
identity; the Godot wrapper owns placement. This deliberate translation is the
pipeline's rig/export exception, not unapplied scale or arbitrary mesh offsets.

Closed original solids with beveled edges; no mesh-derived collisions, new
textures, shaders or animations. UV1: one UV unit/meter with existing 1K maps.
Four existing materials: stone, aged brass, dark walnut and dark iron. Materials
remap to the exact shared Godot resources; no per-instance duplication.
Local ceilings: frame 4,500 triangles, each ring 2,200, focus 1,500;
assembly 12,600. These ceilings do not change global performance budgets.

Three simple fixed blocking boxes cover the base/supports. Four moving grip
Area3D spheres on sample layer 2 demonstrate correct picking and joint following;
the project's interaction-layer/controller contract is not assigned here.
Neither wrapper nor art resources contain behavior. Runtime tests rotate one
joint at a time, preserving all others, and inspect actual physics ray hits.

## Acceptance sequence

1. Existing docs/evidence, authenticated Git/LFS origin and safe refs; disk >4 GiB.
2. Disposable Blender source/export and authenticated TCP X11/Vulkan Forward+.
3. Reopen actual source: joints, unit transforms, closed topology, UVs/normals/
   tangents; exported identity nodes, meter scale, geometry/material ceilings.
4. Godot import: external material identity, three-ring radial gaps, four
   independent pivots, moving grip picking, five distinct focus poses, blocking
   collision and no error output; GameRoot/core contracts unchanged.
5. Three real 1920×1080 Forward+ images, each part's framebuffer contribution
   and articulation frame changes, manual image inspection. Software renderer
   verifies presentation, not GTX1060-class performance.
6. Real LFS upload then independent shallow clone with empty LFS store/no
   alternates, hash-checked ordinary Git hydration, six exact payload hashes,
   reopened retrieved source, Godot import/physics/startup and Git/LFS fsck.
7. Only accepted results update status and merge feature → epic → main.

Do not begin bulk mechanisms or claim full S02 inventory approval from this
carrier. Target-hardware profiling and canonical puzzle/controller requirements
retain their separate gates.
