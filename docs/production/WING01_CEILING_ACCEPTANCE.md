# Wing I ceiling construction sample — 2026-10-06

Status: bounded technical sample PASS; isolated fixture only.
The pre-authoring dimension contract is `WING01_CEILING_SAMPLE.md` and
`wing01_ceiling_sample.json`. Its initial in-progress status is superseded by
this acceptance record. Meter choices are local construction-study decisions,
not dimensions recovered from perspective art or final full-room approval.

One original editable source, `wing01_ceiling_sample.blend`, now supplies two
ARCH-007 rib variants (10 m / 12 m support spans, 2568 triangles each) and a
separate upper transition (1688 triangles). Added total: 6824 triangles / nine
surfaces, reusing external Stone/Iron/Brass. All objects have identity transforms,
closed topology, metric UVs and verified normals/tangents. No accepted prior
model was regenerated. The two rib exports stayed byte-identical during the
spring-belt rendering fix; only the source and transition export changed.

The isolated assembly stands at (0,4,-21), matching the preserved 10x12 m room.
New upper supports/panels reach the global 5.5 m spring. Both original elliptical
ribs connect at a global 9.5 m crown collar. Corner stone infill covers the
rectangle-to-ellipse edge. The spring belt is lowered 0.07 m to avoid a coincident
underside plane: source inspection verifies local iron planes 1.37/1.49 against
the stone underside 1.44. Native-1 contains the visible defect; native-2 contains
the inspected corrected geometry. Segment highlights/raster aliasing on Low
remain; no lighting, antialias or preset change was used to conceal the defect.

Actual four-object LFS upload passes. A second fresh shallow partial clone had
no alternates and an explicitly verified initially empty independent LFS media
store. Its committed pointers and downloaded bytes match current sizes/SHA-256.
Downloaded source reopens in Blender; downloaded GLBs import cache-free and
pass the actual 50-assertion geometry/anchor/capsule/state fixture and startup.
Supporting code is copied from verified local source identities; this is not a
claim of a fully hydrated remote checkout or old-asset redownload.

Current headless-3 also passes those 50 assertions and normal startup. Native-2
passes authentic TCP-Xvfb Forward+ on Low/Medium; all eight player look-up,
entrance, corner and reverse captures were inspected. Both explicitly protected
save slots are hash-identical. Retrieved-copy bookkeeping initially encountered
a diagnostic directory and an extra empty lock; corrected postprocessing checks
the two protected named slots and separately records other test-owned entries.
No functional/source command failed in that retrieved-copy run.

Measured native view draw calls: lookup 13, entrance 31, corner 10, reverse 57
on each preset. Texture monitor: Low 27648512 bytes, Medium 35138048 bytes.
These are software Vulkan counters for this fixture, not target GPU/FPS claims.
All 347 prior game source identities from Hearth Flame acceptance still match;
shipping ArchiveMain/Boot/S02 mechanics, materials, old binaries, guards and
saved progression are unchanged. The study is loaded only by its explicit test
fixture, never the shipping route.

Current evidence families under `evidence/archive_reconstruction/`:
`ceiling-authoring-2`, `ceiling-lfs-upload-2`, `ceiling-lfs-retrieval-2`,
`ceiling-headless-3`, `ceiling-native-2` and aggregate `ceiling-acceptance-1`.
Earlier candidates/failures remain labelled with their actual scope.

Next: resolve intermediate meridian ribs and curved roof-panel/sky coverage
against the pinned Wing I references, then assess this sample's dimensions and
visual fit before shipping-room integration. Two crossed ribs alone are not a
closed dome. Upper-gallery art/routes, full ARCH-007/world art/VS1, audio and
physical target hardware acceptance remain open. No S03/bulk production or main
integration is included in this sample.
