# Material library preflight

Status: **PASS — graphical environment and authored twelve-resource v2 foundation** (2026-10-02).

Recovery feature: `feature/03-art-foundation/graphics-preflight`.
Production feature: `feature/03-art-foundation/material-library`.
The original 2026-09-23 preflight below used isolated procedural test specimens
under `game/tests/`. The authored shared baseline is now implemented and checked
separately; see the 2026-10-02 result at the end and [MATERIAL_LIBRARY.md](MATERIAL_LIBRARY.md).
Full inventory and target-hardware acceptance remain pending.
The current v2 results follow the historical six-family results at the end.

## Corrected diagnosis

The 2026-09-22 failure used `xvfb-run ... -nolisten tcp`. That disabled the
transport already proven in `ENGINE_PREFLIGHT.md` and its successful evidence.
AF_UNIX rejection was real, but the conclusion that graphical validation required
an environment change was incorrect. The existing authenticated TCP path works.
The old [failure log](evidence/material_graphics_preflight_2026-09-22.log) is
retained as historical evidence; its environment-blocker conclusion is superseded.

Reproduced baseline:

- Xvfb, 1920x1080x24, TCP enabled, UNIX/local socket transports disabled;
- temporary MIT-MAGIC-COOKIE authorization, private authority file removed on exit;
- `DISPLAY=127.0.0.1:<display>`, with IP and local-hostname authority entries;
- documented `/usr/bin/xkbcomp` link to the locally extracted executable;
- `-noreset` and initialization of `WM_DELETE_WINDOW` on bare Xvfb;
- Godot **4.7.2.stable.official.ed1daf0bf**, X11, Dummy audio;
- **Vulkan 1.4.318 / Forward+ / llvmpipe (LLVM 20.1.2, 256 bits)**,
  Mesa **25.2.8-0ubuntu0.24.04.2**.

The runner verifies that a correct cookie connects and an unauthenticated client
is rejected. It does not disable access controls or fall back to headless/GL.
Known nonfatal Xvfb interface-enumeration and unused multimedia-keysym warnings
match the earlier successful engine preflight.

## Actual validation

Historical capability results, 2026-09-23:

| Check | Result |
|---|---|
| Pinned package restore/checksum verification | PASS |
| Authenticated TCP X11 and rejection without cookie | PASS |
| Clean Godot editor import | PASS, exit 0 |
| Minimal graphical engine smoke | PASS; real X11/Vulkan/Forward+, eight autoloads, GameRoot, safe exit |
| Graphical material preflight | PASS; six rendered StandardMaterial3D specimens |
| Framebuffer contribution | PASS; each sample differs from its backing-only image; mean RGB delta 0.146–0.475, threshold 0.015 |
| Russian label glyphs and visual inspection | PASS |
| Screenshot readback/save | PASS; 1280x720, matching the existing window override |
| Existing GLB fixture smoke | PASS; scale, Y-up, pivot, normals, UV, material, script-free wrapper |

The specimens exercise opaque surfaces, metallic/specular response, different
roughness values, alpha transparency and emission. Visible stripes behind both
transparent specimens and distinct highlights were inspected in the actual PNG.
This does not validate authored stone/wood textures, production frosted-glass
refraction, glow art direction, final material quality or target-GPU performance.

Evidence: [commands/stdout/stderr](evidence/material_graphics_tcp_2026-09-23.log),
[actual screenshot](evidence/material_graphics_tcp_2026-09-23.png),
[toolchain verification](evidence/material_graphics_setup_2026-09-23.log).
The execution log records the source commit, script hash and screenshot hash.

## Reproduce after an environment reset

Read existing production/evidence first, as required by `ASTRA_WORKFLOW.md`.
Restore Godot with `tools/setup_linux_toolchain.py` if needed. For Linux x86_64
with Ubuntu 24.04-compatible system libraries:

```sh
python tools/setup_linux_graphics.py --prefix /absolute/path/to/graphics
python tools/run_graphical.py --graphics-prefix /absolute/path/to/graphics --godot /absolute/path/to/godot --expect 'ENGINE_PREFLIGHT PASS' -- --path game --script res://tests/engine_preflight.gd
python tools/run_graphical.py --graphics-prefix /absolute/path/to/graphics --godot /absolute/path/to/godot --expect 'MATERIAL_PREFLIGHT PASS' -- --path game --script res://tests/material_graphical_preflight.gd -- --screenshot=/absolute/path/to/material-preflight.png
```

