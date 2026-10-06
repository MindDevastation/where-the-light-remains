# Wing I ceiling — preserved inputs and next source brief

Status: read-only input audit and six inspected references, not authored ceiling.
Recovery base: `4a85204c84feb1f9ef068d5fe3bb5c36bc716f87`.
ARCH-007 requires two ceiling arch/rib/vault variants. Existing five-module
sample intentionally excluded vaults; its accepted sources are not stretched or
regenerated to fill this requirement.

## Current measured boundary

| Input | Preserved value |
|---|---|
| Floor footprint | 10 x 12 m; X=[-5,5], Z=[-27,-15], top Y=0 |
| Room plan center | (0,0,-21) |
| Side/back/front safety guards | ground Y=0, top Y=5.5; unchanged collision |
| Authored wall span height | 4 m; existing pier cap reaches 4.12 m |
| Entrance | existing 4 m portal centered at (0,0,-15) |
| Gameplay | existing capsule, ring/focus grips, emitter, Star and Hearth poses |

These numbers come from scene resources and floor tile placement. They are
implementation constraints, not dimensions measured from perspective art.
A 4 m rib cannot be placed on the 5.5 m guard top by scaling it; the wall-to-upper
structure transition must be explicitly authored as part of the next brief.

## Current visual input

Six exact Wing I room images were recovered, verified against Git blob IDs and
pinned SHA-256 from `wing01_optics_v1.json`, and inspected individually.

| Reference filename | Git blob |
|---|---|
| `wi_002_v2_angle_a.png` | `aa725d266cdaa5528abd1a5ee4b121f5ca6ab42f` |
| `wi_002_v2_angle_b.png` | `bba1ce619c580dc931e1ff287ff057f85bb6a403` |
| `wi_002_v2_angle_c.png` | `2f5930c2642b196ee64ca7a59d15bfed9a20afec` |
| `wi_001_v2_angle_a.png` | `f5ef9b0cbfa0c757290eb2870320fadf84bc90c0` |
| `wi_001_v2_angle_b.png` | `c069fb7c0df7d25c1da482b26e8bc706acc94b46` |
| `wi_001_v2_angle_c.png` | `23fd00472de93e20e93289839e75dc067afb316b` |

The views consistently show tall upper structure, repeated vertical supports,
upper gallery/railings and a curved ribbed sky-facing dome. Key-art B/C expose
its ribs most clearly; gameplay A/B frame the vertical bays while their roof is
partly outside the crop. Perspective/detail drift supplies no exact dimensions.
The art's circular central platform does not authorize replacing the accepted
rectangular playable footprint or introducing a raised platform/stairs into S02.
Do not copy pictured faction emblems, decorative writing or additional puzzle
props; canon still defines three rings, five focus steps and ordered Star/Hearth.

## Required next construction brief

Produce two original ARCH-007 variants with fixed meter envelopes and ground/
spring/apex anchors, using the existing stone/brass/iron material families.
Resolve the 10 m transverse and 12 m longitudinal spans without stretching,
wall-top/upper support transitions, and rectangle-to-curved-roof edge coverage.
A plain low barrel vault does not follow these references. Do not invent a
mezzanine walking route, change guards, add ceiling collision through the
playable headroom, or alter controls/state in order to fit the visuals.

Record a dimensioned construction study and surface/triangle ceilings before
source modeling. Then use the approved Blender/export/LFS/retrieval pipeline,
cache-free imported geometry/anchor checks, actual capsule crossings and
Low/Medium player look-up/entrance/corner review. Only those measured assets
can close the bounded variant stage; complete ARCH-007/full room remains a
separate acceptance from this input audit.

## Current environment dependency

After workspace maintenance, Godot/Blender/graphics and existing runtime GLBs
were restored using prior pinned manifests. Read/download works; saved GH_TOKEN
and the private helper were removed. Native push reports missing credentials.
Code/evidence publication can use the authenticated GitHub connector. This
connector does not expose LFS payload upload, so new Blender/GLB publication
requires restoring a protected write credential. Do not commit raw binaries,
empty pointers or claim an upload from successful download evidence.
