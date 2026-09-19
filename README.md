# Where the Light Remains

**Where the Light Remains** is a short atmospheric first-person romantic puzzle game for Windows, built in **Godot 4.7.2**.

## Current state

The project has moved from content preparation into **implementation preflight / initial implementation**. The narrative, stage flow, puzzle baseline, art direction, audio direction, technical architecture, performance budget and required asset manifest are approved. Selected concept art and the curated music package are now stored in the production asset tree and indexed for implementation.

## Core profile

- Genre: atmospheric first-person narrative puzzle
- Platform: Windows PC
- Engine: Godot 4.7.2 stable / GDScript / Forward+
- Main path: approximately 15–30 minutes
- Structure: central observatory/archive hub, five wings, three memories and finale
- Visual direction: stylized realism; magical archive / observatory
- Performance target: 1920×1080 / 60 FPS on GTX 1060-class hardware
- Ending: one canonical ending; optional secrets never gate the finale

## Repository layout

```text
.
├── docs/                 # canonical implementation-facing design/production docs
├── assets/
│   ├── concept_art/      # selected production references
│   ├── characters/       # future source/model intake
│   └── audio/
│       ├── music/        # curated source masters + runtime policy
│       ├── ambience/
│       └── sfx/
└── game/                 # Godot project and runtime implementation
```

The full long-form master document remains the source of truth for details not reproduced in repository splits. `docs/design/PROJECT_BIBLE_INDEX.md` defines precedence.

## Public repository notice

This repository is intentionally public by project-owner decision. It contains story spoilers, personal narrative material and final-sequence references. Do not redistribute third-party assets independently of their licenses.

## Implementation status

Initial Godot project structure and core service skeletons are now allowed. Implementation must preserve the approved stage map, accessibility constraints, silence map, save/checkpoint contract and GTX 1060 performance budget.

Engine verification and reproducible startup checks are recorded in
[`docs/production/ENGINE_PREFLIGHT.md`](docs/production/ENGINE_PREFLIGHT.md).
