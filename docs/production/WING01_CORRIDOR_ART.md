# Wing I corridor — bounded approved-kit presentation

The actual ArchiveMain now instances the previously accepted v2 structural kit:
four 4 m wall bays, two shared seam piers and one room entrance portal. This is
ordinary placement under `MODULAR_ARCHIVE_KIT.md`; module sources, export
pipeline, shared materials, dimensions, grid and budgets are unchanged.

| Part | Positions X/Y/Z, meters | Yaw | Scale |
| --- | --- | ---: | --- |
| Left wall bays | (-2, 0, -10), (-2, 0, -14) | 90° | 1 |
| Right wall bays | (2, 0, -10), (2, 0, -14) | 270° | 1 |
| Seam piers | (-2, 0, -12), (2, 0, -12) | 0° | 1 |
| Room portal | (0, 0, -15) | 0° | 1 |

The two graybox corridor wall meshes are hidden. Their original higher safety
colliders and existing floor remain; kit wrappers retain their approved solid
walls/piers and capsule-safe arch. The centerline still connects the real Wing I
gate to the existing room, without progression, interaction or save changes.

`evidence/archive_reconstruction/corridor-art-headless-1/` passes clean import,
39 new assertions using the actual 0.35 m radius / 1.8 m player capsule and
101 relevant Archive state/safe-spawn regressions. The player moves through the
portal into the room and back; a seam pier blocks lateral escape. All three
commands preserve two physically existing save fixtures exactly; no runtime
errors/warnings and the private cache-free copy is removed.

Native capture family `corridor-art-native-3/` passes Low/Medium with six actual
player views and protected slot hashes. Failed 1/2 fixtures and their original
source are retained; the test now registers the same S02 IN_PLACE profile as
Boot and uses the existing explicit resume API. No runtime routing change.

Those six views exposed black stone faces away from directional moonlight.
`corridor-ambient-native-1/` resolves this local resource defect: Archive has no
Sky, but selected AMBIENT_SOURCE_SKY (3). It now selects AMBIENT_SOURCE_COLOR (2),
using the existing configured color/energy without changing lighting budgets,
materials or geometry. Cache-free import, Low/Medium captures and protected
physical save hashes pass; all six new views were inspected and stone faces
are readable. `visual_review.json` retains the exact before/after diagnostic.
This is a bounded lighting correction, not authored color or full art acceptance.
The floor now uses 28 approved 1 m instances: X=-1.5/-0.5/0.5/1.5,
Z=-8.5 through -14.5, Y=0. The original corridor slab remains solid and its
coplanar primitive skin is hidden. Shared unit modules retain the prescribed
cell-center phase. `corridor-floor-headless-2/` passes 45 corridor assertions
plus 101 Archive regressions with existing slots unchanged. Seam rays exclude
both old fallback floors; the actual shipping capsule walks both ways with
both disabled only in the private test world. Earlier failed/diagnostic families
retain the fixture's unintended radius-10 Hub floor overlap.

`corridor-floor-native-1/` passes runtime/capture checks, but six inspected
views show coplanar Hub skin interfering with tiles at the entrance:
NEEDS_HUB_SKIN_OVERLAP_FIX. This intermediate floor placement is a WIP checkpoint.
That finding is resolved in `corridor-hub-cutout-native-1/`: a local graybox
floor shader removes only the overlapping visual strip X=[-2,2], Z<=-8. It
retains the old color/roughness, the shared Stone resource and the unchanged
radius-10 Hub collider. No depth offset, floor step or kit asset edit is used.
Four views per preset now include the Hub threshold; all eight were inspected
and the dark jagged overlap patches are gone. The fixture explicitly opens the
already eligible gate without persistence. Cache-free import/native rendering,
protected save hashes and 45 actual-capsule checks pass. This completes the
bounded corridor placement/overlap correction, not full scene acceptance.
Next: reuse approved wall bays/piers on the room's existing side/back spans,
retain its old safety guards and verify puzzle approach/return clearance.
Full room/observatory
art, emitter/Hearth authoring, S00 note/motif selection, scene mix and physical
GTX 1060 profiling remain open. No full GATE-VS1 acceptance is implied.
