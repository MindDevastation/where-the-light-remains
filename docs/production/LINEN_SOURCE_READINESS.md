# MAT-011 — validated unbound linen, 2026-10-07

Status: PARTIAL. One shared editable master and original weave maps are ready;
the current slice has no assigned neutral-fabric dressing actor. No shipping or
complete MAT-011/VS1 acceptance is claimed. Brief: LINEN.md. Gallery:
review/linen.html. Placement audit: ARCHIVE_NEXT_MATERIAL_PLACEMENT_AUDIT.md.

`game/art/materials/m_linen.tres` uses3 original periodic1024 albedo/+Y-normal/
ORM PNGs and editable `tools/generate_linen_maps.py`. Staggered warp/weft
crossing, slightly uneven thread phase and slub/fiber fields are original data.
All3 map hashes differ from accepted woven_textile maps; they are not a tint
variant of that surface. Source roughness.867403–.919856, metallic0, white
reserved AO, normal scale.7. Opaque nonemissive PBR; compressed native mipmaps,
anisotropic filtering and explicit +Y normal import. No alpha/displacement,
new shader, unique prop texture, light, carrier geometry or new LFS payload.

`evidence/archive_reconstruction/linen-native-1/results.json` passes exact fresh
regeneration of3 PNGs+manifest, cache-free isolated import and two actual native
Forward+ runs.33 assertions each =66 execution counts, not66 distinct new tests.
Shared resource identity, compressed texture/mips, source albedo/normal/ORM
ranges, Cyrillic labels and framebuffer contribution pass. Private owned primary/
backup fixtures remain identical. Minimal fixture project has no GameRoot/gameplay
autoload; no actual settings, save slots, DTO, progression or route is changed.

All8 final PNGs were individually inspected:

| Final individual images | Judgment |
| --- | --- |
| linen_neutral_low.png / linen_neutral_medium.png | Neutral flax hue, restrained crossed-thread texture, matte response; accepted crimson remains unchanged |
| linen_warm_low.png / linen_warm_medium.png | Warm light response stays nonmetallic with no glowing/wet sheen |
| linen_cool_low.png / linen_cool_medium.png | Cool illumination preserves fabric shading; no sharp texture glare |
| linen_tiles_low.png / linen_tiles_medium.png | Actual4×4 repeat is seamless; fine weave averages at this distance, as expected with mipmaps; carrier UV density/close-up final cloth art remains open |

Low/Medium refer to isolated specimen scales.75/1.0 derived from the unchanged
SettingsManager. These are not shipping scene views, folds/thickness acceptance,
owner gallery or physical GTX1060/1080p60 proof. Renderer is restored official
Godot4.7.2 and authenticated TCP/Xvfb/software llvmpipe Vulkan/Forward+.

Existing tracked game/stone sources remain byte-identical to de3860c. Accepted
crimson/navy/rug/leather and the original shared woven maps/imports are preserved.
Prior193 art/source identities and47 committed runtime LFS pointer/OID/size
identities are retained. Actual old GLB payloads/source reopens are not freshly
materialized or tested in this restored environment. Stone66 assertions/8 native
images and its source seal are current earlier-stage evidence; old MAT-002301,
dust/inspect/fanlight/gameplay suites remain historical reused evidence, not
fresh execution credit. This current material continuation totals132 scoped
specimen assertion executions and16 individually inspected native frames.

Delta: MAT-011 MISSING→PARTIAL only.26 ACCEPTED/42 PARTIAL/9 MISSING among77;
185 canonical rows retained. No full reconciliation repeat. Final acceptance
requires a concrete canonical neutral-cloth dressing actor/placement, correct
carrier source where applicable, native S01 readability/clearance and affected
scene/save tests. Source preparation does not close an unassigned material.
Next independent native source scope: MAT-012 leaf/ivy atlas brief and raster/
alpha/mipmap specimens; eventual new3D carrier still needs editable source and
independently usable LFS publication before shipping integration.

ARCH-011 owner A/B remains pending; requirement/floor/collision unchanged.
Complete exterior/infill/alcove/backdrop/hero/emblems/channels/carrier, remaining
atlas/trim/decal/dressing/style, authored audio/mix/owner first-note/motif, full
owner gallery and target GPU remain open. GATE-VS1 OPEN; S03 blocked. Full-game
estimate25–30%, low confidence,3/16 playable stages unchanged. Latest source-only
checkpoint is resolved from continuation_20261007.jsonl; last integrated runtime
production STABLE remains5184c48. Main and PR base remain unchanged.
