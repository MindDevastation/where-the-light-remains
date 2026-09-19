# Technical baseline — Godot 4.7.2

Derived from Technical Specification v1.1 + Performance Budget v1.0.

## Verified engine

- Development baseline: **Godot 4.7.2 stable**, standard GDScript editor (not .NET).
- Executable output: `4.7.2.stable.official.ed1daf0bf`.
- Project feature tags: `4.7`, `Forward Plus`; target platform remains Windows.
- The version was verified using the executable, a real editor import and runtime
  startup/safe-exit checks. It was not inferred from the archive name.
- Repeat engine preflight before changing this baseline. Verification scope and
  integration status are recorded in `docs/production/ENGINE_PREFLIGHT.md`.

## Runtime architecture

Persistent structure:

```text
Boot
└── MainMenu
    └── GameRoot
        ├── PlayerContainer/Player
        ├── UILayer
        ├── TransitionLayer
        └── WorldSlot
            └── CurrentWorldScene
```

Archive gameplay uses one connected `archive_main.tscn`; memories are separate PackedScenes. Epilogue is either a separate lightweight scene/chunk or an authored exterior continuation when profiling allows.

## Autoload hard limit

Maximum baseline: 8.

- `App`
- `GameState`
- `SaveManager`
- `SceneRouter`
- `AudioDirector`
- `SettingsManager`
- `InputManager`
- `EventBus`

Level-specific puzzle/cutscene logic must never move into autoloads.

## Required res:// layout

```text
res://
├── autoload/
├── core/
│   ├── game_root/
│   ├── player/
│   ├── interaction/
│   ├── transitions/
│   ├── ui/
│   └── debug/
├── worlds/
│   ├── archive/
│   ├── memories/
│   └── epilogue/
├── gameplay/
│   ├── puzzles/
│   ├── collectibles/
│   ├── checkpoints/
│   ├── hazards/
│   └── scripted_sequences/
├── data/
│   ├── stages/
│   ├── fragments/
│   ├── audio/
│   ├── text/
│   └── settings/
├── audio/
├── art/
├── ui/
├── localization/
└── tests/
```

## Scene routing

Only `SceneRouter` changes major world scenes. Transition order: lock input → checkpoint when required → preload target → unload WorldSlot child → instantiate → apply logical state → spawn player → set audio state → fade/dissolve → restore input.

Gameplay scripts do not call `change_scene_to_file()` directly.

## Save contract

Save logical state only — never SceneTree serialization.

- Typed in-memory `SaveGame`.
- Disk format: validated JSON at `user://savegame.json` plus backup.
- Atomic temp write / flush / backup / replace.
- Sequential schema migration by `save_version`.
- Corrupt primary falls back to backup; if both fail, offer New Game rather than silently destroying data.
- Settings are separate at `user://settings.cfg`.

Checkpoints: Archive after required fragment milestones and around memories; Egg uses disk before/after plus runtime CP0–CP5; final puzzle saves solved pairs; poem/acrostic/confession use milestones; `game_completed` is persisted before credits.

## Input / player

First-person `CharacterBody3D`; walk + look baseline. No sprint/crouch/jump unless a specific scripted state needs it. `InputManager` exclusively owns mouse capture and input mode. Baseline actions: WASD, mouse look, E interact, Esc pause, optional H hint, long-hold Esc repeat-playthrough skip.

Settings must expose resolution, fullscreen/windowed, graphics preset, shadows/effects, Master/Music/SFX, mouse sensitivity, FOV and invert-Y.

## Naming

- files/scenes/resources: `snake_case`
- nodes/classes: `PascalCase`
- signals/methods: `snake_case`
- textures: `t_<family>_<map>`
- materials: `m_<name>`
- static meshes: `sm_<name>`
- animations: `anim_<actor>_<event>`
- runtime music: `mus_s##_name_v##`
- ambience: `amb_s##_name_v##`
- SFX: `sfx_s##_family_event_##`

The WAV files under `assets/audio/music/` are retained as **source masters**; derived runtime files imported into `game/audio/` must follow canonical runtime naming.

## Performance target

Reference: GTX 1060 6GB-class, 1920×1080/60 Medium. Exact minimum CPU/RAM remains TBD.

- frame budget: 16.67 ms
- typical GPU target: roughly ≤12–14 ms; stricter profiler target preferred
- CPU main gameplay target: roughly ≤7–8 ms maximum production envelope
- visible geometry guideline: ~0.5–1.5M triangles typical
- dynamic shadow lights: normally 2–4 maximum, usually Directional + 1–2 hero locals
- VRAM target: ~4.0–4.5 GB; warning above 4.5–5.0 GB
- gameplay RAM target: ~2.5–4.0 GB; warning above 6 GB
- build: ≤5 GB, preferably substantially smaller

Low preset may reduce volumetrics, SSR/refraction, particles, decorative VFX, local shadow lights and render scale, but cannot remove gameplay clues or narrative information.

Profiling, not polycount alone, decides acceptance. Minimum three full profiler-assisted runs before release candidate.
