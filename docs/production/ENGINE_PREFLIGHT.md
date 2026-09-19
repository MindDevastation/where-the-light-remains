# Engine preflight

Status: **IN PROGRESS**. Real headless editor import and runtime smoke checks
have passed. Graphical Forward+ validation, final validation and branch
integration are pending; the feature is not yet completed.

## Verified runtime

- Godot: `4.7.2.stable.official.ed1daf0bf`.
- Engine version fields: major `4`, minor `7`, patch `2`, status `stable`,
  build `official`, source hash `ed1daf0bf001b61586d9930840f2f1394092c079`.
- Standard GDScript editor; runtime `OS.has_feature("C#")` returned `false`.
- Development environment: Ubuntu 24.04 x86_64. Product target remains Windows.
- Official release: <https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable>.
- Download: `Godot_v4.7.2-stable_linux.x86_64.zip`.
- SHA-256 checked against the official release asset digest:
  `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`.

The official stable release was installed because this environment had no
Godot executable and the project had no verified minor version. The owner
explicitly authorized installing the required tools. The version was pinned
only after executing Godot and successfully importing/running the scaffold.

## Checks performed so far

- All ten mandatory design/production documents read at starting commit
  `6e04017fa4238fe1f32721c02dcf91a200c45ecc`.
- `main`, `epic/00-foundation` and `feature/00-foundation/engine-preflight`
  fetched and verified at that starting commit.
- `--version`: confirmed the exact executable build above.
- `--headless --editor --import`: exit `0`, no parse or resource errors.
- Normal project startup with `--headless --quit-after 120`: completed.
- `--headless --script res://tests/engine_preflight.gd`: exit `0` and explicit
  `ENGINE_PREFLIGHT PASS`; GameRoot and its children instantiated, all eight
  autoload scripts loaded, WorldSlot bound, initial stage event emitted,
  baseline settings checked and `App.request_safe_exit()` completed.

Headless validation exercises the real engine but does not prove graphical
Vulkan rendering, even if rendering method getters report configured defaults.

## Reproduce

From the repository root, with `GODOT` set to the Godot 4.7.2 executable:

```sh
"$GODOT" --version
"$GODOT" --headless --path game --editor --import
"$GODOT" --headless --path game --script res://tests/engine_preflight.gd
"$GODOT" --path game
```

Every process must exit successfully and its output must contain no
`SCRIPT ERROR`, parse errors, missing resources or fatal startup errors.
The assertion run must print `ENGINE_PREFLIGHT PASS`. Close the normal project
window using the window close button. The empty GameRoot view is expected at
this milestone; gameplay and UI are separate features.

The smoke script is CLI-only and is not registered as an autoload or attached
to a production scene. Generated `.gd.uid` files are tracked resource identity
metadata. The `.godot/` editor/import cache remains ignored.
