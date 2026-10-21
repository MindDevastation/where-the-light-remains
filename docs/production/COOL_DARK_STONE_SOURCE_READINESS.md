# MAT-005 — validated unbound source, 2026-10-07

Status: PARTIAL. One shared editable master and native specimens are ready;
no shipping assignment or complete MAT-005/VS1 acceptance is claimed. Fixed
brief: COOL_DARK_STONE.md. Placement dependency:
ARCHIVE_NEXT_MATERIAL_PLACEMENT_AUDIT.md. Gallery: review/cool_dark_stone.html.

`m_cool_dark_stone.tres` uses three original periodic1024-square source PNGs,
an explicit +Y normal map and packed ORM. Editable source:
`tools/generate_cool_dark_stone_maps.py`; existing PBR helper unchanged.
R=white reserved AO, G=roughness.822101–.926793, B=0 metallic. Opaque,
nonemissive dielectric; normal scale.5 and anisotropic mipmapped filtering.
No new shader, light, collider, glyph, scene placement or DCC/GLB family.
PNG/source files use ordinary Git; zero new LFS payloads.

`evidence/archive_reconstruction/cool-stone-native-1/results.json` passes exact
fresh regeneration of all3 maps and manifest, cache-free isolated Godot import,
actual compressed textures/mip chains and shared master identity. Two native
Forward+ runs execute33 assertions each,66 executions total. They protect owned
primary/backup fixtures. They never load GameRoot/autoload gameplay or write
settings, actual saves, DTO or progression. The minimal private fixture project
and all source/evidence bytes are hash bound; it is not a shipping scene.

All8 PNGs were individually inspected:

| Final individual images | Judgment |
| --- | --- |
| stone_neutral_low.png / stone_neutral_medium.png | Matte cool charcoal with restrained pores; distinct from accepted warm stone |
| stone_warm_low.png / stone_warm_medium.png | Warm illumination responds naturally; no metal/glow or wet mirror |
| stone_cool_low.png / stone_cool_medium.png | Cool hue and volume remain legible; no texture/noise glare |
| stone_tiles_low.png / stone_tiles_medium.png | Actual4×4 UV repeat on cards; no visible edge seam; no trim/decal claim |

Specimen scales.75/1.0 follow current Low/Medium viewport profiles; no gameplay
scene quality acceptance is inferred. Renderer: restored pinned Godot4.7.2,
authenticated TCP/Xvfb, software llvmpipe Vulkan/Forward+. Physical target GPU,
1080p60 and owner gallery remain open. The scratch environment was replaced;
only required toolchain was restored. Previous accepted suites were not rerun.

All existing tracked game files remain identical to remote8db32c5. Prior193
art/source identities are preserved; LFS identities are checked by committed
pointer/OID/size where payloads are not materialized in this new checkout.
No fresh47-GLB payload download/use, Blender reopen, new LFS upload or old art
acceptance is advertised. Original material masters/maps remain unchanged.
Prior MAT-002301 assertions, dust/inspect and family evidence are historical
reused proof in their original scope, not fresh executions in this66 total.

MAT-005 MISSING→PARTIAL only.26 ACCEPTED/41 PARTIAL/10 MISSING among77 VS1 rows;
185 canonical rows retained, no full reconciliation repeat. Canonical stages
remain0,4,6,8,9. S02 and hidden replaced collider shells are not assignments.
Final acceptance needs a legitimate measured S00 exterior/backdrop surface and
affected shipping native camera/door/E/save tests. Existing warm-stone assets
are preserved. Next independent native source block: MAT-011 linen candidate
and isolated specimens, with its dressing assignment kept open.

ARCH-011 remains MISSING/required_for_vs1 pending owner A/B. Full exterior/
infill/alcove/backdrop/hero, channels/carrier/emblems, remaining material/trim/
decal/dressing/style, authored audio/mix/owner choices, full owner gallery and
physical GPU remain open. GATE-VS1 OPEN, S03 blocked. Full-game estimate25–30%,
low confidence,3/16 playable stages unchanged. Source/specimen checkpoint is
separate from last integrated production STABLE5184c48.
