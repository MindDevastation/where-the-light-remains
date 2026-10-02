# Shared material library

Scope: the six-family Art Foundation baseline. These are reusable runtime
resources, separate from the earlier capability-only specimens.
Full inventory acceptance, representative scene performance and crystal quality
tiers remain open; this slice does not mark every MAT requirement complete.

## Resources

All paths below are relative to `game/art/materials/`.

| Inventory | Resource | Baseline behavior |
|---|---|---|
| MAT-004 | `m_observatory_stone.tres` | Pale warm stone, subtle pores/veins, rough dielectric |
| MAT-001 | `m_aged_brass.tres` | Warm metal with smooth aging, brushed detail and varied roughness |
| MAT-003 | `m_dark_walnut.tres` | Dark brown grain, polished surface and restrained clearcoat |
| MAT-007 | `m_memory_glass.tres` | Cool frosted substrate, fine normal/roughness maps, screen-space refraction |
| MAT-008 | `m_crystal_glass.tres` | Blue/violet glass, clearer refraction, rim and weak emission |
| MAT-014 | `m_archive_emissive_gold.tres` | Warm gold emission; glow supplied by the scene environment |

Each family is one shared `StandardMaterial3D` resource. The opaque families
have one tileable surface set each, not multiple unique prop textures.
No project-wide custom shader or quality policy is introduced.

## Source and import contract

Visual reference: `assets/concept_art/production_sheets/Material sheet.png`,
Git blob `9a6ae67867c22527c3981b71b20b0c74e022df7e`. The sheet was inspected;
its pixels are not copied into these assets. Carving, ornament, model silhouette
and final lighting belong to the corresponding asset/scene work.

`tools/generate_material_maps.py` authors original analytic/seeded periodic maps.
It is the editable source; no third-party texture pack or additional asset
license is involved. Reproduction dependencies: Python 3.11+, NumPy 2.3.5,
Pillow 12.3.0. From the repository root:

```sh
python tools/generate_material_maps.py
```

The eleven 1024x1024 PNGs and SHA-256/provenance/edge metrics are in
`game/art/textures/material_library/texture_manifest.json`. PNGs use ordinary
Git under the forward-only LFS policy. The generator publishes each PNG
atomically so interrupted encoding does not replace a complete map.

Opaque sets contain albedo, tangent-space +Y normal and packed ORM maps:
R=1 (reserved AO, not sampled), G=roughness, B=metallic. Stone/wood are
dielectrics; brass samples metallic from B. Glass adds two maps: normal and
roughness. Godot import settings are tracked: VRAM compression, mipmaps,
explicit normal-map import, and anisotropic mipmapped material filtering.
Brass albedo/ORM use high-quality compression to preserve smooth transitions.
Albedo uses the material's color sampling; normal and ORM are data maps.

## Reuse

Assign the existing resource to a mesh surface or instance override, for example:

```gdscript
mesh_instance.material_override = preload("res://art/materials/m_aged_brass.tres")
```

Keep `resource_local_to_scene` disabled. Do not duplicate a material for each
decoration. A loaded resource is shared: changing it at runtime affects all its
users. Intentional local variants must be explicit and justified by the asset
brief. Adjust UVs on the mesh for consistent density within its asset family;
this baseline does not set a new global texel-density budget. Maps repeat at
integer UV boundaries. The review script includes a 4x4 repetition view.

The glass resources use Godot's built-in screen-space refraction and alpha
rendering. They are a visual approximation, not ray tracing. Test overlapping
transparent surfaces, sorting, backfaces and silhouettes on the actual asset.
The preview puts opaque stripes behind them to reveal blur/displacement.
Memory text/imprints need a separately validated legible presentation; these
resources do not implement text, puzzle states or feedback behavior. Crystal
quality tiers and the stone variation set remain later inventory work.

## Graphical review

Use the authenticated X11 TCP runner from `MATERIAL_PREFLIGHT.md`:

```sh
python tools/run_graphical.py --graphics-prefix /absolute/path/to/graphics --godot /absolute/path/to/godot --timeout 180 --expect 'MATERIAL_LIBRARY PASS' -- --path game --resolution 1920x1080 --script res://tests/material_library_smoke.gd -- --screenshot=/absolute/path/to/materials.png --light=neutral
```

`--light=warm` and `--light=cool` change the key light. `--tiles` renders the
three opaque families with repeated UVs. `--hold` keeps the review window open
after checks. The CLI review is isolated from the shipping main scene.

The script loads the actual shared resources, checks their authored maps,
requires X11/Vulkan/Forward+, verifies framebuffer contribution against a
backing-only capture, checks Russian label glyphs, saves the framebuffer and
requests the existing safe-exit path. Contribution checks establish visibility;
visual inspection is still required for texture/optical quality.

Validation results and actual screenshots are recorded in
`evidence/material_library_2026-10-02.log` and the accompanying neutral, warm,
cool and tiles PNGs. The renderer is llvmpipe software Vulkan. Preview counters
include the environment and framebuffer; they are not a per-material budget
or proof of GTX 1060-class 1080p/60 Medium performance. Representative scene
profiling remains mandatory before mass production.
