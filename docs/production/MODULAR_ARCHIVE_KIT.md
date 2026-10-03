# Modular Archive kit — sample contract v1

Status: **bounded five-module sample validated, 2026-10-03 UTC; full ARCH inventory and representative target performance remain open**.
Feature: `feature/03-art-foundation/modular-archive-kit`.
Implementation base: main `c6773f203717b0058a3ec3aee4a3e26bb1190f1f`.
Original contract feature: `feature/03-art-foundation/modular-kit-contract`,
base `1a7171cb756cfc0e208312ebbf9257af634a898a`.

This defines the approved bounded reusable Archive sample and its measured
implementation. Original Blender source, five GLBs, shared-material import,
Godot wrappers, assembly/collision tests, three actual Forward+ views and
independent LFS retrieval pass. Evidence: [modular_archive_kit/README.md](evidence/modular_archive_kit/README.md).
No production gameplay world or global budget is replaced. This sample does not
complete the architecture inventory or certify physical-GPU performance.

## Visual revision 2 — current production references

Owner visual migration instruction supersedes the v1 image language below.
Technical contract v1 stays intact: dimensions, grid, anchors, UV, passage,
collision plan, sample placements, triangle/material ceilings and file ownership.
The new meshes implement this direction. The versioned JSON records visual_revision=2 and
exact blobs for A/B/C of **Generic modular observatory kit**, **Architectural
shape language sheet**, and hub **Gameplay view/ca_004**, from pack `cabe792`.
Historical source/ref metadata is retained in legacy fields and the section below.

Use the kit's lower architecture panels and shape-sheet supports: layered warm
stone portals, square stepped bases/capitals, broad readable trim. Keep stone/brass
structural sample surfaces within existing ceilings. Heavy aged timber, dark iron
brackets, crimson/navy furnishings and original celestial details form the later
bounded reusable detail family; they do not expand this five-part structural test.
Warm craft comes from proportion, layered edges, restrained aging and shared
material response, not holiday ornament. No copied faction sigils, pseudo-writing,
flowers/ivy walls/candle overload. This brief is not final full-world style acceptance.

The reference set has perspective/detail drift, not permission for three designs.
See `VISUAL_REBASELINE_V2.md` for interpretation and constraints. A front/reverse/
corner runtime review must compare the actual sample against all three current
views; the old dimension drawing remains geometry evidence only.

## Historical v1 authority and reference breakdown (SUPERSEDED visual language)

Read in precedence order: `ASTRA_WORKFLOW.md`, `THREE_D_PRODUCTION_PIPELINE.md`,
`docs/design/TECHNICAL_BASELINE.md`, `REQUIRED_ASSET_TABLE.md`, `NARRATIVE_CANON.md`,
`ASSET_INDEX.md`, then the images below. Existing Blender/export, LFS, engine and
material evidence was reviewed before this contract. Cross-stage modular design
falls under the Extra High policy; the owner's standing request to use Extra
High/highest available applies. This document does not assert a model-setting
change or that the owner has visually accepted an unbuilt sample.

The following repository images were downloaded at the baseline commit,
verified against their Git blob IDs and visually inspected:

| Reference | Observed direction | Git blob |
|---|---|---|
| `assets/concept_art/hero_props/Generic modular observatory kit.png` | 1 m grid and floor tiles, approximately 4 m supports, layered ivory walls, repeated arches and brass accents | `b9fd99c2ca63a4f38e198a10d1f3ddd40e3061f3` |
| `assets/concept_art/production_sheets/Architectural shape language sheet.png` | Vertical proportions, pointed and round arch families, symmetric supports, layered bases/capitals | `698918356a29885e727c59fc826ad858b979f916` |
| `assets/concept_art/environments/s01_observatory/Gameplay view/ca_003.png` | Large readable portal bays around an open central space; stone/brass hierarchy | `9e1bfb71e3fb82b802909e8b673c8ffb6d5142a1` |

The sample chooses the pointed arch family visible in the kit/shape sheet.
The hub's rounded portals remain a later variant. Neither image specifies an
exact construction drawing: widths, wall thickness and clearance below are
explicit sample implementation decisions. They do not fix the final rotunda's
radius, wing angles, dome, route lengths or puzzle placement. English slogans,
wing labels, banners and decorative pseudo-writing in the images are not
canonical player-facing copy and must not be reproduced.

## Five-module scope

Dimensions use Godot X/Y/Z, in meters. Runtime materials already exist in
`game/art/materials/`; only stone and aged brass are needed here.

