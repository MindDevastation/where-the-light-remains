# Wing I ceiling — isolated dimensioned construction sample

Status: construction sample in progress; not instanced by ArchiveMain.
This follows WING01_CEILING_INPUTS.md and ARCH-007's two upper rib variants.
The six pinned Wing I v2 views and Architectural shape language sheet v2 B were
inspected. They establish curved dark ribs, restrained brass and pale stone;
they do not supply meter dimensions. The following dimensions are explicitly
local design choices for an isolated study, not measurements from concept art.

## Fixed meter envelope before source modeling

The accepted floor remains X=[-5,5], Z=[-27,-15]. A new identity assembly uses
origin (0,4,-21); nothing scales accepted models. Two original crossed elliptical
ribs have support-center spans 10 m / 12 m. Rotate only the 12 m variant by 90
 degrees about Y. Both spring centerlines are Y=5.5 globally; their crown joint
is Y=9.5. Local ellipse centerline: (a*cos(t), 1.5+4*sin(t), 0), a=5 or 6.
Each side has 32 segments, a 0.24 m iron section and a 0.02 m brass inlay.
The halves terminate inside a common 0.6 m crown collar to prevent coincident
crossing surfaces. Crown anchors are connection coordinates, not mesh extrema.

| Part | Local bounds min / max | Triangle ceiling | Surfaces |
|---|---|---:|---:|
| 10 m rib with original upper stone feet | (-5.3,0,-.3) / (5.3,5.62,.3) | 2600 | 3 |
| 12 m rib with original upper stone feet | (-6.3,0,-.3) / (6.3,5.62,.3) | 2600 | 3 |
| Rectangular transition + elliptical spring belt + shared crown collar | (-5.2,0,-6.2) / (5.2,5.64,6.2) | 6000 | 3 |

The upper feet start at the existing 4 m wall/portal top and reach the 5.5 m
spring. New perimeter panels cover Y=4..5.5, overlapping existing 4.12 m pier
caps by 0.12 m; no old asset is stretched. Thin horizontal corner spandrels close
the area between the 10x12 rectangle and a 5x6 half-axis ellipse at Y=5.5.
Include exact corner ray angles in the polygonal ellipse boundary, so its outer
edge reaches all four rectangular corners. The spring belt center is Y=5.43, 0.07 m below the spring anchors; its lower
face clears the stone underside to avoid coplanar rendering. This is edge coverage only: the
curved roof panes, intermediate meridian ribs, upper gallery and sky treatment
remain open. The two crossed ribs are not a finished closed dome.

Foot/left/right/spring/crown markers, bounds, source topology, metric UVs,
external shared materials and unit transforms must be checked on reopened
source and actual imported resources. No collision, lights, scripts, transparent
materials, new shaders, inscriptions or extra puzzle objects are exported.
The maximum added sample cost is 11200 triangles / 9 surfaces; it does not
change global budgets and is not a measured count.

## Acceptance boundary

Author one editable Blender source and three GLBs using the verified helper
geometry/export pipeline. Upload real LFS payloads and retrieve exact hashes
from an independent initially empty store before acceptance. Review the study
in an isolated fixture containing the existing room, using the shipping player
capsule for entrance/corner/puzzle approaches and actual Low/Medium look-up,
entrance and corner captures. Preserve physical save slots and old source IDs.
A technical sample PASS does not approve full-room art, roof weather sealing,
ARCH-007 integration, gallery routes or target-hardware performance. Integrate
only after the sample's visual/dimensional fit is reviewed and remaining dome
coverage is resolved. Keep the shipping world unchanged in this stage.
