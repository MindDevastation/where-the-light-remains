# Where the Light Remains

**Where the Light Remains** is a short atmospheric first-person romantic puzzle game for Windows, built in **Godot 4.7.2**.

## Current state

The working branch contains playable **S00 prologue → S01 Archive onboarding → S02 Wing I optics/Star/Hearth and return**, with Russian controls/UI, player movement, pause, settings, routing, transactional progression and private save/reload validation. Eight core services are implemented beyond the initial scaffold. Production art and authored audio remain incomplete: **GATE-VS1 is OPEN**, S03 is gated, and this is not the finished game. Current recoverable status and evidence are in [`docs/production/WORK_RECOVERY.md`](docs/production/WORK_RECOVERY.md); canonical acceptance coverage is in [`VS1_ART_RECONCILIATION_CURRENT.json`](docs/production/VS1_ART_RECONCILIATION_CURRENT.json).

## Run the current slice

Use Godot **4.7.2 stable** with Forward+. Check out `feature/04-archive-gameplay/resume-2026-10-06`, then run `git lfs install` and `git lfs pull` so committed GLB/source pointers become real payloads. Open `game/project.godot` in the editor and press F5, or launch `godot --path game` from the repository root (the configured boot scene opens the game). The editor command is `godot --editor --path game`. Baseline controls: WASD, mouse look, E interaction, Esc pause; settings expose bindings/accessibility options. Existing primary/backup saves must be preserved when running development checks.

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

S00–S02 are the current playable scope (3 of16 stages). Bounded Archive art, native feedback and material sources have per-family evidence; isolated specimens do not establish shipping acceptance. Full architecture/hero/dressing, source integration, authored audio/mix/owner decisions, owner review and physical GTX1060-equivalent1080p60 remain open. Audio routing/playback services exist; the completed artistic soundtrack/mix is not implied. Preserve canonical stages, accessibility, silence, save/checkpoints and performance budgets. Main remains unchanged until an authorized integration.

Engine verification and reproducible startup checks are recorded in
[`docs/production/ENGINE_PREFLIGHT.md`](docs/production/ENGINE_PREFLIGHT.md).

Input bindings, validation scope and repeatable checks are recorded in
[`docs/production/INPUT_MAP.md`](docs/production/INPUT_MAP.md).

Audio routing, mixer measurements and verification limits are recorded in
[`docs/production/AUDIO_BUSES.md`](docs/production/AUDIO_BUSES.md).
