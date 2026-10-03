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
features. Actual acceptance evidence and scope follow.

## Accepted implementation — 2026-10-03 UTC

**PASS** on clean committed source; see `evidence/settings/README.md` and its
source/hash manifest. Exactly eight autoloads remain. `snapshot()`, `validate()`,
`load_settings()`, `apply_settings()` and `save_settings()` are the service API.
Only explicit Apply writes; failures return an Error and preserve current state.
Version 1 ConfigFile fields are typed; absent fields use defaults, future versions
are rejected, finite numeric values are clamped, and files over 64 KiB are rejected.
Atomic temporary write/flush/rename is tested on this Linux filesystem. Windows
replacement and power-loss durability are not certified by this check.

GameRoot owns a hidden `SettingsMenu`; callers invoke `open()`. Draft, defaults,
Cancel/Esc and Apply are tested through actual Godot GUI mouse/key dispatch,
including numeric text without Enter. Closing does not override a later DISABLED
lock. The modal itself does not pause or route worlds; main-menu/pause entry points
are next. Error text is Russian. Both actual screenshot resolutions were inspected;
this initial shell layout does not imply final game UI art approval.

Settings own Master/Music/SFX preference gains/mutes; semantic music/ambience and
silence remain AudioDirector responsibilities. The serialized neutral bus resource
is unchanged. The mixer regression normalizes only its test signal fixture, then
restores and rechecks actual startup preferences.

Runtime environment copies preserve authored resources/effect flags. New attached
WorldEnvironment/Light3D nodes receive current settings; deliberate environment
replacement is observed on the next `apply_scene_graphics()` / preference Apply.
Light shadow restoration preserves the authored flag at first attachment. Future
world controllers changing these flags must coordinate with this preference owner.
Geometry/emission/ordinary fog and puzzle parameters are unchanged. Profiles are
initial technical mappings, not GTX1060 performance certification.

Resolved findings retained in evidence: Godot consumes engine display flags, so
the launcher forwards `--preserve-display`; numeric Apply must call SpinBox.apply()
before reading its value. Headless GUI tests explicitly size their virtual Window.
Malformed ConfigFile input produces one expected parser ERROR in the isolated
headless negative case; graphical tests exclude that case and retain strict
zero-ERROR runner acceptance.