Run a clean editor import before smoke tests if the import cache is absent.
`tools/linux_graphics_packages.json` pins versions, sizes and SHA-256 values
obtained from GPG-verified Ubuntu snapshot metadata dated 20260828T000000Z.
The installer extracts packages locally without apt or maintainer scripts.
Matching system LLVM/DRM/Vulkan packages may be reused; otherwise their pinned
packages are also restored locally. An existing unrelated xkbcomp is not replaced.

Both archive.ubuntu.com and the pinned snapshot are supported download sources;
the same locked size/hash must match either source. Snapshot downloads previously
returned incomplete bodies or timed out; the official archive mirror supplied
the identical Mesa package. Treat this as recoverable transport failure, not as
proof that X11/Vulkan is unavailable.

The renderer is CPU software Vulkan. GTX 1060-class 1080p/60 FPS profiling remains
a separate gate. Routine material work can now proceed with the existing approved
six-family scope; cross-stage architecture/global shader decisions retain their
own workflow requirements.

## Authored library validation — 2026-10-02

Source revision: `e304796` (full SHA in the evidence). Restored the missing
Godot/xkbcomp links with the existing local toolchain and installer, then reran
the authenticated TCP capability smoke before material tests. Godot 4.7.2,
X11/Vulkan/Forward+ and the llvmpipe runtime match the proven baseline.

| Check | Actual result |
|---|---|
| GitHub identity, origin read/write permission, Git fetch/push | PASS; MindDevastation, feature branch pushed |
| Authenticated origin LFS read | PASS; batch HTTP 200, remote 1992-byte GLB payload and expected SHA-256 |
| Dependencies / disk / branch base | PASS; local toolchain restored, ~30 GiB free, feature based on synchronized epic/main `2819831` |
| Map regeneration and integrity | PASS; eleven PNGs plus manifest reproduced byte-for-byte; 6,853,964 source PNG bytes |
| Editor import and script parse | PASS; exit 0, no script/resource errors |
| Minimal graphical engine smoke | PASS; X11 authorization, Vulkan/Forward+, GameRoot, eight autoloads, safe exit |
| Authored material review | PASS; six shared runtime resources in neutral/warm/cool light, 1920x1080 screenshots |
| Framebuffer contribution | PASS; mean RGB delta 0.101–0.799 across the three six-family views, threshold 0.015 |
| Tiling review | PASS; three opaque families repeat 4x4 without visible boundary discontinuities; generator also checks wrap-edge metrics |
| Cyrillic / visual inspection | PASS; all four final screenshots inspected, labels legible, material families distinct |

Visual review found and corrected compression banding/hard patina patches on
brass before acceptance. The final images show pale textured stone, smoothly
aged metal, polished dark grain, blurred/distorted backing through frosted glass,
clearer blue crystal refraction and warm emissive glow. Initial parse errors and
incomplete scratch PNG regeneration were fixed and retested; the final log
records the successful source revision and screenshot hashes.

Evidence: [commands/stdout/stderr](evidence/material_library_2026-10-02.log),
[neutral](evidence/material_library_neutral_2026-10-02.png),
[warm](evidence/material_library_warm_2026-10-02.png),
[cool](evidence/material_library_cool_2026-10-02.png),
[4x4 tiles](evidence/material_library_tiles_2026-10-02.png).

The six-family preview reports 24 draw calls and 127,269,760 texture bytes;
the tile view reports 5 and 118,975,360 respectively. These are total preview
counters including the environment/framebuffer, not incremental material costs
or target-hardware profiling. No new LFS payload/history migration was needed.

Accepted scope is the reusable baseline for sample asset integration. Stone
variants, memory text/imprints, crystal quality tiers, gameplay emission feedback,
transparent-surface overlap on real meshes and representative GTX 1060-class
1080p/60 Medium profiling remain open. No shipping-wide performance PASS is claimed.

## Hybrid Warcraft Observatory v2 validation — 2026-10-02

Feature: `feature/03-art-foundation/visual-rebaseline-v2`, pack `cabe792`, audit
checkpoint `92fa0f2`. Final implementation fingerprints and screenshot hashes:
[validation manifest](evidence/visual_rebaseline_v2/validation_manifest.json).
Reused the verified local toolchain and authenticated TCP workaround above.
Godot 4.7.2 / X11 / Vulkan 1.4.318 / Forward+ / llvmpipe LLVM 20.1.2 passed.

