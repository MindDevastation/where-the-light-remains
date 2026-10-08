# S01 core — corrected mount brief and access proof, 2026-10-08

Status: STABLE_BRIEF_ONLY. Current authoring contract is
`core_orbits_mount_revision2.json`. This supersedes only the straight outer bridge
route in the2026-10-07 proposal. Previous source/trim proofs remain byte-current;
no old result is assigned a new test credit. No production mesh, gameplay scene,
collider, material, inventory acceptance or LFS payload is added.

The original upper straight bridge from pivot(0,1.8,0) to outer anchor approaches
the third orbit's centre line within6.72mm. With the specified20mm ring and20mm
bridge support radii, their conservative envelopes intersect by about33.28mm.
The earlier control/envelope bounds remain true, but did not check internal
mount-to-orbit clearance. This is a pre-modeling design risk, not proof of an
intersection in authored meshes that do not exist yet. Original brief/evidence
is retained as historical v1; use this revision for new assembly authoring.

## Current construction contract

All prior orbit radii .58/.46/.34m, native YXZ orientations, pivot, shared yaw,
materials, UV1024px/m,6000tri ceiling and6surface target are retained. Spindle
radius≤.055m atY1.39–1.8 and collar radius≤.19m atY1.39–1.44 are retained.
Keep entire upper bridge support aboveY1.78;20mm support bounds are mandatory.

| Bridge | Centre-line route before shared parent yaw, world metres |
| --- | --- |
| Outer | (0,1.8,0) → **(0,2.15,0)** → (.149115,2.295474,−.262050) |
| Inner | (0,1.8,0) → (−.220232,2.067328,.302711) |
| Third | (0,1.8,0) → (.113767,2.119805,−.019544) |

Central supports deliberately join the same hub; terminal joins are confined to
60mm centre-line neighborhoods around their own ring anchors. These are permitted
connections, not additional moving parts. Nonconnected ring/bridge envelopes must
remain≥20mm apart. The corrected minimum lower bound is56.66mm, outer bridge to
third orbit. Own-ring clearance outside its intended terminal joint stays positive
(minimum≈19.5mm);ring-to-ring lower bound≥80mm follows the reverse triangle
inequality from concentric radii minus two20mm supports. The shared parent yaw is
an isometry, so assembly internal gaps hold at every yaw, not only one pose.
Do not add independent rotation or spokes below the fixed upper support slab.

## Fresh measured evidence

`evidence/archive_reconstruction/core-mount-access-20261008-final2/results.json`
records **135 final native assertions** in official Godot4.7.2. The fixture uses
actual native default YXZ bases;8192 angular samples minus radius*pi/N Lipschitz
allowance plus10µm numerical reserve bounds continuous circle-to-segment gaps.
For the clipped own-ring domain outside the joint neighborhood, use a full
2*pi*radius/N sample-step reserve at the boundary, not the half-step reserve
that applies to an unclipped complete circle.
Own terminal-joint exclusions and the original problematic support approach are
checked explicitly. New exact source hashes and all retained game files are
protected by the associated readiness seal. Retained attempt1 failed before
loading the fixture because a surviving executable was truncated;verified raw
atomic re-extraction from the existing official ZIP resolved it. Passing132-check
attempt2 is superseded by135 final checks and excluded from final credit.
The initial135-check final fixture is also retained as superseded: final2
strengthens the clipped-domain boundary reserve without weakening any gap check.
Only final2's135 executions count as current final native proof.

Twenty reconstructed native queries cover five outward approach offsets
(−30/−15/0/+15/+30degrees) for each Panel/Lens/Socket/Lever. They use measured
actual Area3D/CoreBody shapes/layers, source player mask3/reach2.5, cameraY1.62
and capsule radius.35. Native PhysicsRayQueryParameters3D flags match the player;
actual unchanged InteractionTarget availability is checked enabled/disabled.
The fixture treats each hypothetical onboarding step as enabled independently;
it does not run the onboarding sequence. Native query identities all match.
Camera/feet/hit coordinates and measured ranges are retained in native.json.

Every proposed orbit/collar/spindle/bridge support fits a .601m sphere around
the unchanged pivot. For these20 actual hit-ray segments, clearance from this
continuous-yaw visual enclosure is≥508mm;standpoint capsule/CoreBody radial
clearance≥261mm;longest native hit distance≤670mm,within existing2.5m reach.
This proves envelope visibility for these selected approaches at every yaw.
It does not test all viewpoints, the imported mesh silhouettes, mouse/E delivery,
actual FirstPersonPlayer, ArchiveMain, pause/awakening, progression/save/quiet
reload, materials/light/readability, performance or target GPU.

`mount_revision2_metric.png` / .svg were inspected as metric diagrams, not native
shipping frames. Render script is reusable and derives lines/routes from the
exact native result. Fresh native graphical frames this block:0. Prior trim128
executions/8 frames and material300/24 remain historical accepted source evidence.

## Next integration dependency and work

The execution environment still has no GH_TOKEN/GITHUB_TOKEN/GIT_ASKPASS,
credential helper or available Blender;ordinary Git Data publication works.
Configure an authenticated GitHub credential helper supporting private git-lfs
upload in this environment. Do not place credentials in command arguments,
Git remotes, repository files or evidence;do not reuse historical token text.
Restore pinned Blender4.5.14 from the verified project toolchain handoff once
LFS can independently upload/retrieve .blend/.glb. Publication permission is
already granted;this is a missing capability, not an approval request.

Author the existing RoomPortal6cm UV sibling or the bounded three-orbit assembly
using this corrected mount route. Preserve accepted source families, origin,
controls, lights, clocks, routes and primary saves. Independently retrieve/reopen
editable source/export, validate actual bevels/UV/tangents/budgets and native
Low/Medium paired scene views, actual E/ray/control/pause/awakening, S01→S02→Hub
and private physical save/quiet reload before bounded runtime acceptance.

Inventory stays26 ACCEPTED/44 PARTIAL/7 MISSING among77;185 rows unchanged.
TRIM-002/hero remain PARTIAL. Integrated runtime STABLE5184c48 and trim source
STABLEce45bad remain unchanged. ARCH-011 owner A/B pending;GATE-VS1 OPEN/S03 blocked.
