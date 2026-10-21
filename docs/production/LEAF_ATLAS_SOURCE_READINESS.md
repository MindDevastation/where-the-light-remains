# MAT-012 — validated unbound leaf atlas, 2026-10-07

Status: PARTIAL. One original raster atlas and one shared editable cutout master
are ready. No plant carrier, shipping scene assignment or full VS1 acceptance.
S00 v2 timber/iron/cobalt-night authority remains unchanged; no ivy architecture
is reinstated. Fixed brief LEAF_ATLAS.md; individual gallery review/leaf_atlas.html.

Built-in imagegen produced eight original olive-green hand-painted leaf accents.
The first layout was excluded because its gutters failed the fixed brief. One
layout-only imagegen edit supplied the selected PNG, preserved byte-for-byte at
game/art/textures/foliage/t_archive_leaf_atlas.png. Exact generation and edit
prompts are leaf_atlas_prompt.txt and leaf_atlas_edit_prompt.txt. SHA256 lineage,
actual1774×887 RGBA dimensions and eight exact normalized/source cell rectangles
are in leaf_atlas_manifest.json. Requested2048×1024 was not returned; integer
rectangles differ by at most1 pixel. No crop, resize, Python pixel edit or claim
of deterministic AI regeneration. PNG is editable raster source; no DCC/3D source
or new LFS family is implied.

Each retained ≥128 silhouette has at least13.06% cell padding. Sparse alpha1–15
residue is present outside shapes; raw all-zero gutters are not claimed. Built-in
m_archive_leaf_cutout.tres explicitly uses .5 alpha-scissor, two-sided culling,
roughness.85, metallic0 and anisotropic mip filtering. Native high-quality VRAM
compression, mip generation and fix-alpha-border preserve actual RGBA use. No
custom shader, blended transparency/refraction, emission or foliage policy.

leaf-atlas-native-1/results.json passes cache-free isolated import and two actual
native X11/Forward+ runs:84 assertions per profile,168 assertion executions.
Every eight-cell view measures leaf framebuffer contribution against an absent-
leaf reference and independently verifies transparent gutters expose the same
checker backing. Compressed returned dimensions/mips, shared identity, source
RGBA, Cyrillic labels and protected primary/backup fixtures pass. Private minimal
project contains no gameplay autoload. No actual save/settings/DTO/route changes.

All eight final PNGs were individually inspected:

| Individual final frames | Judgment |
| --- | --- |
| leaf_atlas_neutral_low.png / leaf_atlas_neutral_medium.png | Eight distinct clean silhouettes; muted green veins; backing remains visible outside shapes |
| leaf_atlas_warm_low.png / leaf_atlas_warm_medium.png | Warm diffuse response; matte surfaces, no opaque texture rectangle or emissive look |
| leaf_atlas_cool_low.png / leaf_atlas_cool_medium.png | Cool green response; reversed top-row faces remain visible; no visible gutter intrusion |
| leaf_atlas_distance_low.png / leaf_atlas_distance_medium.png | Mips average fine veins while retaining eight separate leaf shapes; static distance specimen only |

Low/Medium are isolated scales.75/1, not shipping scenes or physical GTX1060/
1080p60 proof. Software llvmpipe Vulkan uses restored official Godot4.7.2. Actual
plant UV density, stem/carrier geometry, two-sided light response in scenes,
camera motion/shimmer, clearance and owner style review remain open. The checker
backing is test geometry and never ships.

Prior193 art/source identities and47 committed runtime LFS pointer/OID/size
identities remain intact. No fresh old GLB payload use or Blender reopen is
claimed. Earlier stone/linen source seals remain current:132 executions and16
individual views. This source continuation totals300 scoped assertion executions
and24 individually inspected frames. Old integrated suites remain historical.

Delta MAT-012 MISSING→PARTIAL only:26 ACCEPTED/43 PARTIAL/8 MISSING among77;
185 canonical rows retained. ARCH-011 stays required/MISSING pending owner A/B.
Last integrated runtime production STABLE5184c48 remains unchanged. GATE-VS1 OPEN,
S03 blocked; authored audio/mix/owner motif, full art/gallery and target GPU open.
Resolve latest source STABLE/receipt HEAD via continuation_20261007.jsonl.
