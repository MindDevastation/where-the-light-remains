# InputMap validation

Runtime validation: **PASS**, 2026-09-20.

Epic: `epic/00-foundation`.
Feature: `feature/00-foundation/input-map`.
Integration follows feature → epic → main with separate merge commits.
The corresponding Git history records the integration SHAs.

## Implemented contract

Eight keyboard actions are persisted in `game/project.godot`: four walk
directions, `interact`, `pause`, `hint` and `skip_sequence`. The complete
action/key table and consumer contract are in
[`TECHNICAL_BASELINE.md`](../design/TECHNICAL_BASELINE.md#input--player).

WASD/E/H use physical key positions; Esc uses its logical keycode. Built-in
`ui_*` bindings are preserved. Each project action has one keyboard event,
any-device matching and the default `0.2` deadzone. There are no new
sprint/crouch/jump actions. The bindings were serialized with the pinned Godot
executable and loaded back by its project settings and InputMap APIs.

The existing input requirements remain authoritative. The generic `[E] / [R]`
prompt asset in the asset table does not define an R interaction, so this
feature adds no R action or invented puzzle behavior.

## Validation actually performed

- Engine: standard **Godot 4.7.2 stable**, executable version
  `4.7.2.stable.official.ed1daf0bf`, on Linux with the headless display server.
- Committed source: `09a0ba6f69200734c4cf5dea539bcdda10fce740`.
- Verified `game/` tree: `7ae0850a886eb9f9a8fc2c9ca08f2d1b6789427c`.
- Final validation used a fresh `git archive` of `game/`, with no `.godot/`
  cache before import. Archived source files were unchanged after the checks.

| Check | Actual result |
| --- | --- |
| Clean editor import | Exit 0; no script, parse or resource errors |
| InputMap event-dispatch test | Exit 0; `INPUT_MAP PASS` |
| Existing engine preflight regression | Exit 0; `ENGINE_PREFLIGHT PASS`, GameRoot/eight autoloads and App safe exit |
| Normal headless project startup | Exit 0 after 120 frames; no startup errors |
| Negative control using the original project settings without InputMap | Expected exit 1; all eight missing actions detected |

`game/tests/input_map_smoke.gd` passes constructed `InputEventKey` events
through the real engine's `Input.parse_input_event()` and flushes buffered
events. It checks persisted actions, press/release matching with Latin and
Cyrillic labels, differing physical/logical keycodes, release after a modifier
change, forward direction, normalized diagonals, opposing keys, shared Esc
state, keyboard repeat handling and retained `ui_cancel`/`ui_accept` behavior.
Mouse-motion events leave the keyboard action state clear.

An early test compared ordered action arrays and rejected the correct set.
The test now checks action count and membership without depending on ordering.
The final positive checks and negative control all use that corrected test.

Actual commands, output and exit codes are retained in
[`evidence/input_map_2026-09-20.log`](evidence/input_map_2026-09-20.log).
Terminal color escape sequences and trailing line spaces were removed from
the captured output.

## Scope and remaining work

These checks exercise real Godot input dispatch with synthetic events. They
do not test native OS keyboard delivery, physical hardware, live layout
switching or Windows execution. The earlier graphical engine preflight remains
recorded separately in [`ENGINE_PREFLIGHT.md`](ENGINE_PREFLIGHT.md).

This feature supplies bindings. Movement, mouse look, hints, pause UI and
repeat-playthrough skip eligibility/hold timing still need their consumers.
Both Esc actions report the same raw key state; their future consumers must
coordinate pause versus skip. No hold threshold is invented here.
`InputManager` retains sole ownership of mouse capture and input mode.

No player-facing text or UI was added. Cyrillic labels in injected events
verify input matching, not font rendering. Russian UI and Cyrillic rendering
remain acceptance gates for the later UI features. The test is CLI-only and
is not attached to a production scene or autoload. Tool binaries, import caches
and temporary validation projects are excluded from the repository change.

## Reproduce

From the repository root, with `GODOT` set to the verified executable:

```sh
"$GODOT" --headless --path game --editor --import
"$GODOT" --headless --path game --script res://tests/input_map_smoke.gd
"$GODOT" --headless --path game --script res://tests/engine_preflight.gd
"$GODOT" --headless --path game --quit-after 120
```

All four commands must exit 0 without script, parse or resource errors.
The two assertion scripts must emit their respective `PASS` markers.
Before integration, preserve the validated runtime files and repeat the
startup smoke on the epic candidate. Later gameplay work should extend the
input test when it adds or changes the approved action contract.

Engine API references:
[InputEventKey](https://docs.godotengine.org/en/4.7/classes/class_inputeventkey.html),
[InputMap](https://docs.godotengine.org/en/4.7/classes/class_inputmap.html),
[InputEvent processing](https://docs.godotengine.org/en/4.7/tutorials/inputs/inputevent.html).

Next foundation feature: `feature/00-foundation/audio-buses`.
