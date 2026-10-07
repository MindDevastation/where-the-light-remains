# Shared material library

Scope: the six-family historical Art Foundation baseline plus the v2 shared extension below. These are reusable runtime
resources, separate from the earlier capability-only specimens.
Full inventory acceptance, representative scene performance and crystal quality
tiers remain open; this slice does not mark every MAT requirement complete.

## Resources

All paths below are relative to `game/art/materials/`.

| Inventory | Resource | Baseline behavior |
|---|---|---|
| MAT-004 | `m_observatory_stone.tres` | Pale warm stone, subtle pores/veins, rough dielectric |
| MAT-001 | `m_aged_brass.tres` | Warm metal with smooth aging, brushed detail and varied roughness |
| MAT-003 | `m_dark_walnut.tres` | Aged dark brown grain; v2 disables clearcoat and increases roughness |
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

The historical six-family baseline had eleven 1024x1024 PNGs; the current v2
extension has twenty. SHA-256/provenance/edge metrics are in
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

## Current visual authority — v2 owner rebaseline

For new visual work use `VISUAL_REBASELINE_V2.md`, its explicit current references
and `assets/concept_art/README.md`. Nonsuffixed v1 sheets/images referenced above
are historical/LEGACY; technical validation stays valid in its recorded scope.
Canonical mechanics and global budgets remain unchanged.

## V2 shared extension — Hybrid Warcraft Observatory

Owner baseline references: `production_sheets/Material sheet_v2_angle_a/b/c.png`
and `Lighting guide sheet_v2_angle_a/b/c.png` under `assets/concept_art/`, pinned
at `cabe792`. Exact image blobs/hash inventory and interpretation are in
`VISUAL_REBASELINE_V2.md`. No concept pixels are used as runtime textures.

The five compatible original families stay unchanged. `m_dark_walnut.tres`
keeps its path, color/grain/normal/UV identity; clearcoat is disabled and the ORM
roughness is increased from polished ~0.25 to aged ~0.58. This is
KEEP_AND_REMATERIAL, not a mesh or color/UV rebuild. Carved timber uses the same
material with authored geometry/trim in its eventual asset brief.

| Resource under `game/art/materials/` | Relation / use |
|---|---|
| `m_dark_iron.tres` | Owner v2 family; forged dark metallic hardware with restrained varied roughness |
| `m_aged_leather.tres` | Owner v2 family; rough brown leather for books/seating/straps; seams belong to meshes |
| `m_crimson_textile.tres` | MAT-010 palette refinement; restrained crimson dyed woven textile |
| `m_navy_textile.tres` | Owner v2 deep-navy counterpart; shares exactly the same three weave maps with crimson |
| `m_clear_glass.tres` | MAT-006 clear optics substrate, built-in approximation, not ray tracing |
| `m_resonance_teal.tres` | MAT-015 family emission variant; same StandardMaterial3D approach as gold, lower authored energy |

Total library: **12 shared resources / 20 original 1024² maps**; no per-prop
unique materials. New iron/leather/weave use albedo, +Y normal and ORM. Both
textile resources share the three neutral maps and vary resource tint. Existing
texture/filter/channel/mipmap rules apply; iron albedo/ORM use high-quality
compression. New source PNG payloads plus originals total **13,176,703 bytes**.
Generator dependencies remain NumPy 2.3.5 / Pillow 12.3.0. Repeatable regeneration
checks all maps and manifest; no new Blender/GLB/LFS payload is needed.

Use existing runtime resources directly; keep resource_local_to_scene disabled.
Do not mutate shared materials for local puzzle states. Transparent surfaces need
actual asset sorting/backface/overlap/readability review; clear glass does not
complete all lenses/window acceptance. Stage feedback and quality tiers are still
unbuilt. No new global texture/shader budget is introduced.

Review through the existing authenticated graphical runner with `--v2` after the
script's user-argument separator. It renders all twelve resources in neutral,
warm or cool light; `--v2 --tiles` shows seven opaque instances in 4×4 repetition.
The cyan/amber split is an isolated review setup, not a shipped world lighting
state. Cyrillic labels, shared map identity and real framebuffer contribution
are checked in Vulkan Forward+. Logs/screenshots are under
`evidence/visual_rebaseline_v2/`; all four reviews and deterministic regeneration
PASS. Current results and scope are in `MATERIAL_PREFLIGHT.md` and the evidence
README. Historical six-family logs above retain their original scope.

The material board establishes surface behavior and palette. It cannot establish
Warcraft geometry/craftsmanship, navigation, puzzle readability, collision or
representative GTX1060 performance in unbuilt environments.

## MAT-005 unbound source extension — 2026-10-07

The original shared masters/maps are preserved. New m_cool_dark_stone.tres and
three original periodic1024 PNGs use tools/generate_cool_dark_stone_maps.py.
COOL_DARK_STONE_SOURCE_READINESS.md records isolated native source/specimen PASS,
66 assertions/8 images; shipping assignment absent, row PARTIAL. The original
20-map manifest is unchanged; separate cool_dark_stone_manifest.json seals the
new3 maps. The previously accepted polished-brass extension has its own3-map
manifest and acceptance. No fixture lights or specimen geometry ship.
