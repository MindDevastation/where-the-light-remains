# Engine preflight

Runtime validation: **PASS**, 2026-09-19.

Epic: `epic/00-foundation`.
Feature: `feature/00-foundation/engine-preflight`.
Merge gate: preserve the verified game tree, merge feature into epic, then
integrate the runnable slice into `main` with a separate merge commit.
Integration SHAs are recorded by the corresponding Git merge history.

## Verified runtime

- Godot: `4.7.2.stable.official.ed1daf0bf`.
- Engine version fields: major `4`, minor `7`, patch `2`, status `stable`,
  build `official`, source hash `ed1daf0bf001b61586d9930840f2f1394092c079`.
- Standard GDScript editor; runtime `OS.has_feature("C#")` returned `false`.
- Executable used:
  `/workspace/scratch/4f0b36b4bb0e/toolchain/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`.
- Development environment: Ubuntu 24.04 x86_64. Product target remains Windows.
- Graphical renderer: **Forward+**, Vulkan `1.4.318`, Mesa `25.2.8`
  lavapipe, reported device `llvmpipe (LLVM 20.1.2, 256 bits)`.
- X11 display: local Xvfb, 1920x1080; audio driver: `Dummy`.
- Official release: <https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable>.
- Download: `Godot_v4.7.2-stable_linux.x86_64.zip`.
- SHA-256 checked against the official release asset digest:
  `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.

The official stable release was installed because this environment had no
Godot executable and the project had no verified minor version. The owner
explicitly authorized installing the required tools. The version was pinned
only after executing Godot and successfully importing/running the scaffold.

## Validation actually performed

- All ten mandatory design/production documents read at starting commit
  `6e04017fa4238fe1f32721c02dcf91a200c45ecc`.
- `main`, `epic/00-foundation` and `feature/00-foundation/engine-preflight`
  fetched and verified at that starting commit.
- `--version`: confirmed the exact executable build above.
- Final validation used a fresh `git archive` of the committed `game/` tree,
  initially without a `.godot/` cache. Runtime source/configuration revision:
  `feb061bc97803d17f1915c87a4209e679d70a000`.

| Check | Actual result |
|---|---|
| Clean editor import, `--headless --editor --import` | Exit 0; no script/parse/resource errors |
| Clean normal project startup, `--headless --quit-after 120` | Exit 0; no startup errors |
| Headless asserted smoke | Exit 0; `ENGINE_PREFLIGHT PASS` |
| X11/Vulkan asserted smoke | Exit 0; `ENGINE_PREFLIGHT PASS`; Forward+ device header confirmed |
| Normal graphical project startup | Visible 1280x720 window; stayed running for at least 5 seconds |
| Native close request, `WM_DELETE_WINDOW` | Normal project exited with code 0 |

The asserted smoke uses the real engine to check:

- exactly `App`, `GameState`, `SaveManager`, `SceneRouter`, `AudioDirector`,
  `SettingsManager`, `InputManager`, `EventBus`, each with an instantiable script;
- the configured main scene exists, loads and creates `GameRoot`;
- `PlayerContainer`, `UILayer`, `TransitionLayer` and `WorldSlot` exist;
- GameRoot binds WorldSlot and emits the initial stage event;
- 1920x1080 viewport, 60 physics ticks/sec and configured Forward+;
- the scene remains alive after startup and `App.request_safe_exit()` exits.

The 1280x720 window is the scaffold's existing window-size override; the
1920x1080 viewport baseline was preserved. An empty gray GameRoot view is
expected at this milestone.

Actual command output is retained in
[`evidence/engine_preflight_2026-09-19.log`](evidence/engine_preflight_2026-09-19.log).

## Errors found and fixes

No blocking scaffold parse, resource-path or startup errors were found.
Existing service behavior and the main scene required no fixes.

Environment issues encountered and resolved:

1. Godot initially returned `command not found` (127). Installed the official
   standard executable locally and checked its release SHA-256 before use.
2. System APT could not perform its privilege drop (`setgroups`/`seteuid`).
   Required Ubuntu snapshot packages were extracted into the local toolchain;
   archive signatures and package checksums were verified. No package
   maintainer scripts were needed.
3. Unix-domain sockets are unavailable here. Xvfb used local TCP with
   MIT-MAGIC-COOKIE authorization. Its hard-coded `xkbcomp` dependency was
   linked to the locally extracted executable.
4. Bare Xvfb had no window manager to initialize `WM_DELETE_WINDOW`; the first
   close attempts timed out. Initializing that standard protocol atom before
   Godot and keeping Xvfb alive with `-noreset` fixed native close. This changed
   only the verification environment, not the game.

Xvfb reported nonfatal interface-enumeration and unused multimedia-keysym
warnings. Final Godot import/startup/shutdown runs had no script, resource or
fatal errors.

Repository changes:

- added the CLI smoke check and tracked Godot-generated script UID metadata;
- pinned project feature tags to `4.7` / `Forward Plus` after real validation;
- recorded exact Godot 4.7.2 version and synchronized implementation status.

No narrative, InputMap, audio-bus, gameplay or future-system implementation
was added. No toolchain binaries, heavy assets, `.godot/` caches, credentials
or temporary files are part of the change.

## Scope of the result

The renderer test used CPU software Vulkan. Windows export/execution, physical
GPU performance, GTX 1060 frame budgets, real audio output, and Cyrillic UI
rendering have not been tested by this preflight. They remain future QA gates
when those systems exist. No production player-facing text was added.

## Reproduce

From the repository root, with `GODOT` set to the Godot 4.7.2 executable:

```sh
"$GODOT" --version
"$GODOT" --headless --path game --editor --import
"$GODOT" --headless --path game --script res://tests/engine_preflight.gd
"$GODOT" --path game --script res://tests/engine_preflight.gd
"$GODOT" --path game
```

Every process must exit successfully and its output must contain no
`SCRIPT ERROR`, parse errors, missing resources or fatal startup errors.
The assertion run must print `ENGINE_PREFLIGHT PASS`. Close the normal project
window using the window close button. The graphical commands require a working
display and Vulkan support. In a virtual X11 environment without a window
manager, initialize the `WM_DELETE_WINDOW` atom before launching Godot.

The smoke script is CLI-only and is not registered as an autoload or attached
to a production scene. Generated `.gd.uid` files are tracked resource identity
metadata. The `.godot/` editor/import cache remains ignored.

Next allowed feature after integration: `feature/00-foundation/input-map`.
It is not implemented by this change.

## Reusable graphical recovery — 2026-09-23

The TCP/cookie workaround above was reproduced with the same Godot, Vulkan,
Mesa and LLVM baseline. Use `tools/setup_linux_graphics.py` and
`tools/run_graphical.py`; exact commands and current evidence are documented in
[MATERIAL_PREFLIGHT.md](MATERIAL_PREFLIGHT.md). Do not disable TCP when AF_UNIX
is unavailable. The runner retains authorization and the bare-Xvfb protocol atom.
