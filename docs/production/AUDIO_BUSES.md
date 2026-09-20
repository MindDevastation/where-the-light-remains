# Audio bus validation

Runtime validation: **PASS**, 2026-09-20.

Epic: `epic/00-foundation`.
Feature: `feature/00-foundation/audio-buses`.
Integration follows feature → epic → main with separate merge commits.
The corresponding Git history records the integration SHAs.

## Implemented contract

The project explicitly loads `res://audio/default_bus_layout.tres` at startup.
It contains Master; Music with Main/Stems children; SFX with Critical/World
children; and independent Ambience, UI and VO_RESERVED branches. The exact
Godot names, order and send targets are documented in
[`AUDIO_BASELINE.md`](../design/AUDIO_BASELINE.md#bus-layout).

All buses start at neutral gain with no effects or active mute/solo/bypass
flags. Each send reaches an earlier bus and ultimately Master. The resource
uses Godot's own AudioBusLayout serialization; the implicit Master defaults
are verified after loading. No autoload or production player script changed.

## Validation actually performed

- Engine: standard **Godot 4.7.2 stable**, executable version
  `4.7.2.stable.official.ed1daf0bf`.
- Environment: Linux, headless display, `Dummy` audio driver.
- Committed source: `915abb3586b8b4c4ef3f8b5bc8dfe78a55eea23a`.
- Verified `game/` tree: `4440b1604fe2027abca2167e374dbad590c3cca4`.
- Final validation used a fresh `git archive` of `game/`, with no `.godot/`
  cache before import. Archived source files were unchanged after the checks.

| Check | Actual result |
| --- | --- |
| Clean editor import | Exit 0; no parse/resource errors or warnings |
| Audio bus mixer test | Exit 0; `AUDIO_BUS PASS` |
| InputMap regression | Exit 0; `INPUT_MAP PASS` |
| GameRoot/eight-autoload startup and App safe exit | Exit 0; `ENGINE_PREFLIGHT PASS` |
| Normal headless startup | Exit 0 after 120 frames |
| Original project settings without the default-layout selection | Expected exit 1; only Master loaded and missing buses detected |

`game/tests/audio_bus_smoke.gd` first inspects the automatically loaded layout
without calling `set_bus_layout()`. It then creates a finite 440 Hz PCM tone
in memory and routes one temporary AudioStreamPlayer through every bus.
Temporary AudioEffectCapture instances observe Master, Music and SFX.

| Mixer assertion | Measured result |
| --- | --- |
| Signal sent to each of the ten buses reaches Master | Peak approximately `0.099979` |
| Music inputs traverse Music; SFX inputs traverse SFX | Expected parent carries the signal; other group stays at zero |
| Each Music/SFX parent set to half linear gain | Master amplitude ratio `0.5` for both children |
| Music parent muted | Master peak `0.0` from Main and Stems |
| SFX parent muted | Master peak `0.0` from Critical and World |
| Music muted while SFX_Critical, Ambience or UI plays | Independent branch still carries a signal |
| SFX muted while Music_Main plays | Music still carries a signal |
| Test cleanup | Original layout restored; neutral gains/flags and zero effects rechecked |

The test waits for stopped playback to finish before freeing its temporary
resources and has a 30-second failure timeout. During test development, a
typed-array assignment was corrected, an early looping fixture with inconsistent
peak readings was replaced with finite PCM, and playback cleanup was fixed.
Final clean checks exited without script errors or resource-leak warnings.

Actual commands, output and exit codes are retained in
[`evidence/audio_buses_2026-09-20.log`](evidence/audio_buses_2026-09-20.log).
Terminal color sequences and trailing line spaces were removed from the output.

## Scope and remaining work

The capture test verifies the internal Godot mixer using a generated signal.
It does not verify speakers/headphones, device switching, Windows playback,
perceived loudness, musical balance or real source-track quality. No production
audio assets, microphone input or heavy binaries were added.

The layout prepares routes for later consumers. SettingsManager volume
application/UI, AudioDirector players/crossfades/ducking/silence locks, runtime
asset conversion and the final mix pass remain separate work. Neutral bus gain
does not establish release loudness. The VO route remains unused and does not
change the instrumental/vocal policy. No player-facing text was added.

The test is CLI-only; its signal, player and capture effects are not connected
to production scenes or autoloads. Global music/ambience ownership remains
with AudioDirector. The canonical silence map and visual equivalents for
mandatory sound information are unchanged.

## Reproduce

From the repository root, with `GODOT` set to the verified executable:

```sh
"$GODOT" --headless --path game --editor --import
"$GODOT" --headless --path game --script res://tests/audio_bus_smoke.gd
"$GODOT" --headless --path game --script res://tests/input_map_smoke.gd
"$GODOT" --headless --path game --script res://tests/engine_preflight.gd
"$GODOT" --headless --path game --quit-after 120
```

All commands must exit 0 without script/resource errors or leak warnings;
the three assertion scripts must emit their respective `PASS` markers.
Before epic → main integration, preserve the verified runtime files and
repeat the audio and startup smoke checks on the epic candidate.

Engine references:
[Audio buses](https://docs.godotengine.org/en/4.7/tutorials/audio/audio_buses.html),
[AudioServer](https://docs.godotengine.org/en/4.7/classes/class_audioserver.html),
[AudioEffectCapture](https://docs.godotengine.org/en/4.7/classes/class_audioeffectcapture.html).

Next foundation feature: `feature/00-foundation/debug-tools`.
