# Wing I roof — shipping room integration, 2026-10-06

Status: bounded integration PASS. Full room art/lighting/VS1 remains open.
The accepted cardinal ribs/transition and dome coverage now form one static
`wing01_roof_presentation.tscn` instance in ArchiveMain at (0,4,-21), unit scale.
The whole roof measures 26984 triangles / thirteen surfaces; all eight prior
source/export payloads in the two roof families remain byte-identical.
No model regeneration, new collision, lights, shared world environment change,
new walking route or gameplay/state ownership change.

The actual shipping-world oracle verifies one visible dome owner, the two-part
assembly, original crown connections and unchanged 6824-triangle structure,
plus imported geometry/materials/49 roof rays and real capsule approaches:
109 assertions. The isolated fixture hides the shipping roof and keeps its
explicit study; its 98 dome and original 50 ceiling assertions still pass.
49 room, 17 actual Boot/menu/Exit and 60 S02 controls/save/reload/return checks
also pass (383 total), along with cache-free imports and normal startup.
Read-only runs preserve both physically existing save slots; S02 persistence
uses separate test-owned data. Threaded GameRoot loading and cleanup report no
Godot warnings/errors. There is no new LFS payload; reuse was checked against
the accepted exact source/export SHA-256 identities.

Twelve actual Low/Medium shipping-player captures are byte-identical to the
twelve individually inspected isolated dome-native-2 images. All twelve pairs
were compared by SHA-256; the shipping look-up was additionally inspected.
Their counters remain 17/35/14/61/38/30 draw calls per view and 27648512 /
35138048 texture bytes. Matching rendered images and the single visible owner
show that the shipping route has no duplicate visible dome. Software Vulkan
measurements do not certify GTX1060 frame time or final room lighting.

Current proof: roof-headless-1, roof-s02-1, roof-native-1/visual_review.json and
aggregate roof-acceptance-1 under evidence/archive_reconstruction. Geometry
source/export/LFS/retrieved-use proof remains in WING01_CEILING_ACCEPTANCE.md
and WING01_DOME_ACCEPTANCE.md; those are historical isolated stages, not fresh
full-source validation for this changed shipping assembly.

Next: bounded reusable beam and quiet Star presentation, preserving the existing
four sequential ring beam nodes, focus pose/scale, canonical sigil and ordered
Star/Hearth state/save behavior. Then continue room lighting/art within the
owner's active work window. Upper-gallery art, authored audio, full ARCH/VS1 and
physical target hardware remain open. No S03/bulk/main integration is included.
