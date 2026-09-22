# Minimal Blender → GLB → Godot sample

This is a technical fixture, not a production prop or an art-quality baseline.
No gameplay scene instances it. Runtime performance on target hardware has not
been measured and is not inferred from this small import test.

## Files and contract

- Source: `assets/3d/blender/validation/sm_pipeline_meter_cube.blend`.
- Export: `game/art/meshes/validation/sm_pipeline_meter_cube.glb`.
- Wrapper: `game/tests/fixtures/lfs_export_sample.tscn`.
- One-meter cube, Blender metric units, identity object transforms.
- Bottom-center origin: Blender bounds (-0.5,-0.5,0) to (0.5,0.5,1).
- GLB Y-up export; Godot bounds (-0.5,0,-0.5) to (0.5,1,0.5).
- Outward normals, one UV layer, one neutral material slot.
- A rotation around the wrapper's Y axis preserves the bottom-center pivot.
- Imported art and its wrapper have no attached scripts. No collision is needed
  for this isolated geometry fixture; gameplay collision remains authored in
  Godot under the existing production policy.

The neutral imported material only verifies material transport. Shared production
materials will be owned by Godot under `game/art/materials/` in the next feature.
No rig, animation, hero prop, LOD strategy or geometry budget is established here.

## Reproduce

Use the verified tools described in `BLENDER_PREFLIGHT.md`. To create a new
sample, run the following in a disposable checkout without either binary;
the generator refuses to overwrite them:

```sh
blender --background --factory-startup --python-exit-code 1 --python tools/create_export_sample.py -- /absolute/repository
```

To validate existing/retrieved binaries from the repository root:

```sh
blender --background assets/3d/blender/validation/sm_pipeline_meter_cube.blend --python-exit-code 1 --python tools/verify_export_source.py
godot --headless --path game --editor --import
godot --headless --path game --script res://tests/lfs_export_smoke.gd
godot --headless --path game --script res://tests/engine_preflight.gd
```

Source reopening checks meter scale, transforms, geometry bounds, outward
normals, UV layer and material count. The Godot test checks imported geometry,
Y-up scale, pivot rotation, normals, UV presence, material assignment and absence
of gameplay scripts. This is CLI import validation, not visual art acceptance.

See `LFS_POLICY.md` for the separate remote payload retrieval gate.

## Remote validation result

PASS on 2026-09-22 for sample commit
`b6bda309cd2e0a26553bb675515d2609dfa253b9`: both committed LFS pointers were
uploaded and independently retrieved from GitHub, with exact manifest hashes.
Blender source reopen, Godot import/geometry/startup, InputMap, audio buses and
fresh-clone full Git/LFS fsck all passed. See `LFS_POLICY.md` for partial-clone
ordering and `evidence/lfs_retry_2026-09-22.log` for the actual output.
