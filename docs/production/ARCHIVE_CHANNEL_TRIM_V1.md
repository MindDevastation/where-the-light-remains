# Archive channel trim v1 - bounded native acceptance

The existing five S01 route channels now share an original immutable native ArrayMesh luminous insert and a paired dark-iron frame. The insert has a 3 mm cross-section bevel and 2 mm end bevels. The rails use the existing textured `m_dark_iron.tres`, metre-scale UVs and packed normals/tangents. The offline source is `tools/create_archive_channel_mesh.gd`; no mesh is generated at runtime.

The core is 60 triangles and the paired rails 120, totalling 180 per channel, below the local 200-triangle ceiling. All five instances total 900 triangles, compared with the previous 60. The frame adds one surface per visible channel, at most five extra visible surfaces during the existing flash. This is a bounded geometry count, not a measured target-GPU performance result or a new global budget. Rails cast no new shadows.

The original 0.18 by 0.03 by 4.7 m envelope is retained. Core width is 0.12 m, height 0.03 m and length 4.7 m. Two 0.03 m rails centred at X +/-0.075 m fit inside the former width. The core centre, height, longitudinal bounds and visual translation remain unchanged, preserving original forward/reverse pulse endpoints. Rails are children of the owned visual, inheriting its transform and visibility.

The controller, ArchiveMain script/scene, all five route placements/scales, active/completed material properties, shared iron and quality policy are byte-identical to baseline `8dc7ffe618e0f95e802f310b714903d0ea21c39c`. No light, collider, input, progression field or clock is added. This original native VFX source follows the existing beam/flame pattern; it neither converts nor republishes the central mechanism binaries awaiting separate upload approval.

## Current validation

`evidence/archive_reconstruction/channel-trim-native-20261031-2/results.json` records a cache-free Godot 4.7.2 import, 28 bounded component checks, one native Low and one native Medium run, and eight individually inspected original 1280x720 images. Geometry checks cover closed welded edges, nondegenerate outward triangles/UVs, finite unit normals and tangents, packed tangent handedness and exact AABBs. State checks cover dormant/active/completed, unchanged colors/endpoints, pause, quiet cancellation, transformed reverse pulse, one completion, and foreign-marker cancellation at the existing process-frame boundary. No instant synchronous cancellation after reparenting is claimed.

The first attempt is retained as FAIL. Its fixture assumed exact floating-point tangent orthogonality despite native packed decoding and immediate foreign-marker cancellation before the next process guard. Measured maximum decoded tangent dot is 0.00015592575073; the revised bound is 0.00025, below 0.0144 degrees. The original fixture, diagnostic log and correction rationale are preserved. Neither correction changed a shipping mesh or controller.

The first attempt independently retrieved all 47 existing GLBs by committed OID and size. The successful rerun reused those exact verified payloads, with a new private copy and cache-free import. It performed zero fresh payload reads and zero new LFS uploads. Both protected primary/backup save fixtures and DTO/dirty state remained unchanged. Only the documented empty Godot recovery marker is permitted by the existing slot guard.

Each profile has three current shipping player-camera quiet projections (dormant, active, completed with next route active) plus one supplemental close-up under unchanged shipping lights. All eight originals were individually opened. Cyan/gold states remain readable; dormant channels disappear; the dark frame is continuous. The central mechanism partially occludes the near channel in the player framing. Low uses render scale 0.75 and Medium 1.0; both actual profiles have glow and volumetrics off. No new glow-on evidence is claimed. Vulkan Forward+ ran on software llvmpipe, not target hardware.

## Acceptance boundary

This is STABLE_BOUNDED_PRESENTATION after publication, not full ARCH-015/S01-005 acceptance. Both remain PARTIAL. The global floor/wall/curved channel family and complete Hub composition still need review. No real E/awakening/full-route/save-reload suite, full owner gallery or Blender/model-source reopening was rerun. The earlier 2026-10-21 owner gallery remains separate historical review evidence.

Inventory stays 185 rows, 77 VS1 groups: 26 ACCEPTED / 44 PARTIAL / 7 MISSING. ARCH-011 A/B remains pending. GATE-VS1 is OPEN and S03 blocked. Main, PR base and draft are unchanged. Final remote SHA/receipt resolves from the working branch and checkpoint journal.