| Module / inventory | Envelope X × Y × Z | Origin | Material surfaces | Sample triangle ceiling |
|---|---|---|---|---:|
| `wall_2m` / ARCH-004 | 2 × 4 × 0.4 | Ground, span center, wall center-plane | Stone | 1,200 |
| `wall_4m` / ARCH-004 | 4 × 4 × 0.4 | Same | Stone | 1,800 |
| `arch_4m` / ARCH-005 | 4 × 4 × 0.4 | Ground, span center, wall center-plane | Stone + brass | 4,000 |
| `floor_1m` / ARCH-006 | 1 × 0.2 × 1 | Top surface center, Y=0 | Stone | 128 |
| `pier_4m` / ARCH-009 | 0.6 × 4.12 × 0.6 | Ground, junction center | Stone + brass | 2,200 |

The pier has a nominal 4 m support height plus a 0.12 m cap; this cap covers the
wall-top junction. Its shaft must be at least 0.46 m wide in both plan axes so
it encloses the 0.4 m wall thickness at a right-angle join. One pier owns a
junction; do not stack a pier from each neighboring module.

Model restrained stepped bases, capitals, shallow framed wall panels and a
layered arch surround. These features carry the reference silhouette. Keep all
detail inside the stated envelope and out of the passage. Join static detail
by material into one mesh with at most the listed surfaces. Do not bake new
texture sets for the sample. High-frequency carving/trim atlases, windows,
railings, vaults, stairs, interactive doors, glyphs and the core orrery remain
outside this first sample. ARCH-004/005/006/009 inventory rows remain partially
fulfilled until their required variants and production gates are complete.

These ceilings bound this sample's authoring work; they are not changes to the
scene performance budget, measured results or permission to spend the full
ceiling on every part. Exceeding one requires reviewing the cause before export.

## Coordinates, snapping and junction ownership

[Machine-readable contract](modular_archive_kit_v1.json) contains exact bounds,
anchors, the arch profile and sample placements. [Dimensioned drawing](evidence/modular_kit_contract_2026-10-02.svg)
is an engineering diagram of this contract, not a screenshot of finished art.
Its source renderer is `tools/render_modular_kit_contract.py` (Python standard
library). Reproduce the SVG and analytical checks with:

```sh
python tools/render_modular_kit_contract.py --output /absolute/path/to/kit-contract.svg
```

The checked-in PNG is a visual review copy rendered with CairoSVG 2.8.2; it is
not required by the game. Actual design-check output and artifact hashes are in
`evidence/modular_kit_contract_2026-10-02.log`.

- Godot: +Y up, -Z primary front, +X horizontal wall span. Blender: +Z up,
  +Y primary front. Use the already verified glTF Y-up conversion once.
- Unit object and instance scales; no negative scales. Reverse a module with
  180-degree yaw. Structural sample placement uses 0/90/180/270-degree yaw.
- Grid lines are 1 m apart. Wall and junction origins sit on integer grid lines.
  Floor cell boundaries sit on that grid; their center origins have a 0.5 m
  phase in X and Z. This phase is intentional, not a half-meter placement grid.
- Wall/arch anchors are at X=±width/2, Y=0, Z=0. Adjacent anchors coincide within
  1 mm. Floor anchors lie at the midpoints of its four top edges.
- Wall seam planes and floor coverage stay at exact dimensions. Edge dressing
  must not change snapping. Floor bevel/grout may recede at most 2 mm below Y=0;
  the collider remains flush and continuous at Y=0.
- Straight walls butt at endpoints. At a right-angle corner, their endpoint
  anchors coincide; their volumes overlap locally inside the junction pier.
  The pier encloses the join and its cap covers the overlapping wall tops.
  Do not add coplanar trim overlays or bevel a seam into an open crack.
- Both sides of the wall and arch need valid outward-facing surfaces. Closed
  static volume and back-side visibility must not rely on disabling culling.

A 4 m bay can be replaced with two 2 m walls without moving its end anchors.
The 2 m pair may have a visible construction seam; it must not create a gap,
extra collision step or a doubled decorative support.

## Passage profile and collision

Opening: **2.4 m wide**, vertical jambs to **Y=2.0 m**, pointed crown at
**Y=3.6 m**. For half-width `a=1.2` and rise `h=1.6`, the two circle centers
are `X=±c, Y=2`, where `c=(h²-a²)/(2a)=0.4666667` and `R=a+c=1.6666667`.
The left half uses center `(+c,2)`, the right half `(-c,2)`.
Use 16 equal-angle segments per half. The lower arch edge, visual hole and
collision crown use the same sampled polyline. The brass surround is outside
that hole. The opening is static; a wing door/gate and its state logic are later
ARCH-014 work and must not be silently bundled into this module.

Collision stays in the Godot wrapper:

- Floors: a box matching the slab; top at Y=0.
- Walls: one box matching the structural envelope.
- Pier: one conservative 0.6 × 4.12 × 0.6 box. No walk route passes through it.
- Arch: two full-height jamb boxes, centered at X=±1.6, Y=2, size
  0.8 × 4 × 0.4. Above the opening, use 32 convex extruded strips between the
  sampled inner curve and Y=4. This preserves the aperture; a whole-bay box or
  one convex hull of the entire arch would block it and is forbidden.

