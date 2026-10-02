# Visual rebaseline v2 evidence

Date: 2026-10-02 UTC. Pack: `cabe792717828dfe54009219a7f6cc4e0fb5e5e6`.
Feature: `feature/03-art-foundation/visual-rebaseline-v2`.
Audit commit: `92fa0f29e5156a5926c44ad24696a49e3d1137ca`.
Material/evidence commit: `feb658a02c41d334804620b1b6ad303df83b864a`.
Feature integration: [PR #23](https://github.com/MindDevastation/where-the-light-remains/pull/23),
merged epic `93a8e116adac4bad4c04dc16fd795ea64450437e`.

**Bounded shared-material/reference foundation: PASS. Overall visual rebaseline:
PARTIAL. Target physical-GPU certification: BLOCKER for that gate only.**
No new LFS objects or history migration. Canonical mechanics/text/budgets unchanged.

| Evidence | Meaning |
|---|---|
| [concept_inventory.json](concept_inventory.json) | Exact 167 incoming paths, sizes, image hashes and Git blobs pinned to owner pack |
| [audit_integrity.log](audit_integrity.log) | Full PNG decode/hash checks, 62 old payloads retained, 14 unchanged runtime fingerprints, 9 additional decisions; one known missing C |
| [preflight.log](preflight.log) | Actual toolchain recovery failures and successful repair, auth/permission/LFS/disk checks, Blender probe/source reopen, minimal authenticated X11/Vulkan engine smoke |
| [runtime_import.log](runtime_import.log) | Final editor import, unchanged GLB technical regression and headless startup commands/output/exit codes |
| [material_reproduction.log](material_reproduction.log) | Twenty maps and texture manifest reproduced byte-for-byte; 13,176,703 source PNG bytes |
| [contract_preservation.log](contract_preservation.log) | Modular technical dimensions/axes/grid/physics/ceilings/sample exactly unchanged |
| [materials_neutral.log](materials_neutral.log) / [PNG](materials_neutral.png) | Twelve actual shared resources, neutral key, cobalt/amber review environment |
| [materials_warm.log](materials_warm.log) / [PNG](materials_warm.png) | Same twelve resources, warm key |
| [materials_cool.log](materials_cool.log) / [PNG](materials_cool.png) | Same twelve resources, cool key |
| [materials_tiles.log](materials_tiles.log) / [PNG](materials_tiles.png) | Seven opaque instances including both textile tints, 4×4 UV repetition, final separated label layout |
| [validation_manifest.json](validation_manifest.json) | SHA-256/bytes of final authored source/resources and four final screenshots |
| [hardware_scope.log](hardware_scope.log) | Exact exposed-device enumeration: no physical render/NVIDIA device; pinned software Vulkan is not target-GPU certification |
| [integration_epic_smoke.log](integration_epic_smoke.log) | Merged epic tree exactly equals validated feature; authenticated X11/Vulkan GameRoot/eight-autoload/safe-exit smoke PASS |

All four PNGs were visually inspected. There are 43 framebuffer sample observations
(12×3 + 7), with RGB delta 0.039619–0.816702 against backing-only renders;
threshold 0.015. The runner accepts the authorized X11 cookie and rejects a client
without it. Actual renderer: Godot 4.7.2, X11, Vulkan 1.4.318, Forward+,
llvmpipe LLVM 20.1.2. Known nonfatal Xvfb interface/unused keysym warnings match
the successful historical baseline. No headless substitute or TCP-disabled path.

Sphere board counters: 38 draw calls / 137,058,176 texture bytes. Tile board:
9 / 128,763,776. Both include environment/framebuffer; neither is incremental
material cost or proof of the approved shipping performance budget.

## Reproduction

Use already recovered, verified local dependencies; read production/preflight
history first. Absolute toolchain paths are environment-specific. From repo root:

```sh
python tools/audit_visual_baseline.py
python tools/generate_material_maps.py
/absolute/path/to/godot --headless --editor --path game --quit
/absolute/path/to/godot --headless --path game --script res://tests/lfs_export_smoke.gd
python tools/run_graphical.py --graphics-prefix /absolute/path/to/graphics --godot /absolute/path/to/godot --expect 'ENGINE_PREFLIGHT PASS' -- --path game --script res://tests/engine_preflight.gd
python tools/run_graphical.py --graphics-prefix /absolute/path/to/graphics --godot /absolute/path/to/godot --timeout 240 --expect 'MATERIAL_LIBRARY PASS' -- --path game --resolution 1920x1080 --script res://tests/material_library_smoke.gd -- --v2 --light=neutral --screenshot=/absolute/path/to/neutral.png
```

Repeat the final command with `--light=warm`, `--light=cool`, and
`--light=neutral --tiles`, using separate screenshot paths. Compare map/manifest
hashes before and after generation to establish determinism. The logs retain
actual commands and stdout/stderr; only trailing padding/terminal blank lines
were normalized. No credential value is retained.

Neutral/warm/cool images precede the final **tile-only** presentation refinement
(quad size/label offset). Their sphere path/materials/light behavior is unchanged.
The final tile image was regenerated, passed checks and inspected after refinement.
The validation manifest fingerprints the final source snapshot, not a claim that
all earlier images were captured with that exact full-file hash.

## Reference comparison and acceptance limits

Exact reference A/B/C paths and hashes are in the migration matrix/JSON and
concept inventory; material and lighting v2 sheets govern this surface review.
The full incoming pack and all 62 historical PNGs were inspected in labeled
contact sheets. A/B/C represent one design, not three allowed models.

Neutral/warm/cool are lighting presets, **not** implementation camera A/B/C for
an environment/hero. No major environment/hero was modified because none exists;
there is no invented three-camera evidence or gameplay/character art acceptance.
Blender/GLB/source tests are regressions of the unchanged technical cube family,
not new modeling acceptance. No puzzle/save interaction exists to smoke.

Warcraft-inspired geometry/craftsmanship, hero readability, transparent overlap,
shipping UI and 1080p60 target-class profiling remain their later asset gates.
Missing Secrets-Achievements C, six unmatched additional exact-slot assignments,
and final casting/asset inputs pause only dependent work. The next safe roadmap
step is the bounded five-module Archive sample under the updated v2 brief.