| Check | Actual result / scope |
|---|---|
| GitHub identity / origin Git and LFS access | PASS; MindDevastation, read/write permission, fetch/push, authenticated batch download and exact fixture hashes |
| Toolchain recovery / minimal capability smoke | PASS; verified local gh/Blender recovery, real source reopen, X11 cookie accepted and unauthenticated connection rejected, graphical GameRoot/eight-autoload startup/safe exit |
| Shared material implementation | PASS; 12 resources and 20 original 1024² PNG maps; five old resources unchanged, wood rematerialized, six shared resources added |
| Deterministic regeneration | PASS; all 20 maps and texture manifest reproduced byte-for-byte; 13,176,703 source PNG bytes |
| Godot editor import / script parse | PASS; exit 0, no script/resource errors |
| Unchanged source / GLB regression | PASS; meters, transforms, Y-up, bottom-center pivot, normals, UV, one material and script-free wrapper |
| Graphical review | PASS; all 12 resources in neutral/warm/cool, plus seven opaque 4×4 tile instances; four 1920×1080 final PNGs inspected |
| Framebuffer contribution | PASS; mean RGB delta 0.039619–0.816702 across 43 sample observations, threshold 0.015 |
| Russian labels / tile inspection | PASS; Cyrillic glyph checks and actual images legible, material families distinct, no visible tile boundary discontinuity |
| Existing runtime contracts | PASS; 14 source/configuration fingerprints unchanged; modular dimensions/physics/material ceilings unchanged |
| Actual puzzle interaction / save/load | N/A; production controllers/worlds are unbuilt, startup is not a puzzle smoke test |
| Target-class 1080p60 performance | BLOCKER for hardware certification only; no physical GPU exposed, software Vulkan cannot certify the target |

The sphere board reports **38 draw calls / 137,058,176 texture bytes**; tiles
report **9 / 128,763,776**. These are total isolated preview counters including
environment/framebuffer. They do not prove a shipping scene remains within its
budget or establish a new budget. No production scene/light/UI or Blender/GLB
payload changed. No LFS history migration or new LFS object was required.

Wood retains grain/color/normal/UV and its resource path, disables clearcoat and
raises ORM roughness toward aged timber. Iron/leather/woven textiles provide the
new reusable families; crimson/navy share the same weave maps. Clear glass and
teal emission remain compact substrates, with actual mesh sorting, gameplay
feedback and quality tiers deferred to their asset briefs.

Evidence and reproduction commands:
[index](evidence/visual_rebaseline_v2/README.md),
[preflight](evidence/visual_rebaseline_v2/preflight.log),
[import/export/startup](evidence/visual_rebaseline_v2/runtime_import.log),
[regeneration](evidence/visual_rebaseline_v2/material_reproduction.log),
[neutral](evidence/visual_rebaseline_v2/materials_neutral.png),
[warm](evidence/visual_rebaseline_v2/materials_warm.png),
[cool](evidence/visual_rebaseline_v2/materials_cool.png),
[tiles](evidence/visual_rebaseline_v2/materials_tiles.png),
[hardware scope](evidence/visual_rebaseline_v2/hardware_scope.log).

This is technical and surface/palette acceptance for the existing foundation.
Full Warcraft-inspired geometry, hero readability, environment art acceptance
and target-hardware performance remain open; overall rebaseline is PARTIAL.

## Archive structural material integration — 2026-10-03 UTC

Existing shared stone/brass resources now pass actual imported-mesh resource
identity and three-view graphical review on the five-module Archive sample.
Front/reverse/right-angle views use authenticated Xvfb TCP, X11, Vulkan Forward+
on software llvmpipe; final screenshots were inspected. No material/map change
or per-instance duplication. Primary: 63 instances, 4,284 triangles; isolated
preview draw calls 25/27/18 and 120,224,512 total texture bytes including the
environment/framebuffer. Independent LFS retrieval, explicit retrieved-source
opening, fresh import/physics and graphical startup PASS. Exact commands/hashes:
[sample evidence](evidence/modular_archive_kit/README.md).

This accepts stone/brass integration for this bounded structural family. Other
material families, full environment/hero art, gameplay integration and physical
GTX1060-class profiling retain their separate gates.