The future physics probe is a 1.8 m total-height capsule, radius 0.35 m, feet at
Y=0. It must traverse Z=-1.5 to +1.5 in lanes X=-0.75, 0, +0.75 without a
collision stop or height discontinuity. Outer lanes have 0.10 m side margin;
the body top remains 0.20 m below the spring line. This is a conservative test
fixture, not a change to the future player controller dimensions. The diagram
and arithmetic do not substitute for an actual Godot physics test.

## Surface and export contract

Use `m_observatory_stone.tres` and `m_aged_brass.tres` as shared external Godot
resources. Blender material slot names should match these family names; the
Godot wrapper/import remap assigns the existing resources. Do not ship duplicate
embedded material copies or mutate the shared resources per instance.

Opaque sample surfaces use one UV tile per meter (1024 source texels/m with the
current maps). Preserve metric scale across 1/2/4 m pieces, orient stone upward,
and keep brass direction along the surround/support. Put unwrap cuts at
construction seams and concealed edges. Bevels need their own nonzero UV area,
valid tangents and outward normals. This density is local to the sample and may
be revised with the actual viewing-distance review; it is not a project-wide
texture or memory budget. No unique lightmap/trim requirement is introduced.

Planned files, **not present yet**:

- Source: `assets/3d/blender/archive_kit/archive_kit_sample.blend`, with one named
  collection per module and source-only guides excluded from export.
- Five GLBs: `game/art/meshes/archive_kit/<stem>.glb`, with `stem` values in JSON.
- Five script-free wrappers: `game/worlds/archive/modules/archive_<id>.tscn`.
  Each has an identity Node3D root, imported visual child, separate StaticBody3D
  and authored shapes, plus Marker3D connection anchors.
- Isolated assembly: `game/tests/fixtures/archive_kit_sample.tscn`.
  It is not automatically instanced by GameRoot or ArchiveMain.

Save the original Blender source, apply required transforms, export selected
static meshes with meter scale/normals/tangents/UVs, and verify source reopen and
Godot import against this contract. The .blend and five GLBs use LFS. Record
payload hashes/sizes, upload actual objects, retrieve into an independent LFS
store and validate retrieved files before integration, following `LFS_POLICY.md`.

## Assembly and acceptance sequence

The first assembly is a **14 × 4 m open review pad**, with 56 one-meter slabs.
At Z=0 place 4 m wall / arch / 4 m wall, centered at X=-4/0/+4. Four piers sit at
X=-6/-2/+2/+6. This is 63 module instances and tests reuse and passage across the
same floor level. The pad extends beyond the 12 m structural span so the outer piers remain fully supported. It is not a proposed hub room, corridor or level route.

Also test replacement of the left wall with two 2 m pieces and a separate
right-angle junction. Repeat anchor checks after 90/180/270-degree rotation.
The maximum triangle sum from the ceilings is 23,568 for the primary pad and
24,168 after the wall substitution. This arithmetic is not measured mesh data.
There are at most 68 authored material surfaces in the primary assembly before
renderer culling/batching/shadow passes; actual draw calls must be captured.

Production order and gates:

1. Restore the verified Blender and graphical tools if missing. Run the minimal
   Blender CLI/export probe and authenticated Xvfb TCP engine smoke first.
2. Author these five parts with the existing material library. Reopen the saved
   source and inspect dimensions, transforms, topology, UVs and material slots.
3. Export, import and validate real Godot AABBs/anchors/orientation/normals/UVs,
   material resource reuse and the declared triangle/surface ceilings.
4. Build the wrappers and assembly. Test floor continuity, wall replacement,
   corner coverage, solid blockers, and all three capsule traversal lanes.
5. Capture front, reverse and corner/close views in actual Forward+; inspect
   silhouettes, seams, culling, shadows, material density and passage clearance.
   A proxy or headless-only result cannot pass this visual gate.
6. Verify actual LFS upload and independent retrieval; rerun source/import checks
   on the retrieved payloads and retain exact commands/stdout/stderr/hashes.
7. Record actual sample counters and pass the existing project startup smoke.
   Target-class representative scene profiling remains a separate gate before
   bulk production, with no FPS claim from software Vulkan.

The seven bounded sample steps now PASS with actual evidence. The source and
five exports were uploaded from `1e3adf1a500c9fbf7a5ad1497588e7df1dd1015b` and independently
retrieved into an empty separate LFS store; retrieved source/import/physics and
graphical startup pass, as do Git/LFS fsck. Measured primary assembly: 4,284
triangles / 68 authored surfaces / 63 instances; substituted walls: 4,288.
Front/reverse/corner preview draw calls: 25/27/18 under software Vulkan.
Full ARCH inventory, owner full-world art review and target performance remain
open. Next: Wing I hero mechanism brief/sample, then the representative vertical
slice under the established plan. Do not begin bulk modeling from this sample.
