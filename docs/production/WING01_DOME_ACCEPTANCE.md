# Wing I dome coverage — isolated candidate accepted, 2026-10-06

Status: bounded source/import/LFS/visual fit PASS; shipping integration is next.
This supersedes the initial in-progress status in WING01_DOME_COVERAGE.md.
Dimensions are local construction choices constrained by the preserved room,
not meter measurements from the six pinned perspective references.

The new editable `wing01_dome_coverage.blend` supplies twelve intermediate
half-meridians and three latitude ties (10944 triangles / two surfaces), one
connected thin curved glass shell (4608 / one) and a local opaque night backing
(4608 / one). Added total: 20160 / four. With the unchanged earlier two cardinal
ribs and transition, the isolated whole roof is 26984 triangles / thirteen
surfaces. No accepted source/export was regenerated or scaled. Frame and sky
exports remained byte-identical during the glass shading correction.

Reopened source has identity meter transforms, closed positive volumes,
metric UVs and finite unit normals/tangents. Actual BVH coverage passes 49
interior roof rays with a separate farther sky; twelve additional meridians
are present and the four accepted cardinal directions are excluded. Smooth
glass shading removes the conspicuous practical-reflection checker grid in
native-1. Native-2 keeps coherent reflections, strongest overhead; global
lighting/material settings were not changed to conceal the defect.

Cache-free imported geometry, actual arrays/material references/bounds,
49 imported roof rays, shadow scope and original capsule entrance/corner/
checkpoint/grip clearance pass 98 assertions and normal startup. No new
collision, lights, world environment, gameplay scripts or progression data.
The new static sky shader is an explicit reusable local backing, with no
textures, time animation, particles, emission or new clue/constellation marks.
Glazing reuses the existing clear-glass material with interior backface culling.

All twelve native player look-up/entrance/corner/reverse/hero/hearth images
were inspected on Low/Medium. The room-to-dome edge closes without low central
headroom or exposed corner gaps. Original ring/hearth silhouettes remain
unchanged. Draw calls per view: 17/35/14/61/38/30 on both presets, exactly four
above the earlier ceiling-only matching views. Texture monitor remains
27648512 bytes Low / 35138048 Medium. These software Vulkan fixture counters
are not target GPU/FPS or full-room art/lighting acceptance.

Native Git pre-push uploaded four real LFS payloads (4.9 MB), and the working
branch/pointer commit was independently verified. A fresh shallow clone used
an explicitly empty separate media store and no object alternates. Four
committed pointers and retrieved byte sizes/SHA-256 match current payloads.
Retrieved source reopens; retrieved exports import cache-free and pass the
same 98 actual assertions and startup. Supporting game/code is copied from
verified current local identities; this does not claim a fully hydrated clone
or independent redownload of unchanged earlier assets. The new reproducible
`tools/verify_lfs_asset_family.py` records named protected save hashes and
separately inventories extra private bookkeeping files/directories.

All 362 prior game source identities from ceiling-acceptance-1 still match.
Both physically existing protected save slots remain unchanged in native,
headless and retrieved-copy checks. The shipping room still has no new roof:
only the explicit isolated fixture loads this candidate.

Evidence under `evidence/archive_reconstruction/`: dome-authoring-2,
dome-headless-2, dome-native-2 plus visual_review.json, dome-lfs-upload-1,
dome-lfs-retrieval-1 and aggregate dome-acceptance-1. Earlier flat-normal
native-1 and standalone test type-inference failure in headless-1 remain
labelled with their actual failed scopes.

Next: integrate this measured roof into the existing room, preserve isolation
fixtures, validate shipping S02 controls/save/reload/return and entry, then
continue beam/Star presentation. Full ARCH-007/world art/VS1, upper-gallery
art, authored audio and physical GTX1060 acceptance remain open. No new route,
main integration, history rewrite, S03 or bulk production acceptance.
