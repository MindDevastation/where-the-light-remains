# 3D source assets

This directory is the DCC/source side of the 3D pipeline.

Planned structure:

```text
assets/3d/
├── blender/           # .blend source files
├── textures_source/   # source texture/paint files
├── reference/         # approved modeling reference packages
└── export_staging/    # temporary export staging; not a shipping source
```

Rules:
- follow `docs/production/THREE_D_PRODUCTION_PIPELINE.md`;
- do not bulk-add `.blend`, `.glb`, `.gltf`, `.fbx` or other heavy binaries until the Git LFS migration/policy is actually validated;
- source assets do not contain gameplay authority;
- approved concept art remains reference only; mechanics follow canonical design docs;
- runtime-ready exports are promoted into `game/art/` and indexed in `docs/production/ASSET_INDEX.md`.
