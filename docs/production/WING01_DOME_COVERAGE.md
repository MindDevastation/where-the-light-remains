# Wing I dome coverage — dimensioned isolated candidate

Status: pre-authoring brief, not accepted or shipping.
Continue the accepted ceiling rib/transition sample without regenerating its
source or three exports. Six pinned Wing I v2 views were individually inspected
again in this session. They establish curved dark metal ribs, fine brass,
sky-facing glazing and deep cobalt exterior against amber practicals. They do
not determine exact meter dimensions. Numbers below are explicit local design
choices constrained by the accepted 10x12 m room, not perspective measurements.
No emblems, writing, new puzzle symbols, platforms or gallery walking routes
are inferred from the images. Original three rings/five focus steps and ordered
Star/Hearth mechanics remain authoritative.

## Envelope resolved before modeling

Assembly origin remains (0,4,-21), unit scale. Existing 5x6 m ellipse half axes,
local 1.5 m spring/global 5.5 m, and local 5.5 m crown/global 9.5 m are fixed.
Existing two cardinal ribs, stone transition and crown collar stay unchanged.
Add twelve half-meridian members at the remaining positions of a sixteen-ray
ellipse (22.5 degree spacing). They follow (5*cos(phi)*cos(t),1.5+4*sin(t),
6*sin(phi)*cos(t)); thirty-two segments from spring to the collar. Stop at
0.25 m horizontal distance from the crown, within the existing 0.6 m collar.
Their 0.16 m forged-iron section is narrower than the 0.24 m primary ribs;
a 0.012 m brass strip faces the room. Three slender closed latitude ties follow
t=0.31/0.70/1.10 radians, sixty-four segments. Contacts overlap as joined beams;
no coincident broad coplanar metal layers.

A single connected closed thin glass shell sits outside the members: inner
half axes 5.10/6.10 m, outer 5.12/6.12 m, inner/outer rise 4.10/4.12 m, base
local Y=1.50. It has forty-eight longitude segments and twenty-four latitude
bands, one vertex per pole and a sealed bottom rim. Closed editable volume
supplies only its interior face to the player through default backface culling.
The continuous shell uses smooth shading normals. The first flat-normal native
candidate reflected the existing practical as a conspicuous checker grid and
is rejected for visual acceptance; its captures/logs remain in dome-native-1.
Reuse the existing shared clear-glass resource without mutating it. No stack
of individually overlapping transparent panes, glass lights or new refraction
policy. Actual sorting/refraction and clue readability remain acceptance checks.

Local outside backing: a closed opaque shell, inner axes 5.45/6.45 m, outer
5.47/6.47 m, inner/outer rise 4.50/4.52 m, base Y=1.48. Its material is a reusable
bounded Archive night backing, because the existing stone/metal/glass families
cannot express a night sky. One simple unshaded shader uses local position for
a static cobalt gradient and sparse deterministic stars, with no textures,
particles, time animation, emission/light/shadows or constellations/clue marks.
This avoids changing the shared world environment or ambient light across
other Archive rooms. Glass and night shell do not cast shadows; frame retains
normal opaque shadow behavior. No new lights, collision, scripts or behaviors.

| New original part | Local min / max envelope | Triangle ceiling | Surfaces |
|---|---|---:|---:|
| Additional members + latitude ties | (-5.13,1.37,-6.13) / (5.13,5.63,6.13) | 12000 | 2 |
| Connected curved glazing | (-5.12,1.50,-6.12) / (5.12,5.62,6.12) | 4800 | 1 |
| Local night backing | (-5.47,1.48,-6.47) / (5.47,6.00,6.47) | 4800 | 1 |

Maximum new geometry 21600 triangles / four surfaces, plus the existing 6824 /
nine. These are ceilings, not measured counts. No global budget is increased.
Source and runtime use meter UVs, finite unit normals/tangents, identity object
transforms and a common wall-top pivot. No exported camera/light/animation/image.
The machine-readable matching contract is `wing01_dome_coverage.json`.

## Verification and next step

One new editable Blender source and three GLBs, forward-only LFS. Check reopened
closed geometry, actual interior ray coverage, frame locations, separate outer
sky, nondegenerate UVs and material mapping. Cache-free Godot import must verify
real arrays/bounds/material references, anchors, rays against imported meshes,
unchanged shipping capsule passage and puzzle approaches, quiet state/save
preservation. Inspect native Low/Medium look-up, entrance, corner, reverse and
actual hero/clue views; measure draw calls/textures and glass transparency scope.
Upload actual payloads and retrieve exact current pointers into an independently
empty LFS store, reopen retrieved source and import/use retrieved exports.

This candidate is isolated until dimensional/visual fit is assessed. Technical
sample approval cannot close full ARCH-007/world art/VS1, upper gallery/books,
audio or physical GTX1060 performance. Once its bounded checks pass, checkpoint
immediately and begin a separately validated room integration stage. Existing
wall guards and gameplay are retained. No S03 or bulk production acceptance.
