# Modular Archive sample evidence

Date: 2026-10-03 UTC. Feature: `feature/03-art-foundation/modular-archive-kit`.
Base: `c6773f203717b0058a3ec3aee4a3e26bb1190f1f`.
Standing owner reasoning request: Extra High / highest available; no agent-side setting switch claimed.

**Source, export, import, assembly/physics and bounded visual review: PASS.
Remote payload upload/independent retrieval: pending until the feature is pushed.**
This original five-module structural family follows the approved v1 technical
contract and current v2 kit/shape/hub A/B/C references. It is not the full Hub,
ARCH inventory, shipping gameplay scene or physical-GPU performance acceptance.

| Module | Triangles | Surfaces |
|---|---:|---:|
| Wall 2 m | 108 | 1 |
| Wall 4 m | 212 | 1 |
| Arch 4 m | 1,412 | 2 |
| Floor 1 m | 20 | 1 |
| Pier 4 m | 332 | 2 |

Primary: 63 instances, 4,284 triangles against 23,568 ceiling, 68 authored
material surfaces. Wall substitution: 4,288 against 24,168. Separate corner:
39 instances, 1,476 triangles. These are measured mesh sums, not GPU draw calls.
Six new LFS payloads total 888,152 bytes; exact hashes/sizes are in
[payload_manifest.json](payload_manifest.json). Original meshes and editable
Blender source are authored by the project recipe, not copied from concept pixels.

| Evidence | Actual check |
|---|---|
| [auth_preflight.log](auth_preflight.log) | Token presence, gh identity, Git origin read/write dry run, LFS batch/download, permissions, disk and refs; no credentials retained |
| [capability.log](capability.log) | Verified existing local tools; disposable Blender CLI/save/export probe; minimal authenticated X11/Vulkan GameRoot smoke before target tests |
| [authoring.log](authoring.log) | Five original exports and editable source |
| [source_final.log](source_final.log) | Reopened source, closed positive-volume geometry, aperture/corner mesh rays, transforms/bounds/UV/tangents |
| [import_final.log](import_final.log) | Final actual editor import |
| [physics_final.log](physics_final.log) | Imported bounds/anchors/material identity; 810 floor/seam rays, blockers, 15 real capsule traversals, wall substitution and four rotated corner joins |
| [front.log](front.log) / [PNG](front.png) | Actual 63-part front review, 25 draw calls |
| [reverse.log](reverse.log) / [PNG](reverse.png) | Actual reverse faces, 27 draw calls |
| [corner.log](corner.log) / [PNG](corner.png) | Actual isolated right-angle junction, 18 draw calls |
| [contract_preservation.log](contract_preservation.log) | Eight technical JSON keys, nine reference Git blobs and fourteen previous runtime/config fingerprints unchanged |
| [validation_manifest.json](validation_manifest.json) | Final source/import/wrapper/frame hashes and pinned references |

All three final 1920×1080 images were visually inspected: complete silhouettes,
clear arch, solid reverse faces, flush floor seams, stepped square pier covering
the corner, restrained brass and shared tileable stone. Front/reverse/corner
are implementation views of this sample; the concept's Hub A/B/C remains a
reference, not a claim that the entire Hub was built or owner-approved.
No unique texture, ornament/sigil, new shader, world lighting or gameplay change.

Actual rendering: Godot 4.7.2, X11, Vulkan 1.4.318, Forward+, llvmpipe LLVM 20.1.2;
Xvfb over TCP with MIT-MAGIC-COOKIE, authorized client accepted and cookie-less
client rejected. One shadow-casting directional plus one nonshadow fill in the
isolated review only. Texture counter is 120,224,512 bytes including the shared
environment/framebuffer; not incremental kit cost. RGB deltas against the
mesh-hidden frame: front 0.2460434, reverse 0.1563966, corner 0.1976139, threshold
0.03. No target-class FPS assertion; physical GTX1060-class profiling remains open.

The five small GLBs disable automatic LOD and import mesh compression locally
to preserve the 1 mm anchors and 2 mm below-plane floor bevel. This is a sample
import choice, not a global LOD/compression policy. External imported materials
are the existing shared Godot resources, with no per-instance copies.
Arch collision is two jamb boxes plus 32 crown convex strips; the opening stays
empty. Other colliders are separately authored boxes; no gameplay scripts on art.

## Reproduction

Read prior successful preflight evidence first. Reuse the recovered local tools.
Use absolute paths appropriate to the current environment:

```sh
blender --background assets/3d/blender/archive_kit/archive_kit_sample.blend --python-exit-code 1 --python tools/verify_archive_kit_source.py
godot --headless --editor --path game --quit
godot --headless --path game --max-fps 60 --quit-after 2400 --script res://tests/archive_kit_smoke.gd
python tools/run_graphical.py --graphics-prefix /absolute/graphics --godot /absolute/godot --timeout 150 --expect 'ARCHIVE_KIT_REVIEW PASS' -- --path game --resolution 1920x1080 --max-fps 30 --quit-after 1200 --script res://tests/archive_kit_review.gd -- --view=front --screenshot=/absolute/front.png
```

Repeat the final command for reverse/corner. Require final PASS markers and no
Godot errors, not just exit zero or the finite quit bound. Recreate missing
source only into an empty disposable output root with
`tools/create_archive_kit.py`; it refuses to overwrite existing binaries.
`tools/assemble_archive_kit.py` builds wrappers/fixtures; after the first import,
its `--configure-imports` mode sets shared external materials, followed by reimport.

## Resolved checker/presentation defects

[source_visibility_diagnostic.log](source_visibility_diagnostic.log) records the
source validator's failure when ray casts depended on a hidden viewport
collection. The corrected test intersects stored mesh triangles with BVH;
actual source geometry was unchanged. [physics_diagnostic.log](physics_diagnostic.log)
records the typed-array assignment error found after an initial test hit its
180 s parent timeout. Generic anchor-name arrays fix it; final bounded checks
complete with the actual PASS marker. Only trailing whitespace and terminal blank padding are normalized in logs.
The timed-out run's buffered output was
not retained; the bounded diagnostic and successful final log are retained.
Initial views exposed crop/bright lighting; final framing and review-only light
energy were corrected, recaptured and inspected. These are resolved test/review
defects, not permission or environment blockers.
