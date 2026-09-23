# Material library preflight

Status: **PASS — graphical environment and material capability preflight** (2026-09-23).

Recovery feature: `feature/03-art-foundation/graphics-preflight`.
Next production feature: `feature/03-art-foundation/material-library`.
The six shared production material families remain unimplemented/unaccepted.
This preflight uses isolated procedural test specimens under `game/tests/`;
it does not introduce production materials, textures or a global shader strategy.

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
