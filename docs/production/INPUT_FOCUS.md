# Input ownership and focus / pause contract

Epic: `epic/01-shell`. Feature: `feature/01-shell/input-focus`.
Standing owner request: Extra High / highest available; no agent-side model
switch is claimed. Existing production/evidence and the accepted TCP graphics
workaround were read before implementation.

## Behavior

`InputManager` owns requested mode, mouse capture and explicit tree pause.
Startup uses `UI` with a visible cursor; the empty GameRoot does not capture it.
Call `set_mode()` to change mode and `set_paused()` to pause/resume. Requested
mode survives focus loss and pause; returning to the window never overwrites
`UI`, `CINEMATIC` or a routing `DISABLED` lock. Focus loss blocks gameplay input
and releases capture. It does not itself pause world simulation.

| Requested mode | Focused, unpaused | Walk / interact | Mouse |
| --- | --- | --- | --- |
| GAMEPLAY | Look available | Enabled | Captured |
| LIMITED_LOOK | Look available | Disabled | Captured |
| UI / CINEMATIC / DISABLED | Look unavailable | Disabled | Visible |
| Any, unfocused or paused | Look unavailable | Disabled | Visible |

Consumers use `can_move()`, `can_look()`, `can_interact()` and
`get_movement_vector()`. The latter preserves the InputMap circular deadzone,
forward direction and normalized diagonals, filtering controls held across an
input boundary until release or a fresh non-echo press. Pause/focus/mode changes
release the six gameplay actions; keyboard echo cannot resurrect walking.
The first recapture motion is consumed before a player's `_unhandled_input`
look callback to prevent a warp jump. UI mouse motion retains its GUI route.
Signals `mode_changed`, `availability_changed`, `pause_changed` let consumers
clear velocity, targets or UI without taking over mouse capture.

The autoload processes while paused. Direct legacy changes to `SceneTree.paused`
close input gates immediately and synchronize capture on its next process
frame; production callers should use `set_paused()` for synchronous capture.
Existing eight autoloads and eight keyboard actions are preserved.

Esc is still the shared raw pause/skip source. This service does not bind Esc,
invent a skip hold threshold or enable hints. Pause UI and eligible scripted
sequence consumers coordinate those requests in their later features.

## Verification

`tests/input_focus_smoke.tscn` is CLI-only. It exercises 20 mode/focus/pause
combinations with synthetic Window signals, diagonal/forward motion, held-key
and repeat boundaries, UI pointer routing, shared Esc and built-in navigation,
direct tree pause and recapture motion. A separate optional
`tools/x11_focus_driver.py` drives **actual XSetInputFocus** events on the
authenticated isolated Xvfb display: capture releases on focus loss; UI selected
while unfocused stays UI; focus return while paused remains blocked; resume
restores gameplay; `DISABLED` survives return. It uses no new runtime dependency.

Godot baseline is 4.7.2, X11/Vulkan Forward+ through local TCP with
MIT-MAGIC-COOKIE, software llvmpipe. Headless runs cannot validate native capture;
the graphical run asserts actual mouse mode and actual Window focus. Native
Windows input, physical keyboard layout switching and target GPU performance
remain untested. No UI art or puzzle solve behavior is introduced.

The historical debug inspector harness now restores mode using the owner
instead of writing `Input.mouse_mode`. Its complete state/file equality checks
remain in place; the inspector itself remains read-only.

Final committed-source clean import, native focus and startup/regression results
are recorded in `evidence/input_focus/`. Source SHA and hashes are in the README.

## Reproduce

```sh
"$GODOT" --headless --path game --editor --import
"$GODOT" --headless --path game res://tests/input_focus_smoke.tscn
python3 tools/run_graphical.py --graphics-prefix /absolute/graphics --godot "$GODOT" --timeout 70 --expect 'INPUT_FOCUS PASS' -- --path /absolute/repo/game --max-fps 30 res://tests/input_focus_smoke.tscn -- --native-driver=/absolute/repo/tools/x11_focus_driver.py
```

All commands must exit zero without parse/script/resource errors. The driver
and test scene are not attached to a production scene or autoload. Do not use
`-nolisten tcp` for the proven graphics path.

Engine API references: [Input](https://docs.godotengine.org/en/stable/classes/class_input.html),
[Window focus signals](https://docs.godotengine.org/en/stable/classes/class_window.html),
[Node process modes](https://docs.godotengine.org/en/stable/classes/class_node.html).

## Pause consumer checkpoint — 2026-10-03 UTC

The later Russian PauseMenu now consumes fresh Esc for active GAMEPLAY/LIMITED_LOOK
players and delegates mode/pause/capture to this service. Empty UI, DISABLED and
CINEMATIC leave raw Esc available; sequence arbitration remains later work. Nested
settings, held-key/recapture, later locks and removed pause scenes are validated in
`PAUSE_FADE.md` and `evidence/pause_fade/`. InputManager ownership is unchanged.
