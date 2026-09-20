# Runtime art

Godot-ready art lives here after validated promotion from `assets/3d/` and other approved source packages.

Planned structure:

```text
game/art/
├── meshes/
├── materials/
├── textures/
├── shaders/
├── vfx/
└── animations/
```

Rules:
- imported art is wrapped in authored `.tscn` scenes rather than carrying gameplay authority itself;
- runtime naming follows `docs/design/TECHNICAL_BASELINE.md`;
- gameplay behavior remains under `game/gameplay/`, `game/worlds/` and related GDScript controllers;
- every promoted asset must pass the checklist in `docs/production/THREE_D_PRODUCTION_PIPELINE.md` and be reflected in `docs/production/ASSET_INDEX.md`.
