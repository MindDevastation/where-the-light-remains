# Audio baseline

Derived from Audio Direction v1.2 + AUDIO_PLAN v1.0.

## Principles

Music supports gameplay/text/SFX and never dictates a romantic interpretation early. The score is one evolving system. Core palette: felt piano, celesta, glass/crystal harmonics, soft strings, occasional pizzicato/plucks, restrained mechanical pulse, room tone and natural ambience.

Forbidden baseline: trailer brass, heroic choir, EDM drops, aggressive dubstep/synthwave, saccharine romantic pop language, horror drones and constant orchestral climax.

Mandatory audio puzzles always have visual equivalents.

## Archive motif

Short recognizable four-note identity. Prologue reveals only the seed/first note; Stage 1 expands it; later wings add timbral layers. Final harmonic resolution is reserved for the confession/finale arc. Generated tracks are source material; do not assume identical motifs across takes without editing.

## Integration

`AudioDirector` is the single owner of global music/ambience players, crossfades, snapshots, ducking and silence locks. World scripts request semantic state/event changes.

Normal calm scenes may use group playlists, but authored stage substates override them. Important text reduces score by roughly 3–6 dB or thins the orchestration.

Source tracks should be edited into loopable sections/stems where needed. Loop points must avoid expressive cadences/clicks.

## Bus layout

`game/audio/default_bus_layout.tres` is the project's default `AudioBusLayout`,
selected explicitly by `audio/buses/default_bus_layout` in `project.godot`.
The foundation layout expands the planned Music/Main/Stems and
SFX/Critical/World groups into these distinct Godot bus names:

| Index | Bus | Sends to | Role |
| --- | --- | --- | --- |
| 0 | `Master` | Output | Overall mix |
| 1 | `Music` | `Master` | Parent control for all score layers |
| 2 | `Music_Main` | `Music` | Main music cues / crossfade players |
| 3 | `Music_Stems` | `Music` | Authored music stems and layers |
| 4 | `SFX` | `Master` | Parent control for effects |
| 5 | `SFX_Critical` | `SFX` | Gameplay cues with mandatory visual equivalents |
| 6 | `SFX_World` | `SFX` | World sound effects |
| 7 | `Ambience` | `Master` | Environmental beds / room tone |
| 8 | `UI` | `Master` | Interface feedback |
| 9 | `VO_RESERVED` | `Master` | Reserved voice route; no playback enabled |

Every send targets an earlier bus, so each route reaches Master without a
cycle. Consumers should resolve buses by name rather than retain numeric
indices. Ambience and UI are independent of Music and SFX in this layout.
Muting Music therefore covers its Main and Stems children while preserving
the other branches. Muting SFX covers both Critical and World; mandatory cues
must still have their visual equivalents.

The foundation layout uses neutral `0 dB` bus gain, no effects and no active
mute/solo/bypass flags. This is routing infrastructure, not a final loudness
or mix pass. The settings UI and saved volume application are later work;
the scaffold's `SettingsManager` volume fields are not applied by this change.
`AudioDirector` retains ownership of global players, authored silence,
ducking and snapshots. Reserving a VO bus does not change the vocal policy.

## Canonical substates

Egg: `STEALTH → EGG_PICKUP → BOSS_WAKE → CHASE → RESCUE → COMEDIC_BEAT`.

Finale: `HUB_FINAL → PUZZLE → POEM → ACROSTIC → CONFESSION → DAWN` with finer dawn substates allowed.

## Silence map — non-negotiable

- Stage 0: near-silence before first spark.
- Stage 6: deliberate silence immediately after egg pickup; near-silence/comedic release after rescue.
- Stage 7: large negative-space passages.
- Stage 8: music almost disappears around `Не создана`.
- Stage 9: key future text receives near-silence.
- Stage 11/12/13: space after final sigil/pair, full poem and acrostic reveal.
- Stage 14: `Я люблю тебя` remains without a second musical event; force roughly 4–6 seconds of complete music silence after the phrase.
- Stage 15: no second climax; end resolves into natural ambience/wind/glass.

## Vocal policy

Stages 0–14: instrumental only; avoid wordless material that resembles intelligible phonemes. Optional vocal song may begin only after the Stage 15 final wide shot and after `game_completed`, and is not canonical emotional content.
