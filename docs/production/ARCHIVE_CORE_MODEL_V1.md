# Archive central mechanism model v1

The owner requested a textured 3D model from the final-look reference. The complete downloadable model was built and checked on 2026-10-18. The exact delivery was recovered after workspace maintenance on 2026-10-21; no model geometry was regenerated during recovery.

Delivery archive SHA256: `2f03aa80e0e58b314c10ef3d14244990b17961f106f10e9e620a4e5085e45861`. All 40 manifest file identities passed recovery comparison. The packed Blender file, self-contained GLB, 12 PNG maps, Godot wrapper and preview scene remain in that delivery.

## Complete reference-look candidate

- 29,780 triangles; seven mesh parts; six materials; twelve surfaces.
- Godot bounds: width 1.111368 m, height 1.553324 m, depth 0.924 m; lower bound Y 0.006 m.
- Separate visual orbits and central core. Shared visual pivot at (0, 1.02, 0) m; object scales are one.
- Albedo, tangent normal and ORM maps. Four textured materials retain ambient occlusion, roughness and metallic data; glass and emission use dedicated materials.
- No exported lights, cameras, animation, gameplay logic or collision.

The complete candidate has a compact decorative body and wider straps. It is not a direct replacement for the measured upper-only contract. The separate 5,048-triangle upper export preserves the 0.58/0.46/0.34 m radii, 14 by 28 mm profile and existing 1.8 m scene pivot. Neither export is assigned to the shipping scene by this continuation.

## Existing checks, not new executions

The recovered 2026-10-18 receipts record a clean Blender 4.5.14 source reopen, independent GLB reimport, watertight source solids, nondegenerate geometry and UVs, finite normals/tangents, packed images and unit scales. Godot 4.7.2 performed a clean import, material/geometry checks and two inspected native Forward+ software-Vulkan views. The delivered wrapper and preview also loaded successfully. These are asset-file checks, not full gameplay, owner-style or target-GPU acceptance.

Receipts and exact recovery provenance: [20261018 delivery recovered on 20261021](evidence/archive_core_model/20261018-delivery-recovered-20261021/).

## Repository publication boundary

The final modeling/validation recipes are recovered under `tools/`. Proposed binary destinations are:

- `assets/3d/blender/hero_props/s01_archive_core_hero_v1.blend`, SHA256 `bcb075f50eb8f213d8a8e6c1ba2f083560590d8c095e844c9f685075d24f283b`.
- `game/art/meshes/hero_props/sm_s01_archive_core_hero_v1.glb`, SHA256 `30c9630339791d6362ad3758ddac86e146a8c1d4840e6a2464263f886e505ccc`.
- `game/art/meshes/archive_kit/sm_s01_core_upper_v1.glb`, SHA256 `093d908a0aae7a4db19524ed76abb3f9a70d2acc21717537f946dcf78a5fd591`.

They require Git LFS. A fresh ordinary native Git push dry-run on 2026-10-21 failed with missing GitHub Username authentication. The authenticated connector remains available for ordinary source/evidence checkpoints. No binary payload or dangling LFS pointer has been published as a substitute for a successful LFS upload, and no credential from conversation history is used.

The interrupted owner overview continues against the current shipping scene, including its existing provisional rings. Fresh captures use a unique 20261021 evidence folder; they must not be described as recovered original 20261008 image bytes. Inventory remains 26 ACCEPTED / 44 PARTIAL / 7 MISSING among 77 VS1 groups; GATE-VS1 OPEN and S03 blocked. Main and PR #43 base/draft are unchanged.

The exact three hero atlas PNGs and their manifest are recovered under `assets/3d/textures_source/archive_core_hero_v1/`. A bounded new LFS attempt on 2026-10-21 was stopped by automatic approval review before a native process result was available: explicit confirmation for the three reviewed binaries and destination is required. This is separate from the observed missing native Git authentication. No LFS payload write is acknowledged.
