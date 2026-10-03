# Settings persistence and Russian UI

## Implementation brief — 2026-10-03 UTC

Authority: `docs/design/TECHNICAL_BASELINE.md` settings contract; existing
`INPUT_FOCUS.md`, `PLAYER_INTERACTION.md`, `AUDIO_BUSES.md` and their successful
evidence. Use the established authenticated TCP X11/Forward+ runner serially.

This feature implements validated ConfigFile preferences separately from SaveGame,
an atomic replacement on explicit Apply, and a reusable Russian modal. Missing
files use defaults without writing; invalid/unreadable files return an explicit
error and are preserved. Failed writes do not change live settings. Cancel and
reset-to-defaults only affect the draft. InputManager continues owning capture.

Initial technical defaults: Master 1, Music .8, SFX .9; sensitivity .5 (range
.1–2), FOV 75 (50–110), normal Y; 1280×720 window, Medium, shadows/effects on.
Resolution choices: 1280×720, 1600×900, 1920×1080. These are initial shell values,
not puzzle parameters or a measured target-hardware quality certification.

Initial renderer profiles: Low .75 render scale / no MSAA / 512 positional shadow
atlas; Medium 1 / no MSAA / 2048; High 1 / 2× MSAA / 4096. Shadows additionally
gate authored light shadow flags; effects gate authored glow, SSAO, SSIL, SSR and
volumetric fog without enabling anything the author disabled. Original environment
resources are not edited. Gameplay geometry, emission, cues and ordinary fog stay.
Fullscreen uses desktop size and selected resolution as an upper render-height
target; UI remains at native size. Windowed uses the selected window size.
The graphical launcher forwards `-- --preserve-display` for command-line display
overrides, preserving the native startup window until explicit Apply. Direct
launches requiring an engine display override must include this user flag too:
Godot consumes `--resolution`/`--fullscreen` before exposing its argument list.

Acceptance: clean source import; missing/round-trip/malformed/type/range/version/
write-failure persistence cases; actual bus gains/mutes; profile/author-state
restoration and future world attachment; draft/Apply/Cancel ownership; actual
Forward+ Russian interface at 1280×720 and 1920×1080; existing startup/input/player/
read-only-debug/mixer regressions. Main-menu and pause entry points are subsequent
features. Acceptance is pending until actual evidence is retained.
