# Where the Light Remains

**Where the Light Remains** is a short atmospheric first-person romantic puzzle game for Windows, built in **Godot 4.7.2**.

## Current state

The initial Godot scaffold has **passed engine preflight** with Godot 4.7.2: editor import, eight-autoload startup, Forward+ rendering and orderly shutdown were verified in the Linux development environment. The narrative, stage flow, puzzle baseline, art direction, audio direction, technical architecture, performance budget and required asset manifest are approved. Selected concept art and the curated music package are stored in the production asset tree and indexed for implementation.

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

The initial Godot project and eight core service skeletons are runnable in the verified preflight environment. The baseline keyboard InputMap and ten-bus audio layout are configured and covered by real-engine checks. Audio routing, Music/SFX parent gain and mute were verified using an in-memory test signal. The next foundation feature is development-only debug tooling.

Player movement, mouse look, pause, hold-to-skip, settings UI and full AudioDirector playback belong to later features. Implementation must preserve the approved stage map, accessibility constraints, silence map, save/checkpoint contract and GTX 1060 performance budget.

Engine verification and reproducible startup checks are recorded in
[`docs/production/ENGINE_PREFLIGHT.md`](docs/production/ENGINE_PREFLIGHT.md).

Input bindings, validation scope and repeatable checks are recorded in
[`docs/production/INPUT_MAP.md`](docs/production/INPUT_MAP.md).

Audio routing, mixer measurements and verification limits are recorded in
[`docs/production/AUDIO_BUSES.md`](docs/production/AUDIO_BUSES.md).
